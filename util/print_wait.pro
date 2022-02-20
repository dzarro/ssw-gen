;+
; Name: print_wait
;
; Purpose: print a message, but not too fast in succession
;
; Explanation: Print a message if it's been at least 'wait' seconds since the last time we printed that message.
;   Messages and times and wait times are stored in common print_wait_common.
;
; Input arguments:
;   msg - message to print
;
; Input keywords:
;   wait - seconds to wait before printing message again. Default = 3.
;   clear - if set, clear save_xx variables in common (start over) (call without a message)
;
; Written: Kim Tolbert, 26-Feb-2020
; Modifications:
;  21-Sep-2020, Kim. Made smarter - saves multiple messages, times, wait times in common and
;    added clear option.
;
;-
pro print_wait, msg, wait=wait, clear=clear

  checkvar, wait, 3.
  checkvar, clear, 0

  common print_wait_common, save_time, save_msg, save_wait

  if keyword_set(clear) then begin
    delvarx, save_time
    delvarx, save_msg
    delvarx, save_wait
  endif

  if ~is_string(msg) then return

  ; Convert string array to a single line
  pmsg = strlowcase(trim(str2lines(msg,/reverse)))

  if ~exist(save_msg) then begin
    ; If haven't saved any message yet, print message and save in common
    print, msg
    save_time = systime(1)
    save_msg = pmsg
    save_wait = wait
  endif else begin
    ; If have saved messages, check if this message is saved
    q = where(pmsg eq save_msg, kq)
    ; If not saved, print it and save it
    if kq eq 0 then begin
      print, msg
      save_time = [save_time, systime(1)]
      save_msg = [save_msg, pmsg]
      save_wait = [save_wait, wait]
    endif else begin
      ; If saved, print it only if elapsed time is > save_wait
      ii = q[0]
;      print,(systime(1) - save_time[ii]), save_wait[ii]
      if (systime(1) - save_time[ii]) gt save_wait[ii] then begin
        print, msg
        save_time[ii] = systime(1)
        if wait ne save_wait[ii] then save_wait[ii] = wait
      endif
    endelse
  endelse

end