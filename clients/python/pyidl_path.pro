;+
; Project     : HESSI
;
; Name        : PYIDL_PATH
;
; Purpose     : return path of program registered to run in Python-IDL environment
;
; Category    : system utility
;
; Syntax      : IDL> a=pyidl_registered(file)
;
; Inputs      : FILE = program file name
;
; Keywords    : None
;
; Outputs     : PATH = full path to location of registered program
;
; History     : 7-Aug-2017, Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-

function pyidl_path,file,err=err,_extra=extra

err=''
if is_blank(file) then return,''
rdir=local_name('PYIDL_REGISTERED')

if is_blank(rdir) then begin
 err='PYIDL_REGISTERED environment variable undefined.' 
 return,''
endif

dfile=strtrim(file,2)
if ~stregex(dfile,'\.pro$',/bool) then dfile=dfile+'.pro'
if file_test(concat_dir(rdir,dfile),/regular) then return,rdir else return,''
end
