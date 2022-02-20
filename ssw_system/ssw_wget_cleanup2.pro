;+
; Project     :	SolarSoft
;
; Name        :	SSW_WGET_CLEANUP2
;
; Purpose     :	Cleanup extra files after wget call
;
; Category    :	SWmaint
;
; Explanation :	Identifies and deletes extraneous files after wget calls.
;               These extraneous files fall into two categories:
;
;                       1. index.html* files created on-the-fly by the server
;                       2. Obsolete files no longer on the server.
;
;               The routine distinguishes on-the-fly index.html files from
;               actual files by the modification time.  If the file is less
;               than six hours old, it's assumed to be on-the-fly.
;
;               Subdirectories are handled recursively.
;
; Syntax      :	SSW_WGET_CLEANUP2, LOCAL, REMOTE
;
; Examples    :	SSW_WGET_CLEANUP2, '$SSW/gen', $
;                       'https://sohoftp.nascom.nasa.gov/solarsoft/gen/', $
;                       N_DELETED
;
; Inputs      :	LOCAL   = The name of the local directory
;               REMOTE  = The remote URL
;
; Opt. Inputs :	None.
;
; Outputs     :	None.
;
; Opt. Outputs:	N_DELETED = Cumulative count of the number of deleted files.
;                           It is incremented in each recursive call.
;
; Keywords    :	NODELETE = If set, then only print a message for files not
;                          found on the server.
;
;		LOUD = If set, then print out informative messages.  The
; 		       default is to suppress the messages.  Setting /NODELETE
; 		       automatically sets /LOUD.
;
;               INCREMENT = An internal keyword used to signal that N_DELETED
;                           should be incremented instead of initialized.
;
;               PARENT_NAMES = An internal keyword used to pass in the names of
;                              directories found on the server in the parent
;                              of the directory currently being processed.
;
; Calls       :	CONCAT_DIR, DELVARX, BREAK_FILE, FILE_EXIST, SOCK_SEARCH
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 15-Aug-2019, William Thompson, GSFC
;               Version 2, 26-Aug-2019, WTT, use six hours for index.html
;               Version 3, 03-Sep-2019, WTT, rewrote to parse index.html
;		Version 4, 23-Sep-2019, A.K. Tolbert, add LOUD keyword
;               Version 5, 25-Oct-2019, WTT, add logic for removing directories
;                       Merge index.html and sock_search versions.
;                       If index.html not found, then tries sock_search.
;               Version 6, 29-Oct-2019, WTT, don't parse index.html
;                       files more than a day old.
;                       Trim "./" from parsed remote filenames.
;               Version 7, 25-Feb-2020, WTT, handle empty directories.
;                       Fewer constraints on deleting files if index.html files
;                       are found.
;               Version 8, 14-Apr-2020, WTT, catch errors deleting files
;
; Contact     :	WTHOMPSON
;-
;
pro ssw_wget_cleanup2, local, remote, n_deleted, nodelete=nodelete, $
                       increment=increment, loud=k_loud, $
                       parent_names=parent_names
;
on_error, 2
if n_params() lt 2 then begin
    message, /continue, 'Syntax: SSW_WGET_CLEANUP2, LOCAL, REMOTE [, N_DELETED]'
    goto, test_dirs
endif
;
loud = keyword_set(k_loud) or keyword_set(nodelete)
;
;  If not already done, initialize N_DELETED.
;
if not keyword_set(increment) then n_deleted = 0
;
;  Print out the name of the local directory, and the remote site that it's
;  being compared to.  The same will be done on any traversed subdirectories.
;
if loud then begin
    print, 'Comparing ' + local
    print, 'with ' + remote
endif
;
;  Get a list of the local files which are not directories, and also a list of
;  the directories.
;
test_string = concat_dir(local, '*')
local_files = file_search(test_string, /test_regular, count=local_count)
dirs = file_search(test_string, /test_directory, count=ndirs)
;
;  For comparison purposes, separate the local filenames from their paths.
;
break_file, local_files, disk, dir, name, ext
local_names = name + ext
delvarx, not_found
;
;  If any were found, then get a list of the remote files by parsing the
;  index.html file.  If there is no index.html file, and if using IDL 8.3 or
;  above, try using the sock_search method instead.
;
test_dir_delete = 0
if local_count eq 0 then test_dir_delete = 1 else begin
    htmlfile = concat_dir(local, 'index.html')
    if not file_exist(htmlfile) then begin
        if !version.release ge '8.3' then goto, use_sock_search
        message, /continue, 'File not found: ' + htmlfile
        goto, test_dirs
