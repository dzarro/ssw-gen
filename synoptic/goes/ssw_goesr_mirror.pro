pro ssw_goesr_mirror,t0,t1,parent_local=parent_local,_extra=_extra, wget=wget, lftp=lftp, $
   mirror_commands=mirror_commands, nospawn=nospawn, $
   remote_urls=remote_urls, local_paths=local_paths
;
;+
;   Name: ssw_goesr_mirror
;
;   Purpose: "mirror" GOESR data -> local for user time range; default From NOAA/NCEI 
;
;   Input Parameters:
;     t0,t1 - time range 
;
;   Keyword Parameters:
;      parent_local - local top path for output directories/files - default $GOESR_DATA
;      wget - switch - use wget (see ssw_wget_mirror.pro)
;      lftp - switch - use lftp (see ssw_lftp_mirror.pro) - better and faster
;      _extra - keywords inherited by 'ssw_goesr_time2files.pro' and ssw_<wget/lftp>_mirror.pro
;      nospawn - switch - if set, don't spawn the wget or lftp "mirror" (testing, MIRROR_COMMANDS output for example
;      mirror_commands - (output) - derived wget -or- lftp commands; use w/NOPAWN to sanity check before execution for examp.
;      remote_urls - (output) - implied remote urls , mirror Source
;      local_paths - (output) - 1:1 implied local paths, mirror Target
;               
;  Calling Examples:
;     IDL> ssw_goesr_mirror,'5-apr-2020','7-apr-2020',/suvi,waves='94,171,304',/L2,/lftp,loud=3,parallel=10 ; out->$GOESR_DATA
;     IDL> ssw_goesr_mirror,reltime(days=-1),reltime(/now),/suvi,waves='284',/l1b,parent_local=curdir(),/lftp
;
;  History:
;     9-apr-2020 - S.L.Freeland written (after knocking out the AI which is in ssw_goesr_time2files.pro)
;     See ssw_goesr_time2files for options/defaults/keyword etc...
;     https://www.lmsal.com/solarsoft/ssw/vobs/ontology/idl/gen_temp/ssw_goesr_time2files.pro
;
;  Restrictions:
;     full day(s) only pending ssw_time2filelist tweak for noaa/ncei 'odd-man-out' file naming convention - here we go...
;
;  Notes:
;     All local output will inherit NOAA/NCEI GOESR data tree organization (unless you are wget/lftp savy)
;-
;
if n_params() lt 2 then begin 
   box_message,'Need time range at least.. sheesh, ..bailing'
   return ; !!! EARLY EXIT on no user time range
endif

remote_urls=ssw_goesr_time2files(t0,t1,/paths_only,parent_local=parent_local,local_paths=local_paths,_extra=_extra)
spawn=1-keyword_set(nospawn)

case 1 of 
   keyword_set(wget): begin
      mirror_commands=ssw_wget_mirror(remote_urls,local_paths,_extra=_extra,spawn=spawn)
   endcase
   keyword_set(lftp): begin
      mirror_commands=ssw_lftp_mirror(remote_urls,local_paths,_extra=_extra,loud=3,spawn=spawn)
   endcase
   else: begin
      box_message,'no mirror method specified, e.g. /LFTP or /WGET - just returning implied remote_urls/local_paths
   endcase
endcase

return
end
