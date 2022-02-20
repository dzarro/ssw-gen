pro ssw_install_wget, tempdir=tempdir, wget_dir=wget_dir , version=version, $
   config_flags=config_flags, debug=debug
; 
;+
;   Name: ssw_intall_wget
;
;   Purpose: get/compile/build most recent gnu version of wget w/SSL support
;
;   Input Parameters:
;      None for now
;
;   Keyword Parameters:
;      tempdir - where to do the transfer/gunzip/tar extract/cd/.config/make!
;      version - optional wget version - default=latest - STRING, like '1.19.4' or '1.18'
;      wget_dir - where to copy the wget executable
;      config_flags - optional user flags-> ./configure
;                     (defaults as of now are per Phil Shirts Linux build
;               defconfig=' --prefix=/usr --sysconfdir=/etc --with-ssl=openssl'      
;      debug (switch) - if set, halt before return "to check stuff"
;
;   History:
;      1-Aug-2019 - S.L.Freeland - wget build for build dummies (like me)
;                   Based on success use cases by Phil Shirts, Alberto...
;
;   Method
;      gnu source tar.gz(cURL) ->unzip-tar extract -> configure -> make -> wget binar(?)
;   
;   Restrictions: yes, maybe Linux only for next few minutes
;- 
debug=keyword_set(debug)

source='https://ftp.gnu.org/gnu/wget/'  ; only this source for now
if n_elements(version) eq 0 then wversion='latest' else wversion=version
need=' -O ' + source+'wget-'+wversion+'.tar.gz'
proxy=get_logenv('http_proxy') ; assumed set via sswidl IDL_STARTUP
sproxy=([' ',' --proxy '+ proxy])(proxy ne '')
curlcmd='curl' + sproxy +  need
wget_dir='wget_'+time2file(reltime(/now)) ; current UTC subdirectory
if n_elements(tempdir) eq 0 then tempdir=get_temp_dir()
build_dir=concat_dir(tempdir,wget_dir)
cdir=curdir() ; save current directory for return post build...
mk_dir,build_dir & cd,build_dir
box_message,['Using build directory >> '+ build_dir, $
             'Transfering source to local via >> ' , $
             curlcmd]

spawn,curlcmd
gz=findfile('*tar.gz')
if ~ file_exist(gz) then begin
   box_message,'Problem with cURL tranfer cmd= ' + need
endif else begin
   box_message,'Uncompressing ' + gz
   spawn,['gunzip',gz],/noshell
   tar=findfile('*tar')
   box_message,'Extracting tar '+ tar[0]
   spawn,['tar','-xf',tar[0]],/noshell
   wg=findfile()
   ssd=where(is_dir(wg),dcnt)
   if dcnt ne 1 then begin
      box_message,'Problem w/tar extract/unexpected# of directories!'
   endif else begin ; 'Now have wget directory + implied version info
      wdir=wg[ssd[0]]
      box_message,'Building ' + wdir
      defconfig=' --prefix=/usr --sysconfdir=/etc --with-ssl=openssl'
      if ~ keyword_set(config_flags) then config_flags=defconfig
      config='./configure '+ config_flags
      cd,wdir
      box_message,'Running>> ' + config
      spawn,strtrim(str2arr(config,' '),2)
      makefile=findfile('Makefile')
      if file_exist(makefile) then begin
         box_message,'Apparently, got a Makefile! so running make'
         spawn,['make'],/noshell
      endif else begin
         box_message,'No Makefile, so guess out of box .configure problem, sorry'
      endelse
      wget=file_search(build_dir,'wget')
      if file_exist(wget) then begin 
         box_message,['Wow, looks like got a wget binary! ',wget],nbox=3
         spawn,[wget,'--version'],/noshell
      endif else box_message,'Sorry, no wget generated?
   endelse
endelse
cd,cdir ; return to initial path...
if debug then stop,'before returncurcmd,gz,tar,wg,config,...'

end