;
;  If the index.html file is more than a day old, then assume that it
;  wasn't generated as part of the update, and don't try to read it.
;
    end else begin
        info = file_info(htmlfile)
        if systime(1)-info.mtime gt 86400 then begin
            if !version.release ge '8.3' then goto, use_sock_search
            goto, test_dirs
        endif
    endelse
;
    openr, lun, htmlfile, /get_lun
    fstatus = fstat(lun)
    if fstatus.size eq 0 then begin
        message, /continue, 'Empty file: ' + htmlfile
        free_lun, lun
        goto, test_dirs
    endif
;
;  Determine the number of lines in the file by looking for linefeed
;  characters.
;
    btext = bytarr(fstatus.size)
    readu, lun, btext
    wlfs = where(btext eq 10b, lfcount)
    if lfcount eq 0 then text = string(btext) else begin
;
;  Rewind to the start of the file, and read in the lines.
;
        point_lun, lun, 0
        text = strarr(lfcount)
        readf, lun, text
        fstatus = fstat(lun)
;
;  If any text remains, read it in as the last line.
;
        remainder = fstatus.size - fstatus.cur_ptr
        if remainder gt 0 then begin
            lastline = bytarr(remainder)
            readu, lun, lastline
            text = [temporary(text), string(lastline)]
        endif
    endelse
    text = strtrim(text, 2)     ;Remove leading and trailing blanks
    free_lun, lun
;
;  Look for the "Index of ..." line.  Otherwise, this is not a directory
;  listing.
;
    offset = strpos(remote, '://') + 3
    first = strpos(remote, '/', offset)
    teststr = 'Index of ' + strmid(remote, first, strlen(remote)-first)
    last_char = strmid(teststr, strlen(teststr)-1, 1)
    if last_char eq '/' then teststr = strmid(teststr, 0, strlen(teststr)-1)
    test = where(strpos(text, teststr) ne -1)
    if test[0] lt 0 then begin
        if !version.release ge '8.3' then goto, use_sock_search
        message, /continue, 'Not a directory listing: ' + htmlfile
        test_dir_delete = 1
        goto, test_dirs
    endif
;
;  Extract the names of the remote files.
;
    remote_names = strarr(n_elements(text))
    for i=0,n_elements(text)-1 do begin
        href = strpos(text[i], 'href=')
        if href ge 0 then begin
            first = strpos(text[i], '"', href) + 1
            last  = strpos(text[i], '"', first)
            file = strmid(text[i], first, last-first)
            if strmid(file,0,2) eq './' then file = strmid(file,2,strlen(file)-2)
            char = strmid(file,0,1)
            if (char ne '?') and (char ne '/') then remote_names[i] = file
        endif
    endfor
    w = where(remote_names ne '', remote_count)
    if remote_count gt 0 then begin
        remote_names = remote_names[w]
;
;  If no files at all were found on the remote server, then set
;  test_dir_delete.
;
    end else test_dir_delete = 1
;
    parsed_names = remote_names
    used_sock_search = 0
    goto, check_files
;
;  Alternate method using sock_search.
;
use_sock_search:
    used_sock_search = 1
    sock_search, remote, remote_files, err=err, count=remote_count
;
;  If an error occured getting the remote files, then print an error message,
;  but take no further action.
;
    if err ne '' then begin
        message, /continue, err
        test_dir_delete = 1
        goto, test_dirs
    end else begin
;
;  If no files at all were found on the remote server, then test to see if only
;  index.html* files were found on the local server.  Otherwise, set
;  test_dir_delete.
;
        if remote_count eq 0 then begin
            w = where(strmid(local_names, 0, 10) ne 'index.html', count)
            if count gt 0 then begin
                test_dir_delete = 1
                goto, test_dirs
            endif
        endif
;
;  For comparison purposes, separate the remote filenames from their paths.
;
        break_file, remote_files, disk, dir, name, ext
        remote_names = name + ext
    endelse
