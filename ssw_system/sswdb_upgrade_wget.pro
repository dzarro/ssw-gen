pro sswdb_upgrade_wget,dbsets,lockheed=lockheed, lmsal=lmsal, nascom=nascom, proxy=proxy, $
   cmds_wget=cmds_wget,sswdb_parent_url=sswdb_parent_url , spawn=spawn, wget=wget, _extra=_extra
;
;+
;   Name: sswdb_upgrade_wget
;
;   Purpose: upgade local $SSWDB using wget (calls ssw_wget_mirror.pro)
;
;   Input Parameters:
;      dbsets - one or more branches of $SSWDB to update - see sswdb_upgrade doc header for example
;
;   Keyword Parameters:
;      spawn - (switch) - if set, spawn the wget commands
;      cmds_wget - (output) - the implied wget commands (ssw_wget_mirror.pro output) - 1:1 dbsets
;      lockheed/lmsal - (switch) - synomyms, use lockheed http server parent
;      nascom - (witch) - use heritage soho.nascom.nasa.gov (but now https)
;      sswdb_parent_url - optional and alternate SSWDB parent url (if not lockheed or nascom) - caveat emptor!
;      wget - if existing file name, use that explicit wget binary
;      _extra - keyword inherit -> sssw_wget_mirror (like /nowait..etc) - see That doc header
;
;   Calling Sequence:
;      IDL> sswdb_upgrade_wget,['mission1/db1','miss2/db1','miss2/db2'....],[/lmsal],[/nascom],sswdb_parent=
;
;   Calling Examples:
;      IDL> sswdb_upgrade_wget,'hinode/xrt/xrt_gencat_sirius',/nascom,/spawn ; update $SSWDB/hinode/xrt/xrt_genxcat_sirius
;      IDL> sswdb_upgrade_wget,'iris/iris2',/lmsal,/spawn ; update $SSWDB/iris/iris2/ from lockheed (Alberto ainz Dalda)
;      IDL> sswdb_upgrade_wget,['ydb/nar','ydb/gev'],/nascom,/spawn
;   History:
;      15-may-2019 - SLF (BAERI!) - piece of no-ftp@nascom puzzle, ssw_wget_mirror.pro wrapper
;      16-may-2019 - SLF - doc header only, added /SPAWN to calling examples since no-spawn is default as of Now
;      07-Aug-2019 - WTT - Renamed wget_commands to cmds_wget to match ssw_upgrade.pro.
;               Add WGET keyword, call to SSW_BIN_PATH.  Fix WRITE_ACCESS call.
;      09-Aug-2019 - WTT - Remove WRITE_ACCESS call
;      18-Nov-2021 - WTT - change sohowww to soho
;
;   Method:
;      define & optionally spawn wget commands -> relative to local $SSWDB
;
;   Restrictions:
;      Assumes 'wget' available on current machine and visible in users !PATH
;      Not tested on Windows as of today... WinXX beta users and mods invited -> freeland@baeri.org
;      Must be run by local owner of $SSWDB! ask them to run this if that is not you 
;      As of now, calling ssw_wget_mirror2 instead since ssw_get_mirror depracated - but allows me
;      to evolve this without nascom assist/ssw-gen update 
;      TODO - integrate into sswdb_upgrade,/wget
;
;-

dist_wget=ssw_bin_path('wget'+(['','.exe'])(os_family() eq 'Windows'),found=bin_found)
case 1 of 
    file_exist(wget) : wget_cmd=wget ; using user input wget/path
    bin_found: wget_cmd=dist_wget
    else: wget_cmd='wget'
endcase
if os_family() eq 'unix' then begin
   spawn,['which',wget_cmd],wget_cmd,/noshell ; update with local/found wget?
   wget_cmd=wget_cmd[0]
   if ~file_exist(wget_cmd) then begin 
      box_message,"Don't see wget on your machine/in your path, so bailing"
      box_message,['Please send output of following cut&paste sswidl comand -> freeland@baeri.org',$
                   'IDL> ssw_last_update,/version', $
                   '[your output here] => email'] 
      return ; !!! EARLY EXIT on no wget found
   endif
endif

box_message,'Using wget = ' + wget_cmd

if n_params() eq 0 then begin
   box_message,'No dbssets specified via 1st positional parameter, so bailing...'
   return ; !!! EARLY EXIT on no $SSWDB/<dbsets> specified
endif 

; choose SSWDB parent url
nascom=keyword_set(nascom)
lmsal=keyword_set(lmsal) or keyword_set(lockheed)
nascom_url='https://soho.nascom.nasa.gov/sdb/' ; heritage@nascom

case 1 of
   keyword_set(sswdb_parent_url): ; user supplied
   lmsal: sswdb_parent_url='http://www.lmsal.com/solarsoft/sdb/'
   nascom: sswdb_parent_url=nascom_url
   else: begin
      box_message,'No parent specified, using nacom: '+nascom_url
      sswdb_parent_url=nascom_url
   endcase
endcase

sswdb_local=get_logenv('SSWDB')
;;if not write_access(sswdb_local) then begin 
;;   box_message,"Dont think you have $SSWDB write access, so bailing"
;;   return ; EARLY EXIT on no $SSWDB write/update access
;;endif
;
spawn=keyword_set(spawn)

dbsets_local=concat_dir(sswdb_local,dbsets)+'/'
dbsets_urls=sswdb_parent_url+dbsets+'/'
box_message,[dbsets_urls + ' => '+ dbsets_local]
if spawn then mk_dir,dbsets_local
cmds_wget=ssw_wget_mirror2(dbsets_urls,dbsets_local,/cleanup,spawn=spawn,wget_cmd=wget_cmd,_extra=_extra)

return
end

