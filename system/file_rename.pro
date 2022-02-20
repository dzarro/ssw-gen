;+
; Project     : HESSI
;                  
; Name        : FILE_RENAME
;               
; Purpose     : wrapper around FILE_MOVE that catches errors
;                             
; Category    : system utility
;               
; Syntax      : IDL> file_rename,file1,file2
;
; Inputs      : FILE1 = input file to rename
;                                        
; Outputs     : FILE2 = newly named file
;
; Keywords    : 
;               VERBOSE = Set for verbose output
;               ERR = Error message
;                   
; History     : 1-Dec-2019, Zarro (ADNET)
;              30-Dec-2019, Zarro (ADNET
;               - added check for scalar filenames.
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro file_rename,file1,file2,_extra=extra,verbose=verbose,err=err

err=''
verbose=keyword_set(verbose)

if is_blank(file1) then begin
 err='Missing input filename.'
 if verbose then mprint,err
 return
endif

if is_blank(file2) then begin
 err='Missing output filename.'
 if verbose then mprint,err
 return
endif

if (n_elements(file1) gt 1) || (n_elements(file2) gt 1) then begin
 err='Input/Output filenames must be scalar strings.'
 if verbose then mprint,err
 return
endif
 
dfile1=strtrim(file1,2)
dfile2=strtrim(file2,2)

if file_test(dfile1,/dir) then begin
 err='Input file cannot be directory.'
 if verbose then mprint,err
 return
endif

if ~file_test(dfile1,/reg) then begin
 err='Input file not found.'
 if verbose then mprint,err
 return
endif

error=0
catch,error
if error ne 0 then begin
 err=err_state()
 if verbose then mprint,err
 catch,/cancel
 message,/reset
 return
endif

cd,curr=cdir
dir1=file_dirname(dfile1)
dir2=file_dirname(dfile2)
name1=file_basename(dfile1)
name2=file_basename(dfile2)

if is_blank(dir1) || (dir1 eq '.') then dir1=cdir
if is_blank(dir2) || (dir2 eq '.') then dir2=cdir

if ~file_test(dir2,/direc,/write) then begin
 err='No write access to - '+dir2
 if verbose then mprint,err
 return
endif

f1=local_name(concat_dir(dir1,name1))
f2=local_name(concat_dir(dir2,name2))

if f1 eq f2 then return

file_move,f1,f2,/overwrite,/allow_same,_extra=extra

return

end
