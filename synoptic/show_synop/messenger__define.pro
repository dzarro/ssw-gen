;+
; Project     : RHESSI
;
; Name        : MESSENGER__DEFINE
;
; Purpose     : Define a messenger data object.  Search method finds MESSENGER XRS data files for specified times on
;               remote site and returns list of URLs.  Default host and dir to search are defined in object, but user 
;               can also control them through environment variables MESSENGER_XRS_HOST and MESSENGER_XRS_TOPDIR, e.g.
;                 setenv,'MESSENGER_XRS_HOST=https://umbra.nascom.nasa.gov'
;                 setenv,'MESSENGER_XRS_TOPDIR=/messenger'
;
; Category    : Synoptic Objects
;
; Syntax      : IDL> c=obj_new('messenger')
;
; History     : Written 8-Feb-2010, Zarro (ADNET)
;               Modified 31-July-2013, Zarro (ADNET)
;                - added paren around file ext for stregex to work
;               Modified 1-Jul-2020, Kim Tolbert
;                - changed primary host to umbra (from hesperia) and allow environment variables to set host and topdir
;               Modified 22-Aug-2020, Kim Tolbert
;                - added https:// to rhost definition for older versions of IDL
;               Modified 10-Sep-2020, Kim Tolbert
;               - added add_file method to make sure we include both .dat and .lbl files. Called in show_synop::rcopy.
;
; Contact     : dzarro@standford.edu
;-
;----------------------------------------------------------------

function messenger::init,_ref_extra=extra

if ~self->synop_spex::init() then return,0

rhost = chklog('MESSENGER_XRS_HOST')  
if rhost eq '' then rhost = 'https://umbra.nascom.nasa.gov'
topdir = chklog('MESSENGER_XRS_TOPDIR')
if topdir eq '' then topdir = '/messenger'
self->setprop,rhost=rhost,ext='(dat|lbl)',org='year',$
                 topdir=topdir,/full,/round

return,1
end

;----------------------------------------------------------------
;-- search method 

function messenger::search,tstart,tend,count=count,type=type,_ref_extra=extra

type=''
files=self->site::search(tstart,tend,_extra=extra,count=count)
if count gt 0 then type=replicate('sxr/lightcurves',count) else files=''
if count eq 0 then message,'No files found.',/cont

return,files
end

;----------------------------------------------------------------

function messenger::parse_time,file,_ref_extra=extra

fil = file_break(file)
year = strmid(fil, 3, 4)
doy = strmid(fil, 7, 3)
return, anytim(doy2utc(doy, year),/tai)
;return, anytim2tai(file_break(file,/no_ext))

end

;----------------------------------------------------------------

; function add_file makes sure that both the .dat and .lbl files are included. Both are needed.
function messenger::add_file, rfiles
bases = file_break(rfiles, /no_extension, path=paths)
bases = get_uniq(bases)
return, [concat_dir(paths,bases+'.dat'), concat_dir(paths,bases+'.lbl')]
end

;----------------------------------------------------------------

pro messenger__define                 
void={messenger, inherits synop_spex}
return & end

