
PRO line_fits_summary, fitfile, wvl

;+
; NAME:
;      LINE_FITS_SUMMARY
;
; PURPOSE:
;      This routine takes the output from the spec_gauss_widget
;      routine and prints it in a simple text format for easy
;      reading. 
;
; CATEGORY:
;      Gauss fitting; output.
;
; CALLING SEQUENCE:
;      IDL> LINE_FITS_SUMMARY, FITFILE
;
; INPUTS:
;      Fitfile:  The name of file produced by spec_gauss_widget
;                containing the line fit information.
; OPTIONAL INPUTS:
;      Wvl:   If specified, then only lines within +/- 0.2 angstroms
;             of WVL will be printed.
;	
; OUTPUTS:
;      Text is printed to the IDL input window. Note that lines are
;      sorted in ascending wavelength order.
;
; CALL:
;      READ_LINE_FITS.
;
; MODIFICATION HISTORY:
;      Ver.1, 20-Nov-2017, Peter Young
;         Tidied up output and added header.
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> line_fits_summary, fitfile [, wvl]'
  return
ENDIF 

read_line_fits,fitfile,str

;
; Use a different format for printing if lines are above 1000
; angstroms (e.g., IRIS) or below (e.g., EIS).
;
IF mean(str.wvl) GE 1000. THEN BEGIN
  format='(f9.4," +/-",f7.4,f10.1," +/-",f7.1,f10.3," +/-",f7.3,2x,2f9.3)'
ENDIF ELSE BEGIN 
  format='(f8.3," +/-",f7.3,f10.1," +/-",f7.1,f10.3," +/-",f7.3,2x,2f8.3)'
ENDELSE 
  
IF n_elements(wvl) NE 0 THEN BEGIN
  k=where(str.wvl GE wvl-0.2 AND str.wvl LE wvl+0.2,nk)
  IF nk GT 0 THEN BEGIN
    str=str[k]
  ENDIF ELSE BEGIN
    print,'% LINE_FITS_SUMMARY: no lines near this wavelength. Returning...'
    return
  ENDELSE 
ENDIF

n=n_elements(str)

k=sort(str.wvl)
str=str[k]

print,'   Wvl         Err        Int        Err       FWHM       Err       Background'
FOR i=0,n-1 DO BEGIN
  print,format=format, $
        str[i].wvl,str[i].swvl, $
        str[i].int,str[i].sint, $
        str[i].width,str[i].swidth, $
        str[i].x0,str[i].x1
ENDFOR 

END
