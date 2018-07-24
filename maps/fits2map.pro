;+
; Project     : SOHO-CDS
;
; Name        : FITS2MAP
;
; Purpose     : Make an image map from a FITS file
;
; Category    : imaging
;
; Syntax      : fits2map,file,map
;
; Inputs      : FILE = FITS file name (or FITS data + HEADER)
;
; Outputs     : MAP = map structure
;
; Keywords    : HEADER = FITS header (output of last file read)
;               OBJECT = return map as an object
;               INDEX = FITS index matching HEADER
;               LIST = return multiple maps in LIST
;
; History     : Written 22 January 1998, D. Zarro, SAC/GSFC
;               Modified, 22 April 2000, Zarro (SM&A/GSFC)
;               Modified, 1 April 2005, Zarro (L-3Com/GSFC) 
;                - accounted for 180 degree roll
;               14-Sept-2008, Zarro (ADNET) 
;                - fixed typo with 180 roll-correction not being
;                  applied to map
;                - move roll-correction to INDEX2MAP
;               3-Nov-2008, Zarro (ADNET)
;               - added /object for object output
;               9-May-2014, Zarro (ADNET)
;               - added check for RTIME
;               19-Sep-2016, Zarro (ADNET)
;               - return INDEX and HEADER in _REF_EXTRA
;               22-Sep-2016, Zarro (ADNET)
;               - corrected inconsistent return error messages 
;                (Invalid filename input vs Invalid FITS file input)
;               29-Sep-2016, Zarro (ADNET)
;               - added /LIST
;
; Contact     : dzarro@solar.stanford.edu
;-

pro fits2map,file,map,object=object,_ref_extra=extra,list=list

;-- check inputs

if is_blank(file) then begin
 pr_syntax,'fits2map,file,map','Invalid filename input',_extra=extra
 return
endif

;-- return map object

delvarx,map
if keyword_set(object) then begin
 map=obj_new('fits')
 map->read,file,_extra=extra
 return
endif

;-- return map structure

f=obj_new('fits')
f->read,file,_extra=extra
count=f->get(/count)
if (count ne 0) then begin
 if keyword_set(list) then map=f->get(/list) else begin
  for i=0,count-1 do begin
   imap=f->get(/map,i)
   map=merge_struct(map,imap,/no_copy)
  endfor
 endelse
endif
 
obj_destroy,f

return & end
