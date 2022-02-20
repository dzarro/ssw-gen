;+                                                                              
; Project     : HESSI                                                           
;                                                                               
; Name        : SOCK_LIST_OLD                                                       
;                                                                               
; Purpose     : List a URL
;                                                                               
; Category    : utility system sockets                                          
;                                                                               
; Syntax      : IDL> sock_list_old,url,out
;                                                                               
; Inputs      : URL = remote URL
;
; Outputs     : OUT = output listing
;                                                                               
; Keywords    : See HTTP__DEFINE
;                                                                  
; History     : 5-Mar-2019, Zarro (ADNET) 
;               - written as wrapper around old HTTP object
;-                                                                              
                                                                                
pro sock_list_old,url,out,_ref_extra=extra

if ~is_url(url,_extra=extra,/scalar,/verbose) then return

http=obj_new('http')
if n_params() eq 1 then http->list,url,_extra=extra else $
 http->list,url,out,_extra=extra

obj_destroy,http
                                                                                
return                                                                          
end                                                                             
