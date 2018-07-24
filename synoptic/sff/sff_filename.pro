;+
; Name: sff_filename
;
; Purpose: Return the URL of the solar flare finder png or save file selected in the sff widget
; 
; Calling arguments:
;  state - the widget state structure containing the topurl of the archived png and save files
;  choice - the name of the chosen file (without extension)
;  save - if set, return the save file name, otherwise the png file name
;  
; Written: Kim Tolbert, 16-Jun-2016
; Modifications:
;-

function sff_filename, state, choice, save=save

  year = strmid(choice,0,4)
  month = strmid(choice,4,2)

  if keyword_set(save) then return, state.top_dir + '/sav_files/' + year + '/' + month + '/' + choice + '.sav' else $
  return, state.top_dir + '/png_files/' + year + '/' + month + '/' + choice + '.png'
  
end
