;+
; Project     : VSO
;                  
; Name        : FILE_TOUCH
;               
; Purpose     : Change access and modification file times using TOUCH
;                             
; Category    : system utility 
;               
; Syntax      : IDL> file_touch,file,time
;
; Inputs:     : FILE = file name
;               TIME = time to set file access and modification times to
;               [can also be another file, in which case its access
;               and modification times will be used]
;
; Outputs     : None
;
; Keywords    : /ACCESS_ONLY = change access time only
;               /MODIFICATION_ONLY = change modification time only
;               /NO_DAYLIGHT_SAVING = don't correct for DST (Windows only)
;               
; Side effects: Input file access and modification times changed
;               
; History     : 15-Nov-2014, Zarro (ADNET) - written
;               24-Sep-2016, Zarro (ADNET)
;               - encase file name in " " to protect against curious
;                 characters (non-Windows only) 
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro file_touch,file,time,access_only=access_only, modification_only=modification_only,$
               err=err,_ref_extra=extra,output=output,no_daylight_savings=no_daylight_savings


cmd='touch'
windows=os_family(/lower) eq 'windows'

case 1 of
 is_blank(file): err='Missing or invalid input file.'
 n_elements(file) gt 1: err='Input file must be scalar.'
 ~file_test(file,/read,/write): err='Input file does not have read/write permissions.'
 is_blank(time): err='Reference time not entered.'
 ~valid_time(time) && ~file_test(time,/read): err='Reference time file not entered.'
 windows: begin
  cmd=local_name('$SSW/gen/exe/windows/touch.exe')
  if ~file_test(cmd,/exe) then err='Windows touch executable not found.'
 end
 else: err=''
endcase

if is_string(err) then begin
 mprint,err
 return
endif

flag='-a -m'
if keyword_set(access_only) && ~keyword_set(modification_only) then flag='-a'
if keyword_set(modification_only) && ~keyword_set(access_only) then flag='-m'
if ~windows then flag='-f '+flag

dfile=strtrim(file,2)
if os_family(/lower) ne 'windows' then begin 
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
endif else cmd=cmd+' '+flag+' -r '+time+' '+dfile

dprint,'% cmd: ',cmd

espawn,cmd,output,_extra=extra,err=err,/noshell
if is_string(err) then return

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
   output=output,_extra=extra,/no_daylight_savings
 endif
endif
return & end
