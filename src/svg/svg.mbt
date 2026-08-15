// =============================================================================
// svg.mbt — type-safe SVG DSL
//
// SVG is represented using the existing Html tree so the normal `render`
// function remains the single renderer. SVG-specific attributes and element
// constructors live in this file.
//
// Example:
//
// let chart = svg(
//   view_box="0 0 100 100",
//   attrs=[SvgAttr::Width("200"), SvgAttr::Height("200")],
//   children=[
//     rect(x="10", y="10", width="80", height="80",
//       attrs=[SvgAttr::Fill("none"), SvgAttr::Stroke("black")]),
//     circle(cx="50", cy="50", r="30",
//       attrs=[SvgAttr::Fill("red")]),
//   ],
// )
//
// render(chart)
// =============================================================================

///|
using @html {type Attr, type Html}

///|
/// SVG-specific attributes.
///
/// The enum deliberately uses typed constructors for common SVG attributes
/// rather than requiring callers to spell SVG attribute names themselves.
/// `Custom` remains an escape hatch for SVG attributes not represented here.
pub(all) enum SvgAttr {
  X(String)
  Y(String)
  X1(String)
  Y1(String)
  X2(String)
  Y2(String)
  Cx(String)
  Cy(String)
  R(String)
  Rx(String)
  Ry(String)
  D(String)
  Points(String)
  Width(String)
  Height(String)
  ViewBox(String)
  PreserveAspectRatio(String)
  Fill(String)
  FillOpacity(String)
  FillRule(String)
  Stroke(String)
  StrokeWidth(String)
  StrokeOpacity(String)
  StrokeLinecap(String)
  StrokeLinejoin(String)
  StrokeDasharray(String)
  StrokeDashoffset(String)
  Opacity(String)
  Transform(String)
  TransformOrigin(String)
  Offset(String)
  StopColor(String)
  StopOpacity(String)
  GradientUnits(String)
  GradientTransform(String)
  PatternUnits(String)
  PatternContentUnits(String)
  PatternTransform(String)
  ClipPath(String)
  ClipRule(String)
  Mask(String)
  MaskUnits(String)
  MarkerStart(String)
  MarkerMid(String)
  MarkerEnd(String)
  FontFamily(String)
  FontSize(String)
  FontWeight(String)
  TextAnchor(String)
  DominantBaseline(String)
  Role(String)
  AriaLabel(String)
  Custom(String, String)
}

///|
/// Convert a typed SVG attribute to the existing generic HTML attribute.
///
/// SVG attributes are rendered by the same `render` implementation used by
/// HTML, so there is no second renderer to keep in sync.
fn svg_attr_to_attr(attr : SvgAttr) -> Attr {
  match attr {
    X(v) => Prop("x", v)
    Y(v) => Prop("y", v)
    X1(v) => Prop("x1", v)
    Y1(v) => Prop("y1", v)
    X2(v) => Prop("x2", v)
    Y2(v) => Prop("y2", v)
    Cx(v) => Prop("cx", v)
    Cy(v) => Prop("cy", v)
    R(v) => Prop("r", v)
    Rx(v) => Prop("rx", v)
    Ry(v) => Prop("ry", v)
    D(v) => Prop("d", v)
    Points(v) => Prop("points", v)
    Width(v) => Prop("width", v)
    Height(v) => Prop("height", v)
    ViewBox(v) => Prop("viewBox", v)
    PreserveAspectRatio(v) => Prop("preserveAspectRatio", v)
    Fill(v) => Prop("fill", v)
    FillOpacity(v) => Prop("fill-opacity", v)
    FillRule(v) => Prop("fill-rule", v)
    Stroke(v) => Prop("stroke", v)
    StrokeWidth(v) => Prop("stroke-width", v)
    StrokeOpacity(v) => Prop("stroke-opacity", v)
    StrokeLinecap(v) => Prop("stroke-linecap", v)
    StrokeLinejoin(v) => Prop("stroke-linejoin", v)
    StrokeDasharray(v) => Prop("stroke-dasharray", v)
    StrokeDashoffset(v) => Prop("stroke-dashoffset", v)
    Opacity(v) => Prop("opacity", v)
    Transform(v) => Prop("transform", v)
    TransformOrigin(v) => Prop("transform-origin", v)
    Offset(v) => Prop("offset", v)
    StopColor(v) => Prop("stop-color", v)
    StopOpacity(v) => Prop("stop-opacity", v)
    GradientUnits(v) => Prop("gradientUnits", v)
    GradientTransform(v) => Prop("gradientTransform", v)
    PatternUnits(v) => Prop("patternUnits", v)
    PatternContentUnits(v) => Prop("patternContentUnits", v)
    PatternTransform(v) => Prop("patternTransform", v)
    ClipPath(v) => Prop("clip-path", v)
    ClipRule(v) => Prop("clip-rule", v)
    Mask(v) => Prop("mask", v)
    MaskUnits(v) => Prop("maskUnits", v)
    MarkerStart(v) => Prop("marker-start", v)
    MarkerMid(v) => Prop("marker-mid", v)
    MarkerEnd(v) => Prop("marker-end", v)
    FontFamily(v) => Prop("font-family", v)
    FontSize(v) => Prop("font-size", v)
    FontWeight(v) => Prop("font-weight", v)
    TextAnchor(v) => Prop("text-anchor", v)
    DominantBaseline(v) => Prop("dominant-baseline", v)
    Role(v) => Prop("role", v)
    AriaLabel(v) => Prop("aria-label", v)
    Custom(name, value) => Prop(name, value)
  }
}

