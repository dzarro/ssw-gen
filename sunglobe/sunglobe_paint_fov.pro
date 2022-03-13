;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_PAINT_FOV
;
; Purpose     :	Paint instrument FOV on solar surface
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine takes the information describing the instrument
;               field-of-view, and paints it on the solar surface.
;
; Syntax      :	SUNGLOBE_PAINT_FOV, SSTATE
;
; Examples    :	See 
;
; Inputs      :	SSTATE  = SunGlobe widget top-level state structure.
;
; Opt. Inputs :	None
;
; Outputs     : The program returns the structure pointer describing the
;               painted field-of-view, containing the following parameters.
;
;               DATE    = The date associated with the map.
;               OPACITY = The map opacity, initially 0.5
;               MAP     = The map read in from the file.
;               MAPMASK = An opacity map.  All points without data are
;                         transparent.
;               MAP_ROT = A placeholder for a rotated map.
;               MAPMASK_ROT = A placeholder for a rotated opacity map.
;               MAP_ALPHA = Map with alpha channel for opacity
;               OMAP_ALPHA = Map graphics object.
;
; Opt. Outputs: None
;
; Keywords    : SPICE   = If set, then paint the SPICE FOV
;               EUIEUV  = If set, then paint the EUI/HRI/EUV FOV
;               EUILYA  = If set, then paint the EUI/HRI/LYA FOV
;               PHI     = If set, then paint the PHI FOV
;
;               If no keywords are passed, then the generic FOV is painted.
;
; Calls       :	WCS_2D_SIMULATE, WCS_CONV_HG_HCC, WCS_CONV_HCC_HPC
;
; Restrictions: None
;
; History     :	Version 1, 16-Aug-2021, William Thompson, GSFC
;               Version 2, 10-Nov-2021, WTT, include nominal offsets to S/C
;               Version 3, 24-Feb-2022, WTT, split EUI into EUV and Lya channels
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_paint_fov, sstate, spice=spice, euieuv=euieuv, euilya=euilya, phi=phi
;
;  Set up error catching.
;
catch, error_status
if error_status ne 0 then begin
    catch, /cancel
    xack, !error_state.msg
    return
endif
;
;  Get the date, distance and orientation.
;
widget_control, sstate.wtargetdate, get_value=date
widget_control, sstate.wdist, get_value=dsun
widget_control, sstate.wpitch, get_value=b0
widget_control, sstate.wyaw, get_value=l0
widget_control, sstate.wroll, get_value=roll
;
;  Set up a simulated WCS structure to store the viewpoint parameters.
;
wcs = wcs_2d_simulate(512, dsun_obs=dsun*wcs_au(), hgln_obs=l0, hglt_obs=b0)
;
;  Get the pointing in spacecraft coordinates.
;
widget_control, sstate.wxsc, get_value=xsc
widget_control, sstate.wysc, get_value=ysc
;
;  Get the field-of-view parameters, depending on the instrument.
;
if keyword_set(spice) then begin
   sstate.ospice->getproperty, slitnum=slitnum
   ysize = 11
   case slitnum of
      1: slitwid = 4
      2: slitwid = 6
      3: begin
         slitwid = 30
         ysize = 14
      end
      else: slitwid = 2
   endcase
   ysize = ysize * 60           ;arcmin -> arcsec
   sstate.ospice->getproperty, nsteps=nsteps
   sstate.ospice->getproperty, stepsize=stepsize
   xsize = (nsteps-1)*stepsize + slitwid
   sstate.ospice->getproperty, midpos=midpos
   sstate.ospice->getproperty, xoffset=xoffset
   sstate.ospice->getproperty, yoffset=yoffset
   xcen = midpos + xoffset
   ycen = yoffset
   ins_roll = 0
end else if keyword_set(euieuv) then begin
   sstate.oeuieuv->getproperty, xsize=xsize
   sstate.oeuieuv->getproperty, ysize=ysize
   sstate.oeuieuv->getproperty, xcen=xcen
   sstate.oeuieuv->getproperty, ycen=ycen
   sstate.oeuieuv->getproperty, xoffset=xoffset
   sstate.oeuieuv->getproperty, yoffset=yoffset
   xcen = xcen + xoffset
   ycen = ycen + yoffset
   ins_roll = 0
