;+
; Project     : VSO
;
; Name        : IDL_BRIDGE__DEFINE
;
; Purpose     : Wrapper around IDL_IDLBRIDGE class to override SETVAR
;               and GETVAR methods in order to allow passing structures,
;               pointers, and objects.
;
; Category    : Objects
;
; Syntax      : IDL> o=obj_new('idl_bridge')
;
; Outputs     : O = IDL bridge object
;
; Keywords    : See IDL_IDLBRIDGE class definition
;
; History     : 21-November-2015, Zarro (ADNET) - Written
;               19-March-2016, Zarro (ADNET) 
;               - passed !QUIET to bridge
;               18-June-2016, Zarro (ADNET)
;               - added SETENV/GETENV methods
;               30-Jan-2017, Zarro (ADNET)
;               - added check for IDL_STARTUP
;               27-July-2017, Zarro (ADNET)
;               - made IDL_STARTUP more robust
;               6-March-2022, Zarro (ADNET)
;               - added GETPROPERTY wrapper to return OPS
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function idl_bridge::init,_ref_extra=extra,err=err,verbose=verbose,ops=ops

err=''
if ~since_version('8.2.3') then begin
 err='Need at least IDL version 8.2.3'
 mprint,err
 return,0
endif

verbose=keyword_set(verbose)
error=0
catch, error
if (error ne 0) then begin
; if ~stregex(err_state(),'OPENR: Error opening file. Unit: 100',/bool) then begin
;  err=err_state()
; mprint,err
;  if obj_valid(self) then obj_destroy,self
;  catch,/cancel
;  return,0
; endif
 if verbose then mprint,err_state()
 catch,/cancel
 message,/reset
 if is_string(curr) then begin
  cmd='cd,"'+curr+'"' 
  self->execute,cmd
 endif
 self->execute,'clean_path'
 return,1
endif

;-- allow for 32 bit

if is_number(ops) then begin
 if (ops eq 32) || (ops eq 64) then iops=ops
endif else iops=64

s=self->idl_idlbridge::init(_extra=extra,ops=iops)
if s eq 0 then return,0

self.ops=iops

;-- run SSW startup

quiet=strtrim(!quiet,2)
cd,current=curr

cmd='!quiet='+quiet
self->execute,cmd
os=!version.os_family
if os eq 'Windows' then delim='\' else delim='/'
ssw_system=strjoin([getenv('SSW'),'gen','idl','ssw_system'],delim)
if file_test(ssw_system,/dir) then begin
 if verbose then mprint,'Executing SSW startup...'
 cmd='cd,"'+ssw_system+'"'
 self->execute,cmd
 cmd='ssw_load'
 if verbose then cmd=cmd+',/verbose,/inform'
 self->execute,cmd
 cmd='cd,"'+curr+'"'
 self->execute,cmd
 self->execute,'clean_path'
endif

return,1

end

;-----------------------------------------------

pro idl_bridge::getproperty,ops=ops,_ref_extra=extra

if is_string(extra) then self->idl_idlbridge::getproperty,_extra=extra
if arg_present(ops) then ops=self.ops
return
end

;-----------------------------------------------

pro idl_bridge::setvar,name,value,no_copy=no_copy,err=serr

serr=''
no_copy=keyword_set(no_copy)

if is_blank(name) || (n_params() eq 1) then return
if n_elements(value) eq 0 then begin
 cmd='destroy,'+name
 self->execute,cmd
 return
endif

type=size(value,/type)

;-- look for special cases (structure, pointer, object)

chk=where(type eq [8,10,11],count)
if count eq 0 then begin
 self->idl_idlbridge::setvar,name,value
endif else begin
 dimensions=size(value,/dimensions)
 buffer=data_stream(value)
 if type eq 11 then begin
  class=obj_class(value)
  cmd="void=obj_new('"+class+"')"
  self->execute,cmd
 endif
 self->idl_idlbridge::setvar,name,buffer
 self->idl_idlbridge::setvar,'type',type
 self->idl_idlbridge::setvar,'dimensions',dimensions
 cmd=name+'=data_unstream('+name+',type=type,dimensions=dimensions,/no_copy,err=serr)'
 self->execute,cmd
 serr=self->idl_idlbridge::getvar('serr')
endelse

if string(serr) then mprint,serr else if no_copy then destroy,value

return
end

;------------------------------------------------

function idl_bridge::getvar,name,no_copy=no_copy,err=gerr

gerr=''
no_copy=keyword_set(no_copy)
if is_blank(name) then return,null()
cmd='type=size('+name+',/type)'
self->execute,cmd
type=self->idl_idlbridge::getvar('type')
if type eq 0 then begin
; err='Non-existent variable - '+name
; mprint,err
 return,null()
endif

;-- look for special cases (structure, pointer, object)

chk=where(type eq [8,10,11],count)
if count eq 0 then begin
 value=self->idl_idlbridge::getvar(name)
endif else begin
 buffer_name='r'+session_id()
 cmd=buffer_name+'=data_stream('+name+',dimensions=dimensions,err=gerr)'
 self->execute,cmd
 gerr=self->idl_idlbridge::getvar('gerr')
 if is_blank(gerr) then begin
  buffer=self->idl_idlbridge::getvar(buffer_name)
  dimensions=self->idl_idlbridge::getvar('dimensions')
  value=data_unstream(buffer,type=type,dimensions=dimensions,err=gerr,/no_copy)
  gerr=self->idl_idlbridge::getvar('gerr')
  cmd='destroy,'+buffer_name
  self->execute,cmd
 endif
endelse

if is_string(gerr) then begin
 mprint,gerr
 value=null()
endif else begin
 if no_copy then begin
  cmd='destroy,'+name
  self->execute,cmd
 endif
endelse

return,value 

end

;------------------------------------------------------------
;-- set environment variable in bridge environment
 
pro idl_bridge::setenv,name,value
if is_blank(name) || ~exist(value) then return
name=strtrim(name,2)
dvalue=session_id()
self->setvar,dvalue,value
cmd='mklog,"'+name+'",'+dvalue
self->execute,cmd
return
end

;-------------------------------------------------------------
;-- get environment variable from bridge environment

function idl_bridge::getenv,name
if is_blank(name) then return,''
name=strtrim(name,2)
dvalue=session_id()
cmd=dvalue+'=chklog("'+name+'")'
self->execute,cmd
dvalue=self->getvar(dvalue)
return,dvalue
end

;-----------------------------------------------
pro idl_bridge__define

temp={idl_bridge, ops:0L,inherits idl_idlbridge, inherits idl_object}

return & end
