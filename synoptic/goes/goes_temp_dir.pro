;+
; Project     : HESSI
;                  
; Name        : GOES_TEMP_DIR
;               
; Purpose     : return name of temporary directory for caching of local GOES data
;                             
; Category    : synoptic utility
;               
; Syntax      : IDL> dir=goes_temp_dir()
;                                        
; Outputs     : dir= directory name
;                   
; History     : 15 Apr 2002, Zarro (L-3Com/GSFC)
;               5 Jan 2018, Zarro (ADNET) - switched to use session_dir()
;
; Contact     : dzarro@solar.stanford.edu
;-    

function goes_temp_dir,_ref_extra=extra

if test_dir('$GOES_DATA_USER',out=out,/quiet,_extra=extra) then return,out

return,session_dir('goes',_extra=extra)

end

