PRO pmm,a,b,c,d,e,f,g,h,i,j,MM=mm,HELP=help,nan=nan ; print_min_max
;+
;NAME: pmm
;PURPOSE: print min, max of given argument (up to ten arguments)
;CATEGORY: analysis
;CALLING SEQUENCE: pmm,blarch	;blarch = array, image, vector, etc...
;                  pmm,blarch,mm=mm
;                  pmm,blarch,/help
;                  pmm,blarch,/nan
;INPUTS: blarch
;OPTIONAL INPUT PARAMETERS: none
;KEYWORD PARAMETERS: 
; help - if set, print this doc header
; mm - set to a variable name to return mins,maxes
; nan - if set, ignore NaNs in arrays
;OUTPUTS: prints min, max of blarch.  If mm keyword used, return the min and max
;          for it too, with mm=FLTARR(2,N) for N positional parameters.
;COMMON BLOCKS: none
;SIDE EFFECTS: none
;RESTRICTIONS: none
;PROCEDURE: simple min, max call
;MODIFICATION HISTORY: ANM 910507. Updated 911031. Doc'd DKL 930426
; 10-Feb-2022, Kim Tolbert. Added nan keyword. 
;   And updated header to correct example for mm - mm=mm (not /mm)
;-


ON_ERROR,2 & IF KEYWORD_SET(help) THEN BEGIN doc_library,'pmm' & RETURN & END
N = N_PARAMS() & mm = FLTARR(2,N)
IF N GE 1 THEN BEGIN amin = MIN(a,MAX=amax,nan=nan) & mm(*,0) = [amin,amax] & END
IF N GE 2 THEN BEGIN amin = MIN(b,MAX=amax,nan=nan) & mm(*,1) = [amin,amax] & END
IF N GE 3 THEN BEGIN amin = MIN(c,MAX=amax,nan=nan) & mm(*,2) = [amin,amax] & END
IF N GE 4 THEN BEGIN amin = MIN(d,MAX=amax,nan=nan) & mm(*,3) = [amin,amax] & END
IF N GE 5 THEN BEGIN amin = MIN(e,MAX=amax,nan=nan) & mm(*,4) = [amin,amax] & END
IF N GE 6 THEN BEGIN amin = MIN(f,MAX=amax,nan=nan) & mm(*,5) = [amin,amax] & END
IF N GE 7 THEN BEGIN amin = MIN(g,MAX=amax,nan=nan) & mm(*,6) = [amin,amax] & END
IF N GE 8 THEN BEGIN amin = MIN(h,MAX=amax,nan=nan) & mm(*,7) = [amin,amax] & END
IF N GE 9 THEN BEGIN amin = MIN(i,MAX=amax,nan=nan) & mm(*,8) = [amin,amax] & END
IF N GE 10 THEN BEGIN amin = MIN(j,MAX=amax,nan=nan)& mm(*,9) = [amin,amax] & END
PRINT,mm
RETURN
END
