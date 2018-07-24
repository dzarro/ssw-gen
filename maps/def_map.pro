;+
; Project     : SOHO-CDS
;
; Name        : DEF_MAP
;
; Purpose     : Define a basic 2x2 element image map 
;
; Category    : imaging
;
; Syntax      : def_map,map
;
; Outputs     : MAP = {data:data,xp:xp,yp:yp,time:time,id:id} (old format)
;                 or  {data:data,xc:xc,yc:yc,dx:dx,dy:dy,time:time,id:id}
;               where,
;               DATA  = 2x2 image array
;               XP,YP = 2x2 cartesian coordinate arrays
;               XC,YC = image center coordinates
;               DX,DY = image pixel scales
;               ID    = blank ID label
;               TIME  = blank start time of image
;
; Keywords    : OLD = use old format
;               DIM = data dimensions [nx,ny]
;
; History     : Written 22 October 1997, D. Zarro, SAC/GSFC
;               29 November 2016, Zarro (ADNET) - added extra tags
;
; Contact     : dzarro@solar.stanford.edu
;-

pro def_map,map,old_format=old_format,dim=dim

nx=2 & ny=2
ndim=n_elements(dim)
if ndim gt 0 then begin
 nx=dim[0] & ny=dim[0]
 if ndim gt 1 then ny=dim[1]
endif

base=fltarr(nx,ny)
if keyword_set(old) then begin
 map={data:base,xp:base,yp:base,time:'',id:''} 
endif else begin
 map={data:base,xc:0.d,yc:0.d,dx:1.d,dy:1.d,time:'',id:'',$
      dur:0.,xunits:'',yunits:'',roll_angle:0.d,roll_center:[0.d,0.d],$
      SOHO:0b,L0:0.d, B0:0.d,rsun:0.d}
endelse 

return
end
