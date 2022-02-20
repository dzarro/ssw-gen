;+
; Project     : HESSI
;
; Name        : GOES_SERVER
;
; Purpose     : return available Yohkoh or SDAC GOES data server
;
; Category    : synoptic sockets
;
; Inputs      : None
;
; Outputs     : SERVER = Yohkoh GOES data server name
;
; Keywords    : NETWORK = returns 1 if network to that server is up
;               PATH = path to data
;               SDAC = return SDAC server
;
; History     : Written 15-Nov-2006, Zarro (ADNET/GSFC) 
;               Modified 22-Feb-2012, Zarro (ADNET)
;               - made /FULL the default
;               14-Dec-2012, Zarro (ADNET)
;               - removed redundant call to HAVE_NETWORK
;               - switched primary Yohkoh server to faster sohowww
;               - merged Yohkoh and SDAC search logic
;               26-Dec-2012, Zarro (ADNET)
;               - Added NETWORK=0 message 
;               18-Dec-2016, Zarro (ADNET)
;               - switched to HTTPS for Umbra/sohowww
;               28-Jan-2017, Zarro (ADNET)
;               - switched to HTTPS for Hesperia
;               23-Oct-2017, Zarro (ADNET)
;               - added http://www.lmsal.com for non-secure Yohkoh
;                 search
;               29-May-2018, Zarro (ADNET)
;               - added ftp://sohoftp.nascom.nasa.gov for non-secure
;                 SDAC search
;               19-Sep-2019, Zarro (ADNET)
;               - retired FTP
;               18-Nov-2021, Zarro (ADNET)
;               - replaced sohowww by ssw_server()
;               16-Feb-2022, Zarro (ADNET)
;               - switched LMSAL to HTTPS.
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function goes_server,_ref_extra=extra, path=path,network=network,sdac=sdac,verbose=verbose

verbose=keyword_set(verbose)
sdac_servers=['https://umbra.nascom.nasa.gov','https://hesperia.gsfc.nasa.gov']
sdac_paths=['/goes/fits','/goes']

yohkoh_servers=['https://www.lmsal.com',ssw_server(_extra=extra),'https://umbra.nascom.nasa.gov']
yohkoh_paths=['/solarsoft/sdb/ydb','/sdb/yohkoh/ys_dbase','/sdb/yohkoh/ys_dbase']

;-- default to Yohkoh

if keyword_set(sdac) then begin
 servers=sdac_servers & paths=sdac_paths
endif else begin
 servers=yohkoh_servers & paths=yohkoh_paths
endelse

;-- find first available server

for i=0,n_elements(servers)-1 do begin
 server=servers[i]
 path=paths[i]
 url=server+path
 network=have_network(url,_extra=extra,verbose=verbose,/full_path)
 if network then break
endfor

if verbose && ~network then $
 mprint,'Network connection currently unavailable. Will use latest cached lightcurves.',/info

return,server

end
