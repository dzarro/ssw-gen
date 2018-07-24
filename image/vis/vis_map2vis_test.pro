;Test multiple 1d and 2d xy maps with maps including points lt 0
;
;Find the test data
which,'vis_map2vis_test', out = out, /quiet
dir = [file_dirname( out ), curdir() ]
test_file = loc_file( path = dir, 'vis_map2vis_test.dat')
if exist( test_file ) then restore, test_file, /verb
;% RESTORE: Restored variable: MAP.
;% RESTORE: Restored variable: V.
;% RESTORE: Restored variable: XY.
;  IDL> help,map,v,xy
;  MAP             STRUCT    = -> <Anonymous> Array[1, 1]
;  V               STRUCT    = -> HSI_VIS Array[104]
;  XY              STRUCT    = -> <Anonymous> Array[1]
;  IDL> help,map,v,xy,/st
;  ** Structure <2169bea0>, 13 tags, length=66712, data length=66708, refs=2:
;  DATA            FLOAT     Array[129, 129]
;  XC              DOUBLE           338.98837
;  YC              DOUBLE          -114.70513
;  DX              DOUBLE           1.0000000
;  DY              DOUBLE           1.0000000
;  TIME            STRING    '13-Dec-2006 03:23:03.624'
;  ID              STRING    'RHESSI 25.0-50.0 keV'
;  DUR             DOUBLE           46.373535
;  XUNITS          STRING    'arcsec'
;  YUNITS          STRING    'arcsec'
;  ROLL_ANGLE      DOUBLE          0.00000000
;  ROLL_CENTER     DOUBLE    Array[2]
;  DESC            STRING    ''
;  Help, v, /struct
;  ** Structure HSI_VIS, 16 tags, length=120, data length=106:
;  ISC             INT              2
;  HARM            INT              1
;  ERANGE          FLOAT     Array[2]
;  TRANGE          DOUBLE    Array[2]
;  U               FLOAT         0.0735807
;  V               FLOAT        0.00351168
;  OBSVIS          COMPLEX   (     -3.97770,    -0.570598)
;  TOTFLUX         FLOAT           21.4854
;  SIGAMP          FLOAT           8.38558
;  CHI2            FLOAT           1.91115
;  XYOFFSET        FLOAT     Array[2]
;  TYPE            STRING    'photon'
;  UNITS           STRING    'Photons cm!u-2!n s!u-1!n'
;  ATTEN_STATE     INT              1
;  COUNT           FLOAT           23.1372
;  NORM_PH_FACTOR  FLOAT           2.18591
;  Help, XY, /struct
;  ** Structure <21321a40>, 2 tags, length=266256, data length=266256, refs=1:
;  X               DOUBLE    Array[129, 129]
;  Y               DOUBLE    Array[129, 129]
;
; Make visibilities from a map structure with negative numbers
; Negative numbers are restricted and those pixels are effectively set to 0.
; Let's do a test using the 1d and 2d forms of x and y within the routine
; 1D coordinate test with negatives
v1 = vis_map2vis( map, dummy, v )
; 2d coordinate test with negatives
v2 = vis_map2vis( map.data, xy, v )

help, same_data( v1, v2)
;Should be the same and they are
;Same as positive def map?
map.data >=0
pmm, map.data
v3 = vis_map2vis( map, dummy, v )
v4 = vis_map2vis( map.data, xy, v )
help, same_data(v1,v3)
;1
help, same_data(v1,v4)
;1
;yes
end