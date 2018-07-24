;+
; Project     : SDO
;
; Name        : mk_sdo_map
;
; Purpose     : make an SDO (AIA or HMI) image map
;
; Category    : imaging, maps
;
; Syntax      : IDL> map=mk_sdo_map(file)
;
; Inputs      : FILE = SDO FITS file
;
; Outputs     : MAP = AIA or HMI map structure
;
; Keywords    : Input keywords passed to relevant object via _EXTRA
;               INDEX = optional INDEX array
;
; History     : 12 December 2014, Zarro (ADNET) - written
;               11 February 2016, Zarro (ADNET) - streamlined
;               11 April 2017, Zarro (ADNET) - added instrument check
;
; Contact     : dzarro@solar.stanford.edu
;-

function mk_sdo_map,file,_ref_extra=extra,index=index,err=err

err=''
index=-1
if is_blank(file) then begin
 pr_syntax,'map=mk_sdo_map(file)'
 return,-1
endif

;-- read files and create maps

k=-1
nf=n_elements(file)
for i=0,nf-1 do begin
 ifile=file[i]
 err=''
 det=get_fits_det(ifile,err=err)
 if is_string(err) then continue
 aia=stregex(det,'AIA',/bool,/fold)
 hmi=stregex(det,'HMI',/bool,/fold)
 if ~aia && ~hmi then begin
  err='Skipping invalid SDO file - '+ifile
  mprint,err
  sfiles=append_arr(sfiles,ifile)
  continue
 endif
 if aia then sdo=obj_new('aia') else sdo=obj_new('hmi')
 sdo->read,ifile,err=err,_extra=extra
 if string(err) then continue

;-- extract and merge similar-sized maps

 k=k+1
 imap=sdo->get(/map,/no_copy)
 rindex=sdo->get(/index)
 
 sz=size(imap.data) 
 if k eq 0 then begin
  nx=sz[1] & ny=sz[2]
  map=temporary(imap)
  tindex=rindex
 endif else begin
  n1=sz[1] & n2=sz[2]
  if (n1 eq nx) and (n2 eq ny) then begin
   map=merge_struct(map,imap,/no_copy)
   tindex=merge_struct(tindex,rindex,/no_copy)
  endif else sfiles=append_arr(sfiles,ofile)
 endelse  
endfor

;-- cleanup

if obj_valid(sdo) then obj_destroy,sdo
if valid_map(map) then index=tindex else map=-1 

;-- report files that were not processed

if n_elements(sfiles) gt 1 then begin
 message,'Following files not processed - ',/info
 if !quiet eq 0 then iprint,sfiles,/no_quit
endif

return,map

end



