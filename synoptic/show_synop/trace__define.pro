;+
; Project     : HESSI
;
; Name        : TRACE__DEFINE
;
; Purpose     : Define a TRACE data object
;
; Category    : Ancillary GBO Synoptic Objects
;
; Syntax      : IDL> c=obj_new('trace')
;
; History     : Written 30 Dec 2007, D. Zarro (ADNET)
;               Modified 8 Sep 2013, Zarro (ADNET) - added CATCH in ::READ
;               5 April 2016, Zarro (ADNET) 
;                - added /NO_PREP, /ALL
;                - added capability to preselect processed level 1
;                  images
;               16-June-2016, Zarro (ADNET)
;                - added support to run read_trace in Windows 32 bit
;               24-March-2017, Zarro (ADNET)
;                - added COLOR support
;               19-July-2017, Zarro (ADNET)
;                - switched default searching to LMSAL
;               31-July-2017, Zarro (ADNET)
;                - fixed typo with prepped data being undefined
;                  because of misplaced /no_copy 
;
; Contact     : dzarro@solar.stanford.edu
;-

function trace::init,_ref_extra=extra

if ~self->fits::init(_extra=extra) then return,0

self.decoder=-1
;
;-1 = not checked
;0  = not found
;1  = found locally
;2  = found remotely

;-- setup environment

self->setenv,_extra=extra
void=self->have_path(_extra=extra)

return,1 & end

;------------------------------------------------------------------------

pro trace::cleanup

self->binaries,/reset
self->fits::cleanup

return & end

;------------------------------------------------------------------------
;-- setup TRACE environment variables

pro trace::setenv,_extra=extra

if is_string(chklog('TRACE_RESPONSE')) then return

