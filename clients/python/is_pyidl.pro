;+
; Project     : HESSI
;                  
; Name        : IS_PYIDL
;               
; Purpose     : return true if running in Python-IDL environment
;                             
; Category    : system utility
;               
; Syntax      : IDL> a=is_pyidl()
;    
; Keywords    : SET - set to register running in Python-IDL environment
;                              
; Outputs     : 1/0
;               
; History     : 7-Aug-2017, Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-    

function is_pyidl,set=set

if keyword_set(set) then mklog,'PYIDL_REGISTERED',local_name('$SSW/gen/python/bridge/registered')

env=chklog('PYIDL_REGISTERED')
return,is_string(env)

end

