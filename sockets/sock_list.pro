;+                                                                              
; Project     : HESSI                                                           
;                                                                               
; Name        : SOCK_LIST                                                       
;                                                                               
; Purpose     : List remote URL                                       
;                                                                               
; Category    : utility system sockets                                          
;                                                                               
; Syntax      : IDL> sock_list,url,out
;                                                                               
; Inputs      : URL = remote URL
;                                                                               
; Outputs     : OUT = output listing                                                           
;                                                                               
; Keywords    : OLD_WAY = set to invoke old SOCK_LIST
;                                                                  
; History     : 3-Mar-2019, Zarro (ADNET)
;               - refactored as wrapper around new/old SOCK_LIST
;-                                                                              
                                                                                
pro sock_list,url,out,_ref_extra=extra,old_way=old_way

extra=rem_dup_keywords(extra)
old_way=keyword_set(old_way)

if n_params() eq 1 then begin
 if old_way then sock_list_old,url,_extra=extra else $
  sock_list_new,url,_extra=extra
endif else begin
 if old_way then sock_list_old,url,out,_extra=extra else $
  sock_list_new,url,out,_extra=extra
endelse

return & end

