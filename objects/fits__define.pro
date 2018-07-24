;+
; Project     : HESSI
;
; Name        : FITS__DEFINE
;
; Purpose     : Define a FITS map object
;
; Category    : imaging maps objects
;               
; Syntax      : This procedure is invoked when a new FITS object is
;               created via:
;
;               IDL> new=obj_new('fits')
;
; Keywords    : EXTENSION = extension to read [def = all]
;               RECORD = record to read [def = all]
;               APPEND = append to previously read data
;
; History     : Written 19 May 1998, D. Zarro, SM&A/GSFC
;               10 Oct 2009, Zarro (ADNET) 
;                - added capability to read multiple FITS file
;                  extensions
;                - retired mreadfits method 
;               29 Nov 2009, Zarro (ADNET)
;                - added more stringent check for missing input file
;                - rename ::GET method to ::GETFILE
;               12 Sept 2010, Zarro (ADNET)
;                - added called to valid_fits to check
;                  that a valid FITS files is entered
;               27 Dec 2010, Zarro (ADNET)
;                - added APPEND
;               8-Oct-2014, Zarro (ADNET)
;                - added support for reading RICE-compressed files
;               24-Dec-2014, Zarro (ADNET)
;                - added check for degenerate image dimensions
;               17-Aug-2015, Zarro (ADNET)
;                - made downloading to temp directory the default
;                - moved MK_MAP method from MAP class to FITS class
;               6-Apr-2016, Zarro (ADNET)
;               - added Preselect method for selecting multiple
;                 extensions
;               28-Apr-2016, Zarro (ADNET)
;               - disabled error message if at least one valid image
;                 is read.
;               17-May-2016, Zarro (ADNET)
;               - added CLEANUP method
;               14-July-2016, Zarro (ADNET)
;               - added DECOMPRESS method
;               19-Sept-2016, Zarro (ADNET)
;               - pipe SOCK_COPY to SOCK_GET for HTTPS support
;               14-Feb-2017, Zarro (ADNET)
;               - move WCS_INDEXMAP call to INDEX2MAP
;               20-Mar-2017, Zarro (ADNET)
;               - added check for image color method
;               19-July-2017, Zarro (ADNET)
;               - moved NO_COPY to _EXTRA 
;               8-Aug-2017, Zarro (ADNET)
;               - use SESSION_DIR for unique temporary download directory
;
; Contact     : dzarro@solar.stanford.edu
;-

;---------------------------------------------------------------------------
;-- FITS reader

pro fits::read,rfile,data,index=index,err=err,_ref_extra=extra,$
               extension=extension,nodata=nodata,$
               record=record,append=append,select=select
err=''

self->getfile,rfile,local_file=file,err=err,_extra=extra,count=nfiles

if nfiles eq 0 then return

file=strtrim(file,2)

;-- avoid making duplicate copies of data if it is not an argument

no_copy=(n_params() ne 2) && ~arg_present(data)

nodata=keyword_set(nodata)
if ~is_number(record) then record=-1

;-- if extension not specified, read all or select if /select

do_select=keyword_set(select)
do_ext=0b
if exist(extension) then do_ext=is_number(extension[0]) 
do_all=~do_select && ~do_ext

;-- empty linkedlist if not appending

if ~keyword_set(append) then self->empty
m=self->get(/count)-1 

for i=0,nfiles-1 do begin
 terr='' & dfile=file[i] 
 
 if ~valid_fits(dfile,err=terr) then begin
  mprint,terr,/info
  continue
 endif

 n_ext=get_fits_extn(dfile)
 if n_ext eq 0 then begin
  mprint,'Skipping '+file[i],/info
  continue
 endif
 
;-- check if extracting extensions

 extensions=indgen(n_ext)
 if do_ext then begin
  match,extensions,extension,p,q
  if p[0] eq -1 then begin
   terr='No matching extensions in '+file[i]
   mprint,terr
   continue
  endif
  extension=p
 endif

;-- check if doing all

 if do_all then extension=extensions

;-- check if selecting

 if do_select then begin
  self->preselect,dfile,s_extension,cancel=cancel,extension=extension
  extension=s_extension
  if cancel eq 1 then continue
 endif

 nimg=n_elements(extension)
