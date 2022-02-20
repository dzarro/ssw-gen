;+
; Project     : SDO
;
; Name        : IRS__DEFINE
;
; Purpose     : Class definition for IRIS object
;
; Category    : Objects
;
; History     : 8-March-2017, Zarro (ADNET) - written
;               9-Jan-2019, Zarro (ADNET) - made WCS default
;
; Contact     : dzarro@solar.stanford.edu
;-
;---------------------------------------------------

function iris::init,_ref_extra=extra

if ~self->fits::init(_extra=extra) then return,0

self->setenv,_extra=extra

if is_blank(chklog('HOME')) then mklog,'HOME',home_dir()

return,1

end

;---------------------------------------------------

function iris::search,tstart,tend,_ref_extra=extra

return,vso_files(tstart,tend,_extra=extra,window=30,spacecraft='iris')

end

;----------------------------------------------------------------
pro iris::read,file,index,data,_ref_extra=extra,err=err,roll_correct=roll_correct,$
                    no_prep=no_prep

err=''
delvarx,index,data
self->getfile,file,local_file=rfile,err=err,_extra=extra,count=count
if (count eq 0) then return

do_prep=~keyword_set(no_prep)
self->empty
have_iris_path=self->have_path(_extra=extra)
k=0
for i=0,count-1 do begin
 err='' & dfile=rfile[i]

 if ~self->is_valid(dfile,prepped=prepped,err=err) then begin
  mprint,err
  continue
 endif

;-- read file

 if ~have_iris_path then mreadfits,dfile,index,data,_extra=extra else begin
  if prepped then reader='read_iris_l2' else reader='read_iris'
  call_procedure,reader,dfile,index,data,/noshell,/use_shared,/uncomp_delete,_extra=extra
 endelse

 if ~is_struct(index) then begin
  err='Error reading - '+dfile
  mprint,err
  continue
 endif

;-- prep file

 if do_prep && ~prepped then begin
  iris_prep,index,data,pindex,pdata
  if is_struct(pindex) then begin
   index=pindex & data=temporary(pdata)
  endif else begin 
   err='Error prepping - '+dfile
   continue
  endelse
 endif

;-- make maps

 nimg=n_elements(index)
 for j=0,nimg-1 do begin
  self->mk_map,index[j],data[*,*,j],k,_extra=extra,filename=dfile,/use_wcs
  self->set,k,grid=30,/limb,/log
  self->colors,k
  k=k+1
 endfor

endfor

count=self->get(/count)
if count eq 0 then begin 
 err='No maps created.'
 mprint,err
 return
endif

if keyword_set(roll_correct) then self->roll_correct

return & end

;-----------------------------------------------------------------------

function iris::is_prepped,index
 
prepped=0b
if ~is_struct(index) then return,0b
if ~have_tag(index,'history') then return,0b
chk=where(stregex(index.history,'iris_prep',/bool),count)
prepped=count gt 0

return,prepped
end

;------------------------------------------------------------------------

function iris::is_valid,file,prepped=prepped,err=err
err=''
prepped=0b
;if is_blank(file) then return,0b
n_ext=get_fits_extn(file,err=err)
if (n_ext eq 0) || is_string(err) then return,0b

for i=0,n_ext-1 do begin
 header='' & valid=0b & err=''
 mrd_head,file,header,err=err,ext=i
 if is_string(err) then continue
 if is_string(header) then begin
  s=fitshead2struct(header)
;  if have_tag(s,'origin') then if stregex(s.origin,'IRIS',/bool,/fold) then valid=1b
  if have_tag(s,'telescop') then if stregex(s.telescop,'IRIS',/bool,/fold) then valid=1b
  if valid then begin
   prepped=self->is_prepped(s)
   return,valid
  endif
 endif
endfor
err='Invalid IRIS file.'

return,0b
end

;-----------------------------------------------------------------------------
;-- check for IRIS and SDO branches in !path

function iris::have_path,err=err,verbose=verbose


err=''
if ~have_proc('read_sdo') then begin
 ssw_path,/ontology,/quiet
 if ~have_proc('read_sdo') then begin
  err='VOBS/Ontology branch of SSW not installed.'
  if keyword_set(verbose) then mprint,err,/info
  return,0b
 endif
endif

err=''
if ~have_proc('read_iris') then begin
 ssw_path,/iris,/quiet
 if ~have_proc('read_iris') then begin
  err='IRIS branch of SSW not installed.'
  if keyword_set(verbose) then mprint,err,/info
  return,0b
 endif
endif

return,1b
end

;------------------------------------------------------------------------
;-- setup IRIS environment variables

pro iris::setenv,_extra=extra

if is_string(chklog('IRIS_RESPONSE')) then return
mklog,'$SSW_IRIS','$SSW/iris',/local

idl_startup=local_name('$SSW/iris/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup

file_env=local_name('$SSW/iris/setup/setup.iris_env')
file_setenv,file_env,_extra=extra

return & end

;------------------------------------------------------------------------------
;-- load IRIS color table

pro iris::colors,k

if ~have_proc('iris_lct') then return
index=self->get(k,/index)
if ~is_struct(index) then return
;dsave=!d.name
;set_plot,'Z'
;tvlct,rold,gold,bold,/get
iris_lct,index,red,green,blue,/noload
self->set,k,red=red,green=green,blue=blue,/has_colors
;tvlct,rold,gold,bold
;set_plot,dsave

return & end

;------------------------------------------------------
pro iris__define,void                 

void={iris, inherits fits,inherits prep}

return & end
