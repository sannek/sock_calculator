import gleam/int
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/event
import lustre/ui
import lustre/ui/layout/aside

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(value: String, length: Int, max: Int, stitch_count: Int)
}

fn init(_flags) -> Model {
  Model(value: "", length: 0, max: 10, stitch_count: 60)
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  UserUpdatedStitchCount(value: String)
  UserResetStitchCount
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserUpdatedStitchCount(value) -> {
      let stitch_count =
        int.parse(value)
        |> result.unwrap(0)
      Model(..model, stitch_count: stitch_count)
    }
    UserResetStitchCount -> Model(..model, stitch_count: 60)
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]

  let stitch_count = int.to_string(model.stitch_count)

  ui.centre(
    [attribute.style(styles)],
    ui.aside(
      [aside.content_first(), aside.align_centre()],
      ui.field(
        [],
        [element.text("How many stitches is your sock?")],
        ui.input([
          attribute.type_("number"),
          attribute.value(stitch_count),
          event.on_input(UserUpdatedStitchCount),
        ]),
        [],
      ),
      ui.button([event.on_click(UserResetStitchCount)], [element.text("Reset")]),
    ),
  )
}
