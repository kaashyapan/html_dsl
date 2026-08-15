# html_dsl.mbt

A type-safe HTML DSL for [MoonBit](https://moonbitlang.com) that renders to a plain HTML string.  
No external dependencies. Works on all MoonBit targets — **JS, Wasm, and native**.

---

## Features

- **Typed nodes** — `Html` and `Attr` enums catch mistakes at compile time
- **Named-argument API** — optional `id`, `class`, `style`, `attrs` labeled args keep call sites clean
- **XSS-safe rendering** — text content is automatically escaped
- **Void element awareness** — `<br>`, `<input>`, `<meta>` etc. never get a closing tag
- **Escape hatch** — `node()` and `Prop()` handle any tag or attribute not in the DSL
- **HTMX friendly** — `OnRawEvent` renders arbitrary `data-*` and event attributes

---

## Installation

Add to your `moon.pkg`:

```json
import {
  "kaashyapan/html_dsl/html",
  "kaashyapan/html_dsl/svg"
}
```

---

## Quick start

```moonbit
let page : Html =
  html_el(lang="en", [
    head([
      title("My App"),
      link(rel="stylesheet", href="/styles.css"),
    ]),
    body([
      div(class="container mx-auto p-4", [
        h1([text("Hello, MoonBit!")]),
        p(class="text-gray-600", [
          text("A type-safe HTML DSL that renders to a string."),
        ]),
      ]),
    ]),
  ])

let html_string = render(page)
```

**Output:**

```html
<html lang="en">
  <head>
    <title>My App</title>
    <link rel="stylesheet" href="/styles.css" />
  </head>
  <body>
    <div class="container mx-auto p-4">
      <h1>Hello, MoonBit!</h1>
      <p class="text-gray-600">
        A type-safe HTML DSL that renders to a string.
      </p>
    </div>
  </body>
</html>
```

---

## Core types

### `Html`

```moonbit
pub(all) enum Html {
  Node(String, Array[Attr], Array[Html])   // element
  Text(String)                             // escaped text
  Unsafe(String)                           // unsafe raw html
  Fragment(Array[Html])                    // no wrapper element
  Nothing                                  // renders to ""
}
```

### `Attr`

```moonbit
pub(all) enum Attr {
  Id(String)       | Class(String)     | Href(String)
  Src(String)      | Alt(String)       | Type_(String)
  Value(String)    | Placeholder(String)
  Name(String)     | Rel(String)       | Lang(String)
  Prop(String, String)                 // arbitrary attribute
  Style(Array[(String, String)])       // inline styles
  On(Event)                            // typed event handler
  OnRawEvent(String, String)           // raw attribute name + value
  Disabled(Bool)   | Checked(Bool)    | Required(Bool)
  // … and more
}
```

---

## Element builders

All common HTML tags are available as functions. Optional attributes are passed as labeled arguments; children are the final positional argument.

### Structural

```moonbit
html_el(lang="en", [...])
head([...])
body([...])
```

### Block elements

```moonbit
div(id="app", class="flex", style=[("gap", "1rem")], [...])
p(class="text-sm text-gray-500", [...])
span(class="font-bold", [...])
h1([text("Page title")])
h2([text("Section")])
```

### Lists

```moonbit
ul([
  li([text("Apples")]),
  li([text("Bananas")]),
  li([text("Cherries")]),
])

ol([
  li([text("First")]),
  li([text("Second")]),
])
```

### Tables

```moonbit
table([
  thead([
    tr([th([text("Name")]), th([text("Score")])]),
  ]),
  tbody([
    tr([td([text("Alice")]), td([text("98")])]),
    tr([td([text("Bob")]),   td([text("87")])]),
  ]),
])
```

### Links and images

```moonbit
// href defaults to "#", target defaults to Self_
a(href="https://moonbitlang.com", target=Blank, [text("MoonBit")])

img(src="/logo.png", alt="Logo")
```

### Forms

```moonbit
form(on_submit="handleSubmit(event)", [
  label(for_="email", [text("Email")]),
  input(
    input_type=Email,
    placeholder="you@example.com",
    attrs=[Attr::Name("email"), Attr::Required(true)],
    nothing(),
  ),
  button(on_click="", [text("Subscribe")]),
])
```

> `input` takes a dummy `nothing()` as its last argument to keep the API consistent with other elements that accept children.

### Void elements

```moonbit
br()
hr()
meta(charset="utf-8")
meta(attrs=[Name("viewport"), Prop("content", "width=device-width, initial-scale=1")])
link(rel="stylesheet", href="/app.css")
script(defer_=true, type_="module", src="/app.js")
```

---

## Inline styles

Pass `(property, value)` pairs to the `style` labeled argument or the `Style` constructor:

```moonbit
div(
  style=[("display", "flex"), ("gap", "1rem"), ("padding", "1rem")],
  [
    span(style=[("color", "#0ea5e9"), ("font-weight", "bold")], [text("Blue")]),
    span(style=[("color", "#f97316")], [text("Orange")]),
  ],
)
```

---

## Event handlers

Typed events compile to the correct `on*` attribute:

```moonbit
button(on_click="doSomething()", [text("Click me")])

// For other events, use attrs=
div(attrs=[
  on_mouseenter("showTooltip()"),
  on_mouseleave("hideTooltip()"),
], [...])
```

---

## Arbitrary attributes with `Prop` and `Data` and `Aria`

Use `Prop(key, value)` for any attribute not covered by the DSL, and `Data(name, value)` and `Aria(name, value)` for data attributes or framework-specific bindings:

```moonbit
// HTMX
div(attrs=[
  Prop("hx-get", "/partial"),
  Prop("hx-target", "#result"),
  Prop("hx-trigger", "click"),
], [text("Load more")])

// Datastar signals
main_(attrs = [
  Data("signal-locale", "window.navigator.language"),
  Data("signal-theme",  "localStorage.getItem('theme')"),
], [...])
```

---

## Custom elements and escape hatch

`Node(tag, attrs, children)` renders any tag not in the DSL:

```moonbit
// Web components
Node("my-modal", [Prop("open", ""), Class("z-50")], [
  Node("my-modal-header", [], [text("Confirm?")]),
  Node("my-modal-footer", [], [
    button(on_click="modal.close()", [text("Cancel")]),
    button(on_click="modal.confirm()", [text("OK")]),
  ]),
])

// Custom elements with no children
Node("dataspa-inspector", [], [])
Node("subtitle", [], [])
```

---

## Conditional rendering

Use `Nothing` to conditionally include nodes:

```moonbit
fn alert_banner(show : Bool, message : String) -> Html {
  if show {
    div(class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded", [
      text(message),
    ])
  } else {
    Nothing
  }
}
```

Or filter a list with `fragment`:

```moonbit
let items = ["Alice", "Bob", ""]

Fragment(
  items
  .filter(fn(s) { s != "" })
  .map(fn(name) { li([text(name)]) }),
)
```

---

## Full page example

```moonbit
pub fn login_page() -> Html {
  html_el(lang="en", [
    head([
      title("Sign in"),
      meta(charset="utf-8"),
      meta(attrs=[
        Name("viewport"),
        Prop("content", "width=device-width, initial-scale=1"),
      ]),
      link(rel="stylesheet", href="/styles.css"),
    ]),
    body([
      div(class="min-h-screen flex items-center justify-center bg-gray-50", [
        div(class="max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow", [
          h1([text("Sign in to your account")]),
          form(on_submit="handleLogin(event)", [
            div(class="space-y-4 my-4", [
              div(class="flex gap-8", [
                label(class="w-16", for_="email", [text("Email")]),
                input(type_=Email, placeholder="you@example.com", attrs=[
                  Name("email"),
                  Required(true),
                ]),
              ]),
              div([
                label(class="w-16", for_="password", [text("Password")]),
                input(type_=Password, placeholder="••••••••", attrs=[
                  Name("password"),
                  Required(true),
                ]),
              ]),
            ]),
            button(
              type_=Submit,
              class="w-full py-2 px-4 bg-blue-600 text-white rounded-lg",
              [text("Sign in")],
            ),
          ]),
          p(class="text-center text-sm text-gray-500", [
            text("Don't have an account? "),
            a(href="/register", [text("Register")]),
          ]),
        ]),
      ]),
    ]),
  ])
}

// Render to a string ready to send as an HTTP response
let html_string = render(login_page())
```

---

## Rendering

```moonbit
// Html -> String
pub fn render(node : Html) -> String

// Escape text manually if needed
pub fn escape(s : String) -> String
```

