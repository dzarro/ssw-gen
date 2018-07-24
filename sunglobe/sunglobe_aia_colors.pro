;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_AIA_COLORS
;
; Purpose     :	Return the color tables for AIA images
;
; Category    :	AIA, Color-table, Object graphics, 3D, Planning
;
; Explanation :	This routine returns the red, green, and blue color tables for
;               AIA images, based on the wavelength.
;
; Syntax      :	SUNGLOBE_AIA_COLORS, WAVELENGTH, RED, GREEN, BLUE
;
; Examples    :	SUNGLOBE_AIA_COLORS, 304, R, G, B
;
; Inputs      :	WAVELENGTH = The AIA wavelength.  If unrecognized, then a
;                            greyscale color table is returned.
;
; Outputs     :	RED, GREEN, BLUE = The returned color table
;
; Calls       :	NINT
;
; Prev. Hist. :	Based on AIA_LCT
;
; History     :	Version 1, 4-Jan-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_aia_colors, wavelength, red, green, blue
;
;  Set up the various color table arrays to choose from.
;
loadct, 3, rgb_table=table
r0 = table[*,0]
g0 = table[*,1]
b0 = table[*,2]
;
c0 = bindgen(256)
c1 = byte(sqrt(findgen(256)) * sqrt(255.))
c2 = byte(findgen(256)^2 / 255.)
c3 = byte((c1+c2/2.) * 255. / (max(c1)+max(c2)/2.))
;
;  Define the color tables based on the source ID
;
case nint(wavelength) of
    94: begin
        red   = c2
        green = c3
        blue  = c0
    end
;
    131: begin
        red   = g0
        green = r0
        blue  = r0
    end
;
    171: begin
        red   = r0
        green = c0
        blue  = b0
    end
;
    193: begin
        red   = c1
        green = c0
        blue  = c2
    end
;
    211: begin
        red   = c1
        green = c0
        blue  = c3
    end
;
    304: begin
        red   = r0
        green = g0
        blue  = b0
    end
;
    335: begin
        red   = c2
        green = c0
        blue  = c1
    end
;
    1600: begin
        red   = c3
        green = c3
        blue  = c2
    end
;
    1700: begin
        red   = c1
        green = c0
        blue  = c0
    end
;
    4500: begin
        red   = c0
        green = c0
        blue  = byte(b0/2)
    end
;
;  Otherwise, return a standard greyscale
;
    else: begin
        red   = c0
        green = c0
        blue  = c0
    end
endcase
;
end
