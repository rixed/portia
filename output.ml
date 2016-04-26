# 35 "output.fw"
open Batteries

# 11 "output.fw"
open PortiaDefinition

(* output a given definition *)
let definition filename def =
    if def.output then (
        PortiaLog.debug "Generating %s...\n%!" filename ;
        let text = expanded_body "" def |>
                   !PortiaConfig.postprocess in
        output_file ~filename ~text
    ) else (
        PortiaLog.debug "No output file for %s\n%!" filename
    )

(* output all registered definitions *)
let all () =
    Hashtbl.iter definition registry
# 37 "output.fw"
