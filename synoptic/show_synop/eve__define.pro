;+
; Project     : SDO
;
; Name        : EVE__DEFINE
;
; Purpose     : Class definition for SDO/EVE
;
; Category    : Objects
;
; History     : Written 28 September 2010, D. Zarro (ADNET)
;               28-July-2016, Zarro (ADNET) 
;               - added FITS helper object
;
; Contact     : dzarro@solar.stanford.edu
;-

function eve::init,_ref_extra=extra

if ~self->utplot::init(_extra=extra) then return,0
self.fits=obj_new('fits')
self->setenv,_extra=extra

return,1
end

;-------------------------------------------------------------------
pro eve::cleanup

if obj_valid(self.fits) then obj_destroy,self.fits
self->utplot::cleanup

return & end

;------------------------------------------------------------------------

function eve::search,tstart,tend,_ref_extra=extra

return,vso_files(tstart,tend,inst='eve',_extra=extra)

end

;------------------------------------------------------

pro eve::read,file,err=err,_ref_extra=extra,index=index

err=''
index=null()
self.fits->getfile,file,local_file=rfile,_extra=extra,count=count,err=err
if (count eq 0) then return
if count gt 1 then begin
 err='Can only read single files.'
 mprint,err
 return
endif

if get_fits_extn(rfile) lt 7 then begin
 err='Not a valid SDO/EVE lightcurve file.'
 mprint,err
 return
endif

data=mrdfits(rfile,5,/silent,head)
if ~have_tag(data,'LINE_IRRADIANCE') then begin
 err='File does not contain Irradiance data.'
 mprint,err
 return
endif

index=fitshead2struct(head)
rad=transpose(data.line_irradiance)
times=data.tai
wave=mrdfits(rfile,1,/silent,whead)
type=wave.name

;-- insert data into UTPLOT object

self->set,times=times,data=rad,dim1_ids=type,/tai,utbase=tai2utc(times[0],/vms),$
         data_unit='watts m!u-2!n',$
         title=index.telescop+' '+index.instrume,$
         filename=file_basename(rfile)

return & end

;------------------------------------------------------------------------
;-- setup EVE environment 

pro eve::setenv,_extra=extra
if is_string(chklog('EVE_DATA')) then return

mklog,'$SSW_EVE','$SSW/sdo/eve',/local
idl_startup=local_name('$SSW/sdo/eve/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup
file_env=local_name('$SSW/sdo/eve/setup/setup.eve_env')
file_setenv,file_env,_extra=extra
return & end

;------------------------------------------------------
pro eve__define,void                 

void={eve, inherits utplot, fits:obj_new()}

return & end
