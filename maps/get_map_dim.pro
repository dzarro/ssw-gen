;+
; Project     : RHESSI
;
; Name        : GET_MAP_DIM
;
; Purpose     : Return the pixel dimensions for a corresponding XRANGE and YRANGE
;
; Category    : imaging, maps
;
; Syntax      : IDL> dim=get_map_dim(map,xrange=xrange,yrange=yrange)
;
; Inputs      : MAP = map structure
;
; Outputs     : DIM = [nx,ny]
;
; Keywords    : XRANGE (input) = [xmin,xmax] arcsecs for extraction 
;               YRANGE (input) = [ymin,ymax] arcsecs for extraction 
;               CENTER (output)= corresponding center for
;               XRANGE/YRANGE
;
; History     : 7 May 2016, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function get_map_dim,map,xrange=xrange,yrange=yrange,center=center,err=err

err=''
zdim=[0l,0l]
if ~valid_map(map,err=err) then begin
 mprint,err
 return,zdim
endif

dx=map.dx
dy=map.dy

if exist(xrange) then dxrange=xrange else dxrange=get_map_xrange(map)
if exist(yrange) then dyrange=yrange else dyrange=get_map_yrange(map)

if ~valid_range(dxrange) then begin
 err='Invalid XRANGE.'
 mprint,err
 return,zdim
endif

if ~valid_range(dyrange) then begin
 err='Invalid YRANGE.'
 mprint,err
 return,zdim
endif

xc=(dxrange[0]+dxrange[1])/2.d0
yc=(dyrange[0]+dyrange[1])/2.d0
nx=1.d0+2.d0*(xc-min(dxrange))/dx
ny=1.d0+2.d0*(yc-min(dyrange))/dy

dim=round([nx,ny])
center=[xc,yc]

if (dim[0] le 1) || (dim[1] le 1) then begin
 err='Invalid input ranges.'
 mprint,err
endif

return,dim

end
