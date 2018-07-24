;+
; Project     : SOHO - CDS
;
; Name        : TEMP_DIR
;
; Purpose     : Create a temporary session directory
;
; Category    : Utility
;
; Syntax      : IDL> sub_dir=session_dir()
;
; Inputs      : NAME = name of subdirectory with session directory (optional)
;
; Outputs     : SESSION_DIR = sub directory with unique name in temp directory
;
; Keywords    : ERR = error string
;               NEW = set to create new subdir [def = return last]
;
; History     : 3-Aug-2017, Zarro (ADNET) - Written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function session_dir,name,_ref_extra=extra,new=new,err=err

common session_dir,last_sid

err=''
new=keyword_set(new)
if is_string(last_sid) && ~new then sid=last_sid else sid=session_id()

top=get_temp_dir()
if is_string(name) then top=concat_dir(top,name) 
sdir=concat_dir(top,sid)

last_sid=sid
if is_dir(sdir) then return,sdir

mk_dir,sdir,/a_write,/a_read,_extra=extra,err=err
if is_string(err) then return,top

return,sdir

end

