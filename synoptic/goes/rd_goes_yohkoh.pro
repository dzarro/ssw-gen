;+
; Project     : HESSI
;
; Name        : RD_GOES_YOHKOH
;
; Purpose     : read GOES data (wrapper around RD_GOES)
;
; Category    : synoptic gbo
;
; Syntax      : IDL> rd_goes_yohkoh,times,data
;
; Inputs      : None
;
; Outputs     : TIMES = time array (SECS79)
;               DATA  = data array (# TIMES x 2)
;
; Keywords    : See RD_GOES 
;
; History     : 3-January-2018, Zarro (ADNET)
;                
; Contact     : dzarro@solar.stanford.edu
;-

pro rd_goes_yohkoh,times,data,_ref_extra=extra,remote=remote,verbose=verbose,widget=widget

remote=keyword_set(remote)
verbose=keyword_set(verbose)
widget=keyword_set(widget)
output='Local GOES/Yohkoh archive not found. Trying remote archive...'

if ~remote then begin
 have_dir=is_dir('$DIR_GEN_G81')
 if ~have_dir then begin
  if verbose then mprint,output
  if widget then xbanner,output,/append
 endif
endif

do_remote=remote || ~have_dir
rd_goes,times,data,err=err,verbose=verbose,widget=widget,$
 remote=do_remote,_extra=extra

if (is_string(err) || n_elements(times) le 2) && ~do_remote then begin
 if verbose then mprint,output
 if widget then xbanner,output,/append
 rd_goes,times,data,err=err,/remote,verbose=verbose,widget=widget,_extra=extra
endif

return
end
