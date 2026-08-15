## Quick start

```json
import {
  "kaashyapan/html_dsl/html"
}
```

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
