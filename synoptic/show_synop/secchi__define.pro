;+
; Project     : STEREO
;
; Name        : SECCHI__DEFINE
;
; Purpose     : Define a SECCHI data/map object
;
; Category    : Objects
;
; Syntax      : IDL> a=obj_new('secchi')
;
; Examples    : IDL> a->read,'20070501_000400_n4euA.fts' ;-- read FITS file
;               IDL> a->plot                             ;-- plot image
;               IDL> map=a->getmap()                     ;-- access map
;               IDL> data=a->getdata()                   ;-- access data
;                       
;               Searching via VSO:                                     
;               IDL> files=a->search('1-may-07','02:00 1-may-07')
;               IDL> print,files[0]
;               http://stereo-ssc.nascom.nasa.gov/data/ins_data/secchi/L0/a/img/euvi/20070501/20070501_000400_n4euA.fts
;               IDL> a->read,files[0],/verbose
;
; History     : Written 13 May 2007, D. Zarro (ADNET)
;               Modified 31-Oct-2007 William Thompson (ADNET)
;                - modified for COR1/COR2
;               Modified 26 March 2009 - Zarro (ADNET)
;                - renamed index2map method to mk_map
;               13-Oct-2009, Zarro (ADNET)
;                - renamed mk_map to mk_secchi_map
;               25-May-2010, Zarro (ADNET)
;                - fixed bug causing roll_center to be offset relative
;                  to Sun center.
;               1-July-2010, Zarro (ADNET)
;                - fixed another bug with the roll_center offset. It
;                  never ends.
;               21-Nov-2011, Zarro (ADNET)
;                - added support for RICE compressed files.
;               20-Dec-2011, Zarro (ADNET)
;                - register SPICE DLM's during INIT
;               11-April-2012, Zarro (ADNET)
;                - fixed potential bug with RICE-compressed files on 
;                  Windows systems.
;               21-August-2012, Zarro (ADNET)
;                - switched to using WCS software for more accurate
;                  map coordinates.
;               5-July-2013, Zarro (ADNET)
;                - intercepted OUTSIZE keyword  
;               24-May-2014, Zarro (ADNET)
;                - added /APPEND when reading level 1 files
;               11-June-2014, Zarro (ADNET)
;                - added /KEEP_LIMB when resizing || rolling image
;               25-July-2015, Zarro (ADNET)
;                - removed unnecessary use of Z-buffer
;               7-April-2016, Zarro (ADNET)
;                - add /NO_PREP
;               16 July 2016, Zarro (ADNET)
;               - added input file decompress option
;               16 March 2017, Zarro (ADNET)
;               - added call to instrument-specific IDL_STARTUP
;               24 March 2017, Zarro (ADNET)
;               - ensure latest SPICE libraries are loaded
;               18 January 2018, Zarro (ADNET)
;               - load STEREO mission-level SPICE enviroment variables
;
; Contact     : dzarro@solar.stanford.edu
;-

function secchi::init,_ref_extra=extra

if ~self->fits::init(_extra=extra) then return,0

;-- setup environment

self->setenv,_extra=extra

return,1 & end

;------------------------------------------------------------------------
;-- setup SECCHI environment variables

pro secchi::setenv,_extra=extra

file_setenv,'$SSW/gen/setup/setup.stereo_env',_extra=extra

mklog,'SSW_SECCHI',local_name('$SSW/stereo/secchi')
if is_string(chklog('SECCHI_CAL')) then return

