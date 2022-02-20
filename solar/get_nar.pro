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
; Syntax      : IDL> nar=get_nar(tstart)
;
; Inputs      : TSTART = start time 
;
; Opt. Inputs : TEND = end time [def = end of day]
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
;               ALL = return all NOAA names (UNIQUE=0)
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
;               17-Nov-2018, Zarro - made SWPC and UNIQUE defaults
;               27-Jan-2019, Zarro - made REMOTE and NEAREST defaults
;               30-Mar-2019, Zarro - made SWPC default again
;               18-Apr-2019, Zarro - made OLD way the default again
;                7-Jan-2020, Zarro - added /ALL
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function get_nar,tstart,tend,count=count,err=err,quiet=quiet,_ref_extra=extra,$
                 no_helio=no_helio,limit=limit,unique=unique,$
                 remote=remote,status=status,swpc=swpc,all=all

err=''
nar=''
count=0
loud=~keyword_set(quiet)

do_remote=1b
if is_number(remote) then if fix(remote) eq 0 then do_remote=0b
do_unique=1b
if is_number(unique) then if fix(unique) eq 0 then do_unique=0b
if keyword_set(all) then do_unique=0b

do_swpc=keyword_set(swpc)

;-- redirect to SWPC

if do_swpc then begin
 if loud then mprint,'Trying SWPC..'
 nar=get_swpc(tstart,tend,err=err,count=count,unique=do_unique,$
             quiet=quiet,_extra=extra,/nearest,no_helio=no_helio,status=status)
 return,nar
endif

;-- start with error checks

err=''
t1=get_def_times(tstart,tend,dend=t2,/int)
if is_number(limit) then begin
 if (abs(t2.mjd-t1.mjd) gt limit) then begin
  err='Time range exceeds current limit of '+num2str(limit)+' days.'
  mprint,err
  return,''
 endif
endif

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

;-- call RD_NAR

if do_remote then recompile,'sock_goes'

if loud then begin
 mprint,'Searching for NOAA data between '+anytim2utc(t1,/vms)+' and '+anytim2utc(t2,/vms)
endif

rd_nar,anytim2utc(t1,/vms),anytim2utc(t2,/vms),nar,_extra=extra,/nearest,status=status

;-- determine unique AR pointings & append heliocentric pointing tags

if is_struct(nar) then begin
 count=n_elements(nar)
 if do_unique then nar=sort_nar(nar,/unique,count=count)
 if ~keyword_set(no_helio) then nar=helio_nar(nar)
 return,nar
endif

emess='No NOAA data found for specified time(s).'
if count eq 0 then begin
 nar=''
 if loud then mprint,emess
endif

return,nar

end


