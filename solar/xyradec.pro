;+
; PROJECT:
;	SDAC
; NAME: XYRADEC
;
; PURPOSE: This function returns spherical from cartesian coordinates (3-d). 
;
; CATEGORY: util, math, geometry, 3-d
;
; CALLING SEQUENCE: Az_el = XYRADEC(Xyz)
;
; EXAMPLES:
;
;        sun_in_gro = xyradec( sunxyz # x2fov )
;        earth_in_gro = xyradec(-sc#x2fov) ;n x 2, Phi and Theta
;
; INPUTS:
;       xyz, array of n 3 vectors (unit measure), n x 3 or 3 x n, n x 3 preferred
;       
; OUTPUTS:
;       Function returns azimuth and elevation in degrees, n x 2
; CALLS:
;	XYPRO
; PROCEDURE;
;	This just turns the procedure XYPRO into a function.
;	History:
;  29-aug-2018, richard.schwartz@gsfc.nasa.gov, added input flexibility  nx3 or 3xn
;  and checking for unit measure
;
;-
function xyradec, xyz

xypro, xyz, az_el
return, az_el
end
