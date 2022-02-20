function ssw_lftp_mirror,geturls,outdirs,spawn=spawn,mirror_file=mirror_file,_extra=_extra,$
  lftp_command=lftp_command,remote_urls=remote_urls,local_dirs=local_dirs, sswdb=sswdb, clean=clean, $
  lftp_options=lftp_options, debug=debug, parallel=parallel, $
  delete=delete, loud=loud,verbose=verbose ,quiet=quiet, $
  certificate=certificate,no_quote=no_quote, no_delete=no_delete,background=background, $
  log=log
  ;
  ;+
  ;   Name: ssw_ftp_mirror
  ;
  ;   Purpose: construc/return analogous lftp commands (ftp & wget alternative)  & optionally spawn them
  ;
  ;   Input Parameters:
  ;      geturls - list of one or more server urls
  ;      outdirs - 1:1 target relative to local $SSW corresponding to GETURLS
  ;
  ;   Ouput:
  ;      function returns implied/constructed lftp commands
  ;
  ;
  ;   Keyword Parameters:
  ;      spawn (switch) - if set, spawn the implied lftp commands (e.e. function output)
  ;      mirror_file - file for Mirror -> lftp analog ; if switch, use default ssw_upgrade/sswdb_upgrade generated Mirror file
  ;      lftp_command - explicit path to desired lftp - default assumes in $PATH
  ;      remote_urls - implied server urls (aka GETURS if ssupplied)
  ;      local_dirs  - implied local $SSW/$SSWDB paths 1:1 local mapping to remote_urls
  ;      lftp_options - optional lftp user option string (assumes some lftp knowledge or for testing - may void SSW warrenty)
  ;      clean/delete - synonymous switches - remove client side files not on server
  ;      parallel - optional integer number of parallel lftp file transfers
  ;                 default is 5 per Eduard suggestion; let me know if you play with this +/-
  ;      certificate - if set, require ssl certiicate - default No certificate check
  ;      background - if set & os_family=UNIX, append ' &' to lftp commands (need some testing...)
  ;      loud/verbose - synonyms - verbosity level, 1->4, default=1 (use /quiet to set to 0)
  ;      quiet - (switch) - if set, set verbosity (loud/verbose) to 0
  ;      log - if file name, write lftp output to That user supplied log file
  ;            if switch, write lftp output to $SSW/site/logs/ssw_lftp_mirror.log
  ;            Except, if switch -and- /background set, write $SSW/site/logs/ssw_lftp_mirror_<path>.log, 1:1
  ;   History:
  ;      29-oct-2019 - S.L.Freeland - Provide 'lftp' alternate to Mirror/wget -
  ;                    Many Thanks to Eduard Kontar, LOFAR for lftp hints/suggestions
  ;                    Intended as a wget swap in -> ssw_upgrade/sswdb_upgrade
  ;      31-oct-2019 - add /LOUD, /QUIET, CERTIFICATE={0,1}
  ;      15-nov-2019 - add single quote marks around lftp command stringsand /BACKGROUND and
  ;      18-nov-2019 - did the stuff claimed for 15-nov, add /NO_QUOTE
  ;       6-feb-2020 - fix /SPAWN FOR loop subscript - thanks Alfred (sheesh, can't belive I don't add the n_elements -1 by 60 year habit...)
  ;      21-feb-2020 - add LOG keyword + function
  ;      25-feb-2020 - add $lftp_command environmental option
  ;       6-aug-2020 - tweak file permission behavior default per Eduard suggestion ( -p --allow-chown )
  ;      11-aug-2020 - Kim. Modify commands for Windows, assume wsl lftp is best, and change filenames to what wsl can use
  ;
  ;
  ;   Calling Sequence: (~analogous to ssw_wget_mirror[2].pro plug in)
  ;     IDL> lftp_cmds=ssw_lftp_mirror,geturls,outdir [,/spawn,_extra=_extra,  remote_urls=remote_urls,local_dirs=local_dirs)
  ;     IDL> lftp_cmds=ssw_lftp_mirror(/mirror [,/sswdb] [,/spawn, remote_urls=remote_urls,local_dirs=local_dirs,_extra=_extra i
  ;        above calls ssw_upgrade_mirror2wget in place of supplied urls/local )
  ;     IDL> lftp_cmds=ssw_lftp_mirror(geturls,outdirs,parallel=10,[,/LOUD]  [,/SPAWN])
  ;     IDL> lftp_cmds=ssw_lftp_mirror(geturls,outdirs,loud=4,/background,parallel=3) ; caveat emptor pending testing
  ;                    (note: Pariallel uses lftp intrinsic=>parallel FILES per lftp command; /BACKGROUND runs ALL  COMMANDS in parallel
  ;
  ;-

  spawnit=keyword_set(spawn) ;
  sswdb=keyword_set(sswdb)
  debug=keyword_set(debug)

  case 1 of
    n_params() eq 2: begin
      remote_urls=geturls
      local_dirs=outdirs
    endcase
    keyword_set(mirror_file): begin
      if file_exist(mirror_file) then mfile=mirror_file else mfile=concat_dir('$SSW','site/setup/ssw_upgrade.mirror')
      ssw_upgrade_mirror2wget,remote_urls, local_dirs, mirror_file=mfile,_extra=_extra
    endcase
    else: begin
      box_message,'Must supply explicit GETURLS,OUTDIRS or mirror_file option
      return,'' ; EARLY EXIT on unexpected input
    endcase
  endcase

  have_lftp = 0

  if os_family(/lower) eq 'windows' then begin
    espawn, 'wsl which lftp', out  ; this will return a blank string if wsl or lftp not found
    if out ne '' then begin
      lftp_command = 'wsl lftp'
      have_lftp = 1      
    endif else begin
      box_message,'wsl and/or lftp are not installed.'
      lftp_command = 'lftp'  ; fake, just so we can return lftp commands constructed below
    endelse
    local_dirs = convert_filename_win2unix(local_dirs)

  endif else begin
    lftp_env=get_logenv('lftp_command') ; environmental binary path option?
    case 1 of
      file_exist(lftp_command): have_lftp = 1   ; user supplied
      file_exist(lftp_env) : begin
        lftp_command = lftp_env ; $lftp_command environmental set, use that if exists
        have_lftp = 1
      endcase
      else: begin
        spawn,['which','lftp'],/noshell, lftp_command
        lftp_command=lftp_command[0]  ; scalarize output
        if file_exist(lftp_command) then have_lftp = 1 else begin
          box_message,'lftp not in your PATH?'
          lftp_command='lftp' ; fake via 'ideal' command construction below...
        endelse
      endcase
    endcase
  endelse

  if n_elements(parallel) eq 0 then parallel=5 ; default=5 (feedback appreciated if you Play with this#)
  if is_number(parallel) then parr=' -P '+strtrim(parallel,2) else parr=''
  lftp_opt=' -p --allow-chown' ;tweaked default file permission handling, 6-aug-2020'
  if keyword_set(lftp_options) then lftp_opt=' '+strtrim(lftp_options,2) + ' '
  delete=keyword_set(clean) or keyword_set(delete)
  del=(['-e ',''])(keyword_set(no_delete))
  back=(['',' &'])(keyword_set(background))
  quote=(["'",""])(keyword_set(no_quote))
  case 1 of
    keyword_set(quiet): vlev=0
    is_number(loud): vlev=str2number(loud)
    is_number(verbose): vlev=str2number(verbose)
    else: vlev=1; default
  endcase
  verb=''
  if vlev gt 0 then verb=' -'+strpad('v',vlev<4,fill='v') ; verbosity 1->4

  cert='set ssl:verify-certificate '+(['no','yes'])(keyword_set(certificate)) +';'
  ncmds=n_elements(remote_urls)

  case 1 of
    ~keyword_set(log): lftp_logs=replicate('',ncmds)
    back eq '': begin
      if data_chk(log,/string) then  lftp_logs=replicate(log[0],ncmds) else $
        lftp_logs=replicate(concat_dir('$SSW_SITE_LOGS','ssw_lftp_mirror.log'),ncmds)
    endcase
    keyword_set(back): begin
      ldirs=str_replace(str_replace(local_dirs,get_logenv('$SSW'),get_delim()),'/','_')
      lftp_logs=concat_dir('$SSW_SITE_LOGS','ssw_lftp_mirror'+ldirs+'.log')
    endcase
  endcase
  if keyword_set(lftp_logs[0]) then begin
    lftp_logs = convert_filename_win2unix(lftp_logs)  ;does nothing if already unix-style names
    lftp_logs=" --log='"+lftp_logs+"' "
  endif
  lcommands=cert + ' mirror --depth-first ' + del + parr + verb + lftp_opt + lftp_logs + ' ' +remote_urls + ' ' + local_dirs
  lcommands=lftp_command + ' -c ' + quote+lcommands+quote+back


  if debug then stop,'lcommands'

  if spawnit then begin
    if have_lftp then begin
      for i=0,n_elements(lcommands)-1  do begin ; tweaked 6-feb-2020
        espawn,lcommands[i]
      endfor

    endif else begin
      box_message,$
        [' /SPAWN requested but dont see lftp in path or via LFTP_COMMAND keyword', $
        ' so just returning implied lftp commands with no action...']
    endelse
  endif

  return,lcommands
end



