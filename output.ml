# 50 "output.fw"
open Batteries

# 15 "output.fw"
open PortiaDefinition

let read_file filename =
  (BatFile.lines_of filename |>
   List.of_enum |>
   String.concat "\n") ^ "\n"

(* output a given definition *)
let definition filename def =
    if def.output then (
        PortiaLog.debug "Generating %s...\n%!" filename ;
        let text = expanded_body 0 def |>
                   !PortiaConfig.postprocess in
        let content_is_new = match read_file filename with
        | exception _ -> true
        | old_text -> old_text <> text in
        if content_is_new then (
          PortiaLog.debug "Writing output file %s\n" filename ;
          output_file ~filename ~text
        ) else PortiaLog.debug "Skipping same file %s\n" filename
    ) else (
        PortiaLog.debug "No output file for %s\n%!" filename
    )

(* output all registered definitions *)
let all () =
    Hashtbl.iter definition registry
# 52 "output.fw"