;
;  For each file on the local server, see if it also exists on the remote
;  server.  Keep track of all the files that are not found.
;
check_files:
    for ifile = 0, local_count-1 do begin
        test_name = local_names[ifile]
        w = where(test_name eq remote_names, count)
;
;  Because of the way that sock_search works, it will not return any files
;  named index.html.  Assume that any such local files that are less than six
;  hours old are temporary files created by wget.
;
        if count eq 0 then begin
            act = 0
            if (test_name eq 'index.html') then begin
                info = file_info(local_files[ifile])
                if systime(1)-info.mtime lt 21600 then act = 1
            end else act = 1
;
;  Store the names of files not found.
;
            if act then boost_array, not_found, local_files[ifile]
        endif                   ;count eq 0
    endfor                      ;ifile
;
;  If none of the local files were found, and if there are no subdirectories,
;  then print out a message, but take no further action if the sock_search was
;  used.
;
    nnf = n_elements(not_found)
    if nnf eq local_count then begin
        w = where(strmid(local_names, 0, 10) ne 'index.html', count)
        if (count gt 0) and (ndirs eq 0) then begin
            message, /continue, 'None of the files in ' + local + $
                     ' were found on the server'
            if keyword_set(used_sock_search) then goto, test_dirs
        endif
    endif
;
;  Delete the files which were not found.
;
    if nnf gt 0 then for ifile=0,nnf-1 do begin
        do_delete = ~keyword_set(nodelete)
        catch, error_status
        if error_status ne 0 then begin
            if loud then print, 'Unable to delete ' + not_found[ifile]
            do_delete = 0
        endif
        if do_delete then begin
            file_delete, not_found[ifile], verbose=loud
            n_deleted = n_deleted + 1
        end else if loud then print, not_found[ifile] + ' not found on server'
        catch, /cancel
    endfor
;
endelse                                ;local_count gt 0
;
;  If flagged, test whether or not the entire directory should be deleted.
;
test_dirs:
if test_dir_delete then begin
    temp = remote
    lastchr = strmid(temp, strlen(temp)-1, 1)
    if lastchr eq '/' then temp = strmid(temp, 0, strlen(temp)-1)
    break_file, temp, disk, dir, name, ext
    parent = disk + dir
    child = name + ext
;
;  If PARENT_NAMES is defined, then use this to determine what directories
;  exist in the parent directory.  Otherwise, use SOCK_SEARCH.
;
    if n_elements(parent_names) gt 0 then begin
        delvarx, parent_files
        parent_count = 0
        err = ''
        for i=0,n_elements(parent_names)-1 do begin
            temp = parent_names[i]
            lastchr = strmid(temp, strlen(temp)-1, 1)
            if lastchr eq '/' then temp = strmid(temp, 0, strlen(temp)-1)
            boost_array, parent_files, temp
            parent_count = parent_count + 1
        endfor
    end else sock_search, parent, parent_files, err=err, count=parent_count, $
                     /directory
;
;  If files can be found on the parent directory, then test whether
;  this directory is one of them.  If not, delete the entire child
;  directory tree.
;
    if (err eq '') and (parent_count gt 0) then begin
        break_file, parent_files, disk, dir, name, ext
        name = name + ext
        w = where(name eq child, child_count)
        if child_count eq 0 then begin
            do_delete = ~keyword_set(nodelete)
            catch, error_status
            if error_status ne 0 then begin
                if zlound then print, 'Unable to delete ' + local
                do_delete = 0
            endif
            if do_delete then begin
                file_delete, local, /recursive, verbose=loud
                n_deleted = n_deleted + 1
            endif else if loud then print, local + ' not found on server'
            catch, /cancel
            return
        endif
    endif
  endif
;
;  Call this routine recursively for each subdirectory.
;
for idir=0,ndirs-1 do begin
    break_file, dirs[idir], disk, dir, name, ext
    newdir = name + ext
    newremote = remote
    lastchr = strmid(newremote, strlen(newremote)-1, 1)
    if lastchr ne '/' then newremote = newremote + '/'
    newremote = newremote + newdir
    ssw_wget_cleanup2, dirs[idir], newremote, n_deleted, nodelete=nodelete, $
                       /increment, loud=loud, parent_names=parsed_names
endfor
;
end
