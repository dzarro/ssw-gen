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
; Keywords    : CONNFILE = If set, then apply rotation to Magnetic Connectivity
;                          Tool image.
;
;               FOVPAINT = If set, then apply rotation to painted FOV
;
; Calls       :	ANYTIM2TAI, UTC2TAI, DIFF_ROT
;
; History     :	Version 1, 7-Jan-2016, William Thompson, GSFC
;               Version 2, 20-Mar-2018, WTT, correct bug where derotation was
;                       not being applied.
;               Version 3, 10-Apr-2019, WTT, add /CONNFILE keyword
;               Version 4, 17-Aug-2021, WTT, add /FOVPAINT keyword
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_diff_rot, sstate, index, connfile=connfile, fovpaint=fovpaint
;
;  Select the image to be processed.
;
if keyword_set(connfile) then begin
   ptr = sstate.pconnfile
end else if keyword_set(fovpaint) then begin
   ptr = sstate.pfovpaint
end else ptr = sstate.pimagestates[index]
;
;  From the map size, determine the spacing in longitude and latitude.
;
sz = size((*ptr).map)
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
if keyword_set(connfile) then begin
   image_date = (*sstate.pconnfile).date
end else if keyword_set(fovpaint) then begin
   image_date = (*sstate.pfovpaint).date
end else image_date = (*ptr).wcs.time.observ_date
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
(*ptr).omap_alpha->getproperty, data=map_out
for k=0,2 do begin
    temp = (reform(((*ptr).map)[k,*,*]))[ii,jj]
    temp = reform(temp, 1, nx, ny, /overwrite)
    (*ptr).map_rot[k,*,*] = temp
    (*ptr).map_alpha[k,*,*] = temp
endfor
temp = ((*ptr).mapmask)[ii,jj]
temp = reform(temp, 1, nx, ny, /overwrite)
(*ptr).mapmask_rot = temp
(*ptr).map_alpha[3,*,*] = temp * (*ptr).opacity
(*ptr).omap_alpha->setproperty, data=(*ptr).map_alpha
;
end
