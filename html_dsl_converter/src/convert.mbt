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
/// SVG elements go through the `@svg` builders; `<script>` elements without
/// attributes go through `@h.inline_script`, which keeps the JS body raw; text
/// content anywhere else is HTML-escaped by `@h.text`. Doctypes inside
/// elements are dropped because a doctype is not valid element content.
fn convert_element(node : Node) -> @h.Html {
  if is_svg_node(node) {
    return convert_svg_element(node)
  }
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
/// Check whether a parsed element node lives in the SVG namespace.
fn is_svg_node(node : Node) -> Bool {
  node.namespace_uri() == Some("svg")
}

///|
/// Convert an SVG element using the @svg builder functions.
///
/// Every attribute becomes a typed `SvgAttr` (or `Custom` for attributes the
/// enum does not cover); unknown SVG tags fall back to the generic `node`
/// builder with plain HTML attributes.
fn convert_svg_element(node : Node) -> @h.Html {
  let children : Array[@h.Html] = []
  for child in node.children() {
    match child.kind() {
      NodeKind::Doctype => ()
      _ => children.push(convert_node(child))
    }
  }
  let attrs = convert_svg_attrs(node)
  match node.name() {
    "svg" => @svg.svg(attrs~, children)
    "g" => @svg.g(attrs~, children)
    "rect" => @svg.rect(attrs~, children~)
    "circle" => @svg.circle(attrs~, children~)
    "ellipse" => @svg.ellipse(attrs~, children~)
    "line" => @svg.line(attrs~, children~)
    "polyline" => @svg.polyline(attrs~, children~)
    "polygon" => @svg.polygon(attrs~, children~)
    "path" => @svg.path(attrs~, children~)
    "text" => @svg.text(attrs~, children)
    "tspan" => @svg.tspan(attrs~, children)
    "defs" => @svg.defs(attrs~, children)
    "linearGradient" => @svg.linear_gradient(attrs~, children)
    "radialGradient" => @svg.radial_gradient(attrs~, children)
    "stop" => @svg.stop(attrs~, children~)
    "clipPath" => @svg.clip_path(attrs~, children)
    "mask" => @svg.mask(attrs~, children)
    "use" => @svg.use_(attrs~, children~)
    "title" => @svg.title(attrs~, children)
    "desc" => @svg.desc(attrs~, children)
    _ => @h.node(node.name(), convert_attrs(node), children)
  }
}

///|
/// Convert the attribute map of an SVG element to typed `SvgAttr` values.
/// Valueless attributes become `Custom(name, "")`.
fn convert_svg_attrs(node : Node) -> Array[@svg.SvgAttr] {
  let attrs : Array[@svg.SvgAttr] = []
  for name, value in node.attrs() {
    match value {
      Some(v) => attrs.push(svg_attr_from(name, v))
      None => attrs.push(@svg.SvgAttr::Custom(name, ""))
    }
  }
  attrs
}

///|
/// Build a typed SVG attribute from a parsed attribute name and value.
/// Names not covered by the `SvgAttr` enum keep their exact spelling via
/// `Custom`, so nothing is lost.
fn svg_attr_from(name : String, value : String) -> @svg.SvgAttr {
  match name {
    "x" => @svg.SvgAttr::X(value)
    "y" => @svg.SvgAttr::Y(value)
    "x1" => @svg.SvgAttr::X1(value)
    "y1" => @svg.SvgAttr::Y1(value)
    "x2" => @svg.SvgAttr::X2(value)
    "y2" => @svg.SvgAttr::Y2(value)
    "cx" => @svg.SvgAttr::Cx(value)
    "cy" => @svg.SvgAttr::Cy(value)
    "r" => @svg.SvgAttr::R(value)
    "rx" => @svg.SvgAttr::Rx(value)
    "ry" => @svg.SvgAttr::Ry(value)
    "d" => @svg.SvgAttr::D(value)
    "points" => @svg.SvgAttr::Points(value)
    "width" => @svg.SvgAttr::Width(value)
    "height" => @svg.SvgAttr::Height(value)
    "viewBox" => @svg.SvgAttr::ViewBox(value)
    "preserveAspectRatio" => @svg.SvgAttr::PreserveAspectRatio(value)
    "fill" => @svg.SvgAttr::Fill(value)
    "fill-opacity" => @svg.SvgAttr::FillOpacity(value)
    "fill-rule" => @svg.SvgAttr::FillRule(value)
    "stroke" => @svg.SvgAttr::Stroke(value)
    "stroke-width" => @svg.SvgAttr::StrokeWidth(value)
    "stroke-opacity" => @svg.SvgAttr::StrokeOpacity(value)
    "stroke-linecap" => @svg.SvgAttr::StrokeLinecap(value)
    "stroke-linejoin" => @svg.SvgAttr::StrokeLinejoin(value)
    "stroke-dasharray" => @svg.SvgAttr::StrokeDasharray(value)
    "stroke-dashoffset" => @svg.SvgAttr::StrokeDashoffset(value)
    "opacity" => @svg.SvgAttr::Opacity(value)
    "transform" => @svg.SvgAttr::Transform(value)
    "transform-origin" => @svg.SvgAttr::TransformOrigin(value)
    "offset" => @svg.SvgAttr::Offset(value)
    "stop-color" => @svg.SvgAttr::StopColor(value)
    "stop-opacity" => @svg.SvgAttr::StopOpacity(value)
    "gradientUnits" => @svg.SvgAttr::GradientUnits(value)
    "gradientTransform" => @svg.SvgAttr::GradientTransform(value)
    "patternUnits" => @svg.SvgAttr::PatternUnits(value)
    "patternContentUnits" => @svg.SvgAttr::PatternContentUnits(value)
    "patternTransform" => @svg.SvgAttr::PatternTransform(value)
    "clip-path" => @svg.SvgAttr::ClipPath(value)
    "clip-rule" => @svg.SvgAttr::ClipRule(value)
    "mask" => @svg.SvgAttr::Mask(value)
    "maskUnits" => @svg.SvgAttr::MaskUnits(value)
    "marker-start" => @svg.SvgAttr::MarkerStart(value)
    "marker-mid" => @svg.SvgAttr::MarkerMid(value)
    "marker-end" => @svg.SvgAttr::MarkerEnd(value)
    "font-family" => @svg.SvgAttr::FontFamily(value)
    "font-size" => @svg.SvgAttr::FontSize(value)
    "font-weight" => @svg.SvgAttr::FontWeight(value)
    "text-anchor" => @svg.SvgAttr::TextAnchor(value)
    "dominant-baseline" => @svg.SvgAttr::DominantBaseline(value)
    "role" => @svg.SvgAttr::Role(value)
    "aria-label" => @svg.SvgAttr::AriaLabel(value)
    _ => @svg.SvgAttr::Custom(name, value)
  }
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
