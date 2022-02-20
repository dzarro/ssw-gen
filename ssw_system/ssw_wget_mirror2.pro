function ssw_wget_mirror2, geturls, outdirs,  $
  spawn=spawn, accept=accept, pattern=pattern, mirror_file=mirror_file, $
  site=site, nowait=nowait, nopassive=nopassive, $
  old_paradigm=old_paradigm, new_paradigm=new_paradigm, cleanup=cleanup, $
  add_cut_dirs=add_cut_dirs, wait=wait, wget_cmd=wget_cmd, $
  loud=loud, verbose=verbose,no_index=no_index
  ;+
  ;    Name: ssw_wget_cmds
  ;
  ;    Purpose: return and optionally spawn implied mirror-like wget commands
  ;
  ;    Input Paramters:
  ;       geturls - list of one or more urls to get
  ;       outdirs - corresponding parent directory(ies) for output (def=curdir())
  ;
  ;    Output:
  ;       function returns implied wget commmand(s)
  ;
  ;    Keyword Paramters:
  ;       spawn - if set, execute the wget command(s)
  ;       accept,pattern (synonyms) - optional file pattern/pattern list to get
  ;       mirror_file - optionally, mirror package file which will be used
  ;                   to derive 'geturls' and 'outdirs' (Not Yet Implemented)
  ;       nowait - don't insert random wait switch (default is kinder to server)
  ;       wait - !! changed default WAIT to NOWAIT since Major speed up - 15-may-2019!!!
  ;       NOTE: mirror_file provides plan for transitioning ssw_upgrade.pro
  ;             from ftp to wget
  ;       new_paradigm (/switch) - large change in switches; may be better
  ;                       than original, but I'll wait before default change
  ;                       reccomended though for new apps.
  ;       NOTE: /NEW_PARADIGM is default as of 12-nov-2007 - use /OLD_PARDIGM
  ;             to override
  ;       old_paradigm (/switch) - force "old" switches
  ;       cleanup - is /spawn is set, then run ssw_wget_cleanup After execution
  ;                 (removes 'html*index' recursively under OUTDIR/....)
  ;       add_cut_dirs - "sometimes", the auto-derived cut-dirs is off by
  ;                      N (usually +/-1) - use this to tweak (added to cut)
  ;       wget_cmd - optional user/ssw defined wget binary (deault = 'wget' assumed visible/path
  ;       loud/verbose - synonymomous switches - verbose, include blurbs about identical files not transferred etc
  ;
  ;   Calling Sequence:
  ;      IDL> wgetcmds=ssw_wget_mirror(urls, parentdirs [,/spawn] [,pattern=patt])
  ;      IDL> wgetcmds=ssw_wget_mirror(urls,parentdirs,/NEW_PARADIGM,/spawn...)
  ;           (the /new_paradigm forces different switches - try that 1st!)
  ;
  ;  Calling Example:
  ;      Get EIT quicklook files for 15-jan-2007 (assuming still online..; otherwise, use ..'eit_lz'.. in place of ..'eit_qkl')
  ;      IDL> wgetc=ssw_wget_mirror('http://umbra.nascom.nasa.gov/eit_qkl/2007/01/15/',curdir(),/spawn,pattern='efr*')
  ;
  ;  Restrictions:
  ;     This routine Purposefully limits wget options to most closely
  ;     mimic the historical perl Mirror while providing (imho) a more
  ;     intuitive ssw interface - if you want fancy/advanced wget options,
  ;     just use wget since you must be an expert - this is wget for dummies.
  ;     (don't ask me why the -mirror option in wget still requires a wrapper,
  ;     such as -nP (noparent) and -nH (nohost), but there it is...)
  ;     If /SPAWn is set, local/client machine must have 'wget' avaialble'
  ;     TODO? - distribute OS/ARCH wget binaries under $SSW_BINARIES
  ;     mirror_file not implemented as of today...
  ;     unix only for today...
  ;
  ;   History:
  ;      17-jan-2007 - S.L.Freeland - preparing for the day when Mirror is
  ;                    phased out for ssw/sswdb distribution/upgrades...
  ;                    this is planned as an ssw_upgrade.pro swapin/option
  ;       6-mar-2007 - S.L.Freeland - ignore robots.txt , add random wait
  ;      20-oct-2007 - S.L.Freeland - add /NEW_PARADIGM keyword+function
  ;                    (different algorithm/switches and ~better)
  ;      12-nov-2007 - S.L.Freeland - made /new_paradigm the default and
  ;                    added /old_paradigm
  ;      15-may-2019 - S.L.Freeland - moved beta/tested -> new name ssw_wget_mirror2.pro
  ;                                   (so I can evolve no-ftp testing unilaterlly vs nascom intervention)
  ;                                    at least until wring out the ssw_upgrade/sswdb_upgrade no ftp options
  ;                                    made
  ;      17-may-2019 - S.L.Freeland - made --no-check-certificate default for https://geturls
  ;      25-jun-2019 - S.L.Freeland - add wget_cmd (and synonym $ssw_wget_cmd) - override out of box 'wget'
  ;      25-jul-2019 - S.L.Freeland - add /LOUD & /VERBOSE (synonyms) and made quiet/aka NON-VERBOSE the default
  ;      25-Jul-2019 - W.T.Thompson - change "l inf" to "-l inf", and removed duplicated -P switch
  ;      31-Jul-2019 - W.T.Thompson - increase cdirs by one to avoid duplicated directories.
  ;      26-Aug-2019 - W.T.Thompson - use SSW_WGET_CLEANUP2
  ;      23-Sep-2019 - A.K.Tolbert  - add -v to wget options when loud is 0 to make it very quiet, pass loud
  ;                                   to ssw_wget_cleanup2. Add a command saying Updating dir for each dir,
  ;                                   so user can tell it's making progress. Changed some () to [].
  ;-
  ;
  case 1 of
    data_chk(mirror_file,/string): begin
      box_message,'MIRROR_FILE input not yet implemented...'
      return,''
    endcase
    n_params() eq 0: begin
      box_message,'Must supply MIRROR_FILE or geturls input'
      return,''
    endcase
    n_params() eq 1:begin
      outdirs=curdir() ; no user supplied output
    endcase
    else:
  endcase

  nurl=n_elements(geturls)
  nout=n_elements(outdirs)

  case 1 of
    nurl eq nout:
    nout eq 1: outdirs=replicate(outdirs(0),nurl)
    else: begin
      stop,'??
      box_message,'Number OUTDIRS ne number GETURLS, returning...'
      return,''
    endcase
  endcase
  nowait=1-keyword_set(wait) ; per Scotty, reversed the polarity WAIT to NOWAIT, 15-may-2019

  loud=keyword_set(loud) or keyword_set(verbose)
  case 1 of
    data_chk(pattern,/string): apat=' -A "'+pattern+'" '
    data_chk(accept,/string):  apat=' -A "'+accept +'" '
    else: apat=' '
  endcase
  if n_elements(wget_cmd) eq 0 then wget_cmd='wget'
  if keyword_set(site) then wget=concat_dir('$SSW/site/bin',wget)
  waits=(['--wait=2 --random-wait ',''])(keyword_set(nowait))
  certs=(['',' --no-check-certificate '])(strpos(geturls[0],'https://') ne -1)
  no_passive_ftp=(['',' --no-passive-ftp'])(keyword_set(nopassive))
  quiet=([' -nv -q ',''])(loud)


  wcmd="cd "+outdirs + "; wget -mirror -np -nH -erobots=off " + $
  quiet + certs + waits + apat + no_passive_ftp +  geturls


  new_paradigm=1-keyword_set(old_paradigm) ; /NEW_PARADIGM=default 12-nov-2007
  if new_paradigm then begin
    ;  SLF - added this different approach circa 20-oct-2007
    ;  I believe more Mirror like and less likely to behave wierdly
    break_url,geturls,ip,path
    path=str_replace(path,'//','/')
    np=n_elements(path)
    cdirs=lonarr(np)
    for i=0,np-1 do cdirs[i]=n_elements(where_pattern(path[i],byte('/'),ndirs)) - (strlastchar(path[i]) eq '/') + 1
    if n_elements(add_cut_dirs) eq 0 then add_cut_dirs=0
    cutdirs=' --cut-dirs='+strtrim(cdirs+add_cut_dirs,2)+' '
    wcmd=wget_cmd + quiet + ' -np -nH -N -r -l inf -erobots=off -P ' + outdirs + $
      ' ' +  certs + waits + no_passive_ftp + apat + cutdirs + geturls
    if get_logenv('check_wget') ne '' then stop,'wcmd'
  endif
  cleanup=keyword_set(cleanup)
  if keyword_set(spawn) then begin
    cur=curdir()
    for i=0,nurl-1 do begin
      print,'Updating ' + outdirs[i]
      if not file_exist(outdirs[i]) then mk_dir,outdirs[i]
      cd,outdirs[i]
      if get_logenv('check_wget') ne '' then stop,'outdirs,geturls'
      espawn, wcmd[i]
      if cleanup then print, 'Cleaning up after wget...'
      if cleanup then ssw_wget_cleanup2,outdirs[i],geturls[i], loud=loud ; remove residual wget crap
    endfor
    cd,cur
  endif

  return,wcmd
end

