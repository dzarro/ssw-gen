;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_GET_INS_OFFSET
;
; Purpose     :	Returns instrument offset from spacecraft boresight
;
; Category    :	Object graphics, 3D, Planning, SPICE
;
; Explanation :	Returns the instrument offset in arcseconds from the spacecraft
;               boresight.  The initial version of this routine returns
;               constant values.
;
; Syntax      :	SUNGLOBE_GET_INS_OFFSET, SSTATE, INSTRUMENT, XOFFSET, YOFFSET
;
; Examples    :	See sunglobe_*_fov__define.pro.
;
; Inputs      : SSTATE  = Widget top-level state structure.  Not currently
;                         used, included for future development.
;
;               INSTRUMENT = Name of instrument, either "EUI/HRI/EUV",
;                            "EUI/HRI/LYA", "PHI", or "SPICE".  Otherwise, 0,0
;                            is returned.
;
; Outputs     :	XOFFSET = Offset in X direction, in arcseconds
;               YOFFSET = Offset in Y direction, in arcseconds
;
; Restrictions: Currently only EUI offsets are returned.  All others are 0,0.
;
; History     :	Version 1, 16-Nov-2021, William Thompson, GSFC
;               Version 2, 24-Nov-2022, WTT, split EUI into EUV, Lya channels
;               Version 3, 03-Mar-2022, WTT, add values for SPICE
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_get_ins_offset, sstate, instrument, xoffset, yoffset
;
case strupcase(instrument) of
    'EUI/HRI/EUV': begin
        xoffset = -115.0
        yoffset =  143.0
    end
    'EUI/HRI/LYA': begin
        xoffset = -143.0
        yoffset =   48.0
    end
    'PHI': begin
        xoffset = 0.0
        yoffset = 0.0
    end
    'SPICE': begin
        xoffset = -83.0
        yoffset = -68.0
    end
    else: begin
        xoffset = 0.0
        yoffset = 0.0
    end
endcase
;
end
