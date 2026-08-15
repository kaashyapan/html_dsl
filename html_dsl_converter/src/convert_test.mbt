///|
test "convert_html prints a single element" {
  assert_eq(
    convert_html("<p>Hello, MoonBit!</p>"),
    "fragment([p([text(\"Hello, MoonBit!\")])])",
  )
}

///|
test "convert_html prints nested elements" {
  assert_eq(
    convert_html("<div><p>one</p><p>two</p></div>"),
    "fragment([div([p([text(\"one\")]), p([text(\"two\")])])])",
  )
}

///|
test "convert_html prints attributes" {
  assert_eq(
    convert_html("<a href=\"https://example.com\">link</a>"),
    "fragment([a(attrs=[Attr::Prop(\"href\", \"https://example.com\")], [text(\"link\")])])",
  )
}

///|
test "convert_html prints multiple attributes in source order" {
  assert_eq(
    convert_html("<input type=\"checkbox\" name=\"x\" checked>"),
    "fragment([input(checked=true, attrs=[Attr::Prop(\"type\", \"checkbox\"), Attr::Prop(\"name\", \"x\")])])",
  )
}

///|
test "convert_html prints boolean attributes" {
  assert_eq(convert_html("<input checked>"), "fragment([input(checked=true)])")
}

///|
test "convert_html keeps escaped text unescaped in the DSL" {
  assert_eq(
    convert_html("<p>a &amp; b &lt; c</p>"),
    "fragment([p([text(\"a & b < c\")])])",
  )
}

///|
test "convert_html prints void elements" {
  assert_eq(
    convert_html("<div>a<br>b</div>"),
    "fragment([div([text(\"a\"), br(), text(\"b\")])])",
  )
}

///|
test "convert_html prints plain script bodies as inline_script" {
  assert_eq(
    convert_html("<script>if (a < b) { go() }</script>"),
    "fragment([inline_script(\"if (a < b) { go() }\")])",
  )
}

///|
test "convert_html prints comments" {
  assert_eq(
    convert_html("<p>a<!-- note -->b</p>"),
    "fragment([p([text(\"a\"), comment(\" note \"), text(\"b\")])])",
  )
}

///|
test "convert_html prints top-level comments" {
  assert_eq(
    convert_html("<!-- top --><p>x</p>"),
    "fragment([comment(\" top \"), p([text(\"x\")])])",
  )
}

///|
test "convert_html prints bare text fragments" {
  assert_eq(convert_html("hello"), "fragment([text(\"hello\")])")
}

///|
test "convert_html prints empty input as an empty fragment" {
  assert_eq(convert_html(""), "fragment([])")
}

///|
test "convert_html prints multiple top-level nodes" {
  assert_eq(
    convert_html("<p>one</p><p>two</p>"),
    "fragment([p([text(\"one\")]), p([text(\"two\")])])",
  )
}
