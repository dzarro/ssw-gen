pro ssw_upgrade, _extra=_extra, site=site, $
                 outdir=outdir, outpackage=outpackage, $
		 update_log=update_log, nopackage=nopackage,       $
                 ssw_parent=ssw_parent, ssw_instr=ssw_instr, ssw_host=ssw_host, $
                 remote_user=remote_user, remote_password=remote_password, $
                 passive_ftp=passive_ftp, $
                 nospawn=nospawn, noexecute=noexecute, $
		 local_sets=local_sets, remote_sets=remote_sets, $
		 debug=debug, spawnit=spawnit, $
                 loud=loud, verbose=verbose, result=result, $
                 user=user, group=group, mirror=mirror, local_mirror=local_mirror, $
                 wget=wget, lmsal=lmsal, clean_wget=clean_wget, noclean_wget=noclean_wget,$
                 cmds_wget=cmds_wget, remote_urls=remote_urls, local_paths=local_paths
;+
; Name: ssw_upgrade
;
; Purpose: generate SSW set list, generate packages and spawn mirror job
;
; Keyword Parameters:
;   SITE - if set, include $SSW/site (only on request)
;   XXX  - ex: /eit, /mdi, /sxt, /trace.. update only specified instruments
;                (if none specified , list is derived from $SSW_INSTR)
;   outdir -     local path to keep mirror files (def=$SSW_SITE_MIRROR)
;   outpackage - name of mirror file (def='ssw_upgrade.mirror')
;   no package - if set, do not generate new package 
;   spawnit    - if set, spawn the mirror job
;   nospawn    - if set, do not spawn/execute mirror (ex: just make package) DEFAULT
;   noexecute  - synonym for nospawn
;   remote_sets (output) - list of remote sets/paths (on SSW master)
;   local_sets  (output) - list of local ( relative to $SSW)
;   loud - switch, if set, echo Mirror output 
;   verbose - switch , if set, synonym for /LOUD
;   result (output) - output of mirror command
;   mirror - optional path/name of mirror to run (default = ssw_bin('mirror'))
;   ssw_parent - optional '$SSW' (default is local)
;   ssw_instr  - optional list   (default is local)
;   update_log - (switch) - if set, update $SSW/site/logs/ssw_upgrade_xxx.log
;   passive_ftp - (switch) - if set, tell make_mirror to use passive_ftp
;                            (alternately, via $ssw_passive_ftp env) 
;   wget - use wget in place of heritage ftp/Mirror
;          if switch: check for distributed OS/Arch binary - if none, use local default wget in path
;          if existing file name, used that explicit wget binary
;   lmsal - if set, use lmsal $SSW http (allows older wget versions, but possibly some hours stale 
;           for non-lmsal mastered branches) - provides alternate parent using 'http' instead of (nascom) 'https'
;           so allows use of older wget versions - pending filling out the wget +V1.18/ssl matrix in distribution.V
;   clean_wget (switch) - if set, inhibit or remove the wget 'index.html<crap>' - probably the default
;   noclean_wget (switch) - if set, leave the 'index.html<crap>' post wget - maybe used later for client side removes(tbd) and Then removed
;   cmds_wget (output) - vector of wget commands (either spawned or not) - if wget set, but spawn not, can verify prior to /spawn call...
;   remote_urls (output) - implied urls@SSW host (wget source)
;   local_paths (output) - implies local paths (1:1) remote_urls - wget destination, relative to $SSW
;
;   
; Calling Examples:
;   ssw_upgrade,/eit,/sxt,/spawn  - update specified instrument trees (and required GENs)
;   ssw_upgrade,/eit,/sxt         - generate same package but dont spawn mirror job
;   ssw_upgrade,/spawn            - update trees implied by $SSW_INSTR
;   ssw_upgrade,/site,/spawn      - same but update SITE (! warning)
;   ssw_upgrade, remote=remote, local=local,/nospawn, /nopackage - just return paths
;   ssw_upgrade, /eit, mirror='$SSW/packages/mirror/mirror' ; use specified 
;   ---- wget options when ftp@nascom plugged pulled (becomes default on that day);                                                           ; mirror
;   ssw_upgrade,/wispr,/chianti,/pfss,/wget,/spawn,/loud    ; use wget in place of heritage ftp/Mirror
;                                                           ; ('cause they made me..)
;   ssw_upgrade,/iris,/stix,/eis,wget='/my/path/wget',/spawn
;
; History:
;    1-Dec-1996 - Written by Samuel Freeland   
;   16-Jan-1997 - S.L.Freeland - added /SPAWN and made /NOSPAWN the default
;                 Some auto definition of OUTDIR
;   31-mar-1997 - S.L.Freeland - add /LOUD,/VERBOSE, and RESULT
;   16-apr-1997 - S.L.Freeland - add USER & GROUP
;   23-apr-1997 - S.L.Freeland - adjust to allow single instrument missions
;                                to exist directly under $SSW
;                                assure USER and GROUP are defined
;   22-may-1997 - S.L.Freeland - set MAX_DELETE_FILE&MAX_DELTE_DIRS to 99%
;   19-aug-1997 - S.L.Freeland - if MIRROR not passed, call ssw_bin('mirror')
;   10-sep-1997 - S.L.Freeland - use $SSW/gen/mirror if mirror not passed
;   16-sep-1997 - S.L.Freeland - print warning and abort if cannot update
;                                existing mirror file  
;    5-nov-1997 - S.L.Freeland - make yohkoh/gen imply yohkoh/ucon
;   26-Mar-1998 - M.D.Morrison - Added SSW_MIRROR_PKG env var option
;   22-Feb-1999 - S.L.Freeland - use /NO_SYMBOLIC_LINK in make_mirror call
;   27-Feb-1999 - S.L.Freeland - add /nomult to str2arr call for $SSW_INSTR
;                                (assures no 'null' instrumnents)
;   30-Nov-1999 - S.L.Freeland - add ssw_parent, ssw_instr, update_logs
;                                (allow faking for different environment -
;                                 for example , make WINDOWS package under UNIX)
;   18-Apr-2001 - S.L.Freeland - file_delete->ssw_file_delete
;                                due to RSI screwup...
;    4-Oct-2001 - S.L.Freeland - check for $ssw_passive_ftp (firewall client?)
;      09-May-2003, William Thompson - Use ssw_strsplit instead of strsplit
;   16-feb-2004 - S.L.Freeland - add solarb and vobs to multi-instr missions
;   27-apr-2004 - S.L.Freeland - add stereo to multi-instr missions...
;   18-apr-2005 - S.L.Freeland - find perl (used by mirror) if not in "expected" place
;   30-mar-2006 - s.L.Freeland - enable Windows use & enable RHESSI/HESSI synonym
;                                (at least for the weekend, callit ssw_upgrade2.pro)
;    6-oct-2006 - D.M.Zarro / Freeland - solarb->hinode
;    2-jan-2007 - S.L.Freeland - optical->multi_miss (optical/gen now available)
;    9-sep-2012 - S.L.Freeland - oops, finally onlined 'sdo' -> multi mission
;   14-feb-2013 - S.L.Freeland - protection for 'gen' only (Windows hiccup)
;    4-aug-2017 - S.L.Freeland	- psp hooks (Parker Solar Probe) + gen-only
;   17-jul-2019 - S.L.Freeland - add the WGET hooks 
;                                glue ssw_upgrade -> ssw_upgrade_mirror2get -> ssw_wget_mirror(2)2
;   25-jul-2019 - S.L.Freeland - pass loud -> ssw_wget_mirror2 ( omit default --nv flag in wget commands)
;    8-aug-2019 - W.T.Thompson - Make wget the default.  Add package/binaries by default.
;   15-Apr-2020 - W.T.Thompson - Copy over LICENSE file
;
; Restrictions:
;   For now, all local in terms of local $SSW (no split instrument trees)
;   Assume SolarSoft, Perl and Mirror must be installed on local machine (if /SPAWN)
;-
;
if n_elements(wget) eq 0 then wget=1 ;Make wget the default
debug=keyword_set(debug)
spawnit=keyword_set(spawnit)               ; 17-January-1997 DEFAULT = /NOSPAWN
loud=keyword_set(loud) or keyword_set(verbose)
wget_spawnit = keyword_set(spawnit) and keyword_set(wget)

if wget_spawnit then begin 
   box_message,'using WGET w/spawn - so inhibiting Mirror spawn!'
   spawnit=0
endif
if n_elements(group) eq 0 then group=get_group()
if n_elements(user) eq 0 then user=get_user()

sswtop='/solarsoft'                                        ; host tree top
if not data_chk(ssw_host,/string,/scalar) then $
   ssw_host=(get_logenv('ssw_mirror_site'))(0)             ; defult=sohoftp
if ssw_host eq '' then ssw_host='sohoftp.nascom.nasa.gov'  ; default at GSFC

multi_miss=str2arr('yohkoh,soho,smm,hinode,vobs,stereo,optical,sdo,so,psp') ; multiple instrument missions

; Optionally generate Instrument list via keyword inheritance
case 1 of
   data_chk(_extra,/struct): $
      instr=strlowcase(str_replace(tag_names(_extra),'SSW_',''))
   n_elements(ssw_instr) eq 1: $ 
      instr=str2arr(str_replace(ssw_instr,',',' '),' ',/nomult)
   n_elements(ssw_instr) gt 1: instr=ssw_instr
   else:instr=str2arr(get_logenv('SSW_INSTR'),' ',/nomult)
endcase   
;
;      
instr=str_replace(instr,'rhessi','hessi') ; allow RHESSI synonym

; expand list
tinstr=instr                                  ; temp copy
if not keyword_set(nolinkages) then $
    ssw_install_explinkages, instr, tinstr    ; add implied linkages
instr=tinstr
if get_logenv('check_instr') ne '' then stop,'instr,tinstr'
; ---------- prepare the lists (remote and local SSW pathames) ------------
allinstrx=str2arr(get_logenv('SSW_INSTR_ALL'),' ')
allmiss =ssw_strsplit(allinstrx,'/',tail=allinstr)
missions=str2arr(get_logenv('SSW_MISSIONS'),' ')
; ------------------------------------------

; protect against unexpected environmentals (missions ne '')
for i=0,n_elements(missions)-1 do set_logenv,missions(i),'',/quiet

ss=where_arr(allinstr,instr, count)                       ; map local->remote
gensets=['gen',concat_dir('packages','binaries')]         ; implied GEN trees

if count gt 0 then begin
   sss=where(allmiss(ss) eq allinstr(ss),smcnt)           ; mission=instrument?
   if smcnt gt 0 then allinstr(ss(sss))=''                ; null out
   insets=concat_dir(allmiss(ss),allinstr(ss))            ; instruments
endif 
mm=where_arr(multi_miss,allmiss(ss),count)
if count gt 0 and ss[0] ne -1 then gensets=[gensets,concat_dir(multi_miss(mm),'gen')]     ; implied mission GEN
mm=where_arr(multi_miss,instr,count)
if count gt 0 then begin
   gensets=[gensets,concat_dir(multi_miss[mm],'gen')]
   iss=rem_elem(instr,multi_miss[mm],count)
   if count eq 0 then instr='' else instr=instr[iss] ; remove 'gen only' from list
endif

if get_logenv('check_instr') ne '' then stop,'multi_miss,mm'
gensets=all_vals(gensets)
allsets=gensets
if n_elements(insets) gt 0 then allsets=[gensets,insets]  
allsets=allsets(uniq(allsets,sort(allsets)))              ; uniq list
;------------------------------------------------------------------------

if keyword_set(site) then allsets=['site',allsets]  ; add site only on req.

; define local and remote                           ;ouput and for mirror 
remote_sets=concat_dir(sswtop,allsets)

if not data_chk(ssw_parent,/string,/scalar) then ssw_parent=get_logenv('SSW')
local_sets=concat_dir(ssw_parent,allsets)

; ---------- special case handling
; 1) Yohkoh ucon - add if yohkoh/gen is present
ysgen=(where(strpos(remote_sets,'yohkoh/gen') ne -1,ucnt))(0)
if ucnt gt 0 then begin
   remote_sets=[remote_sets, $
       concat_dir(str_replace(remote_sets(ysgen),'gen','ucon'),'idl')]
   local_sets= [local_sets, $
       concat_dir(str_replace(local_sets(ysgen) ,'gen','ucon'),'idl')]