idl_startup=local_name('$SSW/trace/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup

file_env=local_name('$SSW/trace/setup/setup.trace_env')
file_setenv,file_env,_extra=extra
return & end

;-------------------------------------------------------------------------
;-- check that TRACE Databases are loaded  

function trace::have_dbase,err=err,verbose=verbose

err=''
chk=is_dir(local_name('$SSW/trace/dbase')) 
if ~chk then begin
 err='TRACE lookup dbase ($SSW/trace/dbase) not found. Cannot read file.'
 if keyword_set(verbose) then mprint,err,/info
 return,chk
endif
return,1b
end

;----------------------------------------------------------------------
function trace::have_cal,err=err,verbose=verbose

err=''
have_cal=is_dir('$tdb')
if ~have_cal then err='TRACE calibration directory ($SSWDB/tdb) not found. Returned data will not be prepped.'
if keyword_set(verbose) then mprint,err,/info
return,have_cal
end

;-------------------------------------------------------------------------
;-- check for trace_decode_idl shareable object

function trace::have_decoder,err=err,verbose=verbose,_extra=extra

err=''

if self.decoder gt 0 then return,1b

warn='TRACE decompressor not found.'
ferr=warn+' Cannot decompress image.'
verbose=keyword_set(verbose)
if self.decoder eq 0 then begin
 err=ferr
 if verbose then mprint,err
 return,0b
endif

;-- look for it 

wdir=!version.OS + '_' + !version.ARCH
if self->need_thread() then wdir=str_replace(wdir,'_64','') 
decomp='trace_decode_idl.so'
if os_family() eq 'Windows' then decomp='trace_decode_idl.dll'

share=local_name('$SSW_TRACE/binaries/'+wdir+'/'+decomp)
chk=file_search(share,count=count)

;-- found local copy

if count ne 0 then begin
 self.decoder=1 & return,1b
endif

;-- download a copy to temporary directory

mprint,warn+' Attempting download from SSW server...',/info
sdir=get_temp_dir()
tdir=concat_dir(sdir,'exe')
udir=concat_dir(tdir,wdir)
mk_dir,udir,/a_write,/a_read
sloc=ssw_server(/full)
sfile=sloc+'/solarsoft/trace/binaries/'+wdir+'/'+decomp
sock_get,sfile,out_dir=udir,_extra=extra,/no_check,local=share
chk=file_search(share,count=count)
if count ne 0 then begin
 mprint,'Download succeeded.'
 mklog,'SSW_BINARIES_SAVE',chklog('SSW_BINARIES')
 mklog,'SSW_BINARIES_TEMP',sdir
 mklog,'SSW_BINARIES',sdir
 self.decoder=2
 return,1b
endif else mprint,'Download failed.' 

self.decoder=0
err=ferr
if keyword_set(verbose) then mprint,err,/info

return,0b

end

;--------------------------------------------------------------------------

function trace::search,tstart,tend,_ref_extra=extra,vso=vso,$
                count=count,type=type

vso=1b

if keyword_set(vso) then $
 files=self->vso_search(tstart,tend,_extra=extra,count=count) else $
  files=self->lmsal_search(tstart,tend,_extra=extra,count=count)

type='euv/images'
if count gt 1 then type=replicate(type,count)
return,files

end

;-------------------------------------------------------------------------
;-- LMSAL search wrapper

function trace::lmsal_search,tstart,tend,_ref_extra=extra,wave=wave
s=obj_new('site')
s->setprop,rhost='http://www.lmsal.com',topdir='/TRACE/data/level1',/full,ext='fts',delim='/'
if keyword_set(wave) then s->setprop,ftype='.'+trim(wave)
files=s->search(tstart,tend,_extra=extra)
obj_destroy,s
return,files
end
  
;--------------------------------------------------------------------------
;-- VSO search wrapper

function trace::vso_search,tstart,tend,_ref_extra=extra
files=vso_files(tstart,tend,inst='trace',_extra=extra,window=3600.)
return,files
end

;---------------------------------------------------------------------------
;-- check for TRACE branch in !path

function trace::have_path,err=err,verbose=verbose

err=''
if ~have_proc('read_trace') then begin
 epath=local_name('$SSW/trace/idl')
 if is_dir(epath) then ssw_path,/trace,/quiet
 if ~have_proc('read_trace') then begin
  err='TRACE branch of $SSW not installed. Cannot Read nor Prep image.'
  if keyword_set(verbose) then mprint,err,/info
  return,0b
 endif
endif

return,1b

end

;--------------------------------------------------------------------------
;-- FITS reader

pro trace::read,file,data,_ref_extra=extra,image_no=image_no,err=err,$
                all=all,no_prep=no_prep,index=index

err=''
           
;-- download if URL

if is_blank(file) then begin
 pr_syntax,'object_name->read,filename'
 return
endif

self->getfile,file,local_file=ofile,_extra=extra,err=err,count=count
if count eq 0 then return

;-- check what is loaded

self->empty
do_all=keyword_set(all)
do_img=0b
if exist(image_no) then do_img=is_number(image_no[0])
do_select=~do_img && ~do_all
do_prep=~keyword_set(no_prep)
have_path=self->have_path(err=path_err)
have_cal=self->have_cal(err=cal_err)
have_decoder=self->have_decoder(err=decoder_err)
have_dbase=self->have_dbase(err=dbase_err)

;-- read files

nfiles=n_elements(ofile)
j=0
self->binaries

cd,cur=cdir
for i=0,nfiles-1 do begin
 err=''
 dfile=ofile[i]

 valid=self->is_valid(dfile,level=level,_extra=extra,err=err,decomp=decomp)
 if ~valid then continue

;-- if level 1 then read with FITS object

 if level eq 1 then begin
  self->fits::read,dfile,data,extension=image_no,select=do_select,_extra=extra,index=index
  count=self->get(/count)
  for kk=0,count-1 do begin
   log_scale=is_number(index[kk].wave_len)
   self->set,log_scale=log_scale
  endfor
  j=count+1
  continue
 endif

;-- warn if key calibration and prep files are missing

 if level eq 0 then begin
  if ~have_decoder && ~decomp then begin
   xack,decoder_err,/suppress
   continue
  endif
  if ~have_dbase && ~decomp then begin
   xack,dbase_err,/suppress
   continue
  endif
  if ~have_path then begin
   xack,path_err,/suppress
   continue
  endif
  if ~have_cal then xack,cal_err,/suppress
 endif

;-- select image subset?

 records=self->read_records(dfile,count=n_img)
 if n_img eq 0 then continue
 images=indgen(n_img)
 if do_img then begin
  match,images,image_no,p,q
  if p[0] eq -1 then begin
   mprint,'No matching images in '+dfile
   continue
  endif
  image_no=p
 endif

;-- preselect? [def]

 if do_select then begin
  self->preselect,dfile,image_no,cancel=cancel
  if (cancel eq 1) || (image_no[0] eq -1) then continue
 endif 
 
;-- do all?

 if do_all then image_no=images
 nimg=n_elements(image_no)

;-- if level 0 then read use TRACE reader
  
 for k=0,nimg-1 do begin
  err=''
  oindex=-1 & odata=-1
  img=image_no[k]
  mprint,'Reading image '+trim(img)
  if decomp then self->fits::read,dfile,odata,index=oindex,exten=img,err=err,_extra=extra else $
   self->read_comp,dfile,img,oindex,odata,_extra=extra,err=err
  
  if is_string(err) then begin
   mprint,err
   break
  endif

  sz=size(odata)
  if (sz[0] lt 2) then begin
   err='Image '+trim(img)+' is not 2D.'
   mprint,err
   continue
  endif

  if have_cal && do_prep then begin
   mprint,'Prepping image '+trim(img)
   trace_prep,oindex,odata,index,data,/norm,/wave2point,/float,_extra=extra,/quiet
   if ~is_struct(index) then begin
    err='Error prepping image '+trim(img)
    mprint,err
    continue
   endif
  endif else begin
   index=oindex & data=temporary(odata)
  endelse

  index=rep_tag_value(index,2l,'naxis')
  log_scale=is_number(index.wave_len)
  id='TRACE '+trim(index.wave_len)+' ('+trim(index.naxis1)+'x'+trim(index.naxis2)+')'  
  self->mk_map,index,data,j,_extra=extra,filename=dfile,id=id,err=err,log_scale=log_scale
  if is_string(err) then continue
  j=j+1
 endfor
endfor

count=self->get(/count)
if count eq 0 then begin
 err1='No maps created.'
 if is_string(err) then err=err1+' '+err else err=err1
 mprint,err,/info 
endif

self->binaries,/reset

return & end

;--------------------------------------------------------------------

;-- redirect TRACE binaries directory to temporary location if downloading DLL decoder

pro trace::binaries,reset=reset

if self.decoder ne 2 then return

if keyword_set(reset) then begin
 if is_string(chklog('SSW_BINARIES_SAVE')) then mklog,'SSW_BINARIES','SSW_BINARIES_SAVE'
endif else begin
 if is_string(chklog('SSW_BINARIES_TEMP')) then mklog,'SSW_BINARIES',chklog('SSW_BINARIES_TEMP')
endelse

return & end

;-------------------------------------------------------------------
;-- check if need to use 32 bit thread on 64 bit system

function trace::need_thread
mbits=!version.memory_bits
return,(os_family(/lower) eq 'windows') && (mbits eq 64)
end

;-----------------------------------------------------------------------

pro trace::read_comp,dfile,img,oindex,odata,_extra=extra,ops=ops,err=err,thread=thread

err=''
oindex=-1 & odata=-1

cdir=curdir()
error=0
catch,error
if error ne 0 then begin
 err=err_state()
 mprint,err,/info
 catch,/cancel
 error=0
 cd,cdir
 return
endif

;-- if Windows 64 bit, run read_trace in 32 bit thread

if keyword_set(thread) then begin
 if ~is_number(ops) then ops=64
endif else ops=32

if self->need_thread() || keyword_set(thread) then begin
 if ~self.thread then begin
  thread,ops=ops,err=err,_extra=extra,output=concat_dir(get_temp_dir(),'bridge.txt')
  if is_string(err) then begin
   err='Cannot decompress TRACE image on this system.'
   mprint,err
   return
  endif 
  self.thread=1b
  thread,'void=obj_new','trace',/wait
  if self.decoder eq 2 then thread,'mklog','SSW_BINARIES',chklog('SSW_BINARIES_TEMP'),/wait
 endif
 fdir=file_dirname(dfile)
 if (fdir eq '') || (fdir eq '.') then dfile=concat_dir(curdir(),dfile)
 thread,'read_trace',dfile,img,oindex,odata,_extra=extra,/wait
endif else read_trace,dfile,img,oindex,odata,_extra=extra

return & end

;-----------------------------------------------------------------------------
;--- read raw records in a TRACE level 0 file

function trace::read_raw,file

error=0
catch,error
if error ne 0 then begin
 err=err_state()
 mprint,err,/info
 catch,/cancel
 return,''
endif

if is_blank(file) then return,''
if is_url(file) then sock_fits,file,data,extension=1 else data=mrdfits(file,1)
if ~is_struct(data) then data=fitshead2struct(data)
if ~is_struct(data) then return,''

count=n_elements(data)
index={naxis1:0l,naxis2:0l,date_obs:0d,wave_len:''}
index=replicate(index,count)
index.naxis1=data.nx_out
index.naxis2=data.ny_out
index.wave_len='???'
index.date_obs=anytim(data,/tai)
return,index

end
 
;-------------------------------------------------------------------------
;-- read TRACE level 0 records

function trace::read_records,file,count=count

count=0
records=''
valid=self->is_valid(file,level=level,decomp=decomp)

if level eq 0 && ~decomp then begin
 if self->have_path() && ~is_url(file) then read_trace,file,-1,index,/nodata else index=self->read_raw(file)
endif else self->fits::read,file,index=index,/nodata

if ~is_struct(index) then return,''
count=n_elements(index)
return,self->format_list(index)
end

;------------------------------------------------------------------------------
;-- check if valid TRACE file

function trace::is_valid,file,err=err,level=level,verbose=verbose,$
                 decompressed=decompressed

valid=0b & level=0 & err=''
decompressed=0b
verbose=keyword_set(verbose)
if is_url(file) then sock_fits,file,header=header,/nodata,err=err else $
 mrd_head,file,header,err=err
if is_string(err) then begin
 mprint,'Could not read header - '+file,/info
 return,valid
endif

chk1=where(stregex(header,'MPROGNAM.+TR_REFORMAT',/bool,/fold),count1)
chk2=where(stregex(header,'(INST|TEL|DET|ORIG).+TRAC',/bool,/fold),count2)
chk3=where(stregex(header,'TRACE_PREP|tr_dark_sub|tr_flat_sub',/bool,/fold),count3)
valid=(count1 ne 0) || (count2 ne 0)

if ~valid then begin
 mprint,'Not a valid TRACE file - '+file,/info
 return,valid
endif

if (count1 ne 0) then level=0 
if (count3 ne 0) then level=1
if (count1 eq 0) then decompressed=1b

if verbose && (level eq 1) then mprint,'TRACE image is already prepped.',/info

return,valid
end

;----------------------------------------------------------------
function trace::have_colors,index,red,green,blue

common trace_colors,scolors

if ~have_proc('trace_colors2') then return,0b
if ~is_struct(index) then return,0b
if ~have_tag(index,'wave_len') then return,0b
if ~is_number(index.wave_len) then return,0b

if is_struct(scolors) then begin
 chk=where(index.wave_len eq scolors.wave_len,count)
 if count eq 1 then begin
  red=(scolors[chk]).red
  green=(scolors[chk]).green
  blue=(scolors[chk]).blue
  return,1b
endif
endif

dsave=!d.name
set_plot,'Z'
tvlct,r0,g0,b0,/get
trace_colors2,fix(index.wave_len),red,green,blue
tvlct,r0,g0,b0
set_plot,dsave

colors={wave_len:index.wave_len,red:red,green:green,blue:blue}
scolors=merge_struct(scolors,colors)

return,1b & end

;------------------------------------------------------------------------------
;-- TRACE structure definition

pro trace__define,void                 

void={trace,decoder:0,thread:0b,inherits fits, inherits prep}

return & end
