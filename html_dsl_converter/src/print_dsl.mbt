///|
/// Recursively walk a `@html_dsl.Html` node and print the MoonBit source
/// code that defines it, using the html_dsl builder functions.
///
/// Example: a `div` with id/class attributes wrapping a paragraph becomes
/// `div(id="divid-01", class="flex flex-row", [p([text("hello")])])`.
///
/// Attributes that a tag's builder cannot express as labelled arguments are
/// kept in an `attrs=[Attr::...]` list, and tags without a dedicated builder
/// fall back to the generic `node("tag", attrs=[...], [children])` builder.
fn print_html_dsl(node : @h.Html) -> String {
  match node {
    @h.Html::Text(s) => "text(\{str_lit(s)})"
    @h.Html::Nothing => "nothing()"
    @h.Html::Unsafe(s) => "raw_html(\{str_lit(s)})"
    @h.Html::Fragment(children) => "fragment([\{print_children(children)}])"
    @h.Html::Comment(data) => "comment(\{str_lit(data)})"
    @h.Html::Node(tag, attrs, children) => print_element(tag, attrs, children)
  }
}

///|
/// Join the printed children of an element or fragment.
fn print_children(children : Array[@h.Html]) -> String {
  children.map(print_html_dsl).join(", ")
}

///|
/// Print an element node: known tags use their dedicated builder with
/// labelled arguments, unknown tags fall back to the generic `node` builder.
fn print_element(
  tag : String,
  attrs : Array[@h.Attr],
  children : Array[@h.Html],
) -> String {
  if tag == "script" {
    return print_script(attrs, children)
  }
  if tag == "title" {
    return print_title(attrs, children)
  }
  if tag == "head" {
    if attrs.is_empty() {
      return "head([\{print_children(children)}])"
    }
    return node_literal(tag, attrs, children)
  }
  if tag == "html" {
    return print_html_el(attrs, children)
  }
  if tag == "br" || tag == "hr" {
    if attrs.is_empty() {
      return "\{tag}()"
    }
    return node_literal(tag, attrs, children)
  }
  if tag == "embed" || tag == "source" || tag == "track" {
    return print_media(tag, attrs, children)
  }
  match svg_tag_shape(tag) {
    Some(shape) => return print_svg_element(tag, attrs, children, shape)
    None => ()
  }
  match tag_shape(tag) {
    None => node_literal(tag, attrs, children)
    Some(shape) => {
      for required in shape.required {
        if !has_named(attrs, required) {
          return node_literal(tag, attrs, children)
        }
      }
      if !shape.children && !children.is_empty() && !is_void_tag(tag) {
        return node_literal(tag, attrs, children)
      }
      let parts : Array[String] = []
      let rest : Array[String] = []
      for attr in attrs {
        match attr_named(attr) {
          Some((name, value)) if shape.args.contains(name) =>
            parts.push("\{name}=\{value}")
          _ => rest.push(attr_literal(attr))
        }
      }
      if !rest.is_empty() {
        parts.push("attrs=[\{rest.join(", ")}]")
      }
      if shape.children {
        parts.push("[\{print_children(children)}]")
      }
      "\{shape.name}(\{parts.join(", ")})"
    }
  }
}

///|
/// Print a `<script>` element: body-only scripts use `inline_script`, and
/// scripts with a `src` use the `script` builder; anything else falls back to
/// the generic `node` builder.
fn print_script(attrs : Array[@h.Attr], children : Array[@h.Html]) -> String {
  if attrs.is_empty() {
    let body = StringBuilder::new()
    let mut ok = true
    for child in children {
      match child {
        @h.Html::Unsafe(s) => body.write_string(s)
        _ => {
          ok = false
          break
        }
      }
    }
    if ok {
      return "inline_script(\{str_lit(body.to_string())})"
    }
    return node_literal("script", attrs, children)
  }
  if !children.is_empty() {
    return node_literal("script", attrs, children)
  }
  let parts : Array[String] = []
  let mut ok = true
  let mut src_seen = false
  for attr in attrs {
    match attr {
      @h.Attr::Src(v) | @h.Attr::Prop("src", v) => {
        parts.push("src=\{str_lit(v)}")
        src_seen = true
      }
      @h.Attr::Async(b) => parts.push("async_=\{bool_lit(b)}")
      @h.Attr::Defer(b) => parts.push("defer_=\{bool_lit(b)}")
      @h.Attr::Type_(v) | @h.Attr::Prop("type", v) =>
        parts.push("type_=\{str_lit(v)}")
      _ => {
        ok = false
        break
      }
    }
  }
  if ok && src_seen {
    "script(\{parts.join(", ")})"
  } else {
    node_literal("script", attrs, children)
  }
}

