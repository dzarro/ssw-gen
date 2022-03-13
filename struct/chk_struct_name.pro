;+
; Project     :	SDAC
;
; Name        :	CHK_STRUCT_NAME
;
; Purpose     :	check if a structure name is unique
;
; Use         : STATUS=CHK_STRUCT_NAME(SNAME)
;
; Inputs      :	SNAME = structure name to check
;

; Outputs     :	STATUS =0/1 if SNAME already exists/doesn't exist
;
; Opt. Outputs:	None.
;
; Keywords    :	TEMPLATE = extant structure with name SNAME
;             : VERBOSE = for messages
;
; Category    :	Structure handling
;
; Written     :	Dominic Zarro (ARC)
;
; Version     :	Version 1.0, 7 July 1995
;               9-Mar-2022, Zarro (ADNET) - replaced EXECUTE by CREATE_STRUCT
;-

function chk_struct_name,sname,template=template,verbose=verbose,err=err

err=''
verbose=keyword_set(verbose)
if ~is_string(sname,/blank) then begin
 err='Input name must string.'
 mprint,err  
 return,0b
endif

;-- anonymous names are always unique

if strtrim(sname,2) eq '' then return,1b

template=0
error=0
catch,error
if error ne 0 then begin
 err=err_state() 
 catch,/cancel
 message,/reset
 return,1b
endif

template=create_struct(name=sname)

return,0b & end
