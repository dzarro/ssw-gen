function utc2yymmdd,utc, HHMMSS=hhmmss, YYYY=yyyy, CCSDS=ccsds
;
;+
; $Id: utc2yymmdd.pro,v 1.2 2017/12/11 19:43:44 nathan Exp $
; NAME:
;	UTC2YYMMDD
;
; PURPOSE:
;	This function converts a modified julian date structure into a date 
;	string in the format yymmdd 
;
; CATEGORY:
;	UTIL
;
; CALLING SEQUENCE:
;	Result = UTC2YYMMDD(Utc)
;
; INPUTS:
;	Utc:	Universal time in the CDS time structure
;
; OPTIONAL KEYWORDS:
;	Use /HHMMSS to have '_HHMMSS' added.  Ex result: 'YYMMDD_HHMMSS'
;	Use /YYYY to have 4 digit year.  Ex result: 'YYYYMMDD_HHMMSS'
;	Use /CCSDS to have T indicate time.  Ex result: 'YYYYMMDDTHHMMSS'
;
; OUTPUTS:
;	This function returns a date string in the format YYMMDD.
;
; MODIFICATION HISTORY:
; 	Written by:	RA Howard, 1995
;
; $Log: utc2yymmdd.pro,v $
; Revision 1.2  2017/12/11 19:43:44  nathan
; add /ccsds
;
; Revision 1.1  2008/02/20 18:50:02  nathan
; moved from lasco/idl/util
;
; 	  Updated :	97/01/28 SE Paswaters - Added /HHMMSS keyword
; 	  Updated :	97/12/15 SE Paswaters - Added /HHMMSS keyword
;
;	@(#)utc2yymmdd.pro	1.2 05/14/97 LASCO IDL LIBRARY
;-

utcstr = utc2str(utc)
IF KEYWORD_SET(YYYY) THEN BEGIN
   strt=0 
   len=4
ENDIF ELSE BEGIN
   strt=2
   len=2
ENDELSE
ddis = strmid(utcstr,strt,len)+strmid(utcstr,5,2)+strmid(utcstr,8,2)
delim='_'
IF keyword_set(CCSDS) THEN delim='T'
IF KEYWORD_SET(HHMMSS) THEN ddis = ddis + delim + strmid(utcstr,11,2)+strmid(utcstr,14,2)+strmid(utcstr,17,2)
RETURN,ddis
END