///|
/// Convert SVG attributes to the generic attributes understood by `Html`.
fn svg_attrs(attrs : Array[SvgAttr]) -> Array[Attr] {
  attrs.map(svg_attr_to_attr)
}

///|
/// Build an SVG element using the existing Html node representation.
///
/// This is the common implementation behind all SVG element constructors.
fn svg_node(
  tag : String,
  attrs : Array[SvgAttr],
  children : Array[Html],
) -> Html {
  @html.node(tag, svg_attrs(attrs), children)
}

///|
/// Root `<svg>` element.
pub fn svg(
  width? : String = "",
  height? : String = "",
  view_box? : String = "",
  attrs? : Array[SvgAttr] = [],
  children : Array[Html],
) -> Html {
  let a = attrs.copy()
  if width != "" {
    a.push(Width(width))
  }
  if height != "" {
    a.push(Height(height))
  }
  if view_box != "" {
    a.push(ViewBox(view_box))
  }
  svg_node("svg", a, children)
}

///|
/// `<g>` group.
pub fn g(attrs? : Array[SvgAttr] = [], children : Array[Html]) -> Html {
  svg_node("g", attrs, children)
}

///|
/// `<rect>`.
pub fn rect(
  x? : String = "",
  y? : String = "",
  width? : String = "",
  height? : String = "",
  rx? : String = "",
  ry? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if x != "" {
    a.push(X(x))
  }
  if y != "" {
    a.push(Y(y))
  }
  if width != "" {
    a.push(Width(width))
  }
  if height != "" {
    a.push(Height(height))
  }
  if rx != "" {
    a.push(Rx(rx))
  }
  if ry != "" {
    a.push(Ry(ry))
  }
  svg_node("rect", a, children)
}

///|
/// `<circle>`.
pub fn circle(
  cx? : String = "",
  cy? : String = "",
  r? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if cx != "" {
    a.push(Cx(cx))
  }
  if cy != "" {
    a.push(Cy(cy))
  }
  if r != "" {
    a.push(R(r))
  }
  svg_node("circle", a, children)
}

///|
/// `<ellipse>`.
pub fn ellipse(
  cx? : String = "",
  cy? : String = "",
  rx? : String = "",
  ry? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if cx != "" {
    a.push(Cx(cx))
  }
  if cy != "" {
    a.push(Cy(cy))
  }
  if rx != "" {
    a.push(Rx(rx))
  }
  if ry != "" {
    a.push(Ry(ry))
  }
  svg_node("ellipse", a, children)
}

///|
/// `<line>`.
pub fn line(
  x1? : String = "",
  y1? : String = "",
  x2? : String = "",
  y2? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if x1 != "" {
    a.push(X1(x1))
  }
  if y1 != "" {
    a.push(Y1(y1))
  }
  if x2 != "" {
    a.push(X2(x2))
  }
  if y2 != "" {
    a.push(Y2(y2))
  }
  svg_node("line", a, children)
}

