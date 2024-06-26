import gleam/int
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui
import lustre/ui/layout/aside

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(stitch_count: Int, stitch_count_input: String)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model(stitch_count: 60, stitch_count_input: "60"), effect.none())
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  UserPressedKey(value: String)
  UserUpdatedStitchCount(value: String)
  UserSubmittedStitchCount
  UserResetStitchCount
  GotSubmittedStitchCount(Result(String, Nil))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserPressedKey("Enter") -> {
      #(model, get_stitch_count())
    }
    UserPressedKey(_) -> {
      #(model, effect.none())
    }
    UserUpdatedStitchCount(value) -> {
      #(Model(..model, stitch_count_input: value), effect.none())
    }
    UserSubmittedStitchCount -> {
      #(model, get_stitch_count())
    }
    UserResetStitchCount -> #(
      Model(stitch_count: 60, stitch_count_input: "60"),
      effect.none(),
    )
    GotSubmittedStitchCount(Ok(value)) -> {
      let stitch_count =
        int.parse(value)
        |> result.unwrap(60)
      #(
        Model(stitch_count: stitch_count, stitch_count_input: value),
        effect.none(),
      )
    }
    GotSubmittedStitchCount(Error(_)) -> {
      #(model, effect.none())
    }
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let styles = [
    #("max-width", "60ch"),
    #("min-height", "100vh"),
    #("margin", "0 auto"),
    #("padding", "1rem"),
  ]

  ui.centre(
    [attribute.style(styles)],
    ui.stack([], [
      html.div([], [
        html.h1([], [element.text("Let's knit a sock!")]),
        html.p([], [
          element.text(
            "Instructions for a top-down sock with a reinforced heel flap and gusset.",
          ),
        ]),
      ]),
      ui.aside(
        [aside.align_end()],
        ui.field(
          [],
          [element.text("How many stitches?")],
          ui.input([
            attribute.id("stitch-count"),
            attribute.type_("number"),
            attribute.value(model.stitch_count_input),
            event.on_input(UserUpdatedStitchCount),
            event.on_keydown(UserPressedKey),
          ]),
          [],
        ),
        ui.button([event.on_click(UserSubmittedStitchCount)], [
          element.text("Calculate"),
        ]),
      ),
      ui.prose([], [
        collapsible("Cuff & Leg", [
          cuff_instructions(model.stitch_count),
          leg_instructions(),
        ]),
        collapsible("Heel", [
          heel_flap_instructions(model.stitch_count),
          heel_turn_instructions(model.stitch_count),
        ]),
        html.h3([], [element.text("Gusset & Foot")]),
        footer(),
      ]),
    ]),
  )
}

fn get_stitch_count() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_get_stitch_count()
    |> GotSubmittedStitchCount
    |> dispatch
  })
}

@external(javascript, "./sock_calculator.ffi.mjs", "get_stitch_count")
fn do_get_stitch_count() -> Result(String, Nil) {
  Error(Nil)
}

// VIEW HELPERS ------------------------------------------------------------------------

fn footer() -> Element(Msg) {
  html.p([], [
    element.text("You can read about this project here. (soon). "),
    element.text("Created with "),
    link("Gleam", "https://gleam.run/"),
    element.text(" and "),
    link("Lustre", "https://hexdocs.pm/lustre/index.html"),
    element.text(". "),
    element.text("View on "),
    link("GitHub", "https://github.com/sannek/sock_calculator"),
  ])
}

fn link(text: String, to: String) -> Element(Msg) {
  html.a([attribute.href(to), attribute.target("_blank")], [element.text(text)])
}

fn collapsible(summary: String, children: List(Element(Msg))) -> Element(Msg) {
  html.details([attribute.attribute("open", "true")], [
    html.summary([], [element.text(summary)]),
    ..children
  ])
}

// TEXT HELPERS ------------------------------------------------------------------------

fn cuff_instructions(stitch_count: Int) -> Element(Msg) {
  let str_count = int.to_string(stitch_count)
  let cuff =
    "Cast on #stitch_count stitches. Divide evenly between DPNs and join to start knitting in the round. Work about 2cm in ribbing of your choice."
  html.p([], [
    element.text(string.replace(cuff, each: "#stitch_count", with: str_count)),
  ])
}

fn leg_instructions() -> Element(Msg) {
  let leg =
    "Continue in stockinette (or the stitch pattern of your choice) until the leg has reached the desired length. I usually work 13-16cm before starting the heel, depending on size and patience."
  html.p([], [element.text(leg)])
}

fn heel_flap_instructions(stitch_count: Int) -> Element(Msg) {
  // Half of the total stitches, rounded down
  let heel_st_count = stitch_count / 2
  let heel_flap_rows = { heel_st_count / 2 } - 1

  let intro =
    "The heel flap is worked back and forth over the first #heel_st_count stitches. Repeat the two rows below a total #heel_flap_rows times, ending with a WS row."
    |> string.replace(
      each: "#heel_st_count",
      with: int.to_string(heel_st_count),
    )
    |> string.replace(
      each: "#heel_flap_rows",
      with: int.to_string(heel_flap_rows),
    )

  let row_1 = case heel_st_count % 2 {
    0 -> "*sl1, k1*"
    _ -> "*sl1, k1*, k1"
  }

  html.div([], [
    html.p([], [element.text(intro)]),
    html.ol([attribute.class("pattern-rows")], [
      html.li([], [element.text(row_1)]),
      html.li([], [element.text("sl1, p to end")]),
    ]),
  ])
}

fn heel_turn_instructions(stitch_count: Int) -> Element(Msg) {
  let heel_st_count = stitch_count / 2
  let half_heel_st_count = heel_st_count / 2
  let extra = 3 - { half_heel_st_count % 2 }

  // verify this next time you turn a heel
  let row_two_count = extra * 2 + { half_heel_st_count % 2 } + 1

  let row_one =
    "sl1, k" <> int.to_string(half_heel_st_count + extra) <> ", ssk, k1, turn"
  let row_two = "sl1, p" <> int.to_string(row_two_count) <> ", ssk, k1, turn"

  html.div([], [
    html.p([], [element.text("Lets turn the heel!")]),
    html.ol([attribute.class("pattern-rows")], [
      html.li([], [element.text(row_one)]),
      html.li([], [element.text(row_two)]),
      html.li([], [element.text("sl1, k to 1 stitch before gap, ssk, k1, turn")]),
      html.li([], [
        element.text("sl1, p to 1 stitch before gap, p2tog, p1, turn"),
      ]),
    ]),
    html.p([], [
      element.text("Repeat row 3 and 4 until all stitches have been worked."),
    ]),
  ])
}
