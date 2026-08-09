// =============================================================================
// html.mbt — standalone Html/Attr/Event types + render to string
//
// Modelled after rabbita's html API and luna's render output.
// No external dependencies. Works on all MoonBit targets (JS, wasm, native).
//
// Overview
// --------
// - `Html` is the node tree (elements, text, fragments, raw/unsafe html).
// - `Attr` is anything that can sit inside a tag's opening `<tag ...>`,
//   including both static attributes/styles and event handlers.
// - `Event` enumerates the DOM events an `Attr::On(_)` can carry; each
//   variant holds the JS to run as a plain string (no closures — this is a
//   pure string-templating DSL, not a virtual DOM).
// - Element builder functions (`div`, `p`, `a`, ...) are thin, labeled-arg
//   wrappers around `Node(tag, attrs, children)` that mirror common HTML
//   attributes as keyword parameters so call sites read like HTML.
// - `render` walks an `Html` tree and produces the final HTML string,
//   escaping text content and static attribute values, and skipping
//   nothing silently — event handlers ARE rendered as inline `on*` attrs.
//
// =============================================================================

///|
/// The `type` attribute value for `<input>` elements.
/// Passed to `input(input_type~)`; rendered as the matching HTML type string
/// (e.g. `Email` -> `type="email"`).
pub(all) enum InputType {
  Text
  Password
  Email
  Number
  Checkbox
  Radio
  File
  Hidden
  Submit
  Reset
  Button
  Range
  Date
  Color
  Search
  Tel
  Url
}

///|
/// The `target` attribute value for `<a>` (and other linking elements).
/// `Self_` is the default browsing context; the others map 1:1 to the
/// standard `_blank` / `_parent` / `_top` keywords.
pub(all) enum Target {
  Self_
  Blank
  Parent
  Top
}

///|
/// All DOM events that can be attached to an element via `Attr::On`.
/// Each variant carries the JS to run (as a raw string, e.g.
/// `"console.log('hi')"`) which is rendered verbatim as an inline
/// `on*="..."` attribute — it is NOT escaped, so callers are responsible
/// for producing valid/safe JS.
pub(all) enum Event {
  /// mouse / pointer
  Click(String)
  DblClick(String)
  MouseEnter(String)
  MouseLeave(String)
  /// form
  Change(String)
  Input(String)
  Submit(String)
  Focus(String)
  Blur(String)
  /// keyboard
  KeyDown(String)
  KeyUp(String)
  KeyPress(String)
}

///|
/// HTML attribute — either a static property/style or a live event handler.
/// `Attr` values are order-independent; `render_attr` decides how each one
/// is serialized inside a tag's opening bracket.
pub(all) enum Attr {
  // ── static string attributes ─────────────────────────────────────────
  Id(String)
  Class(String)
  Href(String)
  Src(String)
  Alt(String)
  Type_(String) // "type" is a keyword so we use Type_
  Value(String)
  Placeholder(String)
  Name(String)
  For_(String) // "for" is a keyword
  Action(String)
  Method(String)
  Charset(String)
  Rel(String)
  Lang(String)
  Disabled(Bool)
  Checked(Bool)
  Required(Bool)
  Readonly(Bool)
  AutoFocus(Bool)
  Multiple(Bool)
  Target_(Target)
  Defer(Bool)
  Async(Bool)

  // ── extra static attributes (forms, media, tables, misc) ─────────────
  Rows(Int)
  Cols(Int)
  Controls(Bool)
  Autoplay(Bool)
  Loop_(Bool) // "loop" reads oddly as a bare identifier, so we use Loop_
  Muted(Bool)
  Poster(String)
  Min(String)
  Max(String)
  Step(String)
  Selected(Bool)
  Label_(String) // clashes with the `label` element builder otherwise
  DateTime(String)
  Colspan(Int)
  Rowspan(Int)
  Width(Int)
  Height(Int)
  Title_(String) // "title" clashes with the `title` element builder
  Cite(String)

  // ── style ─────────────────────────────────────────────────────────────
  // inline styles as (property, value) pairs, e.g. [("color","red")]
  Style(Array[(String, String)])
  // arbitrary attribute for anything not listed above
  Prop(String, String)
  // ── event handlers ────────────────────────────────────────────────────
  On(Event)
  OnRawEvent(String, String)
}

///|
/// HTML node — the tree that `render` turns into a string.
pub(all) enum Html {
  /// An element: tag name, attributes, children
  Node(String, Array[Attr], Array[Html])
  /// Raw escaped text content
  Text(String)
  /// Multiple nodes with no wrapping element
  Fragment(Array[Html])
  /// Raw, un-escaped HTML/JS dropped verbatim into the output. Use with
  /// care — nothing here is sanitized, so never build this from untrusted
  /// input.
  Unsafe(String)
  /// Renders nothing (useful as a conditional placeholder)
  Nothing
}

// =============================================================================
// Constructor helpers — mirrors rabbita's public API style
// =============================================================================

///|
/// on_click("console.log(`Hello`)")
pub fn on_click(msg : String) -> Attr {
  On(Event::Click(msg))
}

///|
/// on_dblclick("console.log(`Hello`)")
pub fn on_dblclick(msg : String) -> Attr {
  On(Event::DblClick(msg))
}

///|
/// on_mouseenter("console.log(`Hello`)")
pub fn on_mouseenter(msg : String) -> Attr {
  On(Event::MouseEnter(msg))
}

///|
/// on_mouseleave("console.log(`Hello`)")
pub fn on_mouseleave(msg : String) -> Attr {
  On(Event::MouseLeave(msg))
}

///|
/// on_change("console.log(`Hello`)")
pub fn on_change(msg : String) -> Attr {
  On(Event::Change(msg))
}