///|
/// `<polyline>`.
pub fn polyline(
  points? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if points != "" {
    a.push(Points(points))
  }
  svg_node("polyline", a, children)
}

///|
/// `<polygon>`.
pub fn polygon(
  points? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if points != "" {
    a.push(Points(points))
  }
  svg_node("polygon", a, children)
}

///|
/// `<path>`.
pub fn path(
  d? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if d != "" {
    a.push(D(d))
  }
  svg_node("path", a, children)
}

///|
/// `<text>`.
pub fn text(
  x? : String = "",
  y? : String = "",
  attrs? : Array[SvgAttr] = [],
  children : Array[Html],
) -> Html {
  let a = attrs.copy()
  if x != "" {
    a.push(X(x))
  }
  if y != "" {
    a.push(Y(y))
  }
  svg_node("text", a, children)
}

///|
/// `<tspan>`.
pub fn tspan(
  x? : String = "",
  y? : String = "",
  attrs? : Array[SvgAttr] = [],
  children : Array[Html],
) -> Html {
  let a = attrs.copy()
  if x != "" {
    a.push(X(x))
  }
  if y != "" {
    a.push(Y(y))
  }
  svg_node("tspan", a, children)
}

///|
/// `<defs>`.
pub fn defs(attrs? : Array[SvgAttr] = [], children : Array[Html]) -> Html {
  svg_node("defs", attrs, children)
}

///|
/// `<linearGradient>`.
pub fn linear_gradient(
  id? : String = "",
  attrs? : Array[SvgAttr] = [],
  children : Array[Html],
) -> Html {
  let a = attrs.copy()
  if id != "" {
    a.push(Custom("id", id))
  }
  svg_node("linearGradient", a, children)
}

///|
/// `<radialGradient>`.
pub fn radial_gradient(
  id? : String = "",
  attrs? : Array[SvgAttr] = [],
  children : Array[Html],
) -> Html {
  let a = attrs.copy()
  if id != "" {
    a.push(Custom("id", id))
  }
  svg_node("radialGradient", a, children)
}

///|
/// `<stop>`.
pub fn stop(
  offset? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if offset != "" {
    a.push(Offset(offset))
  }
  svg_node("stop", a, children)
}

///|
/// `<clipPath>`.
pub fn clip_path(
  id? : String = "",
  attrs? : Array[SvgAttr] = [],
  children : Array[Html],
) -> Html {
  let a = attrs.copy()
  if id != "" {
    a.push(Custom("id", id))
  }
  svg_node("clipPath", a, children)
}

///|
/// `<mask>`.
pub fn mask(
  id? : String = "",
  attrs? : Array[SvgAttr] = [],
  children : Array[Html],
) -> Html {
  let a = attrs.copy()
  if id != "" {
    a.push(Custom("id", id))
  }
  svg_node("mask", a, children)
}

///|
/// `<use>`.
pub fn use_(
  href? : String = "",
  attrs? : Array[SvgAttr] = [],
  children? : Array[Html] = [],
) -> Html {
  let a = attrs.copy()
  if href != "" {
    a.push(Custom("href", href))
  }
  svg_node("use", a, children)
}

///|
/// SVG `<title>`.
pub fn title(attrs? : Array[SvgAttr] = [], children : Array[Html]) -> Html {
  svg_node("title", attrs, children)
}

///|
/// SVG `<desc>`.
pub fn desc(attrs? : Array[SvgAttr] = [], children : Array[Html]) -> Html {
  svg_node("desc", attrs, children)
}

///|
/// SVG event attributes can still use the existing HTML event API because
/// both SVG and HTML ultimately render through the same Attr type.
///
/// For attributes such as `onclick` this helper provides a convenient
/// SVG-local spelling while preserving the existing renderer.
pub fn on_click(js : String) -> Attr {
  on_click(js)
}

///|
/// Add a generic HTML attribute to an SVG element when it is not represented
/// by `SvgAttr`.
pub fn prop(name : String, value : String) -> SvgAttr {
  Custom(name, value)
}

///|
/// Inline SVG style helper.
///
/// Example:
/// `style([("vector-effect", "non-scaling-stroke")])`
pub fn style(pairs : Array[(String, String)]) -> SvgAttr {
  Custom("style", pairs.map(fn(p) { "\{p.0}:\{p.1}" }).join(";"))
}
