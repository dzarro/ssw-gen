;+
; Project     : SOHO - CDS
;
; Name        : RECOMPILE
;
; Purpose     : recompile a routine
;
; Category    : utility
;
; Explanation : a shell around RESOLVE_ROUTINE (> vers 4) that checks
;               if compiled routine is not recursive, otherwise 
;               recompile will stop suddenly.
;
; Syntax      : IDL> recompile,proc
;
; Inputs      : PROC = procedure name
;
; Keywords    : /IS_FUNCTION - set if routine is a function
;               /SKIP - set to skip if already compiled
;               /QUIET - set to not show compile messages
;               /USE_PATH - if set and proc contains a path name,
;                            compile version in path directory
;
; Side effects: PROC is recompiled
;
; History     : 1-Sep-1996,  Zarro (ARC/GSFC)  Written
;               20-May-1999, Zarro (SM&A/GSFC) - added /SKIP 
;               12-Aug-2000, Zarro (EIT/GSFC) - added /QUIET
;               7-Sept-2001, Zarro (EIT/GSFC) - added check for 
;                existing file
;               21-Dec-2016, Zarro (ADNET) - added /COMPILE_FULL
;               6-Oct-2018, Zarro (ADNET) - added /USE_PATH
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro recompile,proc,is_function=is_function,status=status,skip=skip,$
               quiet=quiet,use_path=use_path,_extra=extra,err=err,debug=debug

quiet=keyword_set(quiet)
use_path=keyword_set(use_path)
debug=keyword_set(debug)
skip=keyword_set(skip)

err=''
status=0b

if is_blank(proc) then begin
 err='Input file name required.'
 return
endif

cd,current=cdir

;-- get list of compiled routines if planning to skip

if skip then begin
 compiled=routine_info()
 compiled=[compiled,routine_info(/functions)]
 compiled=strtrim(strlowcase(compiled),2)
endif

nproc=n_elements(proc)
for i=0,n_elements(proc)-1 do begin
 status=0b
 err=''
 error=0
 catch,error
 if (error ne 0) then begin
  err=err_state() 
  if debug then mprint,err
  catch,/cancel & message,/reset
  cd,cdir & continue
 endif


 lfile=local_name(proc[i])
 break_file,lfile,dsk,dir,name,ext
 path=dsk+dir
 name=strlowcase(name)
 keep_path=is_string(path) && use_path

 if use_path then begin
  if ~file_test(lfile,/regular) then begin
   err='Input file does not exist - '+proc[i]
   mprint,err
   continue
  endif 
 endif else begin
  if ~have_proc(proc[i]) then begin
   err=name+' not found.'
   if debug then mprint,err  
   continue
  endif
  
  if skip then begin
   chk=where(name eq compiled,count)
   if count gt 0 then begin
    if debug then mprint,name+' already compiled.'
    continue 
   endif
  endif
 endelse

;-- can't compile if called recursively

 if was_called(name) then begin
  err=name+' being called recursively. Cannot compile.'
  if debug then mprint,err
  continue
 endif

 if quiet then begin
  squiet=!quiet
  !quiet=1
 endif
 
 if keep_path then begin
  if debug then mprint,'Compiling '+lfile
  cd,path
 endif
 
resolve_routine,name,/either,/compile_full,_extra=extra
 if keep_path then cd,cdir
 if quiet then !quiet=squiet
 status=1b

endfor

return & end
