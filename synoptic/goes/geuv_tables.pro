;+
; Name: geuv_tables
; 
; Purpose: Return structure containing tables for converting GOES EUV data from counts to irradiance (watts/m^2)
;  for requested satellite.
;  Also contains parameters for EUVE data for correcting for degradation and scaling to SOLSTICE
;  These values are from this document: GOES EUVS Measurments document written by Janet Machol:
;  http://www.ngdc.noaa.gov/stp/satellite/goes/doc/GOES_NOP_EUV_readme.pdf
;  
; Input Argument:
;  sat - satellite to return table for (13, 14, or 15)
;  
; Output:
;  Returns structure with the fields listed in tags below as well as correction factors for EUVE, See the document
;  referenced above for an explanation of the fields.
;  
; Written: 3/1/2016, Kim Tolbert
; Modifications:
;  06-Dec-2016, Kim. Inserted the new EUVE fit parameters for correcting degradation, now fitting to
;    SORCE SOLSTICE v15.
; 
;-

function geuv_tables, sat

tags = ['BACKGROUND', 'GAIN', 'CONTAMINATION', 'BANDPASS_MIN', 'BANDPASS_MAX', 'MIN_CONVF', 'MAX_CONVF', 'MIN_SCALE', 'MAX_SCALE']

g13_table = [ $
  create_struct(tags, 25198, 1.91E-15, 2.13E-14, 2.8, 20.6, 8.918e-10, 8.065e-10, .21, .19), $
  create_struct(tags, 15970, 1.89E-15, 1.21E-14, 2.8, 36.4, 6.615e-9, 6.034e-9, .406, .381), $
  create_struct(tags, 16229, 1.90E-15, 4.79E-14, -1., -1., -1., -1., -1., -1.), $
  create_struct(tags, 24387, 1.89E-15, 1.20E-15, -1., -1., -1., -1., -1., -1.), $
  create_struct(tags, 25096, 1.90E-15, 1.32E-12, 113.5, 132.8, 2.612e-9, 2.612e-9, .884, .884)]
  
g14_table = [ $
  create_struct(tags, 26571, 1.92E-15, 1.04E-14, 2.8, 19.0, 8.718e-10, 8.691e-10, .256, .248), $
  create_struct(tags, 23948, 1.93E-15, 7.18E-14, 2.8, 19.0, 8.744e-10, 8.628e-10, .256, .248), $
  create_struct(tags, 14207, 1.93E-15, 2.96E-13, 6.0, 36.6, 4.841e-9, 4.441e-9, .424, .406), $
  create_struct(tags, 24856, 1.95E-15, 5.47E-14, 6.0, 36.6, -1., -1., -1., -1.), $
  create_struct(tags, 25188, 1.94E-15, 2.49E-12, 113.7, 135.9, 2.630e-9, 2.630e-9, .855, .855)]

g15_table = [$
  create_struct(tags, 49454, 1.91E-15, 1.78E-14, 3.6, 20.8, 1.1e-9, 1.006e-9, .213, .193), $
  create_struct(tags, 49797, 1.90E-15, 2.71E-14, 3.6, 38.5, 3.786e-9, 3.594e-9, .399,.379), $
  create_struct(tags, 55451, 1.90E-15, 2.03E-15, -1., -1., -1., -1., -1., -1.), $
  create_struct(tags, 51218, 1.90E-15, 4.37E-14, -1., -1., -1., -1., -1., -1.), $
  create_struct(tags, 40947, 1.90E-15, 2.23E-12, 116.3, 132.4, 2.348e-9, 2.348e-9, .884, .884)]

;tags_efit = ['a0', 'a1', 'a2', 'a3', 't0']
;g13_efit = create_struct(tags_efit, 0.017348879, -0.00048805848, -5.0711674e-005, 1.1609864, 2453857)
;g14_efit = create_struct(tags_efit, 0.20591992, -0.0059919019, -5.6673415e-007, 1.0750063, 2454984)
;g15_efit = create_struct(tags_efit, 0.12569144, -0.0034349324, -0.00016150714, 1.1978867, 2455257)

; These are new parameters for fit to SORCE SOLSTICE v15 provided by Janet Machol. 6-Dec-2016
tags_efit = ['a0', 'a1', 'a2', 'a3', 't0']
g13_efit = create_struct(tags_efit, -10.506987, -6.5582174e-005, -0.00068685569, 11.635565, 2453857)
g14_efit = create_struct(tags_efit, 0.20419478, -0.0070176921, -2.7219186e-005, 1.0905254, 2454984)
g15_efit = create_struct(tags_efit, 0.20327572, -0.0016817982, -0.00011181107, 1.1090724, 2455257)

time_solar_max = ['1-jan-2011','1-jan-2016'] ; rough period during which we'll use the 'max' values in the tables

if sat eq 13 then return, {table: g13_table, efit: g13_efit, time_solar_max:time_solar_max}
if sat eq 14 then return, {table: g14_table, efit: g14_efit, time_solar_max:time_solar_max}
if sat eq 15 then return, {table: g15_table, efit: g15_efit, time_solar_max:time_solar_max}

return, -1
end