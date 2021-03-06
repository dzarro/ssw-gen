;---------------------------------------------------------------------------
; Document name: tag_dereference.pro
; Created by:    Andre Csillaghy, December 16, 1999
; Time-stamp: <Wed Aug 03 2005 14:59:10 csillag tournesol.local>
;---------------------------------------------------------------------------
;
;+
; PROJECT:
;       HESSI
;
; NAME:
;       TAG_DEREFERENCE( struct )
;
; PURPOSE:
;       Checks structure tags for pointers, dereferences them and
;       returns a structure without pointers
;
; CATEGORY:
;       gen/struct
;
; CALLING SEQUENCE:
;       new_struct = tag_dereference( struct )
;
; INPUTS:
;       struct: any structure
;
; OUTPUTS:
;       new_struct: an anonymous structure containing the pointerless
;                   copy of the structure passed in.
;
; EXAMPLE:
;       IDL> struct = {a: 0, b: ptr_new( indgen(10) ), c: 'test' }
;       IDL> help, struct, /str
;       ** Structure <824884c>, 3 tags, length=20, data length=18, refs=1:
;          A               INT              0
;          B               POINTER   <PtrHeapVar1>
;          C               STRING    'test'
;       IDL> help, tag_dereference( struct ), /str
;       ** Structure <8257614>, 3 tags, length=36, data length=34, refs=1:
;          A               INT              0
;          B               INT       Array[10]
;          C               STRING    'test'
;
; SEE ALSO:
;       Rep_Tag_Value
;
; HISTORY:
;       Version 1, December 16, 1999,
;           A Csillaghy, csillag@ssl.berkeley.edu
;       2-May-2005, Kim Tolbert -speed up by using create_struct instead of rep_tag_value
;       3-aug-2005, acs, checks whether there is something to dereference otherwise
;                   just return the same structure. This allows not loosing named structures
;                   when no dereference is needed (needed by jimm in obssumm)
;-
;

FUNCTION Tag_Dereference, struct_in

;struct = struct_in
n_tag = N_Tags( struct_in )
tag_name =  Tag_names( struct_in )

; acs 2005-08-03
struct_types = str_taginfo( struct_in, /type )
w = where( struct_types eq 10 or struct_types eq 8, count )
if count eq 0 then return, struct_in
; here we could check for structures and see if we need to go down the structures
; but we let it go through for now.

;FOR i=0, n_tag-1 DO BEGIN
;    CASE Size( struct.(i), /TYPE ) OF
;        8: begin
;        print,'struct ', tag_name[i]
;        struct = Rep_Tag_Value( struct, Tag_Dereference( struct.(i) ), tag_name[i] )
;        end
;        10: IF Ptr_Valid( struct.(i) ) THEN BEGIN
;            print,'pointer ' , tag_name[i]
;            struct = Rep_Tag_Value( struct, *struct.(i), tag_name[i] )
;        ENDIF
;        ELSE:
;    ENDCASE
;ENDFOR

;struct = {temp_dummy:0} ; need to start with something
; actually it's faster if we don't have to remove this tag at the end, so instead
; each time we call create_struct check if we're on first one.

FOR i=0, n_tag-1 DO BEGIN

    CASE Size( struct_in.(i), /TYPE ) OF
        8: struct = i eq 0 ? $
           create_struct( tag_name[i], Tag_Dereference( struct_in.(i) ) ) : $
           create_struct( struct, tag_name[i], Tag_Dereference( struct_in.(i) ) )

        10: IF Ptr_Valid( struct_in.(i) ) THEN BEGIN
            struct = i eq 0 ? $
               create_struct( tag_name[i], *struct_in.(i) ) : $
               create_struct( struct, tag_name[i], *struct_in.(i) )
            ENDIF else begin
               struct = i eq 0 ? $
               create_struct( tag_name[i], ptr_new() ) : $
               create_struct( struct, tag_name[i], ptr_new() )
            ENDELSE
        ELSE: struct = i eq 0 ? $
           create_struct( tag_name[i], struct_in.(i) ) : $
           create_struct( struct, tag_name[i], struct_in.(i) )
    ENDCASE
ENDFOR

;struct = rem_tag (struct, 'temp_dummy')
RETURN, struct

END

;---------------------------------------------------------------------------
; End of 'tag_dereference.pro'.
;---------------------------------------------------------------------------
 
