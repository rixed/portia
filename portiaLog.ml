# 17 "misc.fw"
open Batteries

let verbose = ref false

let debug fmt =
  if !verbose then
    Printf.fprintf stderr fmt
  else
    Printf.ifprintf stderr fmt
