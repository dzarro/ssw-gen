;+
; :Description:
;
; generic file reading routine for general data files
; that were written by write_dat.pro
;
; Tom Woods
;
; Version 1.0 1994  Initial procedure
;   2.0 1996  Updated to handle array of structures
;
; INPUT:  filename
;
; OUTPUT: data from the file (array of data or array of structure)
;
; $Log: read_dat.pro,v $
; Revision 6.0  2003/03/05 19:32:30  dlwoodra
; version 6 commit
;
; Revision 5.20  2002/09/06 23:21:35  see_sw
; commit of version 5.0
;
; Revision 4.0  2002/05/29 18:10:01  see_sw
; Release of version 4.0
;
; Revision 3.0  2002/02/01 18:55:28  see_sw
; version_3.0_commit
;
; Revision 1.1.1.1  2000/11/21 21:49:17  dlwoodra
; SEE Code Library Import
;
;
;idver='$Id: read_dat.pro,v 6.0 2003/03/05 19:32:30 dlwoodra Exp $'
;
;    Describe the procedure.
;
; :Params:
;    filename
;
; :Keywords:
;    status
;    silent
;
; :Author:
;-
function goesr_read_dat, filename, status=status, silent=silent

  status = -1
  data = -1

  if n_params(0) lt 1 then begin
    filename = ' '
    read, 'Enter filename to read ? ', filename
    if filename eq '' then return, data
  endif
  
  get_lun, lun
  openit = 0
  on_ioerror, openerror
  openr,lun, filename

  numbers = '0123456789'

  ;
  ;	read header comment lines first
  ;	also check for STRUCTURE and FORMAT keywords too
  ;
  on_ioerror, readerror
  openit = 1
  incomments = 1
  sinput = ''
  form = ''
  struct = ''
  while incomments do begin
    readf,lun,sinput
    sinput = strtrim(sinput,1)
    sinputcaps = strupcase(sinput)
    if strpos( sinputcaps, 'STRUCT' ) eq 0 then begin
      startpos = strpos( sinputcaps, '{' )
      endpos = strpos( sinputcaps, '}' )
      if (startpos lt 0) or (endpos lt 0) or $
        (endpos lt startpos) then begin
        if (not(keyword_set(silent))) then print, 'read_dat: Error in STRUCT keyword definition !'
      endif else begin
        struct = strmid( sinput, startpos, endpos-startpos+1 )
      endelse
    endif
    if strpos( sinputcaps, 'FORMAT' ) eq 0 then begin
      startpos = strpos( sinputcaps, '(' )
      endpos = strpos( sinputcaps, ')' )
      if (startpos lt 0) or (endpos lt 0) or $
        (endpos lt startpos) then begin
        if (not(keyword_set(silent))) then print, 'read_dat: Error in FORMAT keyword definition !'
      endif else begin
        form = strmid( sinput, startpos, endpos-startpos+1 )
      endelse
    endif
    if strpos( numbers, strmid(sinput,0,1) ) ge 0 then $
      incomments = 0
  endwhile
  ;
  ;	read number of lines
  ;
  nlines = long( sinput )
  n = strlen(sinput)
  k = 1
  innumber = 1
  numberstr = '0123456789 /.,<>?;:\|=+-_)(*&^%$#@!~'
  while innumber do begin
    if strpos( numberstr, strmid(sinput,k,1) ) lt 0 then begin
      if (k lt n-1) and (not(keyword_set(silent))) then begin
        print, '    ', filename, ' : ', strmid(sinput,k,n-k)
      endif
      innumber = 0
    endif else begin
      k = k + 1
      if k ge n-2 then innumber = 0
    endelse
  endwhile
  ;
  ;	read number of columns
  ;
  readf,lun,sinput
  sinput = strtrim(sinput,1)
  ncolumns = long( sinput )
  n = strlen(sinput)
  k = 1
  innumber = 1
  while innumber do begin
    if strpos( numberstr, strmid(sinput,k,1) ) lt 0 then begin
      if (k lt n-1) and (not(keyword_set(silent))) then begin
        print, '    ', filename, ' : ', strmid(sinput,k,n-k)
      endif
      innumber = 0
    endif else begin
      k = k + 1
      if k ge n-2 then innumber = 0
    endelse
  endwhile

  form = '$' + form

  ;
  ;	read array of numbers if structure is not defined
  ;
  if strlen(struct) le 2 then begin
    data = dblarr(ncolumns, nlines)
    ;
    ; read data (using format if it exists)
    ;
    if strlen(form) le 2 then readf,lun,data else $
      readf,lun,form,data
    status = 0
    goto, cleanup
  endif else begin
    ;
    ;	read array of structure
    ;
    acmd = execute( 'temp = ' + struct )
    data = replicate( temp, nlines )
    ;
    ; read data (using format if it exists)
    ;
    if strlen(form) le 2 then readf,lun,data else $
      readf,lun,form,data
    ;
    ; clean up any string data
    ;
    ntags = n_tags(data)
    tnames = tag_names(data)
    for i=0,ntags-1 do begin
      asize = size( data.(i) )
      if (asize(asize(0)+1) eq 7) then begin
        if (not(keyword_set(silent))) then print, 'read_dat: Compressing strings for DATA.' + tnames(i)
        data.(i) = strtrim( data.(i), 2 )
      endif
    endfor
    status = 0
    goto, cleanup
  endelse

  openerror:
  print, 'ERROR: READ_DAT() could not open ' + filename
  goto,cleanup

  readerror:
  print, 'ERROR: READ_DAT() had a read error for ' + filename

  cleanup:
  if (not(keyword_set(silent))) then print, ' '
  on_ioerror, NULL
  if openit then close,lun
  free_lun, lun
  return, data
