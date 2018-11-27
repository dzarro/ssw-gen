;+
; Project     : VSO
;
; Name        : HTTP_PROXY
;
; Purpose     : Temporarily disable/enable HTTP_PROXY environment variables
;
; Category    : utility system sockets
;
; Syntax      : IDL> http_proxy,/disable,[/enable]
;
; Keywords    : DISABLE = undefine HTTP_PROXY environment variables
;               ENABLE = redefine HTTP_PROXY environment variables
;
; History     : 15-June-2016, Zarro (ADNET) - Written
;-

pro http_proxy,disable=disable,enable=enable

enable=keyword_set(enable)
disable=keyword_set(disable)
if ~enable && ~disable then return

common http_proxy,proxy1,proxy2

tproxy1=getenv('HTTP_PROXY')
tproxy2=getenv('http_proxy')
if is_string(tproxy1) && is_blank(proxy1) then proxy1=tproxy1
if is_string(tproxy2) && is_blank(proxy2) then proxy2=tproxy2

if disable then begin
; mprint,'Disabling proxy.',/debug
 mklog,'HTTP_PROXY',''
 mklog,'http_proxy',''
 return
endif

if enable then begin
; mprint,'Re-enabling proxy.',/debug
 if is_string(proxy1) then mklog,'HTTP_PROXY',proxy1
 if is_string(proxy2) then mklog,'http_proxy',proxy2
endif

return
end



