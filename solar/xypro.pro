;+
; PROJECT:
;	SDAC
; NAME: XYPRO
;
; PURPOSE: compute spherical from cartestian coordinates (3-d)
;
; CATEGORY: util, math, geometry
;
; CALLING SEQUENCE: XYPRO, Xyz, Az_el
;
; EXAMPLES:
;	xypro, xyz, az_el
;
; INPUTS:
;       Xyz, array of n 3 vectors (unit measure), n x 3
; OUTPUTS:
;       Az_el - azimuth and elevation in degrees, n x 2
; HISTORY:
;	 richard.schwartz@gsfc.nasa.gov
;	 29-aug-2018, richard.schwartz@gsfc.nasa.gov, added input flexibility  nx3 or 3xn
;	 and checking for unit measure
;-
pro xypro, xyz_in, az_el

  on_error,2
  default, no_check, 0
  xyz = xyz_in
  
    dim = size(/dimension, xyz )
    fail = n_elements( dim ) gt 2 or product( dim ) mod 3 ne 0
    xyz     = dim[1] eq 3 ? xyz : transpose( xyz )
    xyz2    = xyz^2
    is_unit = abs( sqrt( total( xyz2, 2) ) - 1.0 ) lt 1e-5
    if ~product( is_unit) and dim[0] eq 3 then begin
      xyz = transpose( xyz )
      is_unit = abs( sqrt( total( xyz^2, 2) ) - 1.0 ) lt 1e-5
    endif
    if fail || ~product( is_unit) then begin
      help, xyz_in
      message, 'Input must be dimensioned n x 3 or 3 x n. and each column or row must be of unit measure'
    endif
  

  az_el = !radeg*[[atan(xyz[*,1],xyz[*,0])],[asin(xyz[*,2])]]

end