endif   
if strpos(ssw_parent,'\') ne -1 then $
    local_sets=str_replace(local_sets,'/','\')       ; ->Windows on UNIX server

; ----------------- generate mirror package -------------------------

if not keyword_set(nopackage) then begin
   if not keyword_set(outpackage) then outpackage='ssw_upgrade.mirror' 
   break_file,outpackage,ll,pp,ff,ee,vv    
   case 1 of
      keyword_set(outdir): 
      file_exist(pp): outdir=pp
      file_exist(get_logenv('SSW_SITE_MIRROR')): outdir=get_logenv('SSW_SITE_MIRROR')
      else: outdir=get_logenv('SSW_SITE_SETUP')
   endcase
   pfile=concat_dir(outdir,ff+ee+vv)
   ssw_file_delete,pfile, status
   if file_exist(pfile) then begin
      prstr,strjustify(["WARNING: File: " + pfile , $
        "exists and you do not have update priviledge - aborting...", $
        "Remove file or use OUTPACKAGE and OUTDIR keywords to define a", $
        "different mirror file name...","", $
        "   IDL> ssw_upgrade[,/switches], OUTDIR='pathname',OUTPACK='filename'"],/box)
        return
   endif

   comments='ssw_upgrade_'+ str_replace(remote_sets,'/','_')

   if keyword_set(update_log) then begin
       lfile=str_replace(comments,'_solarsoft','') + '.log'
       case 1 of
          strpos(ssw_parent,'\') ne -1: $
		logdir=str_replace(ssw_parent+'\site\logs','\\','\')
	  else: logdir=get_logenv('SSW_SITE_LOGS')
       endcase
       ulogs=concat_dir(logdir,lfile)
   endif else ulogs=strarr(n_elements(remote_sets))
   if strpos(ssw_parent,'\') ne -1 then ulogs=str_replace(ulogs,'/','\')
   case 1 of
      keyword_set(remote_password): remote_user='anonymous'
      else: begin
         remote_user=''
	 remote_password=''
      endcase
   endcase      
   passive_ftp=keyword_set(passive_ftp) or $
                  get_logenv('ssw_passive_ftp') ne '' 
   remote_sets=str_replace(remote_sets,'\','/') ; Always unix-like server (probably..)
   make_mirror,ssw_host, remote_sets, local_sets, $
      comment=comments, passive_ftp=passive_ftp, $
      mirror_file=pfile,/mode_copy, group=group, user=user, $
      max_delete_file='99%', max_delete_dirs='99%', /no_symbolic_link,$
      update_log=ulogs, remote_user=remote_user, remote_password=remote_password
endif

; --------------- spawn mirror (do the update) ----------------------
if spawnit then begin
   dirtemp=curdir()
   sswmirr_dir=concat_dir(concat_dir('$SSW','gen'),'mirror')
   case 1 of
      data_chk(mirror,/string):                     ; user passed
      keyword_set(local_mirror): mirror='mirror'    ; local alias
      keyword_set(getenv('SSW_MIRROR_PKG')): mirror=getenv('SSW_MIRROR_PKG')    ; 
      else: mirror=concat_dir(sswmirr_dir,'mirror')
   endcase
   if not file_exist(mirror) then mirror='mirror'
   case os_family() of
   'unix': begin  
   if not file_exist(ssw_whereis_perl(/default)) then begin 
      box_message,'Checking for perl location...'
      locperl=ssw_whereis_perl(status=status)
      if status then begin 
         mtemp=rd_tfile(mirror)
         locmirr=concat_dir(sswmirr_dir,'mirror_local.pl')
         mtemp(0)='#!'+locperl  ; gotta be a better way which works for ALL OS/SHELL/1980-2048...
         file_append,locmirr,mtemp,/new
         spawn,['chmod','775',locmirr],/noshell
         mirror=locmirr
         dirtemp=curdir()
         cd,sswmirr_dir
      endif else begin 
         box_message,['Sorry, dont see "perl" where I expected...','Please make symbolic link like:',$
                      '','(from root - ask your sysadmin. if thats not you)','', $
                     '# ln -s </your_perl_path_here> /usr/local/bin/perl','','..then retry']
         return ; !!! early error exit
      endelse
   endif 
   mircmd=mirror + ' ' + pfile
   endcase
   'Windows': begin 
      cd,sswmirr_dir ; Windows requirement, I believe...'
      mircmd='perl '+ mirror + '.pl -d ' + pfile
   endcase
   else: begin 
      box_message,'Unsupported OS... returning'
      return
   endcase
   endcase
   message,/info,"Spawning mirror cmd: " + mircmd
   if loud then spawn,mircmd else spawn,mircmd,result
   if n_elements(dirtemp) gt 0 then cd,dirtemp           ; if run in-situ, recover 
endif  
if keyword_set(wget) then begin 
   box_message,'wget requested'
   dist_wget=ssw_bin_path('wget'+(['','.exe'])(os_family() eq 'Windows'),found=bin_found)
   case 1 of 
      file_exist(wget) : wget_cmd=wget ; using user input wget/path
      bin_found: wget_cmd=dist_wget
      else: wget_cmd='wget'
   endcase
;  map mirror file remote:local -> wget urls:local
   ssw_upgrade_mirror2wget,rem,loc,lmsal=lmsal
   remote_urls=rem
   local_paths=loc
   clean=1-keyword_set(noclean_wget) ; default cleansup wget mess...
   cmds_wget=ssw_wget_mirror2(rem,loc,spawn=wget_spawnit, clean=clean,wget_cmd=wget_cmd,loud=loud)
endif
;
;  Copy over the SolarSoft LICENSE file
;
if (keyword_set(spawnit) or keyword_set(wget_spawnit)) and $
        (!version.release ge '8.3') then begin
    license_file = 'https://' + ssw_host + '/solarsoft/LICENSE'
    sock_copy, license_file, 'LICENSE', out_dir=ssw_parent
endif
;
if debug then stop
return
end
