;+
; Project     : HESSI
;                  
; Name        : SSW_LOAD
;               
; Purpose     : Platform/OS independent SSW startup.
;               Executes IDL startups and loads environment variables for
;               instruments and packages in $SSW_INSTR
;                             
; Category    : utility
;               
; Syntax      : IDL> ssw_load
;
; Inputs      : None
; 
; Outputs     : None
;
; Keywords    : VERBOSE - set for verbose output
;               ERR - error string
;               ENV_ONLY = load environment only
;                                   
; History     : 30-April-2017, written Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro ssw_load,_ref_extra=extra

ssw=getenv('SSW')
if ssw eq '' then begin
 message,'SSW environment variable undefined.',/info
 return
endif

;-- ensure GEN is loaded in path

if strlowcase(!version.os_family) eq 'windows' then begin
 dlim='\' & plim=';'
endif else begin
 dlim='/' & plim=':'
endelse
gen_idl='\'+dlim+'gen\'+dlim+'idl\'+dlim

chk=stregex(!path,gen_idl,/bool,/fold)
if ~chk then begin
 message,'Adding GEN to path',/info 
 SSW_SITE=getenv('SSW_SITE')
 path=''
 if SSW_SITE ne '' then path = expand_path('+'+SSW_SITE+dlim+'idl')
 gen_path=expand_path('+'+SSW+dlim+'gen'+dlim+'idl')
 if path eq '' then path = gen_path else path=path+plim+gen_path
 path = path + plim + expand_path('+'+SSW+dlim+'gen'+dlim+'idl_libs')
 !path = path + plim + !path
endif

ssw_load_instr,_extra=extra

message,/reset

return & end
