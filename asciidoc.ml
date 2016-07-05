# 38 "misc.fw"
open Batteries
open PortiaParse

let ext_of_lang = function
    | "shell" | "bash" | "csh" -> "sh"
    | "autoconf" -> "m4"
    | "docbook" -> "xml"
    | x -> x

let find_code_definitions =
    let re = Str.regexp ("^\\.\\([^:\n]+\\)\\(:[^\n]*\\)?\n" ^
                         "\\[source,\\([^]]+\\)\\]\n" ^
                         "----\n" ^
                         "\\(\\(\\([^-\n].*\\)?\n\\)+\\)" ^
                         "----\n") in
    fold_all_groups (fun l p ->
        match l with
            | Some (id,_,_)::Some _::Some (lang,_,_)::
              Some (_def, start, stop)::_ ->
                (id ^ "." ^ ext_of_lang lang, true, start, stop)::p
            | Some (id,_,_)::None::_::Some (_def, start, stop)::_ ->
                (id, false, start, stop)::p
            | _ -> assert false) [] re

(*$= find_code_definitions & ~printer:dump
  [ "Foo.ml", true, 27, 34 ] \
  (find_code_definitions \
    ".Foo: bar\n\\
     [source,ml]\n\\
     ----\n\\
     glop.\n\\
     \n\\
     ----\n\\
     I'm out!\n\\
     ----\n")
*)

let find_file_content =
    let re = Str.regexp ("^\\.Content of \\([^\n]*\\)\n" ^
                         "\\[source,[^\n]*\\]\n" ^
                         "----\n" ^
                         "\\(\\(\\([^-].*\\)?\n\\)+\\)" ^
                         "----\n") in
    fold_all_groups (fun l p ->
        match l with
            | Some (id,_,_)::Some (_def, start, stop)::_ ->
              (id, true, start, stop)::p
            | _ -> assert false) [] re

let find_definitions str =
    find_code_definitions str @ find_file_content str

let find_references =
    let re = Str.regexp "\\((\\* \\.\\.\\.\\([^\n\\*]+\\)\\.\\.\\. \\*)\\)" in
    fold_all_groups (fun l p -> match l with
        | [ Some (_, start, stop); Some (id, _, _) ] -> (id, start, stop)::p
        | _ -> assert false) [] re

(* Note that we have to break up the comment mark in order not to
   confuse qtest. *)
(*$= find_references & ~printer:dump
  (find_references ("xx ("^"* ...Inventory.Make functor... *"^") yy")) \
    [ "Inventory.Make functor", 3, 37 ]
*)

let find_inclusions =
    let re = Str.regexp "^include::\\([^\\[\n]+\\)\\[\\([^\\[\n]*\\)\\]\n" in
    fold_all_groups (fun l p -> match l with
        | [ Some (f, _, _); _ ] -> f::p
        | _ -> p) [] re

let () =
    PortiaConfig.find_definitions := find_definitions ;
    PortiaConfig.find_references  := find_references ;
    PortiaConfig.find_inclusions  := find_inclusions ;