///|
/// Print a `<title>` element as `title("...")` when its content is plain text.
fn print_title(attrs : Array[@h.Attr], children : Array[@h.Html]) -> String {
  if attrs.is_empty() {
    let body = StringBuilder::new()
    let mut ok = true
    for child in children {
      match child {
        @h.Html::Text(s) => body.write_string(s)
        _ => {
          ok = false
          break
        }
      }
    }
    if ok {
      return "title(\{str_lit(body.to_string())})"
    }
  }
  node_literal("title", attrs, children)
}

///|
/// Print an `<html>` element as `html_el(lang="...", [...])` when its only
/// attribute is `lang`; otherwise fall back to the generic `node` builder
/// (because `html_el` always emits a `lang` attribute).
fn print_html_el(attrs : Array[@h.Attr], children : Array[@h.Html]) -> String {
  let mut lang : String? = None
  for attr in attrs {
    match attr {
      @h.Attr::Lang(v) | @h.Attr::Prop("lang", v) => lang = Some(v)
      _ => return node_literal("html", attrs, children)
    }
  }
  match lang {
    Some(value) =>
      "html_el(lang=\{str_lit(value)}, [\{print_children(children)}])"
    None => node_literal("html", attrs, children)
  }
}

///|
/// Print void media elements (`embed`, `source`, `track`) with their `src`
/// and, where supported, `type_` / `kind` / `label` attributes.
fn print_media(
  tag : String,
  attrs : Array[@h.Attr],
  children : Array[@h.Html],
) -> String {
  let parts : Array[String] = []
  let mut ok = true
  let mut src_seen = false
  for attr in attrs {
    match attr {
      @h.Attr::Src(v) | @h.Attr::Prop("src", v) => {
        parts.push("src=\{str_lit(v)}")
        src_seen = true
      }
      @h.Attr::Type_(v) | @h.Attr::Prop("type", v) =>
        parts.push("type_=\{str_lit(v)}")
      @h.Attr::Label_(v) | @h.Attr::Prop("label", v) if tag == "track" =>
        parts.push("label=\{str_lit(v)}")
      @h.Attr::Prop("kind", v) if tag == "track" =>
        parts.push("kind=\{str_lit(v)}")
      _ => {
        ok = false
        break
      }
    }
  }
  if ok && src_seen {
    let name = if tag == "source" { "source_" } else { tag }
    "\{name}(\{parts.join(", ")})"
  } else {
    node_literal(tag, attrs, children)
  }
}

///|
/// Print an element with the generic `node(tag, attrs, children)` builder.
fn node_literal(
  tag : String,
  attrs : Array[@h.Attr],
  children : Array[@h.Html],
) -> String {
  "node(\{str_lit(tag)}, [\{attrs.map(attr_literal).join(", ")}], [\{print_children(children)}])"
}

///|
/// The html_dsl builder for a tag: its function name, the labelled arguments
/// it accepts (besides children), whether it takes a children array, and any
/// labelled arguments that are required.
priv struct TagShape {
  name : String
  args : Array[String]
  children : Bool
  required : Array[String]
}

