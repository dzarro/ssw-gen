;+
; Project     : HESSI
;                  
; Name        : SSW_LOAD_INSTR
;               
; Purpose     : Platform/OS independent SSW startup.
;               Executes IDL startups and loads environment variables
;               for instruments and packages in $SSW_INSTR
;                             
; Category    : utility
;               
; Syntax      : IDL> ssw_load_instr
;
; Inputs      : None
; 
; Outputs     : None
;
; Keywords    : VERBOSE - set for verbose output
;               ERR - error string
;               ENV_ONLY = load environment only
;                                   
; History     : 30-April-2017, written Zarro (ADNET)
;               11-Aug-2017, Zarro (ADNET) - load non-instrument SITE
;                                            and GEN environment setups
;               18-Jan-2018, Zarro (ADNET) - load mission level setups
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro ssw_load_instr,verbose=verbose,err=err,env_only=env_only,_ref_extra=extra

do_startup=~keyword_set(env_only)
verbose=keyword_set(verbose)
err=''

ssw_instr=getenv('SSW_INSTR')
if is_blank(ssw_instr) then begin
 err='SSW_INSTR undefined. No instruments loaded.'
 mprint,err
 return
endif
inst=str2arr(ssw_instr,delim=' ')

;-- find and read latest SSW map file

map_file=local_name('$SSW/gen/setup/ssw_map.dat')
chk=file_test(map_file)
if ~chk then begin
 err='Non-standard SSW installation.'
 mprint,err
 return
endif

;-- run non-instrument SITE and GEN setups

file_setenv,'$SSW/gen/setup/setup.ssw_env',verbose=verbose,_extra=extra
file_setenv,'$SSW/site/setup/setup.ssw_env',verbose=verbose,_extra=extra
file_setenv,'$SSW/site/setup/setup.ssw_paths',verbose=verbose,_extra=extra

;main_execute,local_name('$SSW/gen/setup/IDL_STARTUP')

;-- cycle through each INST and look for first instance of
;   inst/idl

ssw_map=rd_tfile(map_file)
for i=0,n_elements(inst)-1 do begin

 ival=inst[i]

;-- handle special cases

 if ival eq 'rhessi' then ival='hessi'
 if stregex(ival,'(euvi|cor)',/bool,/fold) then ival='secchi'
 item='/'+ival+'/idl'
 chk=stregex(ssw_map,item,/bool,/fold)
 found=where(chk,count)
 if count gt 0 then begin
  path=ssw_map[found[0]]
  pos=strpos(path,item)
  base=strmid(path,0,pos)
  top=base+item

;-- add instrument path

  root=local_name(str_replace(top,'/idl',''))
  setenv,'SSW_'+strupcase(ival)+'='+root
  add_cmd='ssw_path,/'+ival+',quiet=~verbose'
  status=execute(add_cmd,1,1)
  setup=local_name(str_replace(top,'/idl','/setup'))

  if file_test(setup,/dir) then begin

   idl_env='setup.'+ival+'_env'

;-- load instrument environment variables
 
   idl_gen_env=concat_dir(setup,idl_env)
   file_setenv,idl_gen_env,verbose=verbose,_extra=extra

;-- load mission-level environment variables for instrument

   miss=file_basename(local_name(base))
   idl_miss_env=local_name('$SSW/gen/setup/setup.'+miss+'_env')
   file_setenv,idl_miss_env,verbose=verbose,_extra=extra

;-- run instrument SITE setups

   idl_site_env=concat_dir('$SSW/site/setup',idl_env)
   file_setenv,idl_site_env,verbose=verbose,_extra=extra
   
   idl_paths='setup.'+ival+'_paths'
   idl_site_paths=concat_dir('$SSW/site/setup',idl_paths)
   file_setenv,idl_site_paths,verbose=verbose,_extra=extra

;-- run instrument IDL_STARTUP
   
   if do_startup then begin
    idl_startup=concat_dir(setup,'IDL_STARTUP')
    if file_test(idl_startup,/regular,/read) then begin
     if verbose then begin
      mprint,'Executing IDL_STARTUP for - '+ival
      mprint,idl_startup
     endif
     main_execute,idl_startup
    endif else message,/reset 
   endif
  endif else message,/reset
 endif
endfor

return
end
