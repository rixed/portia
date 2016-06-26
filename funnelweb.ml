open Batteries
open PortiaParse

let find_inclusions =
    let re = Str.regexp "^@i +\\(.+\\) *$" in
    fold_all_groups (fun l p -> match l with
        | [Some (f, _, _)] -> f::p
        | _ -> assert false) [] re

let find_definitions =
    let re = Str.regexp "^@\\(\\$\\|O\\)@<\\([^@]+\\)@>\\(==\\|\\+=\\)@{\
                        \\(@-\n\\)?\\(\\([^@]\\|@[^}]\\)*\\)@}" in
    fold_all_groups (fun l p ->
        PortiaLog.debug "found def: %a\n"
            (List.print (Option.print
                (Tuple3.print String.print Int.print Int.print))) l ;
        match l with
        | [Some (c, _, _); Some (id, _, _); _; _; Some (_, start, stop); _] ->
            (id, c = "O", start, stop) :: p
        | _ -> assert false) [] re

let find_references =
    let re = Str.regexp "\\(@<\\([^@]+\\)@>\\)" in
    fold_all_groups (fun l p -> match l with
        | [Some (_, start, stop); Some (id, _, _)] -> (id, start, stop)::p
        | _ -> assert false) [] re

let postprocess str =
    String.nreplace ~str ~sub:"@@" ~by:"@"


let () =
    PortiaConfig.find_definitions := find_definitions ;
    PortiaConfig.find_references  := find_references ;
    PortiaConfig.find_inclusions  := find_inclusions ;
    PortiaConfig.postprocess      := postprocess
