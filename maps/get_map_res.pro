;+
; Project     : RHESSI
;
; Name        : GET_MAP_RES
;
; Purpose     : Return the pixel resolutions
;               for a corresponding XRANGE and YRANGE and DIMENSIONS
;
; Category    : imaging, maps
;
; Syntax      : IDL> res=get_map_res(map,dimension=dimensions,xrange=xrange,yrange=yrange)
;
; Inputs      : MAP = map structure
;
; Outputs     : RES = [dx,dy]
;
; Keywords    : DIMENSION (input) = [nx,ny] pixel dimensions
;               XRANGE (input) = [xmin,xmax] arcsecs  
;               YRANGE (input) = [ymin,ymax] arcsecs
;               RES (output) = corresponding pixel resolution to
;               match XRANGE/YRANGE
;
; History     : 7 May 2016, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function get_map_res,map,dimensions=dimensions,xrange=xrange,yrange=yrange,err=err

err=''
zres=[0.,0.]
if ~valid_map(map,err=err) then begin
 mprint,err
 return,zres
endif

if n_elements(dimensions) eq 2 then begin
 if is_number(dimensions[0]) then dim1=dimensions[0]
 if is_number(dimensions[1]) then dim2=dimensions[1]
 if (dim1 le 1) || (dim2 le 1) then begin
  err='Invalid input dimensions.'
  mprint,err
  return,zres
 endif
 dim=[dim1,dim2]
endif else dim=size(map.data,/dimensions)
dim=double(dim)

if exist(xrange) then dxrange=xrange else dxrange=get_map_xrange(map)
if exist(yrange) then dyrange=yrange else dyrange=get_map_yrange(map)

if ~valid_range(dxrange) then begin
 err='Invalid XRANGE.'
 mprint,err
 return,zres
endif

if ~valid_range(dyrange) then begin
 err='Invalid YRANGE.'
 mprint,err
 return,zres
endif

;-- compute pixel resolutions so that map ranges exactly match
;   XRANGE/YRANGE

xc=(min(dxrange)+max(dxrange))/2.d0
yc=(min(dyrange)+max(dyrange))/2.d0

dx=2.d0*(xc-min(dxrange))/(dim[0]-1.d0)
dy=2.d0*(yc-min(dyrange))/(dim[1]-1.d0)
resolution=[dx,dy]

return,resolution

end
