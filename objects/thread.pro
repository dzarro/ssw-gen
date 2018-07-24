;+
; Project     : VSO
;
; Name        : THREAD
;
; Purpose     : Wrapper around IDL-IDLBridge object to run any procedure
;               in a background thread
;
; Category    : utility objects
;
; Example     : 
;              IDL> thread,'proc',arg1,arg2,...arg10,key1=key1,key2=key2...
;              IDL> thread,'out=func',arg1,arg2,..,key1=key1,...
;              IDL> thread,'obj->method',arg1,arg2,...arg10,key1=key1,key2=key2..

; Inputs      : PROC = procedure or function
;               ARGi = arguments accepted by proc/func (up to 10)
;
; Keywords    : KEYi = keywords accepted by proc/func
;               NEW_THREAD = set to create a new thread object each
;               time [def = reuse last thread object]
;               ID_THREAD = unique ID string for thread object
;               RESET_THREAD = kill all running threads
;               OPS = OS memory bit to run in (e.g. 32)
;
; History     : 22-Feb-2012, Zarro - Written
;               27-Jan-2015, Zarro 
;               - added support for returning modified
;                 arguments/keywords 
;               13-Feb-2015, Zarro
;               - added /NEW_THREAD
;               16-June-2016, Zarro (ADNET)
;               - added OPS keyword
;               6-Sept-2016, Zarro (ADNET)
;               - added support for threading object method calls
;               2-Sept-2017, Zarro (ADNET)
;               - pass completion message in ID_THREAD
;-

;--- call back routine to notify when thread is complete

pro thread_callback, status, error, oBridge, userdata

common thread,obridge_sav,ocontainer

;-- check for modified input/output variables and return to scope of caller

 ndata=n_elements(userdata)
 if ndata gt 0 then begin
  new_obj=userdata[0].var_input eq 'new'
  id_obj=userdata[0].var_name
  for i=1,ndata-1 do begin
   var_name=userdata[i].var_name
   var_input=userdata[i].var_input
   var_level=userdata[i].var_level
   if (var_name ne '') && (var_input ne '') then begin
    var_val=obridge->getvar(var_name,/no_copy)
    if n_elements(var_val) eq 0 then var_val=null()
    (scope_varfetch(var_input,level=var_level,/enter))=var_val
   endif
  endfor
 endif

;-- signal completion

 case status of
  4: mess='Aborted.'
  3: mess='Completed, but with following warnings:'
  else: mess='Completed.'
 endcase

 if new_obj then begin
  if obj_valid(obridge) then obj_destroy,obridge
  mess=id_obj+' '+mess
  if obj_valid(ocontainer) then ocontainer->remove,obridge
 endif 

 mprint,mess
 tname=userdata[0].var_name
 (scope_varfetch(tname,level=1,/enter))=mess
 
 if error ne '' then begin
  mprint,error
 endif

 return & end

;---------------------------------------------------------------------------------

pro thread,proc,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,_ref_extra=extra,$
                reset_thread=reset_thread,$
                new_thread=new_thread,id_thread=id_thread,wait_thread=wait_thread

common thread,obridge_sav,ocontainer


if keyword_set(reset_thread) then begin
 if obj_valid(obridge_sav) then obj_destroy,obridge_sav
 if obj_valid(ocontainer) then obj_destroy,ocontainer
 return
endif

;-- restore last used thread from common (if not new thread)

new_thread=keyword_set(new_thread)
if ~obj_valid(ocontainer) then ocontainer=obj_new('idl_container') 
if ~new_thread && obj_valid(obridge_sav) then obridge=obridge_sav

;-- set a catch in case of errors

error=0
catch, error
if (error ne 0) then begin
 mprint,err_state()
; if obj_valid(obridge) then obj_destroy,obridge
; if obj_valid(ocontainer) then ocontainer->remove,obridge
 catch,/cancel
 return
endif

;-- check we can open an X-window

;a=widget_base(map=0)
;widget_control,a,/destroy

;-- ensure thread object has same IDL environment/path as parent

if ~obj_valid(obridge) then begin
 obridge = Obj_New('IDL_Bridge',callback='thread_callback',_extra=extra)
 if ~obj_valid(obridge) then return
endif else begin
 obridge->execute,'message,/reset & catch,/cancel & retall'
endelse

;-- if not new thread, save in common for recycling

if ~new_thread && obj_valid(obridge) then obridge_sav=obridge

;-- save new thread

if new_thread then ocontainer->add,obridge

;-- check status

if ~new_thread then begin
 status=obridge->status(error=error)
 if is_string(error) then mprint,error
 if status eq 1 then begin
  mprint,'Current thread busy. Come back again later or use /NEW_THREAD to start new thread.'
  return
 endif
endif


;-- use scope functions to determine: 
;   var_name = local name of argument/keyword
;   var_input = caller name of argument/keyword
;   var_val = input/output value of argument/keyword

