;+
; Project     :	STEREO - SECCHI
;
; Name        :	SUNGLOBE_SECCHI_COLORS
;
; Purpose     :	Return the color table for SECCHI images
;
; Category    :	STEREO, SECCHI, Color-table, Object graphics, 3D, Planning
;
; Explanation : Restores the appropriate IDL save file containing the color
;               table for the selected telescope/wavelength combination.  This
;               routine is a simplified version of secchi_colors.pro, which can
;               be used when the SECCHI SolarSoft tree is not loaded.
;
; Syntax      :	SUNGLOBE_SECCHI_COLORS, TELESCOPE, WAVELENGTH, RED, GREEN, BLUE
;
; Examples    :	SUNGLOBE_SECCHI_COLORS, 'EUVI', 195, R, G, B
;               SUNGLOBE_SECCHI_COLORS, 'COR1', 0,   R, G, B
;
; Inputs      :	TELESCOPE  = The name of the telescope (EUVI,COR1,COR2,HI1,HI2)
;               WAVELENGTH = The wavelength (171,195,284,304).  Ignored for
;                            telescopes other than EUVI.
;
; Outputs     :	RED, GREEN, BLUE = The color table arrays.
;
; Calls       :	FILEPATH, FILE_EXIST
;
; Side effects: If an error condition is found, then the program returns the
;               currently loaded color table using TVLCT, /GET.
;
; Prev. Hist. :	Based on secchi_colors.pro
;
; History     :	Version 1, 29-Dec-2015, William Thompson, GSFC
;-
;
pro sunglobe_secchi_colors, telescope, wavelength, r, g, b
;
;  Form a simplified version of the telescope name from the first (and last)
;  letters, i.e. E, C1, C2, H1, H2.
;
tel = strupcase(strmid(telescope,0,1))
if tel ne 'E' then tel = tel + strmid(telescope,strlen(telescope)-1,1)
case tel of
    'E':  color_table = strtrim(wavelength,2) + '_EUVI_color.dat'
    'C1': color_table = 'COR1_color.dat'
    'C2': color_table = 'COR2_color.dat'
    'H1': color_table = 'HI1_color.dat'
    'H2': color_table = 'HI2_color.dat'
    else: begin
        message, /informational, 'Telescope ' + strtrim(telescope,2) + $
          'not recognized -- using current color table'
        tvlct, r, g, b, /get
        return
    end
endcase
;
;  Form the path to the file, and make sure the file exists.
;
file = filepath(color_table, root_dir=getenv('SSW_SECCHI'), $
                subdirectory=['data','color'])
if not file_exist(file) then begin
    message, /informational, 'File ' + file + $
      ' not found -- using current color table'
    tvlct, r, g, b, /get
    return
endif
;
;  Restore the color table from the IDL save file.
;
restore, file
;
return
end
