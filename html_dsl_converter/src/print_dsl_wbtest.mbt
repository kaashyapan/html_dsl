///|
test "print text" {
  assert_eq(print_html_dsl(@h.text("hello")), "text(\"hello\")")
}

///|
test "print escapes strings" {
  assert_eq(print_html_dsl(@h.text("a\"b\\c")), "text(\"a\\\"b\\\\c\")")
}

///|
test "print nothing" {
  assert_eq(print_html_dsl(@h.nothing()), "nothing()")
}

///|
test "print fragment" {
  assert_eq(
    print_html_dsl(@h.fragment([@h.text("a"), @h.nothing()])),
    "fragment([text(\"a\"), nothing()])",
  )
}

///|
test "print raw html" {
  assert_eq(print_html_dsl(@h.raw_html("<b>x</b>")), "raw_html(\"<b>x</b>\")")
}

///|
test "print comment" {
  assert_eq(print_html_dsl(@h.comment("note")), "comment(\"note\")")
}

///|
test "print doc example" {
  let node = @h.node(
    "div",
    [@h.Attr::Id("divid-01"), @h.Attr::Class("flex flex-row")],
    [@h.node("p", [], [@h.text("hello")])],
  )
  assert_eq(
    print_html_dsl(node),
    "div(id=\"divid-01\", class=\"flex flex-row\", [p([text(\"hello\")])])",
  )
}

///|
test "print attributes that have no labelled argument" {
  let node = @h.node(
    "div",
    [@h.Attr::Href("/x"), @h.Attr::Prop("data-x", "1")],
    [],
  )
  assert_eq(
    print_html_dsl(node),
    "div(attrs=[Attr::Href(\"/x\"), Attr::Prop(\"data-x\", \"1\")], [])",
  )
}

///|
test "print anchor with href and target" {
  let node = @h.node(
    "a",
    [@h.Attr::Href("/x"), @h.Attr::Target_(@h.Target::Blank)],
    [],
  )
  assert_eq(print_html_dsl(node), "a(href=\"/x\", target=Blank, [])")
}

///|
test "print input with boolean attributes" {
  let node = @h.node(
    "input",
    [@h.Attr::Checked(true), @h.Attr::Required(true)],
    [],
  )
  assert_eq(print_html_dsl(node), "input(checked=true, required=true)")
}

///|
test "print button with click handler" {
  let node = @h.node(
    "button",
    [@h.Attr::On(@h.Event::Click("go()")), @h.Attr::Disabled(true)],
    [],
  )
  assert_eq(
    print_html_dsl(node),
    "button(on_click_=\"go()\", disabled=true, [])",
  )
}

///|
test "print img drops children because it is void" {
  let node = @h.node("img", [@h.Attr::Src("/x.png"), @h.Attr::Alt("x")], [
    @h.text("ignored"),
  ])
  assert_eq(print_html_dsl(node), "img(src=\"/x.png\", alt=\"x\")")
}

///|
test "print img without src falls back to node" {
  let node = @h.node("img", [@h.Attr::Alt("x")], [])
  assert_eq(print_html_dsl(node), "node(\"img\", [Attr::Alt(\"x\")], [])")
}

///|
test "print title with plain text" {
  let node = @h.node("title", [], [@h.text("Sign in")])
  assert_eq(print_html_dsl(node), "title(\"Sign in\")")
}

///|
test "print br" {
  assert_eq(print_html_dsl(@h.node("br", [], [])), "br()")
}

///|
test "print script with src" {
  let node = @h.node("script", [@h.Attr::Defer(true), @h.Attr::Src("/x.js")], [])
  assert_eq(print_html_dsl(node), "script(defer_=true, src=\"/x.js\")")
}

///|
test "print inline script from converted html" {
  let dsl = convert_to_dsl("<script>if (a < b) { go() }</script>")
  assert_eq(
    print_html_dsl(dsl),
    "fragment([inline_script(\"if (a < b) { go() }\")])",
  )
}

///|
test "print meta with charset" {
  let node = @h.node("meta", [@h.Attr::Charset("utf-8")], [])
  assert_eq(print_html_dsl(node), "meta(charset=\"utf-8\")")
}

///|
test "print td with colspan" {
  let node = @h.node("td", [@h.Attr::Colspan(2)], [@h.text("x")])
  assert_eq(print_html_dsl(node), "td(colspan=2, [text(\"x\")])")
}

///|
test "print label with for" {
  let node = @h.node("label", [@h.Attr::For_("email")], [@h.text("Email")])
  assert_eq(print_html_dsl(node), "label(for_=\"email\", [text(\"Email\")])")
}

///|
test "print source element" {
  let node = @h.node(
    "source",
    [@h.Attr::Prop("src", "a.mp4"), @h.Attr::Prop("type", "video/mp4")],
    [],
  )
  assert_eq(print_html_dsl(node), "source_(src=\"a.mp4\", type_=\"video/mp4\")")
}

///|
test "print track element" {
  let node = @h.node(
    "track",
    [
      @h.Attr::Src("c.vtt"),
      @h.Attr::Prop("kind", "captions"),
      @h.Attr::Label_("English"),
    ],
    [],
  )
  assert_eq(
    print_html_dsl(node),
    "track(src=\"c.vtt\", kind=\"captions\", label=\"English\")",
  )
}

///|
test "print style attribute stays in attrs" {
  let node = @h.node("div", [@h.Attr::Style([("color", "red")])], [])
  assert_eq(
    print_html_dsl(node),
    "div(attrs=[Attr::Style([(\"color\", \"red\")])], [])",
  )
}

