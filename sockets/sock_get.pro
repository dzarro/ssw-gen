;+
; Project     : VSO
;
; Name        : SOCK_GET
;
; Purpose     : Wrapper around IDLnetURL object to download
;               files via HTTP and FTP
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_get,url,out_name,out_dir=out_dir
;
; Inputs      : URL = remote URL file name to download
;               OUT_NAME = optional output name for downloaded file
;
; Outputs     : See keywords
;
; Keywords    : LOCAL_FILE = Full name of copied file
;               OUT_DIR = Output directory to download file
;               CLOBBER = Clobber existing file
;               STATUS = 0/1/2 fail/success/file exists
;               CANCELLED = 1 if download cancelled
;               PROGRESS = Show download progress
;               NO_CHECK = don't check remote server for valid URL.
;                          Use when sure that remote file is
;                          available
;               QUIET = turn off all messages [def = VERBOSE]
;
; History     : 27-Dec-2009, Zarro (ADNET) - Written
;                8-Oct-2010, Zarro (ADNET) - Dropped support for
;                COPY_FILE. Use LOCAL_FILE.
;               28-Sep-2011, Zarro (ADNET) - ensured that URL_SCHEME
;               property is set to that of input URL   
;               19-Dec-2011, Zarro (ADNET) 
;                - made http the default scheme
;               7-Sep-2012, Zarro (ADNET)
;                - added more stringent check for valid HTTP status code
;                  200
;               27-Sep-2012, Zarro (ADNET)
;                - added check for FTP status code
;               27-Dec-2012, Zarro (ADNET)
;                 - added /NO_CHECK
;               12-Mar-2012, Zarro (ADNET)
;                 - replaced SOCK_RESPONSE by SOCK_HEAD
;               25-May-2014, Zarro (ADNET)
;                 - vectorized
;                 - use FILE_MOVE,/OVERWRITE instead of FILE_DELETE
;               20-Oct-2014, Zarro (ADNET)
;                 - added more header error checking
;               3-Nov-2014, Zarro (ADNET)
;                 - relaxed some error checking
;               8-Nov-2014, Zarro (ADNET)
;                 - improved FTP support
;               18-Nov-2014, Zarro (ADNET)
;                 - added check for local vs remote timestamps
;                 - sped up progress bar by reducing plot updates
;               25-Nov-2014, Zarro (ADNET)
;                 - can now set PROGRESS to value between 1 and 100%
;                   (e.g. PROGRESS=20 to update every 20%)
;                 - check timestamp of remote file for newer version
;                   (requires making CHECK the default)
;               5-Feb-2015, Zarro (ADNET)
;                 - added additional checks for failed downloads
;               10-Feb-2015, Zarro (ADNET)
;               - pass input URL directly to IDLnetURL2 to parse
;                 PROXY keyword properties in one place
;               28-Nov-2015, Zarro (ADNET)
;               - check for blank file name in queries
;               4-Sep-2016, Zarro (ADNET)
;               - added check for DISPOSITION name
;               16-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX
;               30-Sep-2016, Zarro (ADNET)
;               - added QUIET and improved error checking
;               10-Oct-2016, Zarro (ADNET)
;               - added check for URL redirect
;               7-Nov-2016, Zarro (ADNET)
;               - return error message for invalid input URL
;               12-Nov-2016, Zarro (ADNET)
;               - fixed bug caused by blank file name in QUERY string
;               30-January-2017, Zarro (ADNET)
;               - added check for SSL support
;               10-March-2017, Zarro (ADNET)
;               - removed check for newer file for queries 
;               23-June-2017, Zarro (ADNET)
;               - force download for query URL's
;               5-Aug-2017, Zarro (ADNET)
;               - inhibit progress bar when running in Python-IDL bridge mode as it can
;                 crash the widget manager on some systems.
;               8-December-2017, Zarro (ADNET)
;               - added more error checking
;               3-January-2018, Zarro (ADNET)
;               - replace temp download file name with unique session ID to
;                 avoid collisions.
;               1-May-2018, Zarro (ADNET)
;               - removed duplicate call to FILE_CHMOD
;               28-May-2018, Zarro (ADNET)
;               - skip calling sock_check for FTP
;
;-

;-----------------------------------------------------------------  
function sock_get_callback, status, progress, data  

