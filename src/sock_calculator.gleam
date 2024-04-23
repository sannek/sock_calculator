import gleam/int
import gleam/result
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
  GotSubmittedStitchCount(value: Result(String, Nil))
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
      heel_instructions(model.stitch_count),
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

fn heel_instructions(stitch_count: Int) -> Element(Msg) {
  let str_count = int.to_string(stitch_count)
  ui.prose([], [
    html.p([], [element.text("Hello " <> str_count <> " stitch sock.")]),
  ])
}