///|
test "print unknown tag falls back to node" {
  let node = @h.node("marquee", [@h.Attr::Prop("behavior", "scroll")], [
    @h.text("hi"),
  ])
  assert_eq(
    print_html_dsl(node),
    "node(\"marquee\", [Attr::Prop(\"behavior\", \"scroll\")], [text(\"hi\")])",
  )
}

///|
test "print form" {
  let node = @h.node(
    "form",
    [
      @h.Attr::Action("/login"),
      @h.Attr::Method("post"),
      @h.Attr::On(@h.Event::Submit("s()")),
    ],
    [],
  )
  assert_eq(
    print_html_dsl(node),
    "form(action=\"/login\", method_=\"post\", on_submit_=\"s()\", [])",
  )
}

///|
test "print html element with lang" {
  let node = @h.node("html", [@h.Attr::Lang("en")], [@h.node("head", [], [])])
  assert_eq(print_html_dsl(node), "html_el(lang=\"en\", [head([])])")
}

///|
test "print link" {
  let node = @h.node(
    "link",
    [@h.Attr::Href("/s.css"), @h.Attr::Rel("stylesheet")],
    [],
  )
  assert_eq(print_html_dsl(node), "link(href=\"/s.css\", rel=\"stylesheet\")")
}

///|
test "print iframe with children falls back to node" {
  let node = @h.node("iframe", [@h.Attr::Src("/f")], [@h.text("fallback")])
  assert_eq(
    print_html_dsl(node),
    "node(\"iframe\", [Attr::Src(\"/f\")], [text(\"fallback\")])",
  )
}

///|
test "print doctype from doctype builder" {
  assert_eq(
    print_html_dsl(@h.doctype(name="html")),
    "raw_html(\"<!DOCTYPE html>\")",
  )
}

///|
test "print converted html" {
  let dsl = convert_to_dsl("<p>Hello, MoonBit!</p>")
  assert_eq(print_html_dsl(dsl), "fragment([p([text(\"Hello, MoonBit!\")])])")
}

///|
test "print converted html with attributes" {
  let dsl = convert_to_dsl("<div id=\"a\"><p>hi</p></div>")
  assert_eq(
    print_html_dsl(dsl),
    "fragment([div(attrs=[Attr::Prop(\"id\", \"a\")], [p([text(\"hi\")])])])",
  )
}

///|
test "print svg root with view box" {
  let node = @h.node("svg", [@h.Attr::Prop("viewBox", "0 0 100 100")], [])
  assert_eq(print_html_dsl(node), "svg(view_box=\"0 0 100 100\", [])")
}

///|
test "print svg circle with fill" {
  let node = @h.node(
    "circle",
    [
      @h.Attr::Prop("cx", "50"),
      @h.Attr::Prop("cy", "50"),
      @h.Attr::Prop("r", "40"),
      @h.Attr::Prop("fill", "red"),
    ],
    [],
  )
  assert_eq(
    print_html_dsl(node),
    "circle(cx=\"50\", cy=\"50\", r=\"40\", attrs=[SvgAttr::Fill(\"red\")])",
  )
}

///|
test "print svg path" {
  let node = @h.node("path", [@h.Attr::Prop("d", "M0 0 L10 10")], [])
  assert_eq(print_html_dsl(node), "path(d=\"M0 0 L10 10\")")
}

///|
test "print svg gradient" {
  let node = @h.node("linearGradient", [@h.Attr::Prop("id", "g")], [
    @h.node(
      "stop",
      [@h.Attr::Prop("offset", "0%"), @h.Attr::Prop("stop-color", "red")],
      [],
    ),
  ])
  assert_eq(
    print_html_dsl(node),
    "linear_gradient(id=\"g\", [stop(offset=\"0%\", attrs=[SvgAttr::StopColor(\"red\")])])",
  )
}

///|
test "print svg text with children" {
  let node = @h.node("text", [@h.Attr::Prop("x", "10")], [@h.text("hi")])
  assert_eq(print_html_dsl(node), "text(x=\"10\", [text(\"hi\")])")
}

///|
test "print svg clip path" {
  let node = @h.node("clipPath", [@h.Attr::Prop("id", "c")], [
    @h.node("rect", [@h.Attr::Prop("width", "10")], []),
  ])
  assert_eq(print_html_dsl(node), "clip_path(id=\"c\", [rect(width=\"10\")])")
}

///|
test "print svg use element" {
  let node = @h.node("use", [@h.Attr::Prop("href", "#a")], [])
  assert_eq(print_html_dsl(node), "use_(href=\"#a\")")
}

///|
test "print svg rect with children" {
  let node = @h.node("rect", [@h.Attr::Prop("width", "10")], [@h.text("x")])
  assert_eq(print_html_dsl(node), "rect(width=\"10\", children=[text(\"x\")])")
}

///|
test "print unknown svg tag falls back to node" {
  let node = @h.node("feGaussianBlur", [@h.Attr::Prop("stdDeviation", "5")], [])
  assert_eq(
    print_html_dsl(node),
    "node(\"feGaussianBlur\", [Attr::Prop(\"stdDeviation\", \"5\")], [])",
  )
}

///|
test "print svg custom attribute" {
  let node = @h.node("svg", [@h.Attr::Prop("data-x", "1")], [])
  assert_eq(
    print_html_dsl(node),
    "svg(attrs=[SvgAttr::Custom(\"data-x\", \"1\")], [])",
  )
}

///|
test "print svg node with non-prop attribute falls back to node" {
  let node = @h.node("svg", [@h.Attr::Id("chart")], [])
  assert_eq(print_html_dsl(node), "node(\"svg\", [Attr::Id(\"chart\")], [])")
}
