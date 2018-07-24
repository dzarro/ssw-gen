;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_DIFF_ROT
;
; Purpose     :	Apply differential rotation to sunglobe images
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine applies differential rotation to the heliographic
;               maps in the SUNGLOBE program.  The rotation in Carrington
;               coordinates between the image date and the target date is
;               applied to the heliographic maps via diff_rot.pro.
;
; Syntax      :	SUNGLOBE_DIFF_ROT, SSTATE, INDEX
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
;               INDEX   = Index of image to process.
;
; Opt. Inputs :	None
;
; Outputs     :	The heliographic map with alpha channel for the selected image
;               is updated in the SSTATE structure.
;
; Calls       :	ANYTIM2TAI, UTC2TAI, DIFF_ROT
;
; History     :	Version 1, 7-Jan-2016, William Thompson, GSFC
;               Version 2, 20-Mar-2018, WTT, correct bug where derotation was
;                       not being applied.
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_diff_rot, sstate, index
;
;  From the map size, determine the spacing in longitude and latitude.
;
sz = size((*sstate.pimagestates[index]).map)
nx = sz[2]
ny = sz[3]
dlon = (360.0 / nx)
dlat = (180.0 / ny)
;
;  Form the latitude indices and vector.
;
jj = indgen(ny)
lat = (jj + 0.5) * dlat - 90
;
;  Determine the number of days between the observation and the target date.
;
target_date = sstate.target_date
image_date = (*sstate.pimagestates[index]).wcs.time.observ_date
ndays = (anytim2tai(target_date) - utc2tai(image_date)) / 86400
;
;  Determine the amount of rotation in pixels as a function of latitude.
;
dx = round(diff_rot(ndays, lat, /carrington) / dlon)
;
;  Reformat the indices into 2-dimensional arrays.
;
dx = rebin( reform(dx,1,ny), nx, ny)
ii = (rebin( reform(indgen(nx),nx,1), nx, ny) - dx) mod nx
w = where(ii lt 0, count)
if count gt 0 then ii[w] = ii[w] + nx
jj = rebin( reform(jj,1,ny), nx, ny)
;
;  Apply the differential rotation to the map, and store it in the plot object.
;
(*sstate.pimagestates[index]).omap_alpha->getproperty, data=map_out
for k=0,2 do begin
    temp = (reform(((*sstate.pimagestates[index]).map)[k,*,*]))[ii,jj]
    temp = reform(temp, 1, nx, ny, /overwrite)
    (*sstate.pimagestates[index]).map_rot[k,*,*] = temp
    (*sstate.pimagestates[index]).map_alpha[k,*,*] = temp
endfor
temp = ((*sstate.pimagestates[index]).mapmask)[ii,jj]
temp = reform(temp, 1, nx, ny, /overwrite)
(*sstate.pimagestates[index]).mapmask_rot = temp
(*sstate.pimagestates[index]).map_alpha[3,*,*] = temp * $
  (*sstate.pimagestates[index]).opacity
(*sstate.pimagestates[index]).omap_alpha->setproperty, $
  data=(*sstate.pimagestates[index]).map_alpha
;
end
