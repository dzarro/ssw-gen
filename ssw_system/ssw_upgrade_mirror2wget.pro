pro ssw_upgrade_mirror2wget,remote_dirs, local_dirs, mirror_file=mirror_file,ssw_master=ssw_master, $
    _extra=_extra, wgcmds=wgcmds, lmsal=lmsal, debug=debug, wget=wget, no_cleanup=no_cleanup
;+
;   Name: ssw_upgrade_mirror2wget
;
;   Purpose: mirror file generated by ssw_upgrade -> wget analog -> ssw_wget_mirror ready input
;
;   Input:
;      NONE
;
;   Output
;      remote_dirs - list of SSW/SSWDB urls implied by ssw_upgrade mirror file
;      local_dirs - 1:1 local dirs ; absolute/resolved using local $SSW/$SSWDB [
;
;   Keyword Parameters:
;      mirror_file - optional Mirror text file; defult=$SSW/site/setup/ssw_upgrade.mirror
;      ssw_master  - default=https//zeus.nascom.nasa.gov/ {solarsoft,sdb assumed exist on This server}
;      wgcmds - (OUTPUT) - implied wget commands via ssw_wget_mirror.pro output
;      wget - optional location of local/intended 'wget' binary to use 
;     
;
;   Calliing Example:
;      IDL> ssw_upgrade2mirror [MIRROR_FILE_MIRROR_FILE,SSW_MASTER=SSW_MASTER

;   Context: ssw_upgrade.pro helper when /WGET is set
;   
;   Method: convert heritage ssw_uprade Mirror -> wget-ready remote:local (server URLS:local paths)
;
;   History:
;      7-dec-2018 - S.L.Freeland - based on email snippets/discussion w/Greg Slater re: ftp->https transision
;     25-jun-2019 - S.L.Freeland - use ssw_wget_mirror2 (temp?) - beta releae
;     26-Jun-2019 - W.T.Thompson - Correct Windows problem
;      8-aug-2019 - S.L. Freeland - tweak for sswdb v.ssw
;     18-Nov-2021 - W.T.Thompson - change sohowww to soho
;-
debug=keyword_set(debug)
cleanup=1-keyword_set(no_cleanup) ; default removes wget index.html<blah>
if n_elements(mirror_file) eq 0 then mirror_file=concat_dir('$SSW_SITE_MIRROR','ssw_upgrade.mirror')
sdb=strpos(mirror_file,'sswdb') ne -1


case 1 of 
   keyword_set(ssw_master):  ; user supplied SSW master
   keyword_set(lmsal): ssw_master='http://www.lmsal.com/solarsoft/' + (['ssw','sdb'])(sdb)  ; LMSAL 
   else: ssw_master='https://soho.nascom.nasa.gov/'+ (['solarsoft','sdb'])(sdb)  ; default=GSFC/NASCOM
endcase
   

updat=rd_tfile(mirror_file)
remote=updat[where(strpos(updat,'remote_dir=') ne -1)]
local=updat[where(strpos(updat,'local_dir=') ne -1)]  
patt=(['=/solarsoft/','=/sdb/'])(sdb)
remote_dirs=concat_dir(ssw_master,ssw_strsplit(remote,patt,/tail))+'/'
remote_dirs=str_replace(remote_dirs,'\','/') ; Always unix-like server (probably..)
;
;  Remove any trailing // from remote_dirs.
;
for i=0,n_elements(remote_dirs)-1 do begin
    len = strlen(remote_dirs[i])
    if strmid(remote_dirs[i],len-2,2) eq '//' then $
      remote_dirs[i] = strmid(remote_dirs[i],0,len-1)
endfor

local_dirs=ssw_strsplit(local,'=',/tail)

if debug then stop,'wget_cmds'
return
end
