;+
; Project     : SOHO - CDS
;
; Name        : UNIX_SPAWN
;
; Purpose     : spawn a shell command and return STDIO and STDERR
;
; Category    : System
;
; Explanation : regular IDL spawn command doesn't return an error message
;
; Syntax      : IDL> unix_spawn,cmd,out
;
; Inputs      : CMD = command(s) to spawn
;
; Keywords    : COUNT = n_elements(out)
;               NOWAIT = background the commands
;               NOSHELL = bypass shell
;               ERR = error string
;
; Outputs     : OUT = output of CMD
;
; History     : Version 1,  18-Jan-2001, Zarro (EIT/GSFC)
;               20-Jan-01, Zarro (EITI/GSFC) - added IDL 5.4 capability
;               4-Dec-06, Zarro (ADNET/GSFC) - added improved /NOWAIT
;               29-Dec-14, Zarro (ADNET)
;                - fixed bug where ERR was not being returned
;                - removed EXECUTE
;               31-Jan-16, Zarro (ADNET)
;                - replaced AND's by &&
;               7-Jun-2019, Zarro (ADNET) 
;                - removed duplicate output printing
;               8-Jun-2020, Zarro (ADNET)
;                - test for spaces in directory names
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro unix_spawn,cmd,out,err=err,count=count,test=test,noshell=noshell,$
                  nowait=nowait,_ref_extra=extra

err='' & count=0
os=os_family(/lower)
if is_blank(cmd) || (os ne 'unix') then begin
 out=''
 return
endif

print_out=~arg_present(out)
noshell=keyword_set(noshell)
nowait=keyword_set(nowait)
out=''

;--simple case first

if ~nowait && ~noshell && n_elements(cmd) eq 1 then begin
 if print_out then $
 spawn,cmd,count=count,/stderr else $
  spawn,cmd,out,err,count=count
 if is_string(err) then err=arr2str(err)
 return
endif

;-- create temporary command file (BATCH_FILE) in which to insert all commands. 
;   This command is then executed by spawn once.

flag=''
if noshell then flag='-f'
batch_file=get_temp_file('_unix_spawn.csh')
cdir=local_name(curdir())
cdir='"'+cdir+'"'
file_append,batch_file,['#!/bin/csh '+flag,'cd '+cdir,cmd,'exit'], /new
file_chmod,batch_file,/a_execute
ncmd=batch_file
if nowait then ncmd=batch_file+' &'

;-- if using /noshell and /nowait, wrap command in a second temporary file which
;   is backgrounded

if nowait && noshell then begin
 batch_file2=get_temp_file('_unix_spawn2.csh')
 tdir=file_dirname(ncmd)
 tfile=file_basename(ncmd)
 file_append,batch_file2,['#!/bin/csh '+flag,'cd '+tdir,tfile,'exit'], /new
 file_chmod,batch_file2,/a_execute
 ncmd=batch_file2
endif

if keyword_set(test) then begin
 message,'testing...',/cont
 print,ncmd
 stop
endif

if noshell then ncmd=[ncmd]
if print_out then $
 spawn,ncmd,count=count,/stderr,noshell=noshell else $
  spawn,ncmd,out,err,count=count,noshell=noshell

if n_elements(out) eq 1 then out=out[0] 
if is_string(err) then err=arr2str(err)
if is_string(batch_file) then file_delete,batch_file,/quiet,/allow_non
if is_string(batch_file2) then file_delete,batch_file2,/quiet,/allow_non

return & end
