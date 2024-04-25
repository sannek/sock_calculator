import { Ok, Error } from "./gleam.mjs";

export function get_stitch_count() {
  const stitch_count_input = document.getElementById("stitch-count");

  const stitch_count = stitch_count_input?.value;

  return stitch_count ? new Ok(stitch_count) : new Error(undefined);
}
