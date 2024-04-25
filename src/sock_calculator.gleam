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
  let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]

  ui.centre(
    [attribute.style(styles)],
    ui.stack([], [
      html.h1([], [element.text("Let's knit a sock!")]),
      html.p([], [
        element.text(
          "Instructions for a top-down sock with a reinforced heel flap and gusset.",
        ),
      ]),
      ui.aside(
        [aside.content_first(), aside.align_end()],
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
        html.h3([], [element.text("Cuff and Leg")]),
        cuff_instructions(model.stitch_count),
        leg_instructions(),
        html.h3([], [element.text("Heel")]),
        heel_flap_instructions(model.stitch_count),
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

  let #(row_1, row_2) = case heel_st_count % 2 {
    0 -> #("*sl1, k1*", "sl1, p to end")
    _ -> #("*sl1, k1*, k1", "sl1, p to end")
  }

  html.div([], [
    html.p([], [element.text(intro)]),
    html.ol([], [
      html.li([], [element.text(row_1)]),
      html.li([], [element.text(row_2)]),
    ]),
  ])
}