///|
/// Look up the builder shape for a tag, or `None` when the tag has no
/// dedicated builder (the generic `node` builder is used instead).
fn tag_shape(tag : String) -> TagShape? {
  let standard : Array[String] = ["id", "class", "attrs"]
  match tag {
    "address"
    | "article"
    | "aside"
    | "b"
    | "caption"
    | "code"
    | "datalist"
    | "dd"
    | "div"
    | "dl"
    | "dt"
    | "em"
    | "figcaption"
    | "figure"
    | "footer"
    | "h1"
    | "h2"
    | "h3"
    | "h4"
    | "h5"
    | "h6"
    | "header"
    | "i"
    | "legend"
    | "li"
    | "mark"
    | "nav"
    | "ol"
    | "p"
    | "pre"
    | "section"
    | "small"
    | "span"
    | "strong"
    | "sub"
    | "summary"
    | "sup"
    | "table"
    | "tbody"
    | "tfoot"
    | "thead"
    | "tr"
    | "ul" => Some({ name: tag, args: standard, children: true, required: [] })
    "main" =>
      Some({ name: "main_", args: standard, children: true, required: [] })
    "a" =>
      Some({
        name: "a",
        args: ["id", "href", "class", "target", "attrs"],
        children: true,
        required: [],
      })
    "abbr" =>
      Some({
        name: "abbr",
        args: ["id", "class", "title", "attrs"],
        children: true,
        required: [],
      })
    "audio" =>
      Some({
        name: "audio",
        args: [
          "id", "class", "src", "controls", "autoplay", "loop_", "muted", "attrs",
        ],
        children: true,
        required: [],
      })
    "blockquote" =>
      Some({
        name: "blockquote",
        args: ["id", "class", "cite", "attrs"],
        children: true,
        required: [],
      })
    "body" =>
      Some({ name: "body", args: ["attrs"], children: true, required: [] })
    "button" =>
      Some({
        name: "button",
        args: ["id", "on_click_", "class", "disabled", "attrs"],
        children: true,
        required: [],
      })
    "canvas" =>
      Some({
        name: "canvas",
        args: ["id", "class", "width", "height", "attrs"],
        children: true,
        required: [],
      })
    "col" =>
      Some({
        name: "col",
        args: ["span", "attrs"],
        children: false,
        required: [],
      })
    "colgroup" =>
      Some({ name: "colgroup", args: ["attrs"], children: true, required: [] })
    "details" =>
      Some({
        name: "details",
        args: ["id", "class", "attrs"],
        children: true,
        required: [],
      })
    "fieldset" =>
      Some({
        name: "fieldset",
        args: ["id", "class", "disabled", "attrs"],
        children: true,
        required: [],
      })
    "form" =>
      Some({
        name: "form",
        args: ["id", "class", "action", "method_", "attrs", "on_submit_"],
        children: true,
        required: [],
      })
    "iframe" =>
      Some({
        name: "iframe",
        args: ["id", "class", "src", "title", "width", "height", "attrs"],
        children: false,
        required: ["src"],
      })
    "img" =>
      Some({
        name: "img",
        args: ["id", "class", "src", "alt", "width", "height", "attrs"],
        children: false,
        required: ["src"],
      })
    "input" =>
      Some({
        name: "input",
        args: [
          "name", "class", "id", "value", "placeholder", "on_change", "required",
          "disabled", "checked", "attrs",
        ],
        children: false,
        required: [],
      })
    "label" =>
      Some({
        name: "label",
        args: ["id", "class", "for_", "attrs"],
        children: true,
        required: [],
      })
    "link" =>
      Some({
        name: "link",
        args: ["href", "rel", "attrs"],
        children: false,
        required: ["href", "rel"],
      })
    "meta" =>
      Some({
        name: "meta",
        args: ["charset", "content", "name", "attrs"],
        children: false,
        required: [],
      })
    "meter" =>
      Some({
        name: "meter",
        args: ["id", "class", "value", "min", "max", "attrs"],
        children: true,
        required: [],
      })
    "option" =>
      Some({
        name: "option",
        args: ["value", "selected", "disabled", "attrs"],
        children: true,
        required: [],
      })
    "optgroup" =>
      Some({
        name: "optgroup",
        args: ["label", "disabled", "attrs"],
        children: true,
        required: ["label"],
      })
    "progress" =>
      Some({
        name: "progress",
        args: ["id", "class", "value", "max", "attrs"],
        children: false,
        required: [],
      })
    "q" =>
      Some({
        name: "q",
        args: ["id", "class", "cite", "attrs"],
        children: true,
        required: [],
      })
    "select" =>
      Some({
        name: "select",
        args: [
          "name", "id", "class", "multiple", "required", "disabled", "on_change",
          "attrs",
        ],
        children: true,
        required: [],
      })
    "td" | "th" =>
      Some({
        name: tag,
        args: ["id", "class", "colspan", "rowspan", "attrs"],
        children: true,
        required: [],
      })
    "textarea" =>
      Some({
        name: "textarea",
        args: [
          "name", "id", "class", "value", "placeholder", "rows", "cols", "on_change",
          "required", "disabled", "attrs",
        ],
        children: false,
        required: [],
      })
    "time" =>
      Some({
        name: "time",
        args: ["id", "class", "datetime", "attrs"],
        children: true,
        required: [],
      })
    "video" =>
      Some({
        name: "video",
        args: [
          "id", "class", "src", "controls", "autoplay", "loop_", "muted", "poster",
          "width", "height", "attrs",
        ],
        children: true,
        required: [],
      })
    _ => None
  }
}