;-- if a new thread is being requested, tag it so that it can be
;   cleaned up when completed

tname=scope_varname(id_thread,level=1)
tname=tname[0]
if is_string(tname) then name=tname else name='Thread submitted at '+!stime

if new_thread then input='new' else input=''

;-- if thread is waiting, return parameters to caller else return to
;   main level

nscope=scope_level()
wait=keyword_set(wait_thread)
if wait then begin
 in_level=2-nscope
 out_level=-2 
endif else begin
 in_level=1-nscope
 out_level=1
endelse

if ~is_string(proc) then return
in_level=-1
userdata={var_name:name,var_input:input,var_level:out_level}
proc=strcompress(proc,/rem)
is_funct=0b & is_obj=0b
cmd=proc

;-- if proc is an object call, then check for valid method 

spos=strpos(proc,'->')
slen=strlen(proc)
is_obj=spos gt -1 
if is_obj then begin
 obj_name=strmid(proc,0,spos)
 obj_val=scope_varfetch(obj_name,level=-1)
 method=strmid(proc,spos+2,slen-2)
 if ~obj_valid(obj_val) then begin
  mprint,'Invalid object - '+obj_name
  return
 endif
; ok=have_method(obj_val,method)
; if ~ok then begin
;  mprint,'Invalid object method - '+method
;  return
; endif
 temp={var_name:obj_name,var_input:obj_name,var_level:out_level}
 userdata=[userdata,temp]
 cmd=obj_name+'->'+method
endif

;-- if proc is a function, check for return variable name

if ~is_obj then begin
 spos=strpos(proc,'=')
 is_funct=spos gt -1
 if is_funct then begin
  var_name=strmid(proc,0,spos)
  funct=strmid(proc,spos+1,slen-2)
  var_val=null()
  obridge->setvar,var_name,var_val
  temp={var_name:var_name,var_input:var_name,var_level:out_level}
  userdata=[userdata,temp]
  cmd=var_name+'='+funct+'('
 endif
endif


for i=1,n_params()-1 do begin
 var_val=null()
 var_name='p'+strtrim(string(i),2)
 if arg_present(scope_varfetch(var_name)) || n_elements(scope_varfetch(var_name)) ne 0 then begin
  if n_elements(scope_varfetch(var_name)) ne 0 then var_val=scope_varfetch(var_name)
  delim=','
  if strpos(cmd,'(') eq (strlen(cmd)-1) then delim='' 
  cmd=cmd+delim+var_name
 endif
 var_input=scope_varname(scope_varfetch(var_name,/enter),level=in_level)
 obridge->setvar,var_name,var_val
 temp={var_name:var_name, var_input:var_input[0],var_level:out_level}
 userdata=[userdata,temp]
endfor

;-- use scope_varfetch to determine name "var_name" and value "var_value" of keywords at caller level

ntags=n_elements(extra)

if (ntags gt 0) then begin
 if ~is_obj then begin
  chkarg,proc,out=out
  nprocs=n_elements(out)
 endif
 for i=0,ntags-1 do begin
  var_val=null()
  var_name=extra[i]
  if ~is_obj then begin
   temp_var=var_name+'.*='
   j=nprocs-1
   if ~is_blank(out[j]) && ~stregex(out[j],temp_var,/bool,/fold) && ~stregex(out[j],'_extra *=',/bool,/fold) then begin
    mprint,'Skipping keyword - '+var_name
    continue
   endif
  endif
  if n_elements(scope_varfetch(var_name,/ref)) ne 0 then var_val=scope_varfetch(var_name,/ref)
  delim=','
  if strpos(cmd,'(') eq (strlen(cmd)-1) then delim='' 
  cmd=cmd+delim+var_name+'='+var_name
  var_input=scope_varname(scope_varfetch(var_name,/ref),level=in_level)
  obridge->setvar,var_name,var_val
  temp={var_name:var_name, var_input:var_input[0],var_level:out_level}
  userdata=[userdata,temp]
 endfor
endif

;-- pass caller variable names to bridge object for use by callback

if n_elements(userdata) gt 0 then obridge->setproperty,userdata=userdata

;-- set thread object to use same working directory as parent 

if is_funct then cmd=cmd+')'
cd,current=current
cmd2='cd,"'+current+'"'

obridge->execute,cmd2
if is_obj then obridge->setvar,obj_name,obj_val
dprint,'% CMD: ',cmd

obridge->execute,cmd,nowait=~keyword_set(wait_thread)

;-- if not new thread, save in common for recycling

if ~new_thread && obj_valid(obridge) then obridge_sav=obridge

;-- check status

case obridge->status(error=error) of
 1: mprint,'Submitted.'
 2: mprint,'Completed.'
 3: mprint,'Failed.'
 4: mprint,'Aborted.'
 else: mprint,'Ready.'
endcase

if is_blank(error) && wait then thread_callback, status, error, oBridge, userdata
if is_string(error) then mprint,error

return & end


