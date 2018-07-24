;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_HPC2CARR
;
; Purpose     :	Convert HPC coordinates to Carrington longitude, latitude
;
; Category    :	Object graphics, 3D, Planning, generic
;
; Explanation : Calculates the Carrington longitude and latitude in degrees
;               from the HPC coordinates in arcseconds, so long as the
;               coordinates are within the limb.  If off the limb, and the LIMB
;               keyword is set, then the coordinates are adjusted to place the
;               pointing at the limb.
;
; Syntax      :	SUNGLOBE_HPC2CARR, DSUN, L0, B0, XHPC, YHPC, CRLN, CRLT [,/LIMB]
;
; Examples    :	See sunglobe_convert.pro
;
; Inputs      :	DSUN    = Solar distance in AU
;               L0      = Base Carrington longitude in degrees
;               B0      = Solar B0 angle in degrees
;               XHPC    = HPC longitude in arcseconds
;               YHPC    = HPC latitude in arcseconds
;
; Outputs     : CRLN    = Carrington longitude in degrees
;               CRLT    = Carrington latitude in degrees
;
;               If off-limb then returned as NaN.
;
; Keywords    :	LIMB    = If set, and off-limb, then adjust to stay within the
;                         limb.
;
; History     :	Version 1, 01-Aug-2017, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_hpc2carr, dsun_0, l0, b0_0, xhpc, yhpc, crln, crlt, limb=limb
;
;  Convert the HPC coordinates from arcseconds to radians.
;
dtor = !dpi / 180.d0
conv = dtor / 3600.d0
lon = conv * xhpc
lat = conv * yhpc
;
;  Convert the solar distance from AU to solar radii, and convert the B0 angle
;  from degrees to radians.
;
dsun = dsun_0 * wcs_au() / wcs_rsun()
b0 = dtor * b0_0
;
cosx = cos(lon)
sinx = sin(lon)
cosy = cos(lat)
siny = sin(lat)
;
;  Calculate the distance parameter, 0 at limb, 1 at disk center.
;
q = dsun * cosy * cosx
distance = q^2 - dsun^2 + 1
;
;  If the distance is valid, calculate the Carrington coordinates from the HPC
;  coordinates.
;
if distance ge 0 then begin
calculate:
    distance = q - sqrt(distance)
    x = distance * cosy * sinx
    y = distance * siny
    z = dsun - distance * cosy * cosx
;
    cosb = cos(b0)
    sinb = sin(b0)
    crlt = asin(y*cosb + z*sinb) / dtor
    crln = atan(x, z*cosb - y*sinb) / dtor + l0
    if crln lt 0 then crln = crln + 360
    if crln gt 360 then crln = crln - 360
;
;  If the LIMB keyword is set, and the point is outside the limb, then
;  calculate the position angle, and define the radial distance to be the solar
;  limb.
;
end else if keyword_set(limb) then begin
    hrln = atan(-cosy*sinx, siny)
    hrlt = atan(1/dsun)
;
;  Convert back to HPC coordinates, and proceed to the Carrington calculaton.
;
    cosxr = cos(hrln)
    sinxr = sin(hrln)
    cosyr = cos(hrlt)
    sinyr = sin(hrlt)
;
    lon = atan(-sinxr*sinyr, cosyr)
    lat = asin(sinyr*cosxr)
    cosx = cos(lon)
    sinx = sin(lon)
    cosy = cos(lat)
    siny = sin(lat)
;
    xhpc = lon / conv
    yhpc = lat / conv
    distance = 0
    goto, calculate
;
;  Otherwise, signal that the Carrington coordinates cannot be calculated.
;
end else begin
    crln = !values.f_nan
    crlt = !values.f_nan
endelse
;
return
end