; if ~do_select && ~nodata then mprint,'Reading '+trim(nimg)+' extensions.',/info

 for k=0,nimg-1 do begin
  rerr=''
  rext=extension[k]
  self->readfits,dfile,data,index=index,_extra=extra,err=terr,$
                          extension=rext,nodata=nodata
  ndim=size(data,/n_dim)

  if ~nodata && (is_string(terr) || (ndim le 1) || (ndim gt 3) || is_struct(data)) then begin
   if is_blank(terr) then terr='Warning - FITS file contains a non-standard image.'
;   mprint,terr,/info
   continue
  endif

  if nodata then continue
  nindex=n_elements(index)
  for j=0,nindex-1 do begin
   merr=''
   m=m+1
   if nindex gt 1 then begin
    read_one=(record lt nindex) && (record gt -1)
    if read_one then j=record
    self->mk_map,index[j],data[*,*,j],m,err=merr,$
               filename=file[i],_extra=extra,no_copy=no_copy
    if read_one then break
   endif else begin
    self->mk_map,index[j],data,m,err=merr,$
               filename=file[i],_extra=extra,no_copy=no_copy
   endelse
  endfor
 endfor
endfor

;-- return any errors

if ~nodata && (self->get(/count) eq 0) then begin
 cerr='No maps created.'
 case 1 of
  is_string(terr): err=terr 
  is_string(rerr): err=rerr
  is_string(merr): err=merr
  else: err=cerr
 endcase
 mprint,err
endif


return & end


;-------------------------------------------------------------------------
;-- Preselect records from multiple extensions

pro fits::preselect,file,image_no,$
          _ref_extra=extra,count=count,cancel=cancel

cancel=0
count=0
records=''
image_no=-1
if is_blank(file) then return
records=self->read_records(file,_extra=extra,count=nrec)
if is_blank(records) || (nrec eq 0) then return
if nrec eq 1 then begin
 image_no=0 & count=1
 return
endif

image_no=xsel_list_multi(records,/index,_extra=extra,cancel=cancel,$
 label=file_break(file)+' - Select image numbers from list below:')

if cancel eq 1 then begin
 image_no=-1 
 return
endif

count=n_elements(image_no)

return & end

;-----------------------------------------------------------------------
;-- read extension records

function fits::read_records,file,count=count,_ref_extra=extra
count=0
records=''
self->read,file,index=index,/nodata,_extra=extra
if ~is_struct(index) then return,''
count=n_elements(index)
return,self->format_list(index)
end

;-----------------------------------------------------------------------

function fits::format_list,index

count=n_elements(index)
if (count eq 0) || ~is_struct(index) then return,''

if have_tag(index,data_obs) then time=trim(anytim2utc(index.date_obs,/vms)) else $
 time=replicate('???',count)
if have_tag(index,'wave_len') then wave=index.wave_len else $
 wave=replicate('???',count)
records=trim(sindgen(count))+') TIME: '+time+ $
        ' WAVELENGTH: '+strpad(trim(wave),4,/after)+ $
        ' NAXIS1: '+strpad(trim(index.naxis1),4,/after)+ $
        ' NAXIS2: '+strpad(trim(index.naxis2),4,/after)
return,records
end

;--------------------------------------------------------------------------
;-- wrapper around MRDFITS that makes HEADER &&  EXTENSION into keywords

pro fits::mrdfits,file,data,header=header,extension=extension,$
                    verbose=verbose,_ref_extra=extra

forward_function mrdfits
verbose=keyword_set(verbose)
if ~exist(extension) then extension=0
if verbose then begin
 mprint,'Reading file - '+file,/info
 mprint,'Reading extension - '+trim(arr2str(extension)),/info
endif
data=mrdfits(file,extension,header,_extra=extra,/fscale,silent=~verbose)

return & end

;-------------------------------------------------------------------------
;-- READFITS method

pro fits::readfits,file,data,header=header,index=index,_ref_extra=extra,err=err,$
                      status=status,nodata=nodata

