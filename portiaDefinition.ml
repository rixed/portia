# 341 "definitions.fw"
open Batteries

# 84 "definitions.fw"

# 48 "definitions.fw"
type location = { file : string ;
                 mtime : float ;
                lineno : int ;
                 colno : int ;
                offset : int ;
                  size : int }
# 84 "definitions.fw"

# 69 "definitions.fw"
type id = string
# 85 "definitions.fw"

type t = { locs : location list ; (* reverse order *)
             id : id ;
         output : bool }
# 343 "definitions.fw"

# 256 "definitions.fw"
let spaces tab = String.make (String.length tab) ' '

let indent =
    let open Str in
    let re = regexp "\n\\([^\n]\\)" in
    fun tab str ->
        let tab' = spaces tab in
        tab ^ global_replace re ("\n"^ tab' ^"\\1") str

(* first char is at column 0 *)
let colno_at txt =
    let rec aux colno p =
        if p = 0 || txt.[p-1] = '\n' then colno else
        aux (colno+1) (p-1) in
    aux 0 (String.length txt)

(* first line is 0 *)
let lineno_at pos txt =
    let rec aux p n =
        if p >= pos then n else
        aux (p+1) (if txt.[p] = '\n' then n+1 else n) in
    aux 0 0

let read_file fname offset size =
    let open Unix in
    let fd = openfile fname [O_RDONLY] 0 in
    lseek fd offset SEEK_SET |> ignore ;
    let str = String.create size in
    let rec read_chunk prev =
        if prev < size then
            let act_sz = read fd str prev (size-prev) in
            read_chunk (prev + act_sz) in
    read_chunk 0 ;
    close fd ;
    str
# 344 "definitions.fw"

# 182 "definitions.fw"
let location_in_file file offset size =
    let mtime = Unix.((stat file).st_mtime) in
    let txt = read_file file 0 offset in
    let colno = colno_at txt
    and lineno = lineno_at offset txt in
    { file ; offset ; size ; mtime ; lineno ; colno }
# 345 "definitions.fw"

# 108 "definitions.fw"
let location_print fmt loc =
    Printf.fprintf fmt "%s:%d.%d-%d"
        loc.file loc.lineno loc.colno (loc.colno+loc.size)

let mtime_print = Float.print (* TODO: user friendly date&time? *)

let rec locations_print fmt = function
    | [] -> Printf.fprintf fmt "undefined"
    | [loc] -> location_print fmt loc
    | _loc::locs' ->
        locations_print fmt locs' (* print only the first location *)

let print fmt t =
    Printf.fprintf fmt "%s@%a" t.id locations_print t.locs
# 131 "definitions.fw"
exception FileChanged of string
let fetch_loc loc =
    let open Unix in
    let fname = loc.file in
    if (stat fname).st_mtime > loc.mtime then
        raise (FileChanged fname) ;
    read_file fname loc.offset loc.size
# 150 "definitions.fw"

let ignore_missing = ref false

let registry = Hashtbl.create 31

let add id output fname off sz =
    let loc = location_in_file fname off sz in
    PortiaLog.debug "Add definition for %s at position %a\n"
        id location_print loc ;
    Hashtbl.modify_opt id (function
        | None   -> Some { id ; output ; locs = [loc] }
        | Some t -> Some { t with locs = loc :: t.locs })
        registry

let lookup id =
    try Hashtbl.find registry id
    with Not_found ->
        if !ignore_missing then { id ; output = false ; locs = [] }
        else (
            Printf.fprintf stderr "Cannot find definition for '%s'\n" id ;
            exit 1
        )
# 199 "definitions.fw"
let rec expanded_loc tab loc =
    let unexpanded = fetch_loc loc in
    PortiaLog.debug "expand '%s'\n" unexpanded ;
    (* find_references returns a list of (id, start_offset, stop_offset) *)
    let refs = !PortiaConfig.find_references unexpanded in
    (* TODO: sort this list according to start_offset *)
    PortiaLog.debug "found references: %a\n"
        (List.print (Tuple3.print String.print Int.print Int.print)) refs ;
    let txt, last_stop, tab =
        List.fold_left (fun (txt,last_stop,tab) (id,start,stop) ->
            assert (start >= last_stop) ;
            let t' = lookup id in
            (* Warning: this will indent string literals! *)
            let txt = txt ^
                indent tab
                       (String.sub unexpanded last_stop (start - last_stop)) in
            (* Look for last \n in txt to know how to indent sub-definitions: *)
            let txt_pre_nl, tab' =
                try String.rsplit txt ~by:"\n"
                with Not_found -> txt, "" in
            let txt = txt_pre_nl ^ "\n" ^ (expanded_body tab' t') in
            (* add a linenum indication that we are back in this block *)
            let ln = !PortiaConfig.linenum
                         (loc.lineno + (lineno_at stop unexpanded))
                         loc.file in
            txt ^
            (if String.length ln > 0 &&
                String.length txt > 0 &&
                txt.[String.length txt - 1] != '\n' then
                "\n" else "") ^
            ln, stop, spaces tab')
            ("", 0, tab) refs in
    (* Complete with what's left *)
    let rest = String.length unexpanded - last_stop in
    let txt = txt ^
        indent tab (String.sub unexpanded last_stop rest) in
    (* Add line number information. *)
    !PortiaConfig.linenum loc.lineno loc.file ^ txt

and expanded_body tab t =
    (* If there is no definitions return the tabulation. Not doing so would
       make beginning of line (maybe not bank) disappear. *)
    if t.locs = [] then tab else
    List.rev t.locs |>
    List.mapi (fun i loc ->
        expanded_loc (if i=0 then tab else spaces tab) loc) |>
    String.concat ""
# 346 "definitions.fw"

