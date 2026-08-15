///|
test "svg figure" {
  let chart = svg(width="200", height="200", view_box="0 0 100 100", [
    rect(x="10", y="10", width="80", height="80", attrs=[
      SvgAttr::Fill("none"),
      SvgAttr::Stroke("black"),
    ]),
    circle(cx="50", cy="50", r="30", attrs=[SvgAttr::Fill("red")]),
  ])
  assert_eq(
    @html.render(chart),
    "<svg width=\"200\" height=\"200\" viewBox=\"0 0 100 100\"><rect fill=\"none\" stroke=\"black\" x=\"10\" y=\"10\" width=\"80\" height=\"80\"></rect><circle fill=\"red\" cx=\"50\" cy=\"50\" r=\"30\"></circle></svg>",
  )
}