idl_startup=local_name('$SSW/stereo/secchi/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup

file_env=local_name('$SSW/stereo/secchi/setup/setup.secchi_env')
file_setenv,file_env,_extra=extra

;-- load SUNSPICE if package available

idl_startup=local_name('$SSW/packages/sunspice/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup

return & end

;-----------------------------------------------------------------------------
;-- check for SECCHI branch in !path

function secchi::have_path,err=err,verbose=verbose

err=''
if ~have_proc('sccreadfits') then begin
 epath=local_name('$SSW/stereo/secchi/idl')
 if is_dir(epath) then ssw_path,/secchi,/quiet
 if ~have_proc('sccreadfits') then begin
  err='STEREO/SECCHI branch of SSW not installed.'
  if keyword_set(verbose) then mprint,err
  return,0b
 endif
endif

;-- load sunspice for good measure

if ~have_proc('load_sunspice') then begin
 epath=local_name('$SSW/packages/sunspice/idl')
 if is_dir(epath) then ssw_path,/sunspice,/quiet
endif

if have_proc('start_stereo_spice') then start_stereo_spice

return,1b
end

;--------------------------------------------------------------------------
;-- FITS reader

pro secchi::read,file,data,_ref_extra=extra,err=err,verbose=verbose,no_prep=no_prep

forward_function discri_pobj,def_lasco_hdr
err=''

;-- download files if not present

self->getfile,file,local_file=cfile,err=err,_extra=extra,count=count
if count eq 0 then return

do_prep=~keyword_set(no_prep)
self->empty
have_path=self->have_path(err=err2)

j=0
nfiles=n_elements(cfile) 
for i=0,nfiles-1 do begin
 err='' & dfile=cfile[i]
 if is_string(err) then continue
 valid=self->is_valid(dfile,prepped=prepped,_extra=extra,err=err)
 if ~valid then begin
  mprint,err
  continue
 endif

;-- intercept outsize keyword

 if is_struct(extra) then begin
  if have_tag(extra,'out',pos,/start) then begin
   var=extra.(pos)
   chk=where(valid_num(var),count)
   if count eq n_elements(var) then begin
    outsize=var
    if n_elements(outsize) eq 1 then outsize=[outsize,outsize]
    extra=rem_tag(extra,pos)
    if ~is_struct(extra) then delvarx,extra
   endif
  endif
 endif

 if have_path && ~prepped && do_prep then begin
  secchi_prep,dfile,index,data,_extra=extra,/rectify,silent=~keyword_set(verbose)
 endif else begin
  if ~prepped then begin
   if ~have_path then xack,err2,/suppress
   mprint,'Skipping prepping.'
  endif
  self->fits::read,dfile,_extra=extra,/append,err=err
  if is_blank(err) then j=j+self->get(/count)
  continue
 endelse

 ;-- insert data into maps

 self->mk_map,index,data,j,err=err,_extra=extra,outsize=outsize,filename=dfile
 if is_string(err) then continue
 j=j+1
endfor

count=self->get(/count) 
if count eq 0 then mprint,'No maps created.'

return & end

;---------------------------------------------------------------------
;-- store INDEX && DATA into MAP objects

pro secchi::mk_map,index,data,i,err=err,_ref_extra=extra,$
           roll_correct=roll_correct,earth_view=earth_view,outsize=outsize


err=''
if ~is_number(i) then i=0

;-- check inputs

if ~is_struct(index) || (n_elements(index) ne 1) then begin
 err='Input index is not a valid structure.'
 mprint,err
 return
endif

ndim=size(data,/n_dim)
if (ndim ne 2) then begin
 err='Input image is not a 2-D array.'
 mprint,err
 return
endif

;-- add STEREO-specific properties

id=index.OBSRVTRY+' '+index.INSTRUME+' '+index.DETECTOR+' '+trim(index.WAVELNTH)
wcs=fitshead2wcs(index)
if ~valid_wcs(wcs) then begin
 err='Invalid WCS header.'
 mprint,err
 return
endif

wcs2map,data,wcs,map,id=id,/no_copy
earth_view=keyword_set(earth_view)
roll_correct=keyword_set(roll_correct)
resize=exist(outsize)
case 1 of
 earth_view: self->earth_view,index,map,_extra=extra,outsize=outsize
 roll_correct: self->roll_correct,index,map,_extra=extra,outsize=outsize
 resize: begin
  mprint,'Resizing to ['+trim(outsize[0])+','+trim(outsize[1])+']...'
  map=drot_map(map,outsize=outsize,/keep_limb)
  self->update_pc,index,map
 end
 else: do_nothing=1
endcase

if ~have_tag(index,'filename') then index=add_tag(index,'','filename')
if is_string(filename) then index.filename=file_basename(filename)

self->set,i,map=map,/no_copy
self->set,i,index=index
self->set,i,/limb,grid=30,_extra=extra
self->set_colors,i,index

return & end

;-----------------------------------------------------------------------
pro secchi::roll_correct,index,map,_extra=extra

if ~valid_map(map) || ~is_struct(index) then return
if (nint(index.crota) mod 360.) eq 0 then begin
 mprint,'Map already roll-corrected.'
 return
endif

;-- roll correct

mprint,'Correcting for spacecraft roll...'

map=drot_map(map,roll=0.,_extra=extra,/same_center,/keep_limb)
index.crota=0.
self->update_pc,index,map

return & end

;-------------------------------------------------------------------------
pro secchi::earth_view,index,map,_extra=extra

if ~valid_map(map) || ~is_struct(index) then return

mprint,'Correcting to Earth-view...'
map=map2earth(map,/remap,_extra=extra)
index.hglt_obs=map.b0
index.hgln_obs=map.l0
index.rsun=map.rsun
index.crota=0.
self->update_pc,index,map

return & end

;--------------------------------------------------------------------------
pro secchi::update_pc,index,map

index.pc1_1=1 & index.pc1_2=0 & index.pc2_1=0 & index.pc2_2=1
nx=index.naxis1 & ny=index.naxis2
index.crpix1=comp_fits_crpix(map.xc,map.dx,nx,index.crval1)                                            
index.crpix2=comp_fits_crpix(map.yc,map.dy,ny,index.crval2)

return & end

;--------------------------------------------------------------------------
;-- VSO search function

function secchi::search,tstart,tend,_ref_extra=extra,$
                           type=type

f=vso_files(tstart,tend,inst='secchi',_extra=extra,wmin=wmin,window=3600.)
if arg_present(type) && exist(wmin) then type=string(wmin,'(I5.0)')+' A'
return,f

end

;------------------------------------------------------------------------------
;-- save SECCHI color table

function secchi::have_colors,index,red,green,blue

common secchi_colors,scolors

if ~have_proc('secchi_colors') then return,0b
if ~is_struct(index) then return,0b

if is_struct(scolors) then begin
 chk=where((index.detector eq scolors.detector) and $
           (index.wavelnth eq scolors.wavelnth),count)
 if count eq 1 then begin
  red=(scolors[chk]).red
  green=(scolors[chk]).green
  blue=(scolors[chk]).blue
  return,1b
 endif
endif

dsave=!d.name
set_plot,'Z'
tvlct,rold,gold,bold,/get
secchi_colors,index.detector,index.wavelnth,red,green,blue
tvlct,rold,gold,bold
set_plot,dsave

colors={detector:index.detector,wavelnth:index.wavelnth,red:red,green:green,blue:blue}
scolors=merge_struct(scolors,colors)

return,1b & end

;------------------------------------------------------------------------------
;-- check if valid SECCHI file

function secchi::is_valid,file,err=err,detector=detector,$
                  prepped=prepped,_extra=extra

prepped=0 
instrument=''
mrd_head,file,header,err=err
if is_string(err) then return,0b

s=fitshead2struct(header)
if have_tag(s,'inst',/start,index) then sinstrument=strup(s.(index[0]))
if sinstrument ne 'SECCHI' then begin
 err='Invalid SECCHI file - '+file
 return,0b
endif

if have_tag(s,'dete',/start,index) then sdetector=strup(s.(index[0]))
if is_string(detector) && is_string(sdetector) then begin
 if strmid(strupcase(detector),0,4) ne strmid(strupcase(sdetector),0,4) then begin
  err='Invalid SECCHI/'+strup(detector)+' file - '+file
  return,0b
 endif
endif

if have_tag(s,'history') then begin
 chk=where(stregex(s.history,'(Applied Flat Field)|(Applied calibration factor)',/bool,/fold),count)
 prepped=count gt 0
endif

return,1b

end

;------------------------------------------------------------------------
;-- SECCHI data structure

pro secchi__define,void                 

void={secchi, inherits fits, inherits prep}

return & end
