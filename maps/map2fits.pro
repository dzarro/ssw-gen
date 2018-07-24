;+
; Project     : SOHO-CDS
;
; Name        : MAP2FITS
;
; Purpose     : write image map to FITS file
;
; Category    : imaging
;
; Syntax      : map2fits,map,file
;
; Inputs      : MAP = image map structure
;               FILE = FITS file name
;
; Keywords    : ERR = error string
;               BYTE_SCALE = byte scale data
;
; History     : Written 22 August 1997, D. Zarro, SAC/GSFC
;               11-Jul-2003, William Thompson, GSFC
;                - write both DATE_OBS and DATE-OBS
;               9-May-2014, Zarro (ADNET)
;                - added check for RTIME 
;               13-Sep-2016, Zarro (ADNET)
;                - added checks for optional map properties
;                  (e.g. angles)
;               29-November-2016, Zarro (ADNET)
;               - added capability for adding user-defined map
;                 properties to FITS header
;               16-Feb-2017, Zarro (ADNET)
;               - added check for non-scalar user-defined properties
;
; Contact     : dzarro@solar.stanford.edu
;-

   pro map2fits,map,file,err=err,byte_scale=byte_scale,verbose=verbose

   err=''
   verbose=keyword_set(verbose)
 
   if ~valid_map(map) || is_blank(file) then begin
    pr_syntax,'map2fits,map,file'
    return
   endif
   np=n_elements(map)

;-- form output file name

   cd,curr=cdir
   break_file,file,dsk,dir,dfile,dext
   if trim(dsk+dir) eq '' then fdir=cdir else fdir=dsk+dir
   if ~file_test(fdir,/write) then begin
    err='No write access to - '+fdir
    message,err,/info
    return
   endif
   if trim(dext) eq '' then fext='.fits' else fext=dext
   filename=concat_dir(fdir,dfile)+fext
   if verbose then message,'Writing map to - '+filename,/info
   use_rtime=tag_exist(map,'rtime')
   in_tags=tag_names(map)
   def_map,rmap
   def_fits=['SIMPLE','BITPIX','NAXIS','NAXIS1','NAXIS2','DATE','FILENAME','END',$
             'COMMENT','HISTORY']
   ignore=[tag_names(rmap),def_fits]
   delvarx,header
   for i=0,np-1 do begin

;-- unpack data

    unpack_map,map[i],data,xp,yp,dx=cdelt1,dy=cdelt2,xc=xcen,yc=ycen,$
      nx=naxis1,ny=naxis2

;-- scale data?

    if keyword_set(byte_scale) then bscale,data,top=255

;-- add header for the output array.

    fxhmake,header,data,/date

;-- add FITS parameters CRPIX, CRVAL, etc.

    crpix1=comp_fits_crpix(xcen,cdelt1,naxis1,0)
    crpix2=comp_fits_crpix(ycen,cdelt2,naxis2,0)

    fxaddpar, header, 'ctype1', 'solar_x','Solar X (cartesian west) axis'
    fxaddpar, header, 'ctype2', 'solar_y','Solar Y (cartesian north) axis'

    fxaddpar, header, 'cunit1', 'arcsecs','Arcseconds from center of Sun'
    fxaddpar, header, 'cunit2', 'arcsecs','Arcseconds from center of Sun'

    fxaddpar, header, 'crpix1', crpix1, 'Reference pixel along X dimension'
    fxaddpar, header, 'crpix2', crpix2, 'Reference pixel along Y dimension'

    fxaddpar, header, 'crval1',0, 'Reference position along X dimension'
    fxaddpar, header, 'crval2',0, 'Reference position along Y dimension'

    fxaddpar, header, 'cdelt1',cdelt1,'Increments along X dimension'
    fxaddpar, header, 'cdelt2',cdelt2,'Increments along Y dimension'

    if use_rtime then obs_time=map[i].rtime else obs_time=map[i].time

    fxaddpar,header,'date_obs',obs_time,'Observation date'
    fxaddpar,header,'date-obs',obs_time,'Observation date'
    if tag_exist(map,'dur') then fxaddpar,header,'exptime',map[i].dur,'Exposure duration'
    fxaddpar,header,'origin',map[i].id,'Data description'

    if tag_exist(map,'soho') then begin
     if map[i].soho then fxaddpar,header,'telescope','SOHO','Telescope'
    endif

    fxaddpar,header,'CROTA1',map[i].roll_angle,'Rotation angle (degrees)'
    fxaddpar,header,'CROTA2',map[i].roll_angle,'Rotation angle (degrees)'
    fxaddpar,header,'crotacn1',map[i].roll_center[0],'Rotation x center'
    fxaddpar,header,'crotacn2',map[i].roll_center[1],'Rotation y center'
    if tag_exist(map[i],'L0') then fxaddpar,header,'L0',map[i].l0,'L0 (degrees)'
    if tag_exist(map[i],'B0') then fxaddpar,header,'B0',map[i].b0,'B0 (degrees)'
    if tag_exist(map[i],'RSUN') then fxaddpar,header,'RSUN',map[i].rsun,'Solar radius (arcsecs)'

;-- add in user-specified properties

    for k=0,n_elements(in_tags)-1 do begin
     chk=where(in_tags[k] eq ignore,count)
     if count gt 0 then continue
     if ~is_scalar(map[i].(k)) then begin
;      mprint,'Skipping non-scalar user-defined property - '+in_tags[k]
      continue
    endif

     fxaddpar,header,in_tags[k],map[i].(k),''
    endfor

    fxaddpar, header, 'filename', file_basename(filename),'FILENAME'

;-- add optional comments or history
  
    if tag_exist(map[i],'comment') then begin
     comments=map[i].comment
     for k=0,n_elements(comments)-1 do if is_string(comments[k]) then fxaddpar,header,'COMMENT',comments[k]
    endif

    if tag_exist(map[i],'history') then begin
     histories=map[i].history
     for k=0,n_elements(histories)-1 do if is_string(histories[k]) then fxaddpar,header,'HISTORY',histories[k]
    endif

;-- write out the file

    fxwrite, filename, header,data,append=(i gt 0)
   endfor

   return & end
