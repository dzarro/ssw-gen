;+
; Project     : VSO
;                  
; Name        : FILE_TOUCH
;               
; Purpose     : Change access and modification file/directory times using TOUCH
;                             
; Category    : system utility 
;               
; Syntax      : IDL> file_touch,file,time
;
; Inputs:     : FILE = file or directory name
;               TIME = time to set file access and modification times to
;               [can also be another file, in which case its access
;               and modification times will be used]
;
; Outputs     : None
;
; Keywords    : /ACCESS = change access time 
;               /MODIFICATION = change modification time
;               /NO_DAYLIGHT_SAVING = don't correct for DST (Windows only)
;               
; Side effects: Input file access and modification times changed
;               
; History     : 15-Nov-2014, Zarro (ADNET/GSFC) - written
;               24-Sep-2016, Zarro (ADNET/GSFC)
;               - encase file name in " " to protect against curious
;                 characters (non-Windows only) 
;               23-Jan-2019, Zarro (ADNET/GSFC) - removed READ/WRITE check
;                3-Mar-2019, Zarro (ADNET/GSFC) - replaced FILE_TEST with FILE_SEARCH
;               19-Mar-2019, Zarro (ADNET) - add DIRECTORY support
;                1-Apr-2019, Zarro (ADNET) - made modification the default
;               16-Nov-2019, Zarro (ADNET) - added call to WIN_TOUCH
;
; Contact     : dzarro@solar.stanford.edu
;-    


pro file_touch,file,time,access=access, modification=modification,$
               err=err,_ref_extra=extra,output=output,no_daylight_savings=no_daylight_savings


err=''
cmd='touch'
windows=os_family(/lower) eq 'windows'
if is_blank(time) then time=!stime

if is_blank(file) || (n_elements(file) gt 1) then begin
 err='Input must be scalar string.' 
 mprint,err & return
endif
 
chk=file_search(file,count=fcount,/fully_qualify,/expand_envir)
if fcount ne 1 then begin
 err='Input not found.' 
 mprint,err & return
endif
dfile=chk[0]

if windows then begin
; cmd=local_name('$SSW/gen/exe/windows/touch.exe')
 cmd=win_touch()
 chk=file_search(cmd,count=count)
 if count eq 0 then begin
  err='Windows Touch executable not found.' 
  mprint,err & return
 endif
endif

if ~valid_time(time) then begin
 chk=file_search(time,count=count,/fully_qualify,/expand_envir)
 if count eq 0 then begin
  err='Reference time not entered.' 
  mprint,err & return
 endif
 ftime=chk[0]
endif

flag='-m'
if keyword_set(access) then flag='-a'
if ~windows then flag='-f '+flag

if ~windows then begin 
 if ~stregex(dfile,'^"',/bool) || stregex(dfile,'$"',/bool) then dfile='"'+dfile+'"'
endif

if valid_time(time) then begin
 dtime=anytim(time,/ext)
 stime=trim(dtime[6])+ string(dtime[5],'(i2.2)')+$
                       string(dtime[4],'(i2.2)')+$
                       string(dtime[0],'(i2.2)')+$
                       string(dtime[1],'(i2.2)')+'.'+$
                       string(dtime[2],'(i2.2)')
 cmd=cmd+' '+flag+' -t '+stime+' '+dfile
endif else cmd=cmd+' '+flag+' -r '+ftime+' '+dfile

dprint,'% cmd: ',cmd

espawn,cmd,output,_extra=extra,err=err,/noshell
if is_string(err) then begin
 mprint,err & return
endif

;-- DST bug fix

dst=~keyword_set(no_daylight_savings)
if windows && dst then begin 
 ntime=anytim(file_time(dfile))
 if valid_time(time) then tref=anytim(time) else tref=anytim(file_time(time))
 diff=float(nint(ntime-tref))
 if diff ne 0. then begin
  dprint,'%diff ',diff
  ctime=anytim(ntime-2*diff,/vms)
  file_touch,dfile,ctime,access_only=access_only, modification_only=modification_only,$
   output=output,_extra=extra,/no_daylight_savings,err=err
 endif
endif
return & end
