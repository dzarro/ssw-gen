;+
; Project     : VSO
;
; Name        : VALID_DIRNAME
;
; Purpose     : check in input name is a valid directory name for the
;               current OS/platform, whether the directory exists or
;               not.
;
; Category    : system utility
;
; Syntax      : IDL> chk=valid_dirname(name)
;
; Inputs:     : NAME = string directory name to check
;
; Outputs     : Boolean 1 or 0 if valid or not
;
; Keywords    : ERR = error string
;
; History     : 24-May-2017, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function valid_dirname,name,err=err

err=''
if is_blank(name) then return,0b

error=0
catch, error
if (error ne 0) then begin
 err=err_state(sys_msg)
 if is_string(sys_msg) then mprint,sys_msg
 catch,/cancel
 message,/reset
 return,0b
endif

;-- do easy case if directory already exists

if file_test(name,/dir) then return,1b

;-- use temp directory as root to avoid access errors

temp_dir=get_temp_dir()
test_dir=concat_dir(temp_dir,name)

;-- try to create subdirectory name in temp directory
;-- if this fails, go to catch

file_mkdir,test_dir
exists=file_test(test_dir,/dir)
chk2=file_search(test_dir,count=count)
valid=(count ne 0) && exists

;-- clean up

file_delete,test_dir
return,valid

end
