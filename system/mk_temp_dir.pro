;+
; Project     : SOHO - CDS
;
; Name        : MK_TEMP_DIR
;
; Purpose     : Create a temporary directory 
;
; Category    : Utility
;
; Syntax      : IDL>mk_temp_dir,dir,temp_dir
;
; Inputs      : DIR = directory in which to create temporary sub-directory
;
; Outputs     : TEMP_DIR = name of created sub-directory
;
; Keywords    : ERR = error string
;
; Side effects: Subdirectory named temp$$$$ is created
;
; History     : 9-June-1999,  D.M. Zarro.  Written
;               1-Oct-2011, Zarro (ADNET) - improved error messaging
;               3-Aug-2017, Zarro (ADNET) - replaced PID with SESSION_ID
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro mk_temp_dir,dir,temp_dir,err=err,verbose=verbose,_extra=extra

err=''
temp_dir=''
verbose=keyword_set(verbose)

if ~is_dir(dir) then begin
 err='Top directory undefined.'
 mprint,err,/cont
 return
endif

;-- test for write access

if ~write_dir(dir) then begin
 err='No write access to "'+dir+'"'
 mprint,err,/cont
 return
endif

;-- create a unique extension for temp

session=session_id()
sub_dir=concat_dir(dir,session)
mk_dir,sub_dir,err=err,_extra=extra,/a_write,/a_read
if is_string(err) then return

;-- test for success

verbose=keyword_set(verbose)
if is_dir(sub_dir) then begin
 temp_dir=sub_dir
 if verbose then mprint,'Created "'+sub_dir+'"',/cont
endif else begin
 err='Failed to create "'+sub_dir+'"'
 mprint,err,/cont
endelse
           
return & end       

