
;-- test program to test remote GOES searching

pro sock_switch,remote=remote,no_ssl=no_ssl,reset=reset,_extra=extra

common sock_switch,osdac,oyohkoh

sdac=chklog('GOES_FITS')
yohkoh=chklog('DIR_GEN_G81')

if ~exist(osdac) && is_string(sdac) then osdac=sdac
if ~exist(oyohkoh) && is_string(yohkoh) then oyohkoh=yohkoh

if keyword_set(reset) then begin
 if is_string(oyohkoh) then mklog,'DIR_GEN_G81',oyohkoh
 if is_string(osdac) then mklog,'GOES_FITS',osdac
 mklog,'NO_SSL',''
 mprint,'Resetting to original state.'
 return
endif

no_ssl=keyword_set(no_ssl)
if no_ssl || keyword_set(remote) then begin
 mklog,'DIR_GEN_G81',''
 mklog,'GOES_FITS',''
 mprint,'Remote searching on.'
endif

if no_ssl then begin
 mklog,'NO_SSL','1' 
 mprint,'SSL off.'
endif

return & end
