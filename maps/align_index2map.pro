;+
; Project     : RHESSI
;
; Name        : ALIGN_INDEX2MAP
;
; Purpose     : align coordinates in INDEX to that of MAP (e.g after roll)
;
; Category    : imaging
;
; Syntax      : cindex=index2map(index,map)
;
; Inputs      : INDEX = image index structure 
;               MAP = image map structure
;
; Outputs     : CINDEX = INDEX with aligned coordinates
;
; Keywords    : ERR = error string
;
; History     : 3 March 2017, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function align_index2map,index,map,err=err,_extra=extra

if ~valid_map(map) then return,null()
if ~is_struct(index) then return,null()

error=0
catch,error
if error ne 0 then begin
 err=err_state()
 mprint,err,/info
 catch,/cancel
 return,null()
endif

dims=size(map.data,/dimensions)
crval1=0.
crval2=0.
crota2=map.roll_angle
naxis1=dims[0]
naxis2=dims[1]
xcen=map.xc
ycen=map.yc
cdelt1=map.dx
cdelt2=map.dy

cindex=index
cindex.crval1=crval1
cindex.crval2=crval2
cindex.naxis1=naxis1
cindex.naxis2=naxis2
if have_tag(cindex,'crota2') then cindex.crota2=crota2
cindex.cdelt1=cdelt1
cindex.cdelt2=cdelt2
cindex.crpix1=comp_fits_crpix(xcen,cdelt1,naxis1,crval1)
cindex.crpix2=comp_fits_crpix(ycen,cdelt2,naxis2,crval2)
cindex.xcen=xcen
cindex.ycen=ycen

return,cindex
end
