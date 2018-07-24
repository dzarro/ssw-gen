;+
; Project     : RHESSI
;
; Name        : extract_map
;
; Purpose     : Extract a FOV region from a map based on XRANGE and YRANGE
;
; Category    : imaging, maps
;
; Syntax      : IDL> emap=extract_map(map,xrange=xrange,yrange=yrange,dimensions=dimensions)
;
; Inputs      : MAP = map structure
;
; Outputs     : EMAP = new map structure with extracted FOV region.
;
; Keywords    : XRANGE (input) = [xmin,xmax] arcsecs for extraction
;               YRANGE (input) = [ymin,ymax] arcsecs for extraction
;               DIMENSIONS (input) = [nx,ny] user-specified dimensions
;               for extracted map
;               SAME_DIMENSIONS = keep same dimensions as input map 
;               EXACT = rebin resolution of extracted map so that map ranges exactly match XRANGE/YRANGE
; 
; History     : 7 May 2016, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function extract_map,map,xrange=xrange,yrange=yrange,err=err,_extra=extra,dimensions=dimensions,$
                     exact=exact,same_dimensions=same_dimensions

err=''
dims=get_map_dim(map,_extra=extra,center=center,xrange=xrange,yrange=yrange,err=err)
if is_string(err) then return,null()

;-- override with keyword dimensions

if exist(dimensions) || keyword_set(exact) || keyword_set(same_dimensions) then begin
 if exist(dimensions) then dims=dimensions
 if keyword_set(same_dimensions) then dims=size(map.data,/dim)
 res=get_map_res(map,dimensions=dims,xrange=xrange,yrange=yrange,err=err)
 if is_string(err) then return,null()
endif else res=[map.dx,map.dy]

rmap=drot_map(map,outsize=dims,center=center,_extra=extra,$
              err=err,/nearest,resolution=res,/no_rtime)

return,rmap
end