///|
/// on_input("console.log(`Hello`)")
pub fn on_input(msg : String) -> Attr {
  On(Event::Input(msg))
}

///|
/// on_submit("console.log(`Hello`)")
pub fn on_submit(msg : String) -> Attr {
  On(Event::Submit(msg))
}

///|
/// on_focus("console.log(`Hello`)")
pub fn on_focus(msg : String) -> Attr {
  On(Event::Focus(msg))
}

///|
/// on_blur("console.log(`Hello`)")
pub fn on_blur(msg : String) -> Attr {
  On(Event::Blur(msg))
}

///|
/// on_keydown("console.log(`Hello`)")
pub fn on_keydown(msg : String) -> Attr {
  On(Event::KeyDown(msg))
}

///|
/// on_keyup("console.log(`Hello`)")
pub fn on_keyup(msg : String) -> Attr {
  On(Event::KeyUp(msg))
}

///|
/// on_keypress("console.log(`Hello`)")
pub fn on_keypress(msg : String) -> Attr {
  On(Event::KeyPress(msg))
}

///|
/// Style helper: takes (key, value) pairs, e.g.
/// `style([("color", "red"), ("font-weight", "bold")])`.
pub fn style(pairs : Array[(String, String)]) -> Attr {
  Style(pairs)
}

///|
/// Build a node manually — escape hatch for any tag not covered by a
/// dedicated builder function below.
///
/// Example:
/// `node("marquee", [Attr::Prop("behavior", "scroll")], [text("Hi")])`
/// -> `<marquee behavior="scroll">Hi</marquee>`
pub fn node(tag : String, attrs : Array[Attr], children : Array[Html]) -> Html {
  Node(tag, attrs, children)
}

///|
/// Plain (HTML-escaped) text node.
///
/// Example:
/// `text("A & B")` renders as `A &amp; B`
pub fn text(s : String) -> Html {
  Text(s)
}

///|
/// Dummy node that produces no html. Handy as the `else` branch of a
/// conditional when only one side should render something.
///
/// Example:
/// `if is_logged_in { span([text("Hi!")]) } else { nothing() }`
/// -> `` (empty string) when `is_logged_in` is `false`
pub fn nothing() -> Html {
  Nothing
}

///|
/// A fragment to render an array of valid Html with no wrapping element.
///
/// Example:
/// `fragment([text("A"), text("B")])` -> `AB`
pub fn fragment(children : Array[Html]) -> Html {
  Fragment(children)
}

// =============================================================================
// Element builders — one per common HTML tag
// mirrors rabbita's approach: labeled args for attrs, positional for children
//
// Unless noted otherwise, every "block-style" builder below shares the same
// four optional keyword parameters: `id`, `class`, `style`, and `attrs`
// (for anything not otherwise covered), followed by a positional
// `children : Array[Html]`.
// =============================================================================

