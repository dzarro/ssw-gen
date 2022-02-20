;+
; Name: str_named2anon
; 
; Purpose: Convert a named structure (and any named nested structures) to anonymous structure(s)
; 
; Method: Uses rep_struct_name to convert name of named structure to '' which makes it anonymous, and calls
;   itself recursively for each tag in structure.
; 
; Calling sequence:  new_struct = str_named2anon(struct)
; 
; Calling arguments: 
;   struct - structure to be converted
;   
; Written: Kim Tolbert, 23-Apr-2019
; Modifications:
;-
function str_named2anon, struct

  if (not is_struct(struct)) then begin
    pr_syntax, 'new_struct=str_named2anon(struct)'
    if exist(struct) then return,struct else return,-1
  endif
  
  new_struct = rep_struct_name(struct, '')
  tags = tag_names(new_struct)
  ntags = n_elements(tags)
  for i=0,ntags-1 do begin
    if is_struct(new_struct.(i)) then begin
      if tag_names(new_struct.(i), /struct) ne '' then begin
        new_sub = str_named2anon(new_struct.(i))
        new_struct = rep_tag_value(new_struct, new_sub, tags[i])
      endif
    endif
  endfor
  
  return, new_struct
  end
