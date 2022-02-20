;+                                                                              
; Project     : HESSI                                                           
;                                                                               
; Name        : SOCK_COPY                                                       
;                                                                               
; Purpose     : Download remote file
;                                                                               
; Category    : utility system sockets                                          
;                                                                               
; Syntax      : IDL> sock_copy,url,out_name,out_dir=out_dir                           
;                                                                               
; Inputs      : URL = remote file name               
;               OUT_NAME = optional output name for downloaded file
;                                                                               
; Outputs     : None
;                                                                               
; Keywords    : OLD_WAY = set to invoke old SOCK_COPY
;               BACKGROUND = download in background
;                                                                  
; History     : 3-Mar-2019, Zarro (ADNET)
;               - refactored as wrapper around SOCK_GET
;-                                                                              
                                                                                
pro sock_copy,url,out_name,_ref_extra=extra,background=background,$
             old_way=old_way

if keyword_set(background) then begin
 thread,'sock_copy',url,out_name,_extra=extra,old_way=old_way
 return
endif

extra=rem_dup_keywords(extra)
old_way=keyword_set(old_way)
if old_way then sock_copy_old,url,out_name,_extra=extra else $
 sock_get,url,out_name,_extra=extra

return & end