///|
/// `<div>` — generic block-level container; the catch-all building block
/// when no more specific element applies.
///
/// Example:
/// `div(class="card", [text("Hello")])` -> `<div class="card">Hello</div>`
pub fn div(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("div", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<span>` — generic inline container, e.g. for styling a run of text.
///
/// Example:
/// `span(class="highlight", [text("new")])`
/// -> `<span class="highlight">new</span>`
pub fn span(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("span", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<p>` — a paragraph of text.
///
/// Example:
/// `p([text("Hello, world.")])` -> `<p>Hello, world.</p>`
pub fn p(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("p", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<h1>` — the top-level (most important) section heading.
///
/// Example:
/// `h1([text("Welcome")])` -> `<h1>Welcome</h1>`
pub fn h1(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("h1", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<h2>` — second-level section heading.
///
/// Example:
/// `h2([text("About")])` -> `<h2>About</h2>`
pub fn h2(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("h2", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<h3>` — third-level section heading.
///
/// Example:
/// `h3([text("Details")])` -> `<h3>Details</h3>`
pub fn h3(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("h3", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<h4>` — fourth-level section heading.
///
/// Example:
/// `h4([text("Notes")])` -> `<h4>Notes</h4>`
pub fn h4(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("h4", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<h5>` — fifth-level section heading.
///
/// Example:
/// `h5([text("Fine print")])` -> `<h5>Fine print</h5>`
pub fn h5(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("h5", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<h6>` — sixth-level (lowest) section heading.
///
/// Example:
/// `h6([text("Footnote")])` -> `<h6>Footnote</h6>`
pub fn h6(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("h6", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<nav>` — a block of primary navigation links.
///
/// Example:
/// `nav([a(href="/", [text("Home")])])`
/// -> `<nav><a href="/">Home</a></nav>`
pub fn nav(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("nav", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<header>` — introductory content for its nearest sectioning ancestor
/// (a logo, title, tagline, and/or nav).
///
/// Example:
/// `header([h1([text("My Site")])])` -> `<header><h1>My Site</h1></header>`
pub fn header(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("header", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<footer>` — page/section footer, e.g. copyright and secondary links.
///
/// Example:
/// `footer([text("© 2026 Acme")])` -> `<footer>© 2026 Acme</footer>`
pub fn footer(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("footer", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<section>` — a thematic grouping of content, typically with its own
/// heading. Prefer this over a bare `div` when the group is a distinct
/// section of the document outline.
///
/// Example:
/// `section([h2([text("About")]), p([text("We build things.")])])`
/// -> `<section><h2>About</h2><p>We build things.</p></section>`
pub fn section(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("section", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<article>` — self-contained content that could be distributed or
/// reused independently (a blog post, a card, a comment, ...).
///
/// Example:
/// `article([h2([text("Post title")]), p([text("Body text")])])`
/// -> `<article><h2>Post title</h2><p>Body text</p></article>`
pub fn article(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("article", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<aside>` — content only tangentially related to the main content,
/// like a sidebar or a pull quote.
///
/// Example:
/// `aside([text("Related links")])` -> `<aside>Related links</aside>`
pub fn aside(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("aside", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<main>` — the document's primary content region. There should be at
/// most one visible `<main>` per page.
///
/// Example:
/// `main_([p([text("Page content")])])`
/// -> `<main><p>Page content</p></main>`
pub fn main_(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("main", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<ul>` — an unordered (bulleted) list; expects `li` children.
///
/// Example:
/// `ul([li([text("One")]), li([text("Two")])])`
/// -> `<ul><li>One</li><li>Two</li></ul>`
pub fn ul(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("ul", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<ol>` — an ordered (numbered) list; expects `li` children.
///
/// Example:
/// `ol([li([text("First")]), li([text("Second")])])`
/// -> `<ol><li>First</li><li>Second</li></ol>`
pub fn ol(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("ol", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<li>` — a single list item, used inside `ul`/`ol`.
///
/// Example:
/// `li([text("Item")])` -> `<li>Item</li>`
pub fn li(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("li", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<dl>` — description/definition list; expects `dt`/`dd` pairs as
/// children.
///
/// Example:
/// `dl([dt([text("HTML")]), dd([text("HyperText Markup Language")])])`
/// -> `<dl><dt>HTML</dt><dd>HyperText Markup Language</dd></dl>`
pub fn dl(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("dl", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<dt>` — the term being described inside a `dl`.
///
/// Example:
/// `dt([text("HTML")])` -> `<dt>HTML</dt>`
pub fn dt(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("dt", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<dd>` — the description for the preceding `dt` inside a `dl`.
///
/// Example:
/// `dd([text("HyperText Markup Language")])`
/// -> `<dd>HyperText Markup Language</dd>`
pub fn dd(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("dd", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<table>` — tabular data container; typically wraps `thead`/`tbody`
/// (each holding `tr` rows of `th`/`td` cells).
///
/// Example:
/// `table([tbody([tr([td([text("A")])])])])`
/// -> `<table><tbody><tr><td>A</td></tr></tbody></table>`
pub fn table(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("table", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<caption>` — table title, must be the first child of a `table`.
///
/// Example:
/// `caption([text("Monthly Sales")])` -> `<caption>Monthly Sales</caption>`
pub fn caption(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("caption", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<thead>` — groups the header row(s) of a `table`.
///
/// Example:
/// `thead([tr([th([text("Name")])])])`
/// -> `<thead><tr><th>Name</th></tr></thead>`
pub fn thead(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("thead", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<tbody>` — groups the body row(s) of a `table`.
///
/// Example:
/// `tbody([tr([td([text("A")])])])`
/// -> `<tbody><tr><td>A</td></tr></tbody>`
pub fn tbody(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("tbody", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<tfoot>` — table footer row group (totals, summaries, ...).
///
/// Example:
/// `tfoot([tr([td([text("Total: $10")])])])`
/// -> `<tfoot><tr><td>Total: $10</td></tr></tfoot>`
pub fn tfoot(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("tfoot", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<tr>` — a table row; expects `th`/`td` children.
///
/// Example:
/// `tr([td([text("A")]), td([text("B")])])`
/// -> `<tr><td>A</td><td>B</td></tr>`
pub fn tr(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("tr", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<th>` — header cell. `colspan`/`rowspan` are exposed directly since
/// they're by far the most common non-styling attributes on table cells.
///
/// Example:
/// `th([text("Name")])` -> `<th>Name</th>`
/// `th(colspan=2, [text("Totals")])` -> `<th colspan="2">Totals</th>`
pub fn th(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  colspan? : Int = 0,
  rowspan? : Int = 0,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if colspan > 0 {
    base.push(Colspan(colspan))
  }
  if rowspan > 0 {
    base.push(Rowspan(rowspan))
  }
  Node("th", base, children)
}

///|
/// `<td>` — data cell. `colspan`/`rowspan` are exposed directly since
/// they're by far the most common non-styling attributes on table cells.
///
/// Example:
/// `td([text("42")])` -> `<td>42</td>`
/// `td(rowspan=2, [text("42")])` -> `<td rowspan="2">42</td>`
pub fn td(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  colspan? : Int = 0,
  rowspan? : Int = 0,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if colspan > 0 {
    base.push(Colspan(colspan))
  }
  if rowspan > 0 {
    base.push(Rowspan(rowspan))
  }
  Node("td", base, children)
}

///|
/// `<a>` — hyperlink. `href` and `target` are pulled out as dedicated
/// params since almost every link sets `href`, and `target` is common
/// enough (opening in a new tab) to warrant type-safe support via
/// `Target`.
///
/// Example:
/// `a(href="/about", [text("About")])` -> `<a href="/about">About</a>`
/// `a(href="https://x.com", target=Blank, [text("X")])`
/// -> `<a href="https://x.com" target="_blank">X</a>`
pub fn a(
  id? : String = "",
  href? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  target? : Target? = None,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if href != "" {
    base.push(Href(href))
  }
  match target {
    Some(t) => base.push(Target_(t))
    None => ()
  }
  Node("a", base, children)
}

///|
/// `<i>` — generic icon/idiomatic-text hook (commonly used with icon
/// fonts).
///
/// Example:
/// `i(class="fa fa-star", [])` -> `<i class="fa fa-star"></i>`
pub fn i(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("i", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<strong>` — strong importance (typically rendered bold).
///
/// Example:
/// `strong([text("Warning")])` -> `<strong>Warning</strong>`
pub fn strong(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("strong", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<em>` — stress emphasis (typically rendered italic).
///
/// Example:
/// `em([text("really")])` -> `<em>really</em>`
pub fn em(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("em", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<b>` — stylistically bold text with no extra semantic weight.
///
/// Example:
/// `b([text("Bold")])` -> `<b>Bold</b>`
pub fn b(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("b", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<small>` — side comments / fine print.
///
/// Example:
/// `small([text("Terms apply")])` -> `<small>Terms apply</small>`
pub fn small(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("small", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<mark>` — highlighted (marked) text.
///
/// Example:
/// `mark([text("keyword")])` -> `<mark>keyword</mark>`
pub fn mark(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("mark", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<sub>` — subscript text.
///
/// Example:
/// `sub([text("2")])` -> `<sub>2</sub>` (e.g. inside `"H"` + `sub(...)` for H₂)
pub fn sub(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("sub", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<sup>` — superscript text.
///
/// Example:
/// `sup([text("2")])` -> `<sup>2</sup>` (e.g. for `x` squared)
pub fn sup(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("sup", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<code>` — an inline code fragment.
///
/// Example:
/// `code([text("let x = 1")])` -> `<code>let x = 1</code>`
pub fn code(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("code", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<pre>` — preformatted text; whitespace is preserved by the browser.
/// Typically wraps a `code` child for code blocks.
///
/// Example:
/// `pre([code([text("fn main() {}")])])`
/// -> `<pre><code>fn main() {}</code></pre>`
pub fn pre(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("pre", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<blockquote>` — an extended quotation. `cite` (a source URL) is
/// exposed directly since it's the one attribute unique to this element.
///
/// Example:
/// `blockquote(cite="https://example.com", [text("To be or not to be.")])`
/// -> `<blockquote cite="https://example.com">To be or not to be.</blockquote>`
pub fn blockquote(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  cite? : String = "",
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if cite != "" {
    base.push(Cite(cite))
  }
  Node("blockquote", base, children)
}

///|
/// `<q>` — a short, inline quotation (browsers add quote marks
/// automatically).
///
/// Example:
/// `q([text("carpe diem")])` -> `<q>carpe diem</q>`
pub fn q(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  cite? : String = "",
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if cite != "" {
    base.push(Cite(cite))
  }
  Node("q", base, children)
}

///|
/// `<abbr>` — an abbreviation/acronym. `title` supplies the expansion
/// shown on hover.
///
/// Example:
/// `abbr(title="HyperText Markup Language", [text("HTML")])`
/// -> `<abbr title="HyperText Markup Language">HTML</abbr>`
pub fn abbr(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  title? : String = "",
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if title != "" {
    base.push(Title_(title))
  }
  Node("abbr", base, children)
}

///|
/// `<time>` — a human-readable date/time, optionally paired with a
/// machine-readable `datetime` attribute (e.g. an ISO 8601 string).
///
/// Example:
/// `time(datetime="2026-08-09", [text("Aug 9, 2026")])`
/// -> `<time datetime="2026-08-09">Aug 9, 2026</time>`
pub fn time(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  datetime? : String = "",
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if datetime != "" {
    base.push(DateTime(datetime))
  }
  Node("time", base, children)
}

///|
/// `<address>` — contact information for the nearest `article`/document.
///
/// Example:
/// `address([text("123 Main St.")])` -> `<address>123 Main St.</address>`
pub fn address(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("address", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<figure>` — self-contained media (usually an `img`), typically paired
/// with a `figcaption` child.
///
/// Example:
/// `figure([img(src="cat.png", alt="A cat"), figcaption([text("A cat")])])`
/// -> `<figure><img src="cat.png" alt="A cat"><figcaption>A cat</figcaption></figure>`
pub fn figure(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("figure", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<figcaption>` — caption for the enclosing `figure`.
///
/// Example:
/// `figcaption([text("A cat")])` -> `<figcaption>A cat</figcaption>`
pub fn figcaption(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("figcaption", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<details>` — a disclosure widget; pair with a `summary` child as the
/// always-visible toggle. Set `open` to render it expanded by default.
///
/// Example:
/// `details([summary([text("More info")]), p([text("Here it is.")])])`
/// -> `<details><summary>More info</summary><p>Here it is.</p></details>`
pub fn details(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  open? : Bool = false,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if open {
    base.push(Prop("open", "open"))
  }
  Node("details", base, children)
}

///|
/// `<summary>` — the always-visible heading/toggle for a `details`.
///
/// Example:
/// `summary([text("More info")])` -> `<summary>More info</summary>`
pub fn summary(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("summary", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<button>` — a clickable button. `on_click_` is a convenience shortcut
/// for the common case of attaching a single click handler.
///
/// Example:
/// `button(on_click_="alert('hi')", [text("Click me")])`
/// -> `<button onclick="alert('hi')">Click me</button>`
pub fn button(
  id? : String = "",
  on_click_? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  disabled? : Bool = false,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if on_click_ != "" {
    base.push(on_click(on_click_))
  }
  if disabled {
    base.push(Disabled(true))
  }
  Node("button", base, children)
}

///|
/// `<input>` — a form input; void element, no children. `input_type`
/// picks the `type="..."` attribute via the type-safe `InputType` enum.
///
/// Example:
/// `input(name="email", input_type=Email, placeholder="you@example.com")`
/// -> `<input type="email" placeholder="you@example.com" name="email">`
pub fn input(
  name? : String = "",
  class? : String = "",
  id? : String = "",
  style? : Array[(String, String)] = [],
  input_type? : InputType = Text,
  value? : String = "",
  placeholder? : String = "",
  on_change? : String? = None,
  required? : Bool = false,
  disabled? : Bool = false,
  checked? : Bool = false,
  attrs? : Array[Attr] = [],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  base.push(Type_(input_type_to_string(input_type)))
  if value != "" {
    base.push(Value(value))
  }
  if placeholder != "" {
    base.push(Placeholder(placeholder))
  }
  if name != "" {
    base.push(Name(name))
  }
  if disabled {
    base.push(Disabled(true))
  }
  if required {
    base.push(Required(true))
  }
  if checked {
    base.push(Checked(true))
  }
  match on_change {
    Some(f) => base.push(On(Event::Change(f)))
    None => ()
  }
  Node("input", base, [])
}

///|
/// `<textarea>` — multi-line text input. Unlike `input`, its value is
/// rendered as escaped text content between the tags (per the HTML spec),
/// not a `value` attribute.
///
/// Example:
/// `textarea(name="bio", rows=4, value="Hello there")`
/// -> `<textarea rows="4" name="bio">Hello there</textarea>`
pub fn textarea(
  name? : String = "",
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  value? : String = "",
  placeholder? : String = "",
  rows? : Int = 0,
  cols? : Int = 0,
  on_change? : String? = None,
  required? : Bool = false,
  disabled? : Bool = false,
  attrs? : Array[Attr] = [],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if name != "" {
    base.push(Name(name))
  }
  if placeholder != "" {
    base.push(Placeholder(placeholder))
  }
  if rows > 0 {
    base.push(Rows(rows))
  }
  if cols > 0 {
    base.push(Cols(cols))
  }
  if required {
    base.push(Required(true))
  }
  if disabled {
    base.push(Disabled(true))
  }
  match on_change {
    Some(f) => base.push(On(Event::Change(f)))
    None => ()
  }
  Node("textarea", base, [Text(value)])
}

///|
/// `<select>` — a dropdown; children should be built with `option`
/// (and optionally grouped with `optgroup`).
///
/// Example:
/// `select(name="color", [option(value="r", [text("Red")]), option(value="b", [text("Blue")])])`
/// -> `<select name="color"><option value="r">Red</option><option value="b">Blue</option></select>`
pub fn select(
  name? : String = "",
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  multiple? : Bool = false,
  required? : Bool = false,
  disabled? : Bool = false,
  on_change? : String? = None,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if name != "" {
    base.push(Name(name))
  }
  if multiple {
    base.push(Multiple(true))
  }
  if required {
    base.push(Required(true))
  }
  if disabled {
    base.push(Disabled(true))
  }
  match on_change {
    Some(f) => base.push(On(Event::Change(f)))
    None => ()
  }
  Node("select", base, children)
}

///|
/// `<option>` — one choice inside a `select`/`datalist`.
///
/// Example:
/// `option(value="r", selected=true, [text("Red")])`
/// -> `<option value="r" selected>Red</option>`
pub fn option(
  value? : String = "",
  selected? : Bool = false,
  disabled? : Bool = false,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base : Array[Attr] = attrs.copy()
  if value != "" {
    base.push(Value(value))
  }
  if selected {
    base.push(Selected(true))
  }
  if disabled {
    base.push(Disabled(true))
  }
  Node("option", base, children)
}

///|
/// `<optgroup>` — groups related `option`s under a shared `label` inside
/// a `select`.
///
/// Example:
/// `optgroup(label="Warm colors", [option(value="r", [text("Red")])])`
/// -> `<optgroup label="Warm colors"><option value="r">Red</option></optgroup>`
pub fn optgroup(
  label~ : String,
  disabled? : Bool = false,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base : Array[Attr] = [Label_(label), ..attrs]
  if disabled {
    base.push(Disabled(true))
  }
  Node("optgroup", base, children)
}

///|
/// `<fieldset>` — groups related form controls, typically with a
/// `legend` child as the group's caption.
///
/// Example:
/// `fieldset([legend([text("Contact")]), input(name="email", input_type=Email)])`
/// -> `<fieldset><legend>Contact</legend><input type="email" name="email"></fieldset>`
pub fn fieldset(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  disabled? : Bool = false,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if disabled {
    base.push(Disabled(true))
  }
  Node("fieldset", base, children)
}

///|
/// `<legend>` — caption for the enclosing `fieldset`.
///
/// Example:
/// `legend([text("Contact")])` -> `<legend>Contact</legend>`
pub fn legend(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("legend", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<label>` — caption for a form control; `for_` should match the
/// target control's `name`/`id`.
///
/// Example:
/// `label(for_="email", [text("Email")])`
/// -> `<label for="email">Email</label>`
pub fn label(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  for_? : String = "",
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if for_ != "" {
    base.push(For_(for_))
  }
  Node("label", base, children)
}

///|
/// `<datalist>` — a set of `option`s offered as autocomplete suggestions
/// for a text `input` referencing this list's `id`.
///
/// Example:
/// `datalist(id="colors", [option(value="Red", []), option(value="Blue", [])])`
/// -> `<datalist id="colors"><option value="Red"></option><option value="Blue"></option></datalist>`
pub fn datalist(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  Node("datalist", build_attrs(id~, class~, style~, attrs~), children)
}

///|
/// `<form>` — `action`/`method` are exposed directly since virtually
/// every form sets at least one of them; anything else goes through
/// `attrs`.
///
/// Example:
/// `form(action="/submit", method_="post", [input(name="q"), button([text("Go")])])`
/// -> `<form action="/submit" method_="post"><input type="text" name="q"><button>Go</button></form>`
pub fn form(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  action? : String = "",
  method_? : String = "",
  attrs? : Array[Attr] = [],
  on_submit_? : String = "",
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if action != "" {
    base.push(Action(action))
  }
  if method_ != "" {
    base.push(Method(method_))
  }
  if on_submit_ != "" {
    base.push(on_submit(on_submit_))
  }
  Node("form", base, children)
}

// void elements

///|
/// `<br>` — a line break. Void element: no children, no closing tag.
///
/// Example:
/// `br()` -> `<br>`
pub fn br() -> Html {
  Node("br", [], [])
}

///|
/// `<hr>` — a thematic break (horizontal rule). Void element.
///
/// Example:
/// `hr()` -> `<hr>`
pub fn hr() -> Html {
  Node("hr", [], [])
}

///|
/// `<img>` — an image. Void element: `src`/`alt` are required-ish (both
/// default to `""` for convenience, but real markup should set both for
/// accessibility).
///
/// Example:
/// `img(src="cat.png", alt="A cat", width=200)`
/// -> `<img src="cat.png" alt="A cat" width="200">`
pub fn img(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  src~ : String,
  alt? : String = "",
  width? : Int = 0,
  height? : Int = 0,
  attrs? : Array[Attr] = [],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  base.push(Src(src))
  base.push(Alt(alt))
  if width > 0 {
    base.push(Width(width))
  }
  if height > 0 {
    base.push(Height(height))
  }
  Node("img", base, [])
}

///|
/// `<canvas>` — a raster drawing surface for JS-driven graphics. Any
/// children only serve as a fallback for non-supporting browsers.
///
/// Example:
/// `canvas(id="chart", width=300, height=150, [])`
/// -> `<canvas id="chart" width="300" height="150"></canvas>`
pub fn canvas(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  width? : Int = 0,
  height? : Int = 0,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if width > 0 {
    base.push(Width(width))
  }
  if height > 0 {
    base.push(Height(height))
  }
  Node("canvas", base, children)
}

///|
/// `<iframe>` — an embedded browsing context (embeds another page).
///
/// Example:
/// `iframe(src="https://example.com", title="Example", width=400, height=300)`
/// -> `<iframe src="https://example.com" title="Example" width="400" height="300"></iframe>`
pub fn iframe(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  src~ : String,
  title? : String = "",
  width? : Int = 0,
  height? : Int = 0,
  attrs? : Array[Attr] = [],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  base.push(Src(src))
  if title != "" {
    base.push(Title_(title))
  }
  if width > 0 {
    base.push(Width(width))
  }
  if height > 0 {
    base.push(Height(height))
  }
  Node("iframe", base, [])
}

///|
/// `<video>` — embedded video. Pass `<source>` elements (via `source_`)
/// as children, or a bare `src` for a single source.
///
/// Example:
/// `video(src="clip.mp4", controls=true, [])`
/// -> `<video src="clip.mp4" controls></video>`
pub fn video(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  src? : String = "",
  controls? : Bool = true,
  autoplay? : Bool = false,
  loop_? : Bool = false,
  muted? : Bool = false,
  poster? : String = "",
  width? : Int = 0,
  height? : Int = 0,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if src != "" {
    base.push(Src(src))
  }
  if controls {
    base.push(Controls(true))
  }
  if autoplay {
    base.push(Autoplay(true))
  }
  if loop_ {
    base.push(Loop_(true))
  }
  if muted {
    base.push(Muted(true))
  }
  if poster != "" {
    base.push(Poster(poster))
  }
  if width > 0 {
    base.push(Width(width))
  }
  if height > 0 {
    base.push(Height(height))
  }
  Node("video", base, children)
}

///|
/// `<audio>` — embedded audio. Pass `<source>` elements (via `source_`)
/// as children, or a bare `src` for a single source.
///
/// Example:
/// `audio(src="song.mp3", controls=true, [])`
/// -> `<audio src="song.mp3" controls></audio>`
pub fn audio(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  src? : String = "",
  controls? : Bool = true,
  autoplay? : Bool = false,
  loop_? : Bool = false,
  muted? : Bool = false,
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if src != "" {
    base.push(Src(src))
  }
  if controls {
    base.push(Controls(true))
  }
  if autoplay {
    base.push(Autoplay(true))
  }
  if loop_ {
    base.push(Loop_(true))
  }
  if muted {
    base.push(Muted(true))
  }
  Node("audio", base, children)
}

///|
/// `<source>` — an alternate media resource for `video`/`audio`/`picture`.
/// Void element. Named `source_` to avoid clashing with common local
/// variable names like `source`.
///
/// Example:
/// `video([source_(src="clip.webm", type_="video/webm"), source_(src="clip.mp4", type_="video/mp4")])`
/// -> `<video><source src="clip.webm" type="video/webm"><source src="clip.mp4" type="video/mp4"></video>`
pub fn source_(src~ : String, type_? : String = "") -> Html {
  let base : Array[Attr] = [Src(src)]
  if type_ != "" {
    base.push(Type_(type_))
  }
  Node("source", base, [])
}

///|
/// `<track>` — timed text track (captions/subtitles) for `video`/`audio`.
/// Void element.
///
/// Example:
/// `track(src="captions.vtt", kind="captions", label="English")`
/// -> `<track src="captions.vtt" kind="captions" label="English">`
pub fn track(src~ : String, kind? : String = "", label? : String = "") -> Html {
  let base : Array[Attr] = [Src(src)]
  if kind != "" {
    base.push(Prop("kind", kind))
  }
  if label != "" {
    base.push(Label_(label))
  }
  Node("track", base, [])
}

///|
/// `<embed>` — a plugin/external-content placeholder. Void element.
///
/// Example:
/// `embed(src="chart.svg", type_="image/svg+xml")`
/// -> `<embed src="chart.svg" type="image/svg+xml">`
pub fn embed(src~ : String, type_? : String = "") -> Html {
  let base : Array[Attr] = [Src(src)]
  if type_ != "" {
    base.push(Type_(type_))
  }
  Node("embed", base, [])
}

///|
/// `<col>` — column formatting hint inside a `colgroup`. Void element.
///
/// Example:
/// `col(span=2)` -> `<col span="2">`
pub fn col(span? : Int = 0, attrs? : Array[Attr] = []) -> Html {
  let base = attrs.copy()
  if span > 0 {
    base.push(Prop("span", "\{span}"))
  }
  Node("col", base, [])
}

///|
/// `<colgroup>` — groups `col` formatting hints for a `table`.
///
/// Example:
/// `colgroup([col(span=2), col()])`
/// -> `<colgroup><col span="2"><col></colgroup>`
pub fn colgroup(attrs? : Array[Attr] = [], children : Array[Html]) -> Html {
  Node("colgroup", attrs, children)
}

///|
/// `<progress>` — a determinate/indeterminate progress bar. Omit `value`
/// (leave it `""`) for an indeterminate bar.
///
/// Example:
/// `progress(value="70", max="100")` -> `<progress value="70" max="100">`
pub fn progress(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  value? : String = "",
  max? : String = "",
  attrs? : Array[Attr] = [],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if value != "" {
    base.push(Value(value))
  }
  if max != "" {
    base.push(Max(max))
  }
  Node("progress", base, [])
}

///|
/// `<meter>` — a scalar measurement within a known range (e.g. disk
/// usage), as distinct from `progress`'s task-completion meaning.
///
/// Example:
/// `meter(value="6", min="0", max="10", [text("6 out of 10")])`
/// -> `<meter value="6" min="0" max="10">6 out of 10</meter>`
pub fn meter(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  value? : String = "",
  min? : String = "",
  max? : String = "",
  attrs? : Array[Attr] = [],
  children : Array[Html],
) -> Html {
  let base = build_attrs(id~, class~, style~, attrs~)
  if value != "" {
    base.push(Value(value))
  }
  if min != "" {
    base.push(Min(min))
  }
  if max != "" {
    base.push(Max(max))
  }
  Node("meter", base, children)
}

///|
/// `<meta>` — document metadata. Provide either `charset` (for
/// `<meta charset="...">`) or a `name`/`content` pair (for
/// `<meta name="..." content="...">`).
///
/// Example:
/// `meta(charset="utf-8")` -> `<meta charset="utf-8">`
/// `meta(name="viewport", content="width=device-width")`
/// -> `<meta name="viewport" content="width=device-width">`
pub fn meta(
  charset? : String = "",
  content? : String = "",
  name? : String = "",
  attrs? : Array[Attr] = [],
) -> Html {
  let base : Array[Attr] = []
  if charset != "" {
    base.push(Charset(charset))
  }
  if content != "" {
    base.push(Prop("content", content))
  }
  if name != "" {
    base.push(Prop("name", name))
  }
  Node("meta", [..base, ..attrs], [])
}

///|
/// `<link>` — an external resource link, most commonly a stylesheet.
///
/// Example:
/// `link(href="/style.css", rel="stylesheet")`
/// -> `<link rel="stylesheet" href="/style.css">`
pub fn link(
  href~ : String,
  rel~ : String,
  type_? : String = "",
  attrs? : Array[Attr] = [],
) -> Html {
  let base = [Rel(rel), Href(href)]
  if type_ != "" {
    base.push(Type_(type_))
  }
  Node("link", [..base, ..attrs], [])
}

///|
/// `<script src="...">` — an external script tag. For inline script
/// bodies use `inline_script`.
///
/// Example:
/// `script(src="/app.js", defer_=true)` -> `<script defer src="/app.js"></script>`
pub fn script(
  async_? : Bool = false,
  defer_? : Bool = false,
  type_? : String = "",
  src~ : String,
) -> Html {
  let base = [Async(async_), Defer(defer_), Src(src)]
  if type_ != "" {
    base.push(Type_(type_))
  }
  Node("script", base, [])
}

///|
/// `<script>...</script>` with a raw, un-escaped JS body. See `Unsafe`
/// for the same caveat: never build `src` from untrusted input.
///
/// Example:
/// `inline_script("console.log('hi')")`
/// -> `<script>console.log('hi')</script>`
pub fn inline_script(src : String) -> Html {
  Node("script", [], [Unsafe(src)])
}

///|
/// `<title>` — the document title shown in the browser tab/history.
///
/// Example:
/// `title("My Site")` -> `<title>My Site</title>`
pub fn title(t : String) -> Html {
  Node("title", [], [Text(t)])
}

// structural

///|
/// `<html lang="...">` — the document root.
///
/// Example:
/// `html_el([head([title("My Site")]), body([])])`
/// -> `<html lang="en"><head><title>My Site</title></head><body></body></html>`
pub fn html_el(lang? : String = "en", children : Array[Html]) -> Html {
  Node("html", [Lang(lang)], children)
}

///|
/// `<head>` — document metadata container (title, meta, link, script).
///
/// Example:
/// `head([title("My Site"), meta(charset="utf-8")])`
/// -> `<head><title>My Site</title><meta charset="utf-8"></head>`
pub fn head(children : Array[Html]) -> Html {
  Node("head", [], children)
}

///|
/// `<body>` — the document's visible content root.
///
/// Example:
/// `body([h1([text("Hi")])])` -> `<body><h1>Hi</h1></body>`
pub fn body(attrs? : Array[Attr] = [], children : Array[Html]) -> Html {
  Node("body", build_attrs(attrs~), children)
}

// =============================================================================
// Internal helpers
// =============================================================================

///|
fn input_type_to_string(t : InputType) -> String {
  match t {
    Text => "text"
    Password => "password"
    Email => "email"
    Number => "number"
    Checkbox => "checkbox"
    Radio => "radio"
    File => "file"
    Hidden => "hidden"
    Submit => "submit"
    Reset => "reset"
    Button => "button"
    Range => "range"
    Date => "date"
    Color => "color"
    Search => "search"
    Tel => "tel"
    Url => "url"
  }
}

///|
fn target_to_string(t : Target) -> String {
  match t {
    Self_ => "_self"
    Blank => "_blank"
    Parent => "_parent"
    Top => "_top"
  }
}

///|
/// Internal: accumulate common attrs (`id`, `class`, `style`) plus any
/// caller-supplied `attrs` into a single `Array[Attr]`. Every element
/// builder above funnels its labeled args through this so behavior stays
/// consistent (e.g. empty strings/arrays are always omitted from output).
fn build_attrs(
  id? : String = "",
  class? : String = "",
  style? : Array[(String, String)] = [],
  attrs? : Array[Attr] = [],
) -> Array[Attr] {
  let out : Array[Attr] = []
  if id != "" {
    out.push(Id(id))
  }
  if class != "" {
    out.push(Class(class))
  }
  if !style.is_empty() {
    out.push(Style(style))
  }
  attrs.each(fn(a) { out.push(a) })
  out
}

///|
/// Void elements must not have a closing tag.
fn is_void(tag : String) -> Bool {
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

// =============================================================================
// Render — Html -> String  (mirrors luna's render output)
// =============================================================================

///|
/// Escape HTML special characters to prevent XSS.
pub fn escape(s : String) -> String {
  let buf = StringBuilder::new(size_hint=s.length())
  s
  .iter()
  .each(fn(c) {
    match c {
      '&' => buf.write_string("&amp;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(c)
    }
  })
  buf.to_string()
}

///|
/// Render a single Attr to its HTML string, including the leading space
/// so callers can just concatenate the results directly after the tag
/// name (`render` does exactly that).
fn render_attr(attr : Attr) -> String {
  match attr {
    Id(v) => " id=\"\{escape(v)}\""
    Class(v) => " class=\"\{escape(v)}\""
    Href(v) => " href=\"\{escape(v)}\""
    Src(v) => " src=\"\{escape(v)}\""
    Alt(v) => " alt=\"\{escape(v)}\""
    Type_(v) => " type=\"\{escape(v)}\""
    Value(v) => " value=\"\{escape(v)}\""
    Placeholder(v) => " placeholder=\"\{escape(v)}\""
    Name(v) => " name=\"\{escape(v)}\""
    For_(v) => " for=\"\{escape(v)}\""
    Action(v) => " action=\"\{escape(v)}\""
    Method(v) => " method=\"\{escape(v)}\""
    Charset(v) => " charset=\"\{escape(v)}\""
    Rel(v) => " rel=\"\{escape(v)}\""
    Lang(v) => " lang=\"\{escape(v)}\""
    Target_(t) => " target=\"\{target_to_string(t)}\""
    Prop(k, v) => " \{k}=\"\{escape(v)}\""
    Disabled(b) => if b { " disabled" } else { "" }
    Checked(b) => if b { " checked" } else { "" }
    Required(b) => if b { " required" } else { "" }
    Readonly(b) => if b { " readonly" } else { "" }
    AutoFocus(b) => if b { " autofocus" } else { "" }
    Multiple(b) => if b { " multiple" } else { "" }
    Rows(n) => " rows=\"\{n}\""
    Cols(n) => " cols=\"\{n}\""
    Controls(b) => if b { " controls" } else { "" }
    Autoplay(b) => if b { " autoplay" } else { "" }
    Loop_(b) => if b { " loop" } else { "" }
    Muted(b) => if b { " muted" } else { "" }
    Poster(v) => " poster=\"\{escape(v)}\""
    Min(v) => " min=\"\{escape(v)}\""
    Max(v) => " max=\"\{escape(v)}\""
    Step(v) => " step=\"\{escape(v)}\""
    Selected(b) => if b { " selected" } else { "" }
    Label_(v) => " label=\"\{escape(v)}\""
    DateTime(v) => " datetime=\"\{escape(v)}\""
    Colspan(n) => " colspan=\"\{n}\""
    Rowspan(n) => " rowspan=\"\{n}\""
    Width(n) => " width=\"\{n}\""
    Height(n) => " height=\"\{n}\""
    Title_(v) => " title=\"\{escape(v)}\""
    Cite(v) => " cite=\"\{escape(v)}\""
    Style(pairs) => {
      if pairs.is_empty() {
        return ""
      }
      let css = pairs.map(fn(kv) { "\{kv.0}:\{kv.1}" }).join(";")
      " style=\"\{css}\""
    }
    Defer(b) => if b { " defer" } else { "" }
    Async(b) => if b { " async" } else { "" }
    On(Click(js)) => " onclick=\"\{js}\""
    On(Change(js)) => " onchange=\"\{js}\""
    On(DblClick(js)) => " ondblclick=\"\{js}\""
    On(MouseEnter(js)) => " onmouseenter=\"\{js}\""
    On(MouseLeave(js)) => " onmouseleave=\"\{js}\""
    On(Input(js)) => " oninput=\"\{js}\""
    On(Submit(js)) => " onsubmit=\"\{js}\""
    On(Focus(js)) => " onfocus=\"\{js}\""
    On(Blur(js)) => " onblur=\"\{js}\""
    On(KeyDown(js)) => " onkeydown=\"\{js}\""
    On(KeyUp(js)) => " onkeyup=\"\{js}\""
    On(KeyPress(js)) => " onkeypress=\"\{js}\""
    OnRawEvent(name, js) => " \{name}=\"\{js}\""
  }
}

///|
/// Core recursive renderer: Html -> String.
pub fn render(node : Html) -> String {
  match node {
    Nothing => ""
    Text(s) => escape(s)
    Unsafe(s) => s
    Fragment(children) => children.map(render).join("")
    Node(tag, attrs, children) => {
      let buf = StringBuilder::new()
      buf.write_char('<')
      buf.write_string(tag)
      attrs.each(fn(a) { buf.write_string(render_attr(a)) })
      buf.write_char('>')
      if !is_void(tag) {
        children.each(fn(c) { buf.write_string(render(c)) })
        buf.write_string("</")
        buf.write_string(tag)
        buf.write_char('>')
      }
      buf.to_string()
    }
  }
}