///|
/// Check whether one of the attrs maps to the given labelled argument name.
fn has_named(attrs : Array[@h.Attr], name : String) -> Bool {
  for attr in attrs {
    match attr_named(attr) {
      Some((n, _)) if n == name => return true
      _ => ()
    }
  }
  false
}

///|
/// Map an attribute to its labelled-argument form `(name, value_source)`,
/// or `None` for attributes that can only be expressed inside `attrs=[...]`.
fn attr_named(attr : @h.Attr) -> (String, String)? {
  match attr {
    @h.Attr::Id(v) => Some(("id", str_lit(v)))
    @h.Attr::Class(v) => Some(("class", str_lit(v)))
    @h.Attr::Href(v) => Some(("href", str_lit(v)))
    @h.Attr::Src(v) => Some(("src", str_lit(v)))
    @h.Attr::Alt(v) => Some(("alt", str_lit(v)))
    @h.Attr::Value(v) => Some(("value", str_lit(v)))
    @h.Attr::Placeholder(v) => Some(("placeholder", str_lit(v)))
    @h.Attr::Name(v) => Some(("name", str_lit(v)))
    @h.Attr::For_(v) => Some(("for_", str_lit(v)))
    @h.Attr::Action(v) => Some(("action", str_lit(v)))
    @h.Attr::Method(v) => Some(("method_", str_lit(v)))
    @h.Attr::Charset(v) => Some(("charset", str_lit(v)))
    @h.Attr::Rel(v) => Some(("rel", str_lit(v)))
    @h.Attr::Lang(v) => Some(("lang", str_lit(v)))
    @h.Attr::Target_(t) => Some(("target", target_lit(t)))
    @h.Attr::Disabled(b) => Some(("disabled", bool_lit(b)))
    @h.Attr::Checked(b) => Some(("checked", bool_lit(b)))
    @h.Attr::Required(b) => Some(("required", bool_lit(b)))
    @h.Attr::Readonly(b) => Some(("readonly", bool_lit(b)))
    @h.Attr::AutoFocus(b) => Some(("autofocus", bool_lit(b)))
    @h.Attr::Multiple(b) => Some(("multiple", bool_lit(b)))
    @h.Attr::Defer(b) => Some(("defer_", bool_lit(b)))
    @h.Attr::Async(b) => Some(("async_", bool_lit(b)))
    @h.Attr::Rows(n) => Some(("rows", n.to_string()))
    @h.Attr::Cols(n) => Some(("cols", n.to_string()))
    @h.Attr::Controls(b) => Some(("controls", bool_lit(b)))
    @h.Attr::Autoplay(b) => Some(("autoplay", bool_lit(b)))
    @h.Attr::Loop_(b) => Some(("loop_", bool_lit(b)))
    @h.Attr::Muted(b) => Some(("muted", bool_lit(b)))
    @h.Attr::Poster(v) => Some(("poster", str_lit(v)))
    @h.Attr::Min(v) => Some(("min", str_lit(v)))
    @h.Attr::Max(v) => Some(("max", str_lit(v)))
    @h.Attr::Step(v) => Some(("step", str_lit(v)))
    @h.Attr::Selected(b) => Some(("selected", bool_lit(b)))
    @h.Attr::Label_(v) => Some(("label", str_lit(v)))
    @h.Attr::DateTime(v) => Some(("datetime", str_lit(v)))
    @h.Attr::Colspan(n) => Some(("colspan", n.to_string()))
    @h.Attr::Rowspan(n) => Some(("rowspan", n.to_string()))
    @h.Attr::Width(n) => Some(("width", n.to_string()))
    @h.Attr::Height(n) => Some(("height", n.to_string()))
    @h.Attr::Title_(v) => Some(("title", str_lit(v)))
    @h.Attr::Cite(v) => Some(("cite", str_lit(v)))
    @h.Attr::On(@h.Event::Click(js)) => Some(("on_click_", str_lit(js)))
    @h.Attr::On(@h.Event::Change(js)) => Some(("on_change", str_lit(js)))
    @h.Attr::On(@h.Event::Submit(js)) => Some(("on_submit_", str_lit(js)))
    _ => None
  }
}