if (progress[0] eq 1) && (progress[1] gt 0) then begin
 if ptr_valid(data) then begin
  (*data).completed=progress[1] eq progress[2]
  val = float(progress[2])/float(progress[1])
  pval=100.*val
  if ~(*data).completed && ~(*data).cancelled then begin
   if ~widget_valid( (*data).pid) then begin
    bsize=progress[1]
    bmess=trim(str_format(bsize,"(i10)"))
    cmess=['Please wait. Downloading...','File: '+(*data).file,$
           'Size: '+bmess+' bytes',$
           'From: '+(*data).server,$
           'To: '+(*data).ofile]
    (*data).pid=progmeter(/init,button='Cancel',_extra=extra,input=cmess)
   endif
  endif 
 
  if (pval ge (*data).bar) then begin
   if widget_valid((*data).pid) then begin
    if (progmeter((*data).pid,val) eq 'Cancel') then begin
     xkill,(*data).pid
     (*data).cancelled=1b
     return,0
    endif else (*data).bar=(*data).bar+(*data).init
   endif
  endif 
 endif
endif

if ~exist(bsize) then bsize=0l
if ptr_valid(data) then begin
 (*data).bsize=bsize
 if ((*data).completed || (*data).cancelled) then xkill,(*data).pid
endif
 
return, 1
end

;-----------------------------------------------------------------------------

pro sock_get_main,url,out_name,clobber=clobber,local_file=local_file,no_check=no_check,$
  progress=progress,err=err,status=status,cancelled=cancelled,$
  out_dir=out_dir,_ref_extra=extra,verbose=verbose,$
  debug=debug,quiet=quiet

err='' & status=0

verbose=keyword_set(verbose)
quiet=keyword_set(quiet)
loud= verbose || ~quiet

error=0
catch,error
if (error ne 0) then begin
 if keyword_set(debug) then begin
  mprint,err_state()
  if obj_valid(ourl) then begin
   ourl->getproperty,response_code=rcode
   mprint,'Response code = '+trim(rcode)
  endif
 endif
 catch, /cancel
 message,/reset  
 goto,bail  
endif
  
cancelled=0b
local_file=''
clobber=keyword_set(clobber)

stc=url_parse(url)
file=file_break(stc.path)
path=file_break(stc.path,/path)+'/'
query=stc.query

if is_blank(file) && is_blank(path) then begin
 err='File name not included in URL path.'
 if loud then mprint,err
 return
endif

;-- default copying file with same name to current directory
 
odir=curdir()
ofile=file
if n_elements(out_name) gt 1 then begin
 err='Output filename must be scalar string.'
 if loud then mprint,err
 return
endif

if is_string(out_name) then begin
 tdir=file_break(out_name,/path)
 if is_string(tdir) then odir=tdir 
 ofile=file_break(out_name)
endif
if is_string(out_dir) then odir=out_dir
if ~test_dir(odir,verbose=loud,err=err) then return

bsize=0l & chunked=0b & ok=1b & rdate='' & code=404 & disposition=''
durl=url_fix(url,_extra=extra)

use_ftp=is_ftp(durl)
pre_check=~keyword_set(no_check) && is_blank(query) && ~use_ftp
if pre_check then begin
 for i=0,1 do begin
  ok=sock_check(durl,chunked=chunked,disposition=disposition,size=bsize,$
               _extra=extra,date=rdate,code=code,debug=debug,$
                location=location,response_code=ocode)
  if ~ok then begin
   sock_error,durl,code,response_code=ocode,err=err,verbose=loud
   return
  endif

  if keyword_set(debug) then begin
   print,'% DISPOSITION: ',disposition
   print,'% RDATE: '+rdate
   print,'% BSIZE: '+trim(bsize)
  endif

;-- check if redirecting

  if is_string(location) then begin
   if loud then mprint,'Redirecting to '+location
   durl=url_fix(location,_extra=extra)
  endif else begin
   if is_string(disposition) then ofile=disposition
   break
  endelse
 endfor
endif

;-- if file exists, download a new one if /clobber or local size or time
;   differs from remote

ofile=local_name(concat_dir(odir,ofile))
osize=0l
have_file=file_test(ofile,/regular)
if have_file then osize=file_size(ofile)

;-- check if remote file is newer
;   (a URL query doesn't have a remote timestamp, so we don't check in
;   this case) 

newer_file=1b
if valid_time(rdate) && have_file then begin
 local_time=anytim(file_time(ofile))
 remote_time=anytim(rdate)+ut_diff(/sec)
 dprint,'% Remote file time: ',anytim(remote_time,/vms)
 dprint,'% Local file time: ',anytim(local_time,/vms)
 newer_file=remote_time gt local_time
 if loud then if newer_file then mprint,'Remote file is newer than local file.'
endif

size_change=1b
if (bsize gt 0) && (osize gt 0) then size_change=(bsize ne osize)

download=~have_file || clobber || size_change || newer_file || is_string(query)
if ~download then begin
 if loud then mprint,'Identical local file '+ofile+' already exists (not downloaded). Use /clobber to re-download.'
 local_file=ofile
 status=2
 return
endif

;-- initialize object 

ourl=obj_new('idlneturl2',durl,_extra=extra,debug=debug)

;-- show progress bar?

if keyword_set(progress) && ~is_pyidl() then begin
 if ~chunked && (bsize ne 0) then begin
  bar= 100. <  float(progress) > 10.
  if allow_windows() && (bar lt 100.) then begin
   callback_function='sock_get_callback'
   init=bar
   callback_data=ptr_new({file:file_basename(ofile),server:stc.host,ofile:ofile,pid:0l,bsize:bsize,init:init,$
    bar:bar,cancelled:0b,completed:0b})
   ourl->setproperty,callback_data=callback_data,callback_function=callback_function
  endif
 endif
endif

;-- download into temporary file and then rename to output file 

if loud then t1=systime(/seconds)
t_ofile=ofile+session_id()

result = ourl->Get(file=t_ofile)  

;-- check what happened

bail: 

ourl->getproperty,response_header=response,response_code=ocode
obj_destroy,ourl

if ptr_valid(callback_data) then begin
 if (*callback_data).cancelled then begin
  err='Download cancelled.' 
  if loud then mprint,err
  cancelled=1b
  return
  heap_free,callback_data
 endif
endif

sock_content,response,code=code,disposition=disposition,date=rdate,size=bsize
chk=file_info(t_ofile)
tsize=chk.size

;-- check all failure possibilities

scode=strmid(trim(code),0,1)
case 1 of
  scode ne '2': begin
  success=0b
  err='Download failed with HTTP status code: '+trim(code)
 end
 ~chk.exists: begin
   err='Downloaded file not written to disk - check write access.'
   success=0b
 end
 tsize eq 0: begin
   err='Downloaded file has zero byte size - check disk space.'
  success=0b
 end
 (bsize gt 0) && (tsize gt 0) && (tsize ne bsize): begin
   err='File failed to download completely - possible network timeout.'
   help,tsize,bsize
   success=0b
 end
  is_blank(result): begin
   success=0b
   err='File download failed - check URL.'
  end
else: success=1b
endcase

if ~success then begin
 if is_string(err) && scode eq '2' then mprint,err else $
  sock_error,durl,code,response_code=ocode,err=err,verbose=loud
 if is_string(t_ofile) then file_delete,t_ofile,/quiet,/noexpand_path,/allow_nonexistent
 return
endif

;-- update downloaded filename to original name

if is_string(disposition) then begin
 bfile=file_basename(ofile)
 if disposition ne bfile then ofile=concat_dir(odir,disposition)
endif
 
bsize=tsize
if loud then begin
 t2=systime(/seconds)
 tdiff=t2-t1
 m1=trim(string(bsize,'(i10)'))+' bytes of '+file_basename(ofile)
 m2=' copied in '+strtrim(str_format(tdiff,'(f8.2)'),2)+' seconds.'
 mprint,m1+m2
endif

file_move,t_ofile,ofile,/overwrite,/allow_same
file_chmod,ofile,/a_read,/a_write 
local_file=ofile
status=1

;-- update timestamp of downloaded file to local time
   
if valid_time(rdate) then begin
 local_time=anytim(anytim(rdate)+ut_diff(/sec),/vms)
 file_touch,ofile,local_time
endif

return & end  

;-----------------------------------------------------------------------
  
pro sock_get,url,out_name,local_file=local_file,_ref_extra=extra,$
                     status=status,err=err,cancelled=cancelled

local_file=''
if ~since_version('6.4') then begin
 err='Requires IDL version 6.4 or greater.'
 mprint,err
 return
endif

if ~is_url(url) then begin
 pr_syntax,'sock_get,url,out_dir=out_dir'
 err='Input must be valid URL.'
 return
endif

np=n_elements(url)
if is_string(out_name) then begin
 if (n_elements(out_name) ne np) then begin
  err='Number of elements of output file name and input URL must match.'
  mprint,err
  return
 endif
endif else out_name=strarr(np)
local_file=strarr(np)

for i=0,np-1 do begin
 sock_get_main,url[i],out_name[i],local_file=lfile,err=err,status=status,$
               cancelled=cancelled,_extra=extra
 if is_string(err) || (status eq 0) || cancelled then continue
 local_file[i]=lfile
endfor

if np eq 1 then local_file=local_file[0]

return & end
