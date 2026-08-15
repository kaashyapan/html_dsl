///|
using @bobzhang/html_parser {
  type HtmlError,
  type ParsedHtml,
  type Node,
  type NodeKind,
  parse_fragment,
}

///|
/// Convert parsed html from @bobzhang/html_parser to the MoonBit Html DSL
fn convert_parsed_html(nodes : ParsedHtml) -> @h.Html {
  return convert_node(nodes.root)
}

///|
/// Convert raw html string to the MoonBit Html DSL
fn convert_to_dsl(str : String) -> @h.Html raise HtmlError {
  str |> parse_fragment() |> convert_parsed_html()
}

///|
/// Convert raw html string to the MoonBit Html DSL
pub fn convert_html(str : String) -> String raise HtmlError {
  str |> convert_to_dsl() |> print_html_dsl()
}

///|
/// Convert a single @bobzhang/html_parser node to the MoonBit Html DSL.
///
/// Document and fragment roots become `@h.fragment`, comments become
/// `@h.comment`, and doctypes become `@h.doctype`.
fn convert_node(node : Node) -> @h.Html {
  match node.kind() {
    NodeKind::Document | NodeKind::Fragment =>
      @h.fragment(node.children().map(convert_node))
    NodeKind::Element => convert_element(node)
    NodeKind::Text => @h.text(node.data())
    NodeKind::Comment => @h.comment(node.data())
    NodeKind::Doctype => convert_doctype(node)
  }
}

///|
/// Convert a doctype node to a DSL doctype declaration.
fn convert_doctype(node : Node) -> @h.Html {
  match (node.public_id, node.system_id) {
    (Some(public_id), Some(system_id)) =>
      @h.doctype(name=node.data(), public_id~, system_id~)
    (Some(public_id), None) => @h.doctype(name=node.data(), public_id~)
    (None, Some(system_id)) => @h.doctype(name=node.data(), system_id~)
    (None, None) => @h.doctype(name=node.data())
  }
}

///|
/// Convert an element node: tag name, attributes, and recursively converted
/// children.
///
/// `<script>` elements without attributes go through `@h.inline_script`, which
/// keeps the JS body raw; text content anywhere else is HTML-escaped by
/// `@h.text`. Doctypes inside elements are dropped because a doctype is not
/// valid element content.
fn convert_element(node : Node) -> @h.Html {
  if node.name() == "script" && node.attrs().is_empty() {
    return @h.inline_script(text_data(node))
  }
  let children : Array[@h.Html] = []
  for child in node.children() {
    match child.kind() {
      NodeKind::Doctype => ()
      _ => children.push(convert_node(child))
    }
  }
  @h.node(node.name(), convert_attrs(node), children)
}

///|
/// Join the direct text content of an element, skipping non-text children.
fn text_data(node : Node) -> String {
  let buf = StringBuilder::new()
  for child in node.children() {
    if child.kind() == NodeKind::Text {
      buf.write_string(child.data())
    }
  }
  buf.to_string()
}

///|
/// Convert the attribute map of an element to DSL attributes.
/// `None` values are valueless (boolean) attributes; anything else becomes a
/// generic `Prop`.
fn convert_attrs(node : Node) -> Array[@h.Attr] {
  let attrs : Array[@h.Attr] = []
  for name, value in node.attrs() {
    match value {
      Some(v) => attrs.push(@h.Attr::Prop(name, v))
      None => attrs.push(boolean_attr(name))
    }
  }
  attrs
}

///|
/// Map a valueless attribute to the closest DSL attribute, so common boolean
/// attributes render as `disabled` rather than `disabled=""`.
fn boolean_attr(name : String) -> @h.Attr {
  match name {
    "disabled" => @h.Attr::Disabled(true)
    "checked" => @h.Attr::Checked(true)
    "required" => @h.Attr::Required(true)
    "readonly" => @h.Attr::Readonly(true)
    "autofocus" => @h.Attr::AutoFocus(true)
    "multiple" => @h.Attr::Multiple(true)
    "controls" => @h.Attr::Controls(true)
    "autoplay" => @h.Attr::Autoplay(true)
    "loop" => @h.Attr::Loop_(true)
    "muted" => @h.Attr::Muted(true)
    "defer" => @h.Attr::Defer(true)
    "async" => @h.Attr::Async(true)
    "selected" => @h.Attr::Selected(true)
    _ => @h.Attr::Prop(name, "")
  }
}

///|
test {
  let html = [@h.text("Hello, MoonBit!")] |> @h.p() |> @h.render
  println(html)
  assert_eq("<p>Hello, MoonBit!</p>", html)
}
