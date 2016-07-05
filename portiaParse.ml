# 46 "parsing.fw"
open Batteries

# 25 "parsing.fw"
let read_whole_file file =
    let ic = Unix.(openfile file [O_RDONLY] 0 |> input_of_descr) in
    IO.read_all ic (* autoclosed *)

let rec parse file =
    PortiaLog.debug "Parsing file %s\n" file ;
    let txt = read_whole_file file in
    !PortiaConfig.find_definitions txt |>
    List.iter (fun (id, output, start, stop) ->
        PortiaDefinition.add id output file start (stop-start)) ;
    !PortiaConfig.find_inclusions txt |>
    List.iter parse
# 48 "parsing.fw"

# 99 "parsing.fw"
let fold_all_groups f p re str =
    let open Str in
    let rec aux p o =
        try search_forward re str o |> ignore ;
            let rec fetch_grps n groups =
                try let g = try Some (matched_group n str,
                                      group_beginning n,
                                      group_end n)
                            with Not_found -> None in
                    fetch_grps (n+1) (g::groups)
                with Invalid_argument _ -> List.rev groups in
            let groups = fetch_grps 1 [] in
            aux (f groups p) (Str.match_end ())
        with Not_found ->
            p in
    aux p 0 |> List.rev
# 49 "parsing.fw"