///|
/// Render an attribute as an `Attr::...` constructor call for use inside an
/// `attrs=[...]` list.
fn attr_literal(attr : @h.Attr) -> String {
  match attr {
    @h.Attr::Id(v) => "Attr::Id(\{str_lit(v)})"
    @h.Attr::Class(v) => "Attr::Class(\{str_lit(v)})"
    @h.Attr::Href(v) => "Attr::Href(\{str_lit(v)})"
    @h.Attr::Src(v) => "Attr::Src(\{str_lit(v)})"
    @h.Attr::Alt(v) => "Attr::Alt(\{str_lit(v)})"
    @h.Attr::Type_(v) => "Attr::Type_(\{str_lit(v)})"
    @h.Attr::Value(v) => "Attr::Value(\{str_lit(v)})"
    @h.Attr::Placeholder(v) => "Attr::Placeholder(\{str_lit(v)})"
    @h.Attr::Name(v) => "Attr::Name(\{str_lit(v)})"
    @h.Attr::For_(v) => "Attr::For_(\{str_lit(v)})"
    @h.Attr::Action(v) => "Attr::Action(\{str_lit(v)})"
    @h.Attr::Method(v) => "Attr::Method(\{str_lit(v)})"
    @h.Attr::Charset(v) => "Attr::Charset(\{str_lit(v)})"
    @h.Attr::Rel(v) => "Attr::Rel(\{str_lit(v)})"
    @h.Attr::Lang(v) => "Attr::Lang(\{str_lit(v)})"
    @h.Attr::Disabled(b) => "Attr::Disabled(\{bool_lit(b)})"
    @h.Attr::Checked(b) => "Attr::Checked(\{bool_lit(b)})"
    @h.Attr::Required(b) => "Attr::Required(\{bool_lit(b)})"
    @h.Attr::Readonly(b) => "Attr::Readonly(\{bool_lit(b)})"
    @h.Attr::AutoFocus(b) => "Attr::AutoFocus(\{bool_lit(b)})"
    @h.Attr::Multiple(b) => "Attr::Multiple(\{bool_lit(b)})"
    @h.Attr::Target_(t) => "Attr::Target_(\{target_lit(t)})"
    @h.Attr::Defer(b) => "Attr::Defer(\{bool_lit(b)})"
    @h.Attr::Async(b) => "Attr::Async(\{bool_lit(b)})"
    @h.Attr::Rows(n) => "Attr::Rows(\{n})"
    @h.Attr::Cols(n) => "Attr::Cols(\{n})"
    @h.Attr::Controls(b) => "Attr::Controls(\{bool_lit(b)})"
    @h.Attr::Autoplay(b) => "Attr::Autoplay(\{bool_lit(b)})"
    @h.Attr::Loop_(b) => "Attr::Loop_(\{bool_lit(b)})"
    @h.Attr::Muted(b) => "Attr::Muted(\{bool_lit(b)})"
    @h.Attr::Poster(v) => "Attr::Poster(\{str_lit(v)})"
    @h.Attr::Min(v) => "Attr::Min(\{str_lit(v)})"
    @h.Attr::Max(v) => "Attr::Max(\{str_lit(v)})"
    @h.Attr::Step(v) => "Attr::Step(\{str_lit(v)})"
    @h.Attr::Selected(b) => "Attr::Selected(\{bool_lit(b)})"
    @h.Attr::Label_(v) => "Attr::Label_(\{str_lit(v)})"
    @h.Attr::DateTime(v) => "Attr::DateTime(\{str_lit(v)})"
    @h.Attr::Colspan(n) => "Attr::Colspan(\{n})"
    @h.Attr::Rowspan(n) => "Attr::Rowspan(\{n})"
    @h.Attr::Width(n) => "Attr::Width(\{n})"
    @h.Attr::Height(n) => "Attr::Height(\{n})"
    @h.Attr::Title_(v) => "Attr::Title_(\{str_lit(v)})"
    @h.Attr::Cite(v) => "Attr::Cite(\{str_lit(v)})"
    @h.Attr::Style(pairs) =>
      "Attr::Style([\{pairs.map(fn(pair) { "(\{str_lit(pair.0)}, \{str_lit(pair.1)})" }).join(", ")}])"
    @h.Attr::Aria(k, v) => "Attr::Aria(\{str_lit(k)}, \{str_lit(v)})"
    @h.Attr::Data(k, v) => "Attr::Data(\{str_lit(k)}, \{str_lit(v)})"
    @h.Attr::Prop(k, v) => "Attr::Prop(\{str_lit(k)}, \{str_lit(v)})"
    @h.Attr::On(event) => "Attr::On(\{event_lit(event)})"
    @h.Attr::OnRawEvent(k, v) =>
      "Attr::OnRawEvent(\{str_lit(k)}, \{str_lit(v)})"
  }
}

