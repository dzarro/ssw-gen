pro ssw_install_bin, tempdir=tempdir, bin_dir=bin_dir , version=version, $
   config_flags=config_flags, debug=debug, $
   lftp=lftp, wget=wget, bin_name=bin_name
; 
;+
;   Name: ssw_intall_bin
;
;   Purpose: get/compile/build SSW helper binary; lftp or most recent gnu version of wget w/SSL support
;
;   Input Parameters:
;      None for now
;
;   Keyword Parameters:
;      tempdir - where to do the transfer/gunzip/tar extract/cd/.config/make!
;      builddir - synonym for 'tempdir'
;      version - optional lftp/wget version - default=Latest - STRING, like '1.19.4' or '1.18'
;      bin_dir - where to copy the bin executable; Default=$SSW/site/bin/OS_ARCH/ (see ssw_bin.pro)
;      config_flags - optional user flags-> ./configure; default assume Not root priv (local install)
;               defconfig=' --prefix=/usr --sysconfdir=/etc --with-ssl=openssl'      
;      root_install (switch) - if set & user=root, attempt root install
;      debug (switch) - if set, halt before return "to check stuff"
;      wget (swtich) - if set, do the gnu-wget w/ssl
;      lftp (switch) - if set, lfto w/ssl
;      bin_name - name of desired binarty (future use beyond wget/lftp apps)

;   History:
;      1-Aug-2019 - S.L.Freeland - wget build for build dummies (like me)
;                   Based on success use cases by Phil Shirts, Alberto...
;     21-Feb-2020 - S.L.Freeland - add lftp w/SSL  build for dummnies - generalize a bit for wget&lftp(&future?)
;                   Default install -> $SSW/site/bin/OS_ARCH
;      2-mar-2020 - S.L.Freeland - add --without-gnutls to ./configure --with-openssl line (due to google -> adhoc success - I have no clue about the Why)
;
;   Method
;      source tar.gz(cURL) ->unzip-tar extract -> configure -> make -> wget binar(?)
;   
;   Restrictions: yes, maybe Linux only for next few minutes; /root_install requires user=root
;- 
debug=keyword_set(debug)

case 1 of
   keyword_set(builddir): tempdir=buildir
   keyword_set(tempdir):
   else: tempdir=get_temp_dir()
endcase

case 1 of
   keyword_set(bin_name):
   keyword_set(wget) : bin_name='wget'
   else: bin_name='lftp'
endcase

build_dir=concat_dir(tempdir,bin_name +'_' +time2file(reltime(/now)))
cdir=curdir() ; save current directory for return post build...
case bin_name of
   'wget': begin
     source='https://ftp.gnu.org/gnu/wget/'  ; only this source for now
     if n_elements(version) eq 0 then wversion='latest' else wversion=version
     source=source+'wget-'+wversion+'.tar.gz'
   endcase
   'lftp': source='http://lftp.yar.ru/ftp/lftp-4.9.1.tar.gz'
   'pkg-config': begin
      source='https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz'
      config_flags=' '
   endcase
   else: begin
      box_message,'Sorry, no support yet for >> ' + bin_name[0] +' ..., returning with no action'
      return
   endcase
endcase 
need = ' -O '+source
proxy=get_logenv('http_proxy') ; assumed set via sswidl IDL_STARTUP
sproxy=([' ',' --proxy '+ proxy])(proxy ne '')
curlcmd='curl' + sproxy +  need
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
      root=keyword_set(root_install) and get_user() eq 'root'
      defconfig=(['',' --prefix=/usr --sysconfdir=/etc'])(root) + '--with-openssl --without-gnutls' ;' --with-ssl=openssl'
      if ~ keyword_set(config_flags) then config_flags=defconfig
      config='./configure '+ config_flags
      cd,wdir
      box_message,'Running>> ' + config
      spawn,config
      makefile=findfile('Makefile')
      if file_exist(makefile) then begin
         box_message,'Apparently, got a Makefile! so running make'
         spawn,['make'],/noshell
      endif else begin
         box_message,'No Makefile, so guess out of box .configure problem, sorry'
      endelse
      binary=file_search(build_dir,bin_name)
      if file_exist(binary) then begin 
         box_message,['Wow, looks like got a binary! ',binary],nbox=3
         spawn,[binary,'--version'],/noshell
      endif else box_message,'Sorry, no '+bin_name+ ' binary generated?
   endelse
endelse
cd,cdir ; return to initial path...
if debug then stop,'before return, curcmd,gz,tar,wg,config,...'

return

end