err=''
status=-1
delvarx,index,data

;-- just read header

if keyword_set(nodata) then begin
 mrd_head,file,header,status=status,/no_check_compress,_extra=extra
 if status eq 0 then index=fitshead2struct(header)
 return
endif

;-- call MRDFITS

have_mrdfits=have_proc('mrdfits')
if have_mrdfits then begin
 self->mrdfits,file,data,header=header,status=status,_extra=extra
 if status eq 0 then begin
;  if is_struct(data) then data=data.(0)
  index=fitshead2struct(header)
  if ~is_struct(data) then data=comdim2(data)
  sz=size(data)
  if sz[0] eq 3 then index=replicate(index,sz[3])
 endif else begin
  err='Error reading file.'
  mprint,err,/info
 endelse
 return
endif else mreadfits,file,index,data,header=header,_extra=extra

return & end

;------------------------------------------------------------------------

pro fits::decompress,file,dfile,_ref_extra=extra,err=err,status=status

err='' & status=0b
if is_string(file) then dfile=file else dfile=''
if ~is_compressed(file) && ~is_rice_comp(file) then return
out_dir=session_dir('decompress')

;-- check if regular-compressed

dfile=file
if is_compressed(file) then begin
 if since_version('8.2.3') then $
  file_decompress,file,local_file=dfile,out_dir=out_dir,err=err else $
   uncompress,file,out_file=dfile,out_dir=out_dir,_extra=extra,err=err
 if is_string(err) then return
 status=1b
endif

;-- check if rice-compressed

if is_rice_comp(dfile) then begin
 rdfile=rice_decomp(dfile,out_dir=out_dir,err=err,_extra=extra)
 if is_string(err) then begin
  status=0b & return
 endif
 dfile=rdfile
 status=1b
endif 

return
end
 

;------------------------------------------------------------------------
;-- download remote URL files to local directory

pro fits::getfile,file,out_dir=out_dir,_ref_extra=extra,err=err,local_file=local_file,count=count

count=0
err=''

local_file=''
if is_blank(file) then begin
 err='No file name entered.'
 mprint,err,/info
 return
endif

nf=n_elements(file)
local_file=strarr(nf)

;-- create temp directory for download

if is_url(file,/scheme) then begin
 if ~write_dir(out_dir,/quiet) then out_dir=session_dir('download')
endif

for i=0,nf-1 do begin
 if is_url(file[i],/scheme) then begin
  sock_copy,file[i],out_dir=out_dir,_extra=extra,local_file=copy_file,/use_network
  if file_test(copy_file,/read) then local_file[i]=copy_file
 endif else begin
  if file_test(file[i],/read) then local_file[i]=file[i]
 endelse
endfor

chk=where(local_file ne '',count)
if count eq 0 then begin
 err='File not found.'
 local_file=''
 mprint,err,/info
 return
endif else local_file=local_file[chk]

;-- decompress

out_file=local_file
for i=0,count-1 do begin
 self->decompress,local_file[i],lfile,err=err,status=status,_extra=extra
 if status && is_blank(err) then out_file[i]=lfile
endfor
local_file=out_file

if count eq 1 then local_file=local_file[0]

return & end

;---------------------------------------------------------------------------------
;-- create map structure

pro fits::mk_map,index,data,k,_ref_extra=extra,filename=filename,id=id
             
index2map,index,data,map,_extra=extra
if ~valid_map(map) then return

if ~have_tag(index,'filename') then index=add_tag(index,'','filename')
if is_string(filename) then index.filename=file_basename(filename)
if is_string(id) then map.id=id


self->set,k,map=map,/no_copy
self->set,k,index=index
self->set,k,grid=30,/limb,_extra=extra
self->set_colors,k,index

return & end

;--------------------------------------------------------------------

pro fits::set_colors,k,index

if ~have_method(self,'have_colors') then return
chk=call_method('have_colors',self,index,red,green,blue)

if chk then self->set,k,red=red,green=green,blue=blue,/has_colors

return & end

;--------------------------------------------------------------------------                  
;-- define FITS object

pro fits__define                 

fits_struct={fits, inherits map}

return & end
