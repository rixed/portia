
# 209 "parsing.fw"
open Batteries
open PortiaParse


# 85 "parsing.fw"
let find_inclusions =
    let re = Str.regexp 
# 77 "parsing.fw"
"^@i +\\(.+\\) *$"
# 86 "parsing.fw"
 in
    fold_all_groups (fun l p -> match l with
        | [Some (f, _, _)] -> f::p
        | _ -> assert false) [] re

# 212 "parsing.fw"


# 145 "parsing.fw"
let find_definitions =
    let re = Str.regexp 
# 129 "parsing.fw"
"^@\\(\\$\\|O\\)@<\\([^@]+\\)@>\\(==\\|\\+=\\)@{\
\\(@-\n\\)?\\(\\([^@]\\|@[^}]\\)*\\)@}"
# 146 "parsing.fw"
 in
    fold_all_groups (fun l p ->
        PortiaLog.debug "found def: %a\n"
            (List.print (Option.print
                (Tuple3.print String.print Int.print Int.print))) l ;
        match l with
        | [Some (c, _, _); Some (id, _, _); _; _; Some (_, start, stop); _] ->
            (id, c = "O", start, stop) :: p
        | _ -> assert false) [] re

# 213 "parsing.fw"


# 175 "parsing.fw"
let find_references =
    let re = Str.regexp 
# 166 "parsing.fw"
"\\(@<\\([^@]+\\)@>\\)"
# 176 "parsing.fw"
 in
    fold_all_groups (fun l p -> match l with
        | [Some (_, start, stop); Some (id, _, _)] -> (id, start, stop)::p
        | _ -> assert false) [] re

# 214 "parsing.fw"


# 195 "parsing.fw"
let postprocess str =
    String.nreplace ~str ~sub:"@@" ~by:"@"

# 215 "parsing.fw"


let () =
    PortiaConfig.find_definitions := find_definitions ;
    PortiaConfig.find_references  := find_references ;
    PortiaConfig.find_inclusions  := find_inclusions ;
    PortiaConfig.postprocess      := postprocess
