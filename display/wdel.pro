;+
; Project     : SOHO - CDS
;
; Name        : WDEL
;
; Purpose     : Close a window
;
; Category    : utility
;
; Explanation : WDELETE doesn't provide an ALL option to close all
;               open windows. WDEL does. Also can exclude windows used in managed widgets.
;
; Syntax      : IDL> wdel,id
;
; Examples    :
;
; Inputs      : ID = window to close,
;                    as comma-delimited list, 0,1,2,3,4.. up to 10 elements
;                    or array [1,2,3,...]
;
; Opt. Inputs : None
;
; Outputs     : None
;
; Opt. Outputs: None
;
; Keywords    : ALL - if set, delete all
;               exclude_managed - if set, don't delete the windows used in managed widgets
;
; Common      : None
;
; Restrictions: Delete up to 10 windows individually
;
; Side effects: Windows are closed
;
; History     : Version 1,  26-Jan-1998, Zarro (SAC/GSFC)
;               Similar to WDELETES
;               12-Apr-2017, Kim Tolbert, Added exclude_managed keyword.
;
; Contact     : dzarro@solar.stanford.edu
;-

pro wdel,w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,all=all, exclude_managed=exclude_managed

  on_error,1

  if ((!d.name ne 'X') and (!d.name ne 'WIN')) then return

  ;-- check open windows

  device,window=windows

  ;-- delete all?

  all=keyword_set(all)
  open=where(windows eq 1,count)
  if all and (count gt 0) then begin
    if keyword_set(exclude_managed) then begin
      managed = get_managed_window_ids(nman)
      if nman gt 0 then begin
        ind = rem_elem(open, managed, count)
        if count gt 0 then open = open[ind] else return
      endif
    endif
    for i=0,count-1 do wdelete,open(i)
    return
  endif

  ;-- delete specified windows

  nwind=n_params()
  if nwind gt 10 then begin
    message,'currently limited to closing 10 windows',/cont
  endif
  curr_window=!d.window

  for i=0,nwind-1 do begin
    arg='w'+trim(string(i))
    defined=0
    stat='defined=exist('+arg+')'
    ok=execute(stat)
    if ok and defined then begin
      stat='window='+arg
      ok=execute(stat)
      if ok then begin
        if not exist(window) then del_window=curr_window else del_window=window
        for k=0,n_elements(del_window)-1 do begin
          open=where(del_window(k) eq where(windows),cnt)
          if (cnt gt 0) and (del_window(k) gt -1) then wdelete,del_window(k)
        endfor
      endif
    endif
  endfor
  return & end
