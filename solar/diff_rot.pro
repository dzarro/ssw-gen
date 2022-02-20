;+
; PROJECT:
;       SOHO - CDS
;
; NAME:	
;       DIFF_ROT()
;
; PURPOSE:
;     Computes the differential rotation of the sun
;       
; CALLING SEQUENCE: 
;       Result = DIFF_ROT(ddays,latitude)
;
; INPUTS:
;       DDAYS    --  number of days to rotate
;       LATITUDE --  latitude in DEGREES
;       
; OUTPUTS:
;       Result -- Change in longitude over ddays days in DEGREES
;
; KEYWORD PARAMETERS: 
;       ALLEN    -- use values from Allen, Astrophysical Quantities, 1973
;       HOWARD   -- use values for small magnetic features from Howard et al.
;                   (DEFAULT)
;       SNODGRASS-- use values for magnetic features from Snodgrass and Ulrich,
;                   1990.  (Model used for Solar Orbiter planning.)
;       DOPP_SNOD-- use values for Doppler Residuals from Snodgrass and Ulrich
;       SPEC_SNOD-- use values for Spectroscopic from Snodgrass and Ulrich
;       SIDEREAL -- use sidereal rotation rate (DEFAULT)
;       SYNODIC  -- use synodic rotation rate
;       CARRINGTON -- use rate in Carrington coordinates.
;       RIGID    -- rotate as rigid body
;       RATE     -- user specified rotation rate in degrees per day
;                   (only used if /RIGID)
;
; PREVIOUS HISTORY:
;       Written T. Metcalf  June 1992
;
; MODIFICATION HISTORY:
;       Version 1, Liyun Wang, GSFC/ARC, November 17, 1994
;          Incorporated into the CDS library
;       Version 2, Zarro, GSFC, 1 July 1997 - made Howard the default
;       Version 3, Zarro, GSFC, 19 Sept 1997 - corrected Howard coeff's
;       Version 4, Zarro (EER/GSFC) 22 Feb 2003 - added /RIGID
;       Version 5, Zarro (EER/GSFC) 29 Mar 2003 - added /RATE
;       Version 6, William Thompson, GSFC, 3-Mar-2009, Added
;       /CARRINGTON
;       Modified, 23 October 2011, Zarro (ADNET)
;          - optimized memory management
;       Modified, 22 October 2014, Zarro (ADNET)
;          - use double-precision arithmetic
;       16 July 2016, Zarro (ADNET) - initialized angle arrays
;       08-Jun-2017, William Thompson, ADNET/GSFC, add /SNODGRASS option
;       13-Oct-2020, William Thompson, add /DOPP_SNOD, /SPEC_SNOD
;-

FUNCTION DIFF_ROT, ddays, latitude, howard=howard, allen=allen,debug=debug,$
                   synodic=synodic, sidereal=sidereal,rigid=rigid,rate=rate,$
                   carrington=carrington, snodgrass=snodgrass, $
                   dopp_snod=dopp_snod, spec_snod=spec_snod

;-- check if rotating as rigid body

   if keyword_set(rigid) then begin
    sz=size(latitude) 
    if n_elements(sz) lt 4 then sin2l=0.d else $
     sin2l=make_array(size=size(latitude))
     sin4l=sin2l
    if is_number(rate) then begin
     if keyword_set(debug) then message,'using rigid rate of '+trim(rate),/cont
     if rate gt 0 then return,ddays*rate+sin2l
    endif else if keyword_set(debug) then message,'using rigid body rotation',/cont
   endif else begin
    sin2l = (SIN(DOUBLE(latitude*!dtor)))^2
    sin4l = sin2l*sin2l
   endelse

   IF KEYWORD_SET(allen) THEN BEGIN

;  Allen, Astrophysical Quantities

    rotation = ddays*(14.44d0 - 3.d0*sin2l)
   ENDIF ELSE IF KEYWORD_SET(snodgrass) then begin

;  Magnetic features as used by the Solar Orbiter project for planning
;  (Snodgrass and Ulrich, 1990, Ap. J., 351, 309-316)

    rotation = ddays*(14.252d0 - 1.678*sin2l - 2.401*sin4l)

;  Doppler residuals from Snodgrass and Ulrich, 1990

   ENDIF ELSE IF KEYWORD_SET(dopp_snod) then begin

    rotation = ddays*(14.712d0 - 2.396*sin2l - 1.787*sin4l)

;  Spectroscopic from Snodgrass and Ulrich, 1990

   ENDIF ELSE IF KEYWORD_SET(spec_snod) then begin

    rotation = ddays*(14.113d0 - 1.698*sin2l - 2.346*sin4l)

   ENDIF ELSE BEGIN

;  Small magnetic features 
;  (Howard, Harvey, and Forgach, Solar Physics, 130, 295, 1990)

    rotation = (1.d-6)*ddays*(2.894d0 - 0.428d0*sin2l - 0.37d0*sin4l)*24.d0*3600.d0/!dtor
   ENDELSE

   IF KEYWORD_SET(synodic) THEN BEGIN
    rotation = temporary(rotation) - 0.9856d0*ddays
   END ELSE IF KEYWORD_SET(carrington) THEN BEGIN
    rotation = temporary(rotation) - (360.d0/25.38d0)*ddays
   ENDIF 

   RETURN, rotation
END