///|
/// Render a DOM event as an `Event::...` constructor call.
fn event_lit(event : @h.Event) -> String {
  match event {
    @h.Event::Click(js) => "Event::Click(\{str_lit(js)})"
    @h.Event::DblClick(js) => "Event::DblClick(\{str_lit(js)})"
    @h.Event::MouseEnter(js) => "Event::MouseEnter(\{str_lit(js)})"
    @h.Event::MouseLeave(js) => "Event::MouseLeave(\{str_lit(js)})"
    @h.Event::Change(js) => "Event::Change(\{str_lit(js)})"
    @h.Event::Input(js) => "Event::Input(\{str_lit(js)})"
    @h.Event::Submit(js) => "Event::Submit(\{str_lit(js)})"
    @h.Event::Focus(js) => "Event::Focus(\{str_lit(js)})"
    @h.Event::Blur(js) => "Event::Blur(\{str_lit(js)})"
    @h.Event::KeyDown(js) => "Event::KeyDown(\{str_lit(js)})"
    @h.Event::KeyUp(js) => "Event::KeyUp(\{str_lit(js)})"
    @h.Event::KeyPress(js) => "Event::KeyPress(\{str_lit(js)})"
  }
}

///|
/// Render a link target as its `Target` constructor name.
fn target_lit(target : @h.Target) -> String {
  match target {
    @h.Target::Self_ => "Self_"
    @h.Target::Blank => "Blank"
    @h.Target::Parent => "Parent"
    @h.Target::Top => "Top"
  }
}

///|
/// The tags that html_dsl's renderer treats as void (children never render).
fn is_void_tag(tag : String) -> Bool {
  match tag {
    "area"
    | "base"
    | "br"
    | "col"
    | "embed"
    | "hr"
    | "img"
    | "input"
    | "link"
    | "meta"
    | "param"
    | "source"
    | "track"
    | "wbr" => true
    _ => false
  }
}

///|
/// Escape a string as a MoonBit string literal, including the quotes.
fn str_lit(s : String) -> String {
  let buf = StringBuilder::new(size_hint=s.length() + 2)
  buf.write_char('"')
  s
  .iter()
  .each(fn(c) {
    match c {
      '\\' => buf.write_string("\\\\")
      '"' => buf.write_string("\\\"")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(c)
    }
  })
  buf.write_char('"')
  buf.to_string()
}

///|
/// Render a bool as a MoonBit literal.
fn bool_lit(b : Bool) -> String {
  if b {
    "true"
  } else {
    "false"
  }
}