end else if keyword_set(euilya) then begin
   sstate.oeuilya->getproperty, xsize=xsize
   sstate.oeuilya->getproperty, ysize=ysize
   sstate.oeuilya->getproperty, xcen=xcen
   sstate.oeuilya->getproperty, ycen=ycen
   sstate.oeuilya->getproperty, xoffset=xoffset
   sstate.oeuilya->getproperty, yoffset=yoffset
   xcen = xcen + xoffset
   ycen = ycen + yoffset
   ins_roll = 0
end else if keyword_set(phi) then begin
   sstate.ophi->getproperty, xsize=xsize
   sstate.ophi->getproperty, ysize=ysize
   sstate.ophi->getproperty, xcen=xcen
   sstate.ophi->getproperty, ycen=ycen
   sstate.ophi->getproperty, xoffset=xoffset
   sstate.ophi->getproperty, yoffset=yoffset
   xcen = xcen + xoffset
   ycen = ycen + yoffset
   ins_roll = 0
end else begin
   sstate.ogen->getproperty, xsize=xsize
   sstate.ogen->getproperty, ysize=ysize
   sstate.ogen->getproperty, xcen=xcen
   sstate.ogen->getproperty, ycen=ycen
   sstate.ogen->getproperty, ins_roll=ins_roll
endelse
;
;  Set up a map, and define the longitude and latitude values for each point in
;  the map.
;
nn = 4
scl = 1.d0 / nn
nx = 360*nn
ny = 180*nn
mapmask = bytarr(nx, ny)
lon = scl * rebin( reform( dindgen(nx) + 0.5, nx,1), nx,ny)
lat = scl * rebin( reform( dindgen(ny) + 0.5, 1,ny), nx,ny) - 90
;
;  Convert the longitude and latitude values into spacecraft coordinates
;
wcs_conv_hg_hcc, lon, lat, x_temp, y_temp, z_temp, wcs=wcs
dtor = !dpi / 180.d0
angle = roll * dtor
cs = cos(angle)
sn = sin(angle)
x = x_temp * cs - y_temp * sn
y = x_temp * sn + y_temp * cs
wcs_conv_hcc_hpc, x, y, scln, sclt, distance, solz=z_temp, wcs=wcs, /arcseconds
;
;  Apply the spacecraft pointing, and the FOV offset.
;
scln = scln - xsc - xcen
sclt = sclt - ysc - ycen
;
;  Apply the FOV rotation
;
if ins_roll ne 0 then begin
   angle = ins_roll * dtor
   cs = cos(angle)
   sn = sin(angle)
   x = scln * cs - sclt * sn
   y = scln * sn + sclt * cs
end else begin
   x = scln
   y = sclt
endelse
;
;  Determine which positions are within the field-of-view
;
w = where((abs(x) le (xsize/2)) and (abs(y) le (ysize/2)), count)
if count eq 0 then return
mapmask[w] = 255b
;
;  Create a version of the map with an alpha channel, and define the alpha
;  channel based on the mask and opacity.  Form an image object.
;
sz = size(mapmask)
map = bytarr(3,sz[1],sz[2])
map_alpha = bytarr(4,sz[1],sz[2])
opacity = 0.5
for i=0,2 do begin
    map[i,*,*] = mapmask
    map_alpha[i,*,*] = map[i,*,*]
endfor
map_alpha[3,*,*] = mapmask * opacity
omap_alpha = obj_new('idlgrimage', map_alpha, location=[-1,-1], $
                     dimension=[2,2], blend_function=[3,4], hide=0)
;
;  Create dummy rotated versions of MAP and MAPMASK.  These will be updated in
;  SUNGLOBE_DIFF_ROT.
;
map_rot = map
mapmask_rot = mapmask
;
;  Define the output structure, and add it to the state structure.
;
povpaint = {date: date, $
            opacity: opacity, $
            map: map, $
            mapmask: mapmask, $
            map_rot: map_rot, $
            mapmask_rot: mapmask_rot, $
            map_alpha: map_alpha, $
            omap_alpha: omap_alpha}
sstate.pfovpaint = ptr_new(povpaint)
sstate.hidefovpaint = 0
;
return
end
