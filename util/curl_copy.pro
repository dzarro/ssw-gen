pro curl_copy, remote_urls, local_paths, out_dir=out_dir, debug=debug, $
       proxy=proxy, no_proxy=no_proxy,  loud=loud, verbose=verbose, $ 
       no_spawn=no_spawn, spawn=spawn, $
      _extra=_extra, windows_test=windows_test, curl_path=curl_path, local_file=local_file 

;
;+  
;   Name: curl_copy
;
;   Purpose: generate, &  optionally spawn implied cURL commands for user remote_url(s) -> local copy/transfer
;
;   Input Parameters:
;      remote_urls - vector of one or more remote_urls desired
;      local_paths - optional vector for local copy - 1:1 remote_urls; if scalar and > 1 remote, all direct to this
;                    (see OUT_DIR for alternative Keyword option as copy redirect - default is current dir if neither specified)
;
;   Output:
;      only via keywords below, LOCAL_FILE, CURL_COMMANDS...
;
;   Keyword Parameters:
;      out_dir - keyword synonym for LOCAL_PATHS, same rules (allow sock_copy.pro-like API/swap-in)
;      proxy - optional local proxy IP required (def=$http_proxy, NONE if neither defined)
;      no_proxy (switch) - don't add the proxy bit to derived cURL command, even if $http_proxy defined
;      loud/verbose (switches) - synonyms to increase verbosity
;      spawn - (switcH) if set, spawn/execute the derived cURL commands - (default ala sock_copy
;      background - (switch) if set, derived commands include backgrounding piece (unix only for today)
;      script - if set, write derived cURL commands to .[t]csh script - name of cURL command script
;      windows_test - (switch) - if set, pretend you are running on WinXX machine for command derivations...
;      curl_path - optional path to curl on local machine - default assumes 'curl' installed/visible out of the box
;      local_file - Output, full path to local files ( following sock_copy API)
;      curl_commands - Output, the derived curl commands (for example, use with /NO_SPAWN for sanity check prior to commit
;
;   Calling Sequence:
;      IDL> curl_copy,remote_urls [,local_paths]  [,out_dir=out_dir] [,local_file=local_file] [,curl_commands=cmds], [,/NO_SPAWN] [script='<name>.csh'] [,/back
;
;   Motivation: based on ssw_install FORM curl derivations, which seem to work on all OS/ARCH (IDL version & IDL independent) 
;               but required for IDL versions < 8.4 copies from https/SSL via IDL http object https support >=8.4
;               offers 'sock_copy.pro' (Dominc Zarro) swap-in/version dependent option for [ https: + IDL version < 8.4 , SSL support in the cURL)
;
;   History:
;      27-jul-2020 - S.L.Freeland - finallyknocked out - ssw_curl_commands -> curl_copy
;
;   Rescriptions:
;      limited  to basic curl remote url(s) -> local file(s); curl probably way more capable, but all we need for now...
;      Some keywords/options not enabled until Tomorrow - check back ( SCRIPT=, /BACKGROUND...) should do copies though
;-
;
if n_params() lt 1 then begin
   box_message,'Need at least One input remote url to help you out... returning with no action'
   return
endif
debug=keyword_set(debug)

turl=strlowcase(strtrim(remote_urls,2)) ; test url - (assume All either 'http' -or- 'https' for now)
https=strpos(turl[0],'https:') eq 0

if 1-file_exist(curl_path) then curl_path='curl' ; default is out of the box curl in local machine path ; supply ia keyword if not/or desired SSL version
cdir=curdir() ; current PWD
nfiles=n_elements(remote_urls)

case 1 of
   n_params() gt 1: begin
      box_message,'local_paths input
      break_file,local_paths,ll,pp,ff
      allp=all_vals(pp)
      out_dirs=pp ; 1:1 target out_dir
   endcase
   data_chk(out_dir,/string): out_dirs=replicate(out_dir[0],nfiles); user supplied OUT_DIR
   else: out_dirs=replicate(cdir,nfiles) ; default = current pwd
endcase

http_proxy=strtrim(get_logenv('http_proxy'),2)
https_proxy=strtrim(get_logenv('https_proxy'),2)
cdir=curdir() ; 
proxy=''
case 1 of 
   https_proxy ne '' and https: proxy=https_proxy
   http_proxy ne '' : proxy=http_proxy
   else: proxy=''
endcase 
if proxy ne '' and strpos(proxy,'://') eq -1 then proxy='http://'+proxy
curl_commands=curl_path + ([' ',' --proxy '+proxy[0]])(proxy[0] ne '') +    $
                     ' -O ' + remote_urls

spawnit=~keyword_set(no_spawn)
local_file=concat_dir(out_dirs,ssw_strsplit(remote_urls,'/',/tail))
if spawnit then begin 
   mk_dir,all_vals(out_dirs)  ; create dirs if needed - (TODO? only on request
   for od=0,nfiles-1 do begin
      cd,out_dirs[od] ; don't see an OUT_DIR equiv option for curl, so just move there, hope for no crash before CD,PWD restore.... 
      spawn,curl_commands[od]
   endfor
   cd,cdir ; restore init PWD
endif 

if debug then stop,'curl_commands,local_file'
return 
end



   
