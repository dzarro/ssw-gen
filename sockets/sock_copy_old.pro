;+                                                                              
; Project     : HESSI                                                           
;                                                                               
; Name        : SOCK_COPY_OLD                                                       
;                                                                               
; Purpose     : Download remote file
;                                                                               
; Category    : utility system sockets                                          
;                                                                               
; Syntax      : IDL> sock_copy_old,url,out_name,out_dir=out_dir                           
;                                                                               
; Inputs      : URL = remote file name
;               OUT_NAME = optional output name for downloaded file
;                                                                               
; Outputs     : None                                                           
;                                                                               
; Keywords    : See HTTP__DEFINE
;                                                                  
; History     : 5-Mar-2019, Zarro (ADNET)
;               - written as wrapper around old HTTP object

pro sock_copy_old,url,out_name,_ref_extra=extra,local_file=local_file,err=err

err=''
local_file=''
if ~is_url(url,_extra=extra,/verbose,err=err) then return
                     
n_url=n_elements(url)                                                           
local_file=strarr(n_url)    
for i=0,n_url-1 do begin         
 if ~obj_valid(sock) then sock=obj_new('http',_extra=extra)             
 sock->copy,url[i],out_name,_extra=extra,local_file=temp,err=err
 if is_string(temp) then begin
  chk=file_search(temp,count=fcount)
  if fcount eq 1 then local_file[i]=temp
 endif
endfor                                                 
                         
if n_url eq 1 then local_file=local_file[0]
                                                                                
if obj_valid(sock) then obj_destroy,sock
                                                                                
return                                                                          
end                                                                             
