///|
test "convert_to_dsl converts a single element" {
  assert_eq(
    @h.render(convert_to_dsl("<p>Hello, MoonBit!</p>")),
    "<p>Hello, MoonBit!</p>",
  )
}

///|
test "convert_to_dsl converts nested elements" {
  assert_eq(
    @h.render(convert_to_dsl("<div><p>one</p><p>two</p></div>")),
    "<div><p>one</p><p>two</p></div>",
  )
}

///|
test "convert_to_dsl converts attributes" {
  assert_eq(
    @h.render(convert_to_dsl("<a href=\"https://example.com\">link</a>")),
    "<a href=\"https://example.com\">link</a>",
  )
}

///|
test "convert_to_dsl converts multiple attributes in source order" {
  assert_eq(
    @h.render(convert_to_dsl("<input type=\"checkbox\" name=\"x\" checked>")),
    "<input type=\"checkbox\" name=\"x\" checked>",
  )
}

///|
test "convert_to_dsl converts boolean attributes" {
  assert_eq(@h.render(convert_to_dsl("<input checked>")), "<input checked>")
}

///|
test "convert_to_dsl escapes text content" {
  assert_eq(
    @h.render(convert_to_dsl("<p>a &amp; b &lt; c</p>")),
    "<p>a &amp; b &lt; c</p>",
  )
}

///|
test "convert_to_dsl handles void elements" {
  assert_eq(@h.render(convert_to_dsl("<div>a<br>b</div>")), "<div>a<br>b</div>")
}

///|
test "convert_to_dsl keeps plain script bodies raw" {
  assert_eq(
    @h.render(convert_to_dsl("<script>if (a < b) { go() }</script>")),
    "<script>if (a < b) { go() }</script>",
  )
}

///|
test "convert_to_dsl preserves comments" {
  assert_eq(
    @h.render(convert_to_dsl("<p>a<!-- note -->b</p>")),
    "<p>a<!-- note -->b</p>",
  )
}

///|
test "convert_to_dsl preserves top-level comments" {
  assert_eq(
    @h.render(convert_to_dsl("<!-- top --><p>x</p>")),
    "<!-- top --><p>x</p>",
  )
}

///|
test "convert_to_dsl converts bare text fragments" {
  assert_eq(@h.render(convert_to_dsl("hello")), "hello")
}

///|
test "convert_to_dsl converts empty input to empty output" {
  assert_eq(@h.render(convert_to_dsl("")), "")
}

///|
test "convert_to_dsl converts multiple top-level nodes to a fragment" {
  assert_eq(
    @h.render(convert_to_dsl("<p>one</p><p>two</p>")),
    "<p>one</p><p>two</p>",
  )
}

///|
test "convert_to_dsl converts svg elements" {
  assert_eq(
    @h.render(
      convert_to_dsl(
        "<svg viewBox=\"0 0 100 100\"><circle cx=\"50\" cy=\"50\" r=\"40\" fill=\"red\"></circle></svg>",
      ),
    ),
    "<svg viewBox=\"0 0 100 100\"><circle cx=\"50\" cy=\"50\" r=\"40\" fill=\"red\"></circle></svg>",
  )
}

///|
test "convert_to_dsl converts svg gradients" {
  assert_eq(
    @h.render(
      convert_to_dsl(
        "<svg><linearGradient id=\"g\"><stop offset=\"0%\" stop-color=\"red\"></stop></linearGradient></svg>",
      ),
    ),
    "<svg><linearGradient id=\"g\"><stop offset=\"0%\" stop-color=\"red\"></stop></linearGradient></svg>",
  )
}

///|
test "convert_to_dsl converts svg titles and text" {
  assert_eq(
    @h.render(
      convert_to_dsl(
        "<svg><title>T</title><text x=\"10\" y=\"20\">hello</text></svg>",
      ),
    ),
    "<svg><title>T</title><text x=\"10\" y=\"20\">hello</text></svg>",
  )
}
