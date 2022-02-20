;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_GET_FITS()
;
; Purpose     :	Read in a generic FITS file for the SUNGLOBE program
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : This routine calls SUNGLOBE_READ_FITS to read in a generic FITS
;               file, and then converts it into a structure suitable for use in
;               the SUNGLOBE program.
;
; Syntax      :	Result = SUNGLOBE_GET_FITS()
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	None
;
; Opt. Inputs :	None
;
; Keywords    : OPACITY = A floating-point opacity value between 0.0
;                         (completely transparent) and 1.0 (completely
;                         opaque).  If not passed, then 1.0 is assumed.
;
;               SOAR_DATE = Date for searching Solar Orbiter archive.
;
;               GROUP_LEADER = The widget ID of the group leader.  When this
;                              keyword points to a valid widget ID, this
;                              routine is run in modal mode.
;
; Outputs     :	The result of the function is a structure containing the
;               Helioviewer image data in both direct and heliographic formats,
;               along with additional information describing the image.
;
; Calls       :	XACK, SUNGLOBE_READ_FITS, WCS_CONVERT_TO_COORD, WCS_GET_PIXEL,
;               CONGRID
;
; History     :	Version 1, William Thompson, 14-Jan-2019, GSFC
;               Version 2, WTT, 21-Jan-2021, added Solar Orbiter option,
;                       corrected subimage problem
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_get_fits, opacity=k_opacity, group_leader=group_leader, $
                            soar_date=soar_date
;
;  Determine the opacity value.
;
if n_elements(k_opacity) eq 1 then opacity = 0.0 > k_opacity < 1.0 else $
  opacity = 1.0
;
;  Define a dummy result in case of error, and set up error catching.
;
result = 0
catch, error_status
if error_status ne 0 then begin
    catch, /cancel
    xack, !error_state.msg
    goto, cleanup
endif
;
;  Use SUNGLOBE_READ_FITS to select a file and read it in.
;
sunglobe_read_fits, poutput, group_leader=group_leader, soar_date=soar_date
if (*poutput).pimage eq !NULL then begin
    catch, /cancel
    xack, 'SUNGLOBE_GET_FITS: No file selected'
    goto, cleanup
endif
;
;  Extract the image and the WCS structure.
;
image = *((*poutput).pimage)
wcs = *((*poutput).pwcs)
;
;  Form the longitude and latitude arrays for the synoptic map.
;
nx = 2880
ny = 1440
lon = (findgen(nx) + 0.5) * 360 / nx
lat = (findgen(ny) + 0.5) * 180 / ny - 90
radeg = 180.d0 / !dpi
lon = rebin(reform(lon,nx,1), nx, ny)
lat = rebin(reform(lat,1,ny), nx, ny)
;
;  Convert the image into the synoptic map.
;
wcs_convert_to_coord, wcs, coord, 'hg', lon, lat, /carrington
pixel = wcs_get_pixel(wcs, coord)
i = reform(pixel[0,*,*])
j = reform(pixel[1,*,*])
w = where(finite(i) and finite(j) and $
          (i ge 0) and (i le (wcs.naxis[0]-1)) and $
          (j ge 0) and (j le (wcs.naxis[1]-1)))
map = bytarr(3, nx, ny)
mapmask = bytarr(nx, ny)
mapmask[w] = 255b
for k=0,2L do begin
    temp0 = map[k,*,*]
    temp1 = reform(image[k,*,*])
    temp0[w] = temp1[i[w],j[w]]
    map[k,*,*] = temp0
endfor
;
;  Create an icon from the image.
;
icon = bytarr(3,64,64)
for i=0,2 do icon[i,*,*] = congrid(reform(image[i,*,*]), 64, 64)
;
;  Create a version of the map with an alpha channel, and define the alpha
;  channel based on the mask and opacity.  Form an image object.
;
sz = size(map)
map_alpha = bytarr(4,sz[2],sz[3])
map_alpha[0:2,*,*] = map
map_alpha[3,*,*] = mapmask * opacity
omap_alpha = obj_new('idlgrimage', map_alpha, location=[-1,-1], $
                     dimension=[2,2], blend_function=[3,4])
;
;  Create dummy rotated versions of MAP and MAPMASK.  These will be updated in
;  SUNGLOBE_DIFF_ROT.
;
map_rot = map
mapmask_rot = mapmask
;
;  Return the result as a structure.
;
result = {image: image, $
          wcs: wcs, $
          map: map, $
          mapmask: mapmask, $
          map_rot: map_rot, $
          mapmask_rot: mapmask_rot, $
          opacity: opacity, $
          map_alpha: map_alpha, $
          omap_alpha: omap_alpha, $
          label: (*poutput).label, $
          icon: icon}
;
;  Return the result.
;
cleanup:
return, result
end
