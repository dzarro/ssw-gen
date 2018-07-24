;+
; Project     : SDO
;
; Name        : SDO__DEFINE
;
; Purpose     : Parent class definition for SDO
;
; Category    : Objects
;
; History     : 30 August 2012, Zarro (ADNET) - written
;               23 August 2013, Zarro (ADNET)
;               - defined HOME (if not defined)
;               8 October 2014, Zarro (ADNET)
;               - moved RICE-decompression to FITS parent class 
;               30 September 2015, Zarro (ADNET)
;               - added AIA_ and HMI_PREP branches
;               2 November 2015, Zarro (ADNET)
;               - fixed bug where prepped file was crashing read_sdo
;               16 July 2016, Zarro (ADNET)
;               - added input file decompress option
;               6 December 2016, Zarro (ADNET)
;               - improved error check for non-SDO file inputs
;               3 March 2017, Zarro (ADNET)
;               - added ROLL_CORRECT keyword 
;
; Contact     : dzarro@solar.stanford.edu
;-
;---------------------------------------------------

function sdo::init,_ref_extra=extra

if ~self->fits::init(_extra=extra) then return,0
if is_blank(chklog('HOME')) then mklog,'HOME',home_dir()

return,1

end

;----------------------------------------------------------------------

function sdo::search,tstart,tend,_ref_extra=extra

return,vso_files(tstart,tend,_extra=extra,window=30,spacecraft='sdo')

end

;----------------------------------------------------------------
pro sdo::read,file,_ref_extra=extra,err=err,roll_correct=roll_correct

err=''

self->getfile,file,local_file=rfile,err=err,_extra=extra,count=count

if (count eq 0) then return
self->empty
have_sdo_path=self->sdo::have_path(_extra=extra)
k=0
for i=0,count-1 do begin
 err='' & dfile=rfile[i]
 if ~self->is_valid(dfile,prepped=prepped,err=err,_extra=extra,sdo_read=sdo_read) then begin
  mprint,err
  continue
 endif

 if ~have_sdo_path || prepped || sdo_read then mreadfits,dfile,index,data,_extra=extra else $
  read_sdo,dfile,index,data,/noshell,/use_shared,/uncomp_delete,_extra=extra
 
 self->prep,index,data,err=err,_extra=extra
 if is_blank(err) then begin
  self->mk_map,index,data,k,_extra=extra,filename=dfile
  k=k+1
 endif
endfor


if keyword_set(roll_correct) then self->roll_correct

return & end

;------------------------------------------------------------------------

function sdo::is_valid,file,prepped=prepped,err=err,instrument=instrument,_ref_extra=extra
err=''
prepped=0b
sdo_read=0b
;if is_blank(file) then return,0b
n_ext=get_fits_extn(file,err=err)
if (n_ext eq 0) || is_string(err) then return,0b

for i=0,n_ext-1 do begin
 header='' & valid=0b & err=''
 mrd_head,file,header,err=err,ext=i
 if is_string(err) then continue
 if is_string(header) then begin
  s=fitshead2struct(header)
  if have_tag(s,'origin') then if stregex(s.origin,'SDO',/bool,/fold) then valid=1b
  if have_tag(s,'telescop') then if stregex(s.telescop,'SDO',/bool,/fold) then valid=1b
  if have_tag(s,'instrume') && is_string(instrument) then valid=strmid(strlowcase(instrument),0,3) eq strmid(strlowcase(s.instrume),0,3)
  if valid then begin
    prepped=self->is_prepped(s,_extra=extra)
   return,valid
  endif
 endif
endfor
if is_string(instrument) then lab='SDO/'+strupcase(instrument) else lab='SDO'
err='Invalid '+lab+' file - '+file

return,0b
end

;-----------------------------------------------------------------------

function sdo::is_prepped,index,sdo_read=sdo_read

prepped=0b & sdo_read=sdo_read
if ~is_struct(index) then return,0b
if ~have_tag(index,'history') then return,0b
chk=where(stregex(index.history,'_prep',/bool),count)
prepped=count gt 0

chk=where(stregex(index.history,'read_sdo',/bool),count)
sdo_read=count gt 0

return,prepped
end

;-----------------------------------------------------------------------------
;-- check for SDO branch in !path

function sdo::have_path,err=err,verbose=verbose

err=''
if ~have_proc('read_sdo') then begin
 ssw_path,/ontology,/quiet
 if ~have_proc('read_sdo') then begin
  err='VOBS/Ontology branch of SSW not installed.'
  if keyword_set(verbose) then mprint,err,/info
  return,0b
 endif
endif

return,1b
end

;------------------------------------------------------
pro sdo__define,void                 

void={sdo, inherits fits, inherits prep}

return & end
