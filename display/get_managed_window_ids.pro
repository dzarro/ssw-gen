;+
; Name: get_managed_window_ids
;
; Purpose: Return the window ids of all windows that are inside a Draw Widget
;
; Calling sequence: managed_ids = get_managed_window_ids()
;
; Written: Kim Tolbert, 12-Apr-2017
; Modifications:
; 24-Apr-2017, Kim. Compile xmanager to make sure ValidateManagedWidgets is available. Also
;   check that widget ids[ii] is alive before calling xwidump
; 
;
;-

function get_managed_window_ids, count

  COMMON MANAGED, ids, names, modalList
  
  ; ValidateManagedWidgets is inside the file xamanger.pro, so compile xmanager to make sure it's available
  resolve_routine, 'xmanager', /compile_full_file 
  
  ; Make sure XManager's version of the list is up to date
  ValidateManagedWidgets
  
  count = 0
  
  num_ids = n_elements(ids)
  if num_ids eq 0 then return, -1

  for ii = 0,num_ids-1 do begin
    
    if ~xalive(ids[ii]) then continue ; if widget isn't active, jump to next ii
    
    xwidump, ids[ii], text, id
    
    delvarx, draw_ids
    for jj = 0,n_elements(id)-1 do if widget_info(id[jj], /name) eq 'DRAW' then draw_ids = append_arr(draw_ids,id[jj])
    
    if exist(draw_ids) then begin
      wids = lonarr(n_elements(draw_ids))
      for jj = 0,n_elements(draw_ids)-1 do begin
        widget_control, draw_ids[jj], get_value=wid  ; value of draw widget is window ID
        wids[jj] = wid
      endfor
      wids_all = append_arr(wids_all, wids)
    endif
    
  endfor

  count = n_elements(wids_all)
  return, count eq 0 ? -1 : wids_all
end