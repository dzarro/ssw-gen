;+
; Project     : STEREO
;
; Name        : RICE_DECOMP
;
; Purpose     : Decompress RICE compressed file
;
; Category    : system utility 
;
; Syntax      : IDL> rfile=rice_decomp(file)
;
; Inputs      : FILE = RICE compressed file name
;
; Outputs     : RFILE = decompressed file name
;
; Keywords    : ERR= error string
;               OUT_DIR = output directory for decompressed file
;
; History     : 21-Nov-2011, Zarro (ADNET) - written
;               23-Dec-2014, Zarro (ADNET)
;                - moved input error checking to is_rice_comp
;               18-July-2016, Zarro (ADNET)
;                - added OUT_DIR
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-
                                                                                         
function rice_decomp,file,err=err,_ref_extra=extra,verbose=verbose,out_dir=out_dir

err=''

verbose=keyword_set(verbose)
if ~is_rice_comp(file,_extra=extra,err=err,verbose=verbose) then begin
 if is_string(file) then return,file else return,''
endif

if ~have_proc('mreadfits_tilecomp') then begin
 epath=local_name('$SSW/vobs/ontology/idl/jsoc')
 if is_dir(epath) then add_path,epath,/quiet,/append
 if ~have_proc('mreadfits_tilecomp') then begin
  err='Missing RICE decompressor function - mreadfits_tilecomp.'
  mprint,err,/info
  return,''
 endif
endif

;-- always return to current directory in case we switched or had errors

cd,current=cdir
error=0
catch,error
if error ne 0 then begin
 catch,/cancel
 cd,cdir
 return,''
endif

rdir=file_dirname(file)
rfile=file_basename(file)
if is_blank(out_dir) then out_dir=concat_dir(get_temp_dir(),'rice_decomp') else $
 out_dir=chklog(out_dir,/pre)
mk_dir,out_dir,err=err,/a_write,/a_read
if is_string(err) then return,''

;-- kluge for Windows

if os_family() eq 'Windows' then begin
 cd,rdir & hide=1
endif else rfile=file

mreadfits_tilecomp,rfile,index,/nodata,fnames_uncomp=fname_uncomp,$
 /silent,/noshell,/only_uncompress,_extra=extra,hide=hide,outdir=out_dir

cd,cdir
if ~file_test(fname_uncomp,/read) then begin
 err='RICE decompression failed.'
 mprint,err,/info
 return,''
endif

if verbose then mprint,'Decompressed RICE-compressed file.',/info

return,fname_uncomp

end
