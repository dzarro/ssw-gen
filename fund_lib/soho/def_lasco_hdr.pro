FUNCTION DEF_LASCO_HDR, lasco_hdr_tags
;+	
; $Id: def_lasco_hdr.pro,v 1.2 2012/12/14 19:31:44 nathan Exp $
;
; NAME:				DEF_LASCO_HDR
; PURPOSE:			Define a Header Structure for a Level 0.5 or Level 1 LASCO Image
; CATEGORY:			CCD
; CALLING SEQUENCE:		hdr=DEF_LASCO_HDR(empty_variable)
; INPUTS:			None
; OPTIONAL INPUT PARAMETERS:	None
; KEYWORD PARAMETERS:		None
;
; OUTPUTS:		a structure array containing an initialized header
;  lasco_hdr_tags	Returns strarr of tags in structure
;
; OPTIONAL OUTPUT PARAMETERS:
; COMMON BLOCKS (deleted):	LASCO_HEADER_COMMON,header,nt,tags
;				header = the header structure
;				nt = number of elements in the header
;				tags = string array of names of header items
; SIDE EFFECTS:
; RESTRICTIONS:			DATE_OBS does not conform to SSW 
; PROCEDURE:
; MODIFICATION HISTORY:
; 
; $Log: def_lasco_hdr.pro,v $
; Revision 1.2  2012/12/14 19:31:44  nathan
; change defn of flt from 0d to 0.; allow 20 not 10
;
; Revision 1.1  2011/08/01 14:42:14  nathan
; @(#)def_lasco_hdr.pro 1.4 07/28/11 from lasco/idl/inout
;
;   	SEP 1/07/95  Adapted from define_ccd_hdr.pro
;   	SEP 1/20/95  If a FITS header is passed in the LASCO
;   	    	    header structure is filled with its contents.
;   	SEP 3/17/95  Added CAMP_ID
;	NBR  8/08/00	Update for current Level 0.5 and Level 1 LASCO hdr structure
;	NBR  9/17/02	Add keywords for level 1; remove common block; change EXP_CMD to EXPCMD
;   	NBR  7/28/11	Added DATAP50 
;
;-
;
;COMMON LASCO_HEADER_COMMON, lasco_hdr, lasco_hdr_nt, lasco_hdr_tags, lasco_hdr_str

   int = 0
   lon = 0L
   flt = 0.
   str = ''
   sta = REPLICATE(str, 20)
   ; LEB Flight Science Header
   lasco_hdr={lasco_hdr_struct,	$
	;HDR_TYPE:3,		$	;Hdr type 0=Breadboard 1 = HP DGSE 2 = FITS 3=Flight
	SIMPLE	:1,		$
	BITPIX	:int,		$	;Number of bits per pixel (multiple of 8)
	NAXIS	:int,		$	;Number of axes in array
	NAXIS1	:int,		$	;Number of pixels in fastest ranging axis
	NAXIS2	:int,		$	;Number of pixels in second fastest ranging axis
	;NAXIS3	:int,		$	;Number of pixels in third fastest ranging axis
	;NAXIS4	:int,		$	;Number of pixels in fourth fastest ranging axis
	FILENAME:str,		$	;Filename of image data
	FILEORIG:str,		$	;Original filename as collected
	DATE	:str,		$	;Date File written (dd/mm/yy)
	DATE_OBS:str,		$	;Starting date of data acquisition (CALC)
	TIME_OBS:str,		$	;Starting time of data acquisition (CALC)
	P1COL	:int,		$	;Column value of the image point closest to the readout
	P1ROW	:int,		$	;Row value of the image point closest to the readout
	P2COL	:int,		$	;Column value of the image point farthest from the readout
	P2ROW	:int,		$	;Row value of the image point farthest from the readout
	VERSION :int,		$
	EXPTIME	:flt,		$	;Exposure time (seconds) (CALC)
	EXP0	:flt,		$
        ;EXP_START_TIME1:int, 	$  	; Exposure start time MSW  (TAI time format)
        ;EXP_START_TIME2:int, 	$  	; Exposure start time MidSW
        ;EXP_START_TIME3:int, 	$  	; Exposure start time LSW
        ;EXP_DUR:int,         	$       ; Exposure Time in 1/2048ths of a sec (measured by OBE)
        EXPCMD:flt,         	$       ; Exposure Time in 1/2048ths of a sec (commanded)
					; NOTE: does not match database field name
        ;READ_TIME:int,       	$       ; CCD Read Time in 1/2048ths of a sec
        EXP1:flt,         	$       ; Used in debugging of exposure time (dependent on obs prog)
        EXP2:flt,         	$       ; Used in debugging of exposure time (dependent on obs prog)
        EXP3:flt,         	$       ; Used in debugging of exposure time (dependent on obs prog)
        ;EXPMODE:flt,		$	;Exposure mode
	;OBJECT	:str,		$	;Image object ("flat field", "resolution target")
	TELESCOP:str,		$	;Data acquisition telescope (C1, etc, EIT, TEST)
	INSTRUME:str,		$	;SOHO
	DETECTOR:str,		$
	READPORT:str,		$	;Designation of readout port (A,B,C,D)
	;BLANK	:int,		$	;Undefined pixels set to this value
	;LPULSE	:int,		$	;Long Pulse
	SUMROW	:int,		$	;Number of rows summed together in camera
	SUMCOL	:int,		$	;Number of columns summed together in camera
	LEBXSUM :int,		$
	LEBYSUM :int,		$
	SHUTTR	:int,		$
        LAMP	:int,       	$       ; 0 = off 1 = shutter lamp 2=door lamp on
	FILTER	:str,		$
	POLAR	:str,		$
        ;SHUTTER:int,       	$       ; 0 = OPEN 1 = CLOSED
        ;FILTER:int,     	$       ; Filter wheel position 0-4
        ;POLAR:int,      	$       ; polarizer wheel 0-4 or sector 0-3 for EIT
	LP_NUM	:str,		$
	OS_NUM	:lon,		$
	IMGCTR	:lon,		$
	IMGSEQ	:lon,		$
	COMPRSSN:str,		$
	HCOMP_SF:lon,		$
	FP_WL_UP:flt,		$
	FP_WL_CM:flt,		$
	WAVELENG:flt,		$
	FP_ORDER:int,		$
        M1_PZ1:int,		$	; M1 Piezo 1  (12 bits)
        M1_PZ2:int,		$	; M1 Piezo 2  (12 bits)
        M1_PZ3:int,		$	; M1 Piezo 3  (12 bits)
	MID_DATE:lon,		$
	MID_TIME:flt,		$
	PLATESCL:flt,		$
	OFFSET	:lon,		$
	IMAGE_CT:lon,		$
	SEQ_NUM :lon,		$
	OBT_TIME:flt,		$
	R1COL	:int,		$
	R1ROW	:int,		$
	R2COL	:int,		$
	R2ROW	:int,		$
	BUNIT	:str,		$	;Brightness units
	EFFPORT :str,		$
	;RECTIFY :int,		$	;Rectification parameter: 0=no 1=yes
	RECTIFY :str,		$
	;CLRMODE	:str,		$	;Camera run mode:  fast/slow clear
	;NCLEARS	:int,		$	;Number of clears per cycle
	DATAMAX	:flt,		$	;Maximum data value in the (pre-scaled) image
	DATAMIN	:flt,		$	;Minimum (non-zero) data value
	DATAZER :lon,	$	; number of zero (blank) pixels
	DATASAT :lon,	$	; number of saturated pixels
	DSATVAL	:flt,	$	; value used as saturated
	DSATMIN :flt,	$ 	; Minimum value in scaled image
	NSATMIN :lon,	$	; Number of pixels cut off on lower end
	DATAAVG :flt,	$
	DATASIG :flt,	$
	DATAP01 :flt,	$
	DATAP10 :flt,	$
	DATAP25 :flt,	$
	DATAP50 :flt,	$
	DATAP75 :flt,	$
	DATAP90 :flt,	$
	DATAP95 :flt,	$
	DATAP98 :flt,	$
	DATAP99 :flt,	$
	CRPIX1	:flt,	$
	CRPIX2	:flt,	$
	CRVAL1	:flt,	$
	CRVAL2	:flt,	$
	CROTA	:flt,	$
	XCEN	:flt,	$
	YCEN	:flt,	$
	CROTA1	:flt,	$
	CROTA2	:flt,	$
	CTYPE1	:str,	$
	CTYPE2	:str,	$
	CUNIT1	:str,	$
	CUNIT2	:str,	$
	CDELT1	:flt,	$
	CDELT2	:flt,	$
	SECTOR	:str,	$
	RSUN	:flt,	$	; solar radius in arcseconds
	NMISSING:int,	$	; number of missing blocks
	MISSLIST:str,	$	; string list of missing block coordinates
	;BSCALE	:flt,		$	; Scale factor (true=value*bscale+bzero)
	;BZERO	:flt,		$	; Offset applied to true pixel values
	COMMENT :sta,	$	; Comment
	HISTORY :sta    	$	; Comments of processing history

	;CCD_SIDE:int,		$	; 0 = FRONT  1 = BACK
	;PROC_SPEED:str,		$	;Camera microprocessor speed, slow/fast
        ;LINE_SYNC:int,  	$       ; Line sync error 0 = no 1 = yes
        ;CAMERA_ERR:int,      	$  	; Camera error 0 = no 1 = yes
	;OBS_PROG:int,		$	; Observation Program ID
	;IMAGE_OF_SEQ:int,	$	; Image Num of Sequence (e.g. 3rd of 5)
	;NUM_LEB_PROC:int,	$	; Num of LEB Image Proc Steps
	;LEB_PROC:INTARR(32),	$	; Image Proc Steps (up to 32)
	;IMAGE_DATA:int,		$	; Image data with this header 0 = NO 1 = YES
	;BLOCKS_HORZ:int,	$	; Num of blocks in columns
	;BLOCKS_VERT:int,	$	; Num of blocks in rows
	;BLOCKS_TOTAL:int,	$	; Total num of data blocks
	;TRANSIENT_IMAGE:int,	$	; 0 = Normal Image 1 = Transient Image
	;TRANSIENT_DET:int,	$	; 0 = No 1 = Transient Detected
        ;FP_UP_LAMBDAI:int,      $ 	; FP Uplink wavelength (Integer portion)
        ;FP_UP_LAMBDAF:int,      $ 	; FP Uplink wavelength (Fraction portion)
        ;FP_CM_LAMBDAI:int,      $ 	; FP Command wavelength (Integer portion)
        ;FP_CM_LAMBDAF:int,      $ 	; FP Command wavelength (Fraction portion)
        ;M1_LID:int,		$	; M1 Lid (0 = Closed 1 = Open)
        ;CAMP_ID:int,	$	; Observing Sequence Identifying Number
   }

   telescope_array = ['C1','C2','C3','EIT']
   clear_array  = ['SLOW','FAST']
   port_array = ['A','B','C','D']
   shutter_array = ['OPEN', 'CLOSED']
   lamp_array = ['OFF','OFF1','DOOR','SHUTTER']
   ;*                    0        1           2           3         4
   filter_array = [['CaXV',  'FeX',      'Orange',   'Na',     'FeXIV'],    $;* C1
                   ['Blue',  'H_alpha',  'Deep_Red', 'Orange', 'Lens'],     $;* C2
                   ['Clear', 'Deep_Red', 'Orange',   'IR',     'Blue'],     $;* C3
                   ['ALU 1', 'ALU 2',    'AL/2 INF', 'Clear',  'AL/2 SUP']]  ;* EIT
   ;*                    0        1           2           3         4
   polar_array  = [['Clear', 'H_alpha',  '-60',      '0',      '+60'],     	$;* C1
                   ['Clear', '+60',        '0',    '-60',      'Density'], 	$;* C2
                   ['Clear', 'H_alpha',  '-60',      '0',      '+60'],      $;* C3
                   ['Sector 1', 'Sector 2', 'Sector 3', 'Sector 4', 'Invalid']] ;* EIT
   op_array = [ 'INF_LOOP',                 $;*  0
                'SR',                       $;*  1
                'M1_MSR',           	    $;*  2
                'WOBBLE_IN',                $;*  3
                'WOBBLE_OUT',               $;*  4
                'DARK_IMG',                 $;*  5
                'CC',                       $;*  6
                'CONTINUOUS_IMAGE',         $;*  7
                'FP_SCAN_LINE',     	    $;*  8
                'TAKE_NORM',                $;*  9
                'DUMP_MEM',                 $;* 10
                'GRND_PERIPH_CMNDS',        $;* 11
                'PERIPH_LOADING',   	    $;* 12
                'UPD_DFLT_PARAMS',  	    $;* 13
                'SEQ_PW_AT_FW',     	    $;* 14
                'FP_CAM_COORD',     	    $;* 15
                'CONCURRENT',               $;* 16
                'TAKE_CAL_LAMP',    	    $;* 17
                'GRND_MECH_CMNDS',  	    $;* 18
                'TAKE_SUM',                 $;* 19
                'TAKE_SEQ',                 $;* 20
                'MOVE_M1',          	    $;* 21
                'TRANS_DET' ]                ;* 22

   lasco_hdr_str = {lasco_hdr_str,		$
           telescope_names : telescope_array, 	$
           clear_types : clear_array, 		$
           port_types : port_array, 		$
           shutter_pos : shutter_array, 	$
           lamp_types : lamp_array, 		$
           filter_types : filter_array, 	$
           polar_types : polar_array, 		$
           op_types : op_array  		$
          }


   lasco_hdr_nt = N_TAGS(lasco_hdr)
   lasco_hdr_tags = TAG_NAMES(lasco_hdr)

  ; IF (N_PARAMS() EQ 1) THEN BEGIN	;** fill in the structure with the contents of the FITS header
 ;     FOR t=0, lasco_hdr_nt -1 DO BEGIN	;** for each tag in the lasco hdr structure
 ;        var = FXPAR(fits_hdr, lasco_hdr_tags(t))
 ;        lasco_hdr.(t) = var
 ;     ENDFOR
 ;  ENDIF

   RETURN, lasco_hdr

END
