;+
; Name: convert_filename_win2unix
;
; Purpose: Convert windows-style filename(s) to unix style, e.g. C:\ssw\a.txt -> /mnt/c/a.txt 
;   Useful for accessing Windows files through a unix interface installed on Windows.
;   If input filename(s) don't have a '\', then assumed already unix-style, just return filename(s).
; 
; Input argument:
;  filename - scalar or array of filenames with full path
;  
; Input Keywords: 
;  topdir - name of topdir for unix-style name. Defaults to 'mnt'.
;  
; Example:
;   print,convert_filename_win2unix('D:\temp\b.pro')
;      /mnt/d/temp/b.pro
;   print, convert_filename_win2unix('C:\ssw\a\b\c.txt', topdir='newmnt')
;      /newmnt/c/ssw/a/b/c.txt
;      
; Written: Kim Tolbert, 11-Aug-2020
; Modifications:
; 
;-
function convert_filename_win2unix, filename, topdir=topdir_in
  checkvar, topdir_in, 'mnt'
  topdir = '/' + topdir_in + '/'

  if strpos(filename[0], '\') eq -1 then return, filename

  disk = strmid(filename,0, 2)
  newtop = topdir + strmid(strlowcase(disk), 0, 1)
  outfiles = str_replace(filename, disk, newtop)
  outfiles = str_replace(outfiles, '\', '/')
  return, outfiles
end