///|
/// The @svg builder for an SVG tag: its function name, the labelled arguments
/// it accepts (besides children), and whether the children array is positional
/// (`children:`) or optional (`children? :`, printed only when non-empty).
fn svg_tag_shape(tag : String) -> TagShape? {
  match tag {
    "svg" =>
      Some({
        name: "svg",
        args: ["width", "height", "view_box", "attrs"],
        children: true,
        required: [],
      })
    "g" => Some({ name: "g", args: ["attrs"], children: true, required: [] })
    "rect" =>
      Some({
        name: "rect",
        args: ["x", "y", "width", "height", "rx", "ry", "attrs"],
        children: false,
        required: [],
      })
    "circle" =>
      Some({
        name: "circle",
        args: ["cx", "cy", "r", "attrs"],
        children: false,
        required: [],
      })
    "ellipse" =>
      Some({
        name: "ellipse",
        args: ["cx", "cy", "rx", "ry", "attrs"],
        children: false,
        required: [],
      })
    "line" =>
      Some({
        name: "line",
        args: ["x1", "y1", "x2", "y2", "attrs"],
        children: false,
        required: [],
      })
    "polyline" =>
      Some({
        name: "polyline",
        args: ["points", "attrs"],
        children: false,
        required: [],
      })
    "polygon" =>
      Some({
        name: "polygon",
        args: ["points", "attrs"],
        children: false,
        required: [],
      })
    "path" =>
      Some({ name: "path", args: ["d", "attrs"], children: false, required: [] })
    "text" =>
      Some({
        name: "text",
        args: ["x", "y", "attrs"],
        children: true,
        required: [],
      })
    "tspan" =>
      Some({
        name: "tspan",
        args: ["x", "y", "attrs"],
        children: true,
        required: [],
      })
    "defs" =>
      Some({ name: "defs", args: ["attrs"], children: true, required: [] })
    "linearGradient" =>
      Some({
        name: "linear_gradient",
        args: ["id", "attrs"],
        children: true,
        required: [],
      })
    "radialGradient" =>
      Some({
        name: "radial_gradient",
        args: ["id", "attrs"],
        children: true,
        required: [],
      })
    "stop" =>
      Some({
        name: "stop",
        args: ["offset", "attrs"],
        children: false,
        required: [],
      })
    "clipPath" =>
      Some({
        name: "clip_path",
        args: ["id", "attrs"],
        children: true,
        required: [],
      })
    "mask" =>
      Some({ name: "mask", args: ["id", "attrs"], children: true, required: [] })
    "use" =>
      Some({
        name: "use_",
        args: ["href", "attrs"],
        children: false,
        required: [],
      })
    "title" =>
      Some({ name: "title", args: ["attrs"], children: true, required: [] })
    "desc" =>
      Some({ name: "desc", args: ["attrs"], children: true, required: [] })
    _ => None
  }
}

///|
/// Print an SVG element with its `@svg` builder.
///
/// Generic `Prop` attributes map to the builder's labelled arguments when it
/// accepts them and to `SvgAttr::...` constructors otherwise; any attribute
/// that is not a plain `Prop` falls back to the generic `node` builder.
fn print_svg_element(
  tag : String,
  attrs : Array[@h.Attr],
  children : Array[@h.Html],
  shape : TagShape,
) -> String {
  let parts : Array[String] = []
  let rest : Array[String] = []
  for attr in attrs {
    match attr {
      @h.Attr::Prop(name, value) => {
        let arg = svg_labelled_arg(name)
        if shape.args.contains(arg) {
          parts.push("\{arg}=\{str_lit(value)}")
        } else {
          rest.push(svg_attr_literal(name, value))
        }
      }
      _ => return node_literal(tag, attrs, children)
    }
  }
  if !rest.is_empty() {
    parts.push("attrs=[\{rest.join(", ")}]")
  }
  if shape.children {
    parts.push("[\{print_children(children)}]")
  } else if !children.is_empty() {
    parts.push("children=[\{print_children(children)}]")
  }
  "\{shape.name}(\{parts.join(", ")})"
}

///|
/// The labelled-argument spelling for an SVG attribute name; only `viewBox`
/// differs from its attribute spelling (`view_box`).
fn svg_labelled_arg(name : String) -> String {
  if name == "viewBox" {
    return "view_box"
  }
  name
}

