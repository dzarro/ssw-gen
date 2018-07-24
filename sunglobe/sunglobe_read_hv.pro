;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_READ_HV()
;
; Purpose     :	Read in a Helioviewer image for the SUNGLOBE program
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine reads in a Helioviewer image into a structure
;               suitable for use in the SUNGLOBE program.  The input parameters
;               SOURCE_ID and LABEL are presumed to have been selected
;               beforehand via SUNGLOBE_SELECT_HV.
;
; Syntax      :	Result = SUNGLOBE_READ_HV( DATE, SOURCE_ID, LABEL )
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	DATE      = Target date.  The image closest to this date is
;                           read in.
;
;               SOURCE_ID = Helioviewer source ID number.
;
;               LABEL     = Image label to be stored within the returned
;                           structure.
;
; Opt. Inputs :	None
;
; Keywords    : OPACITY = A floating-point opacity value between 0.0
;                         (completely transparent) and 1.0 (completely
;                         opaque).  If not passed, then 1.0 is assumed.
;
; Outputs     :	The result of the function is a structure containing the
;               Helioviewer image data in both direct and heliographic formats,
;               along with additional information describing the image.
;
; Calls       :	XACK, MK_TEMP_DIR, HV_GET, ANYTIM2UTC, FITSXML2STRUCT,
;               FITSHEAD2WCS, WCS_CONVERT_TO_COORD, WCS_GET_PIXEL,
;               SUNGLOBE_AIA_COLORS, SUNGLOBE_SECCHI_COLORS
;
; History     :	Version 1, William Thompson, 4-Jan-2016, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_read_hv, date, source_id, label, opacity=k_opacity
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
;  Create a temporary directory to receive the file.
;
mk_temp_dir, get_temp_dir(), temp_dir
cd, temp_dir, current=current
;
hv_get, anytim2utc(date,/ccsds), source_id, err=err, local=filename
if err ne '' then begin
    xack, err
    goto, cleanup
endif
;
;  Read in the file, and extract the image and image header.
;
ohv = obj_new('IDLffJPEG2000', filename, persistent=0)
image = ohv->getdata(_extra=_extra)
ohv->getproperty, xml=xml
obj_destroy, ohv
;
;  Return to the current directory, and delete the temporary directory.
;
cd, current
delvarx, current
file_delete, temp_dir, /recursive
;
;  Form a WCS structure from the header.
;
header = fitsxml2struct(xml, _extra=_extra)
wcs = fitshead2wcs(header)
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
w = where(finite(i) and finite(j))
map = bytarr(nx, ny)
mapmask = bytarr(nx, ny)
map[w] = image[i[w],j[w]]
mapmask[w] = 255b
;
;  Get the colors for the image and map.
;
red   = bindgen(256)
green = red
blue  = red
if (source_id ge 8) and (source_id le 17) then begin    ;SDO/AIA
    wavelength = [94,131,171,193,211,304,335,1600,1700,4500]
    sunglobe_aia_colors, wavelength[source_id-8], red, green, blue
endif
if (source_id ge 20) and (source_id le 27) then begin   ;STEREO EUVI
    wavelength = [171,195,284,304]
    i = (source_id-20) mod 4
    sunglobe_secchi_colors, 'EUVI', wavelength[i], red, green, blue
endif
;
;  Colorize the image.
;
temp = temporary(image)
sz = size(temp)
image = bytarr(3,sz[1],sz[2])
image[0,*,*] = red[temp]
image[1,*,*] = green[temp]
image[2,*,*] = blue[temp]
;
;  Create an icon from the image.
;
icon = bytarr(3,64,64)
for i=0,2 do icon[i,*,*] = congrid(reform(image[i,*,*]), 64, 64)
;
;  Colorize the map.
;
temp = temporary(map)
sz = size(temp)
map = bytarr(3,sz[1],sz[2])
map[0,*,*] = red[temp]
map[1,*,*] = green[temp]
map[2,*,*] = blue[temp]
;
;  Create a version of the map with an alpha channel, and define the alpha
;  channel based on the mask and opacity.  Form an image object.
;
map_alpha = bytarr(4,sz[1],sz[2])
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
          label: label, $
          icon: icon}
;
;  Return to the original directory, and delete the temporary directory and its
;  contents.
;
cleanup:
if n_elements(current) eq 1 then cd, current
if file_exist(temp_dir) then file_delete, temp_dir, /recursive
;
return, result
end