end

;+
; :Description:
; XRS FM-1 Calibration File = xrs_fm1_responsivity_renormalize.dat
; Generated by xrs_responsivity_make_file.pro using a FLAT spectrum.
;
; Integrated Responsivity (IntegR) is used to convert XRS signal
;    in Amps to Watts/m^2 as follows:
;            Irradiance_W_per_m2 = Signal_Amps / IntegR_Amps_m2_per_W
; For GOES16
;    XRS A1 IntegR = 9.6150000e-06
;    XRS A2 IntegR = 5.0636203e-07
;    XRS B1 IntegR = 1.4690000e-05
;    XRS B2 IntegR = 7.7616903e-07
;
; Aperture Area for the XRS channels are:
;    XRS A1 Area = 0.80946551 cm^2
;    XRS A2 Area = 0.040307721 cm^2
;    XRS B1 Area = 0.80946551 cm^2
;    XRS B2 Area = 0.040024905 cm^2
;
; For GOES17
;
;    XRS A1 IntegR = 9.5770001e-06
;    XRS A2 IntegR = 4.8472299e-07
;    XRS B1 IntegR = 1.4790000e-05
;    XRS B2 IntegR = 7.7749502e-07
; Aperture Area for the XRS channels are:
;    XRS A1 Area = 0.80946551 cm^2
;    XRS A2 Area = 0.040288123 cm^2
;    XRS B1 Area = 0.80946551 cm^2
;    XRS B2 Area = 0.040288123 cm^2
;
;
;
; :Params:
;    sat - satellite number
;
; :Keywords:
;    path
;    silent
;    max_sat - returns the maximum available satellite number
;
; :Author: rschwartz70@gmail.com, 22-jul-2020
;-
function goesr_transfer, sat, path = path,  silent = silent, max_sat = max_sat

  ; XRS FM-1 Calibration File = xrs_fm1_responsivity_renormalize.dat
  ; Generated by xrs_responsivity_make_file.pro using a FLAT spectrum.
  ;
  ;
  ;
  ; Data in this file are Responsivity (in Amp/Watt)
  ;    as a function of wavelength (in Angstroms).
  if keyword_set( max_sat ) then return, 17  ;4-jul-2020, maximum GOES XRS number
  default, sat, 16
  sat = sat > 16 < 17
  file = sat eq 16 ? 'xrs_fm1_responsivity_renormalize.dat' :'xrs_fm2_responsivity_renormalize.dat'
  default, path, [curdir(), concat_dir( getenv('SSW'),'gen/idl/synoptic/goes')]
  default, silent, 1
  ;might be in the test path. Look here first
  filnam = file_search( concat_dir( getenv('SSW'),'gen/idl/aatest/goes'), file, count = nfile)
  if nfile eq 0 then filnam = file_search( path, file, count = nfile )
  if nfile eq 0 then return, -1
  out = goesr_read_dat( filnam[0], status = status, silent = silent )

  gbar = { gb_a1: 9.615e-6, gb_a2: 5.0636203e-07, gb_b1: 1.4690000e-05, gb_b2:7.7616903e-07}
  if sat eq 17 then gbar = { gb_a1: 9.577e-6, gb_a2: 4.84723e-07, gb_b1: 1.4790000e-05, gb_b2:7.775e-07}
  area = { area_a1: 0.80946551, area_a2:0.040307721 , area_b1: 0.80946551,area_b2:0.0400249}
  ;Multiply out by area to put transfer coefficients in familiar units
  for i= 1, 4 do out[ i, *] = out[ i, *] * area.(i-1) * 1e-4 ;area in m^2
  return, { sat: sat, transfer: out, gb_a1: 9.615e-6, gb_a2: 5.0636203e-07, gb_b1: 1.4690000e-05, gb_b2:7.7616903e-07, $
    area_a1: 9.615e-6, area_a2: 5.0636203e-07, area_b1: 1.4690000e-05, area_b2:7.7616903e-07}
end
