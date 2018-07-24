;+
; Project     : STEREO
;
; Name        : WCS_INDEX2MAP
;
; Purpose     : Make an image map from index/data pair using WCS software
;
; Category    : imaging
;
; Syntax      : wcs_index2map,index,data,map

; Inputs      : index - vector of 'index' structures (per
;                       mreadfits/fitshead2struct)

;               data  - 2D or 3D
;
; Outputs     : maparr - 2D or 3D array of corresponding 'map structures'
;
; Keywords    : 
;
; History     : Written, 5 September 2012, Zarro (ADNET)
;               Modified, 24 May 2014, Zarro (ADNET)
;                - get ID from GET_FITS_PAR
;               21 February 2017, Zarro (ADNET) - improved error checking
;-

pro wcs_index2map, index, data, map, _ref_extra=extra,err=err

err=''
error=0
catch,error
if error ne 0 then begin
 err=err_state()
 mprint,err,/info
 catch,/cancel
 return
endif

get_fits_par,index,id=id,err=err
if is_string(err) then return

wcs=fitshead2wcs(index,_extra=extra,errmsg=err) 
if is_string(err) then return

if ~valid_wcs(wcs) then begin
 err='Index is not WCS compliant.'
 mprint,err
 return
endif

wcs2map,data,wcs,map,id=id,_extra=extra

return

end


