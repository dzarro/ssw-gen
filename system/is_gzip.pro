;+
; Project     : HESSI
;
; Name        : IS_GZIP
;
; Purpose     : returns true if file is GZIP compressed
;
; Category    : utility I/O
;
; Syntax      : IDL> chk=is_gzipfile)
;
; Inputs      : FILE = input filename(s)
;
; Outputs     : 1/0 if compressed or not
; 
; History     : 26 August 2016, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function is_gzip,file,verbose=verbose,buffer=buffer

verbose=keyword_set(verbose)
if is_blank(file) then return,0b
if n_elements(file) ne 1 then begin
 mprint,'Input filename must be scalar string.'
 return,0b
endif

error=0
catch,error
if error ne 0 then begin
 if verbose then mprint,err_state()
 catch,/cancel
 return,0b
endif

;-- if GUNZIP fails, then file is not GZIP
 
file_gunzip,file,buffer=cbuffer,count=count,verbose=verbose
if verbose then help,cbuffer,count
if (n_elements(cbuffer) le 1) || (count eq 0) then return,0b 

;-- clean up

if arg_present(buffer) then buffer=temporary(cbuffer) else destroy,cbuffer
return,1b

end
