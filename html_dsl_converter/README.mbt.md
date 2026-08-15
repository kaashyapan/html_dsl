# html_dsl_converter.mbt

Function to parse html string and convert it into the MoonBit Html DSL
---

## Installation

Add to your `moon.pkg`:

```json
import {
  "kaashyapan/html_dsl_converter"
}
```

---

## Quick start

```moonbit
  let html_str = "<p>Hello, MoonBit!</p>"
  let dsl = convert_html(html_str)
  let html_string = @html_dsl.render(dsl)
```

