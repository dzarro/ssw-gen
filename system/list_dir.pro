;+
; Project     : EIS
;
; Name        : LIST_DIR
;
; Purpose     : fast directory listing
;
; Category    : utility system
;
; Syntax      : IDL> dirs=ls_dir(indir)
;
; Inputs      : INDIR = directory to search
;
; Outputs     : DIRS = directories in INDIR
;
; Keywords    : COUNT = # of directories found
;
; History     : Written, 29 April 2003, D. Zarro (L-3Com/GSFC)
;               Modified, 3 March 2007, Zarro (ADNET)
;               - improved error checking
;               11-Nov-2016, William Thompson, GSFC - rewrote to use FILE_SEARCH
;               12-Nov-16, Zarro (ADNET) - added call to GET_UNIQ
;
; Contact     : dzarro@solar.stanford.edu
;-

function list_dir,dir,count=count,err=err

forward_function file_test

err=''
count=0
if is_blank(dir) then begin
 err='Directory name not entered.'
 mprint,err
 return,''
endif

odir=strtrim(dir,2)
if ~file_test(odir,/directory) then begin
 err='Invalid directory - '+dir
 mprint,err
 return,''
endif

dirs=file_search(concat_dir(odir,'*'), /test_directory, count=count)
if count eq 1 then dirs=dirs[0]
if count gt 1 then dirs=get_uniq(dirs)
return,dirs
end


