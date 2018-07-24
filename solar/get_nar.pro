;+
; Project     : SOHO - CDS
;
; Name        : GET_NAR
;
; Purpose     : Wrapper around RD_NAR
;
; Category    : planning
;
; Explanation : Get NOAA AR pointing from $DIR_GEN_NAR files
;
; Syntax      : IDL>nar=get_nar(tstart)
;
; Inputs      : TSTART = start time 
;
; Opt. Inputs : TEND = end time
;
; Outputs     : NAR = structure array with NOAA info
;
; Keywords    : COUNT = # or entries found
;               ERR = error messages
;               QUIET = turn off messages
;               NO_HELIO = don't do heliographic conversion
;               LIMIT= limiting no of days in time range
;               UNIQUE = return unique NOAA names
;               REMOTE = force searching remote LMSAL archive
;               SWPC = search remote SWPC archive if RD_NAR fails
;
; History     : 20-Jun-1998, Zarro (EITI/GSFC) - written
;               20-Nov-2001, Zarro - added extra checks for DB's
;               24-Nov-2004, Zarro - fixed sort problem
;                3-May-2007, Zarro - added _extra to pass keywords to hel2arcmin
;               22-Aug-2013, Zarro - filtered entries from outside
;                                    requested period
;               31-Mar-2015, Zarro - added check for valid NAR
;                                    directory
;               23-Jun-2018, Zarro - added REMOTE & SWPC keywords
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function get_nar,tstart,tend,count=count,err=err,quiet=quiet,_ref_extra=extra,$
                 no_helio=no_helio,limit=limit,unique=unique,$
                 remote=remote,status=status,swpc=swpc

err=''
delvarx,nar
count=0
loud=~keyword_set(quiet)
do_remote=keyword_set(remote)
unique=keyword_set(unique)

;-- start with error checks

if ~have_proc('rd_nar') then begin
 sxt_dir='$SSW/yohkoh/gen/idl'
 if is_dir(sxt_dir,out=sdir) then add_path,sdir,/append,/expand
 if ~have_proc('rd_nar') then begin
  err='Cannot find RD_NAR in IDL !path.'
  mprint,err
  return,''
 endif
endif

;-- check if NOAA active region files are loaded

if ~do_remote then begin
 ok=is_dir(chklog('DIR_GEN_NAR'))
 if ~ok then begin
  sdb=chklog('SSWDB')
  if sdb ne '' then begin
   dir_gen_nar=concat_dir(sdb,'yohkoh/ys_dbase/nar')
   if is_dir(dir_gen_nar) then mklog,'DIR_GEN_NAR',dir_gen_nar
  endif
  if chklog('DIR_GEN_NAR') eq '' then begin
   err='Cannot locate NOAA files in $DIR_GEN_NAR. Trying remote search.'
   do_remote=1b
   mprint,err
;  return,''
  endif
 endif
endif

if do_remote then recompile,'sock_goes'

err=''
t1=get_def_times(tstart,tend,dend=t2,/int)
if is_number(limit) then begin
 if (abs(t2.mjd-t1.mjd) gt limit) then begin
  err='Time range exceeds current limit of '+num2str(limit)+' days.'
  if loud then mprint,err
  return,''
 endif
endif

;-- call RD_NAR

if loud then begin
 mprint,'Retrieving NAR data between '+anytim2utc(t1,/vms)+' and '+anytim2utc(t2,/vms)
endif

rd_nar,anytim2utc(t1,/vms),anytim2utc(t2,/vms),nar,_extra=extra,status=status

if keyword_set(swpc) then begin
 if (status ne 0) then begin
  nar=get_swpc(t1,t2,err=err,count=count,unique=0b,/no_helio,_extra=extra)
 endif 
endif

if ~is_struct(nar) then begin
 err='No NOAA data found for specified time(s).'
 mprint,err
 return,''
endif

;-- determine unique AR pointings

count=n_elements(nar)
if unique then nar=sort_nar(nar,/unique,count=count)

;-- append heliocentric pointing tags

if ~keyword_set(no_helio) then nar=helio_nar(nar)

return,nar

end


