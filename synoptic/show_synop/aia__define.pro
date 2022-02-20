;+
; Project     : SDO
;
; Name        : AIA__DEFINE
;
; Purpose     : Class definition for SDO/AIA
;
; Category    : Objects
;
; History     : 15 June 2010, D. Zarro (ADNET) - written
;               20-Mar-2013, Kim Tolbert
;               -Added normalize keyword to read method. If set, divide image by
;                exposure time.
;               28-Mar-2013, Zarro (ADNET)
;               - Added patch to use B0 from PB0R
;               2-Apr-2013, Zarro (ADNET)
;               - NORMALIZE now a supported keyword in AIA_PREP. Check if applied.
;               16-Aug-2013, Zarro (ADNET)
;               - Replaced WCS2MAP by INDEX2MAP since AIA headers not
;                 fully WCS-compliant
;               16-Oct-2014, Zarro (ADNET)
;               - Set index.exptime = 1 when normalizing
;               - Added O_EXPTIME to INDEX
;               23-Dec-2014, Zarro (ADNET)
;               - removed deletion of RICE-decompressed file
;               1-Apr-2015, Zarro (ADNET)
;               - added AIA color tables
;               25-July-2015, Zarro (ADNET)
;               - removed unnecessary Z-buffer call (sorry Kim)
;               28-Sep-2015, Zarro (ADNET)
;               - split aia_prep into separate PREP method
;               - added Z-buffer protection for batch running
;               12-Nov-2015, Kim. In aia::prep, make normalize=1 the
;               default
;               3-Dec-2015, Zarro (ADNET) - restored /NO_PREP option
;               14-Feb-2017, Zarro (ADNET) - added check for CROTA2
;               16-Mar-2017, Zarro (ADNET)
;               - added call to instrument-specific IDL_STARTUP
;               24-July-2020, Zarro (ADNET)
;               - add INDEX_REF keyword to AIA_PREP to align image to itself
;
; Contact     : dzarro@solar.stanford.edu
;- 

function aia::init,_ref_extra=extra

if ~self->sdo::init(_extra=extra) then return,0

;-- setup environment

self->setenv,_extra=extra

return,1 & end

;---------------------------------------------------

function aia::search,tstart,tend,_ref_extra=extra

return,self->sdo::search(tstart,tend,instrument='aia',_extra=extra)

end

;-----------------------------------------------------------------------------
;-- check for AIA branch in !path

function aia::have_path,err=err,verbose=verbose

err=''
if ~have_proc('aia_prep') then begin
 ssw_path,/aia,/quiet
 if ~have_proc('aia_prep') then begin
  err='SDO/AIA branch of SSW not installed.'
  if keyword_set(verbose) then mprint,err
  return,0b
 endif
endif

return,1b
end

;-------------------------------------------------------------------------

pro aia::read,file,_ref_extra=extra

self->sdo::read,file,_extra=extra,instrument='aia'

return & end

;---------------------------------------------------------------------

pro aia::mk_map,index,data,k,_ref_extra=extra

self->sdo::mk_map,index,data,k,_extra=extra,/log

return & end

;--------------------------------------------------------------------------

pro aia::prep,index,data,normalize=normalize,_ref_extra=extra,no_prep=no_prep,err=err

err=''
checkvar, normalize, 1
o_exptime=index.exptime
no_prep=keyword_set(no_prep)
prepped=self->is_prepped(index)

if ~no_prep && ~prepped && self->have_path(_extra=extra) then begin
 if ~have_tag(index,'crota2') then tindex=add_tag(index,0.,'crota2') else tindex=index

 aia_prep,tindex,data,oindex,odata,_extra=extra,/quiet,/use_ref,/nearest,$
                       normalize=normalize,index_ref=tindex
 data=temporary(odata)
 index=oindex
endif

if keyword_set(normalize) then begin
 chk=where(stregex(index.history,'normalization',/bool,/fold),count)
 type=size(data,/tname)
 if count eq 0 then begin
  if index.exptime gt 0. then begin
   data=temporary(data)/index.exptime
   if type eq 'INT' then data=nint(temporary(data))
   index.exptime=1.
  endif
 endif
endif
index=add_tag(index,o_exptime,'o_exptime',index='exptime')
return
end

;------------------------------------------------------------------------
;-- setup AIA environment variables

pro aia::setenv,_extra=extra

mklog,'$SSW_AIA',local_name('$SSW/sdo/aia')
if is_string(chklog('AIA_CALIBRATION')) then return

idl_startup=local_name('$SSW/sdo/aia/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup

file_env=local_name('$SSW/sdo/aia/setup/setup.aia_env')
file_setenv,file_env,_extra=extra
return & end

;----------------------------------------------------------------
function aia::have_colors,index,red,green,blue

common aia_colors,scolors

if ~have_proc('aia_lct') then return,0b
if ~is_struct(index) then return,0b
if ~have_tag(index,'wavelnth') then return,0b

if is_struct(scolors) then begin
 chk=where(index.wavelnth eq scolors.wavelnth,count)
 if count eq 1 then begin
  red=(scolors[chk]).red
  green=(scolors[chk]).green
  blue=(scolors[chk]).blue
  return,1b
 endif
endif

error=0
catch,error
if error ne 0 then begin
 err=err_state()
 mprint,err,/info
 catch,/cancel
 if exist(dsave) then set_plot,dsave
 return,0b
endif

dsave=!d.name
set_plot,'Z'
tvlct,r0,g0,b0,/get
aia_lct,wave=index.wavelnth,red,green,blue
tvlct,r0,g0,b0
set_plot,dsave

colors={wavelnth:index.wavelnth,red:red,green:green,blue:blue}
scolors=merge_struct(scolors,colors)

return,1b & end

;------------------------------------------------------
pro aia__define,void                 

void={aia, inherits sdo}

return & end