///|
/// Render an SVG attribute as an `SvgAttr::...` constructor call for use
/// inside an `attrs=[...]` list, using `Custom` when the `SvgAttr` enum has
/// no variant for the attribute name.
fn svg_attr_literal(name : String, value : String) -> String {
  let lit = str_lit(value)
  match name {
    "x" => "SvgAttr::X(\{lit})"
    "y" => "SvgAttr::Y(\{lit})"
    "x1" => "SvgAttr::X1(\{lit})"
    "y1" => "SvgAttr::Y1(\{lit})"
    "x2" => "SvgAttr::X2(\{lit})"
    "y2" => "SvgAttr::Y2(\{lit})"
    "cx" => "SvgAttr::Cx(\{lit})"
    "cy" => "SvgAttr::Cy(\{lit})"
    "r" => "SvgAttr::R(\{lit})"
    "rx" => "SvgAttr::Rx(\{lit})"
    "ry" => "SvgAttr::Ry(\{lit})"
    "d" => "SvgAttr::D(\{lit})"
    "points" => "SvgAttr::Points(\{lit})"
    "width" => "SvgAttr::Width(\{lit})"
    "height" => "SvgAttr::Height(\{lit})"
    "viewBox" => "SvgAttr::ViewBox(\{lit})"
    "preserveAspectRatio" => "SvgAttr::PreserveAspectRatio(\{lit})"
    "fill" => "SvgAttr::Fill(\{lit})"
    "fill-opacity" => "SvgAttr::FillOpacity(\{lit})"
    "fill-rule" => "SvgAttr::FillRule(\{lit})"
    "stroke" => "SvgAttr::Stroke(\{lit})"
    "stroke-width" => "SvgAttr::StrokeWidth(\{lit})"
    "stroke-opacity" => "SvgAttr::StrokeOpacity(\{lit})"
    "stroke-linecap" => "SvgAttr::StrokeLinecap(\{lit})"
    "stroke-linejoin" => "SvgAttr::StrokeLinejoin(\{lit})"
    "stroke-dasharray" => "SvgAttr::StrokeDasharray(\{lit})"
    "stroke-dashoffset" => "SvgAttr::StrokeDashoffset(\{lit})"
    "opacity" => "SvgAttr::Opacity(\{lit})"
    "transform" => "SvgAttr::Transform(\{lit})"
    "transform-origin" => "SvgAttr::TransformOrigin(\{lit})"
    "offset" => "SvgAttr::Offset(\{lit})"
    "stop-color" => "SvgAttr::StopColor(\{lit})"
    "stop-opacity" => "SvgAttr::StopOpacity(\{lit})"
    "gradientUnits" => "SvgAttr::GradientUnits(\{lit})"
    "gradientTransform" => "SvgAttr::GradientTransform(\{lit})"
    "patternUnits" => "SvgAttr::PatternUnits(\{lit})"
    "patternContentUnits" => "SvgAttr::PatternContentUnits(\{lit})"
    "patternTransform" => "SvgAttr::PatternTransform(\{lit})"
    "clip-path" => "SvgAttr::ClipPath(\{lit})"
    "clip-rule" => "SvgAttr::ClipRule(\{lit})"
    "mask" => "SvgAttr::Mask(\{lit})"
    "maskUnits" => "SvgAttr::MaskUnits(\{lit})"
    "marker-start" => "SvgAttr::MarkerStart(\{lit})"
    "marker-mid" => "SvgAttr::MarkerMid(\{lit})"
    "marker-end" => "SvgAttr::MarkerEnd(\{lit})"
    "font-family" => "SvgAttr::FontFamily(\{lit})"
    "font-size" => "SvgAttr::FontSize(\{lit})"
    "font-weight" => "SvgAttr::FontWeight(\{lit})"
    "text-anchor" => "SvgAttr::TextAnchor(\{lit})"
    "dominant-baseline" => "SvgAttr::DominantBaseline(\{lit})"
    "role" => "SvgAttr::Role(\{lit})"
    "aria-label" => "SvgAttr::AriaLabel(\{lit})"
    _ => "SvgAttr::Custom(\{str_lit(name)}, \{lit})"
  }
}
