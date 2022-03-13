;+
; Project     :	SDAC
;
; Name        :	REP_STRUCT_NAME
;
; Purpose     :	Replace structure name 
;
; Use         : NEW_STRUCT=REP_STRUCT_NAME(STRUCT,NEW_NAME)
;
; Inputs      :	STRUCT = input structure
;             : NEW_NAME= new structure name
;
; Outputs     :	NEW_STRUCT = new structure
;
; Category    :	Structure handling
;
; Written     : 7 July 1995, Zarro (ARC/GSFC)
;
; Modified    : 4 Jan 2005, Zarro (L-3Com/GSFC) - vectorized
;                9-Mar-2022, Zarro (ADNET) - cleaned-up
;-

function rep_struct_name,struct,new_name,err=err

err=''
if ~is_struct(struct) then begin
 pr_syntax,'NEW_STRUCT=REP_STRUCT_NAME(STRUCT,NEW_NAME)'
 if exist(struct) then return,struct else return,-1
endif

;-- check if same name

cur_name=strupcase(trim(tag_names(struct,/struct)))
if is_string(new_name) then sname=new_name else sname=''
sname=strup(sname)
if cur_name eq sname then return,struct

;-- check if new name is unique

chk=chk_struct_name(new_name)
if ~chk then begin
 err='Structure name '+new_name+' already taken.
 mprint,err
 return,struct
endif
 
new_struct=create_struct(struct[0],name=sname)
nstruct=n_elements(struct)
if nstruct gt 1 then begin
 new_struct=replicate(new_struct,nstruct)
 struct_assign,struct,new_struct,/nozero
endif

return,new_struct

end
