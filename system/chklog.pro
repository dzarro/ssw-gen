;+
; Project     : SOHO - CDS
;
; Name        :
;	CHKLOG
; Purpose     :
;	Determine actual name of logical or environment variable.
; Explanation :
;	This routine determines the actual name of a logical name (VMS) or
;	environment variable (UNIX).  In VMS the routine TRNLOG,/FULL is used;
;	otherwise GETENV is used.
; Use         :
;	Result = CHKLOG( VAR  [, OS ] )
; Inputs      :
;	VAR = String containing the name of the variable to be translated.
; Outputs     :
;	The result of the function is the translated name, or (in VMS) an array
;	containing the translated names.
; Opt. Outputs:
;       OS = The name of the operating system, from !VERSION.OS.
; Keywords    :
;	DELIM = delimiter to use for separating substrings
;       FULL = do full translation (VMS only)
;       PRESERVE = return input name if no translation found
;       FIX_DELIM = fix slash to match OS-appropriate delimiter
; Category    :
;	Utilities, Operating_system.
; Prev. Hist. :
;       Written  - DMZ (ARC) May 1991
;       Modified - DMZ (ARC) Nov 1992, to use GETENV
; Written     :
;	D. Zarro, GSFC/SDAC, May 1991.
; Modified    :
;	Version 1, Zarro, ARC/GSFC 23 April 1993.
;       Version 2, GSFC, 1 August 1994.
;               Added capability for vector inputs
;       Version 3, Liyun Wang, GSFC/ARC, January 3, 1995
;               Added capability of interpreting the "~" character under UNIX
;       Version 4, Zarro, GSFC/ARC, February 17 1997
;               Added call to EXPAND_TILDE, corrected many potential bugs
;       Version 5, Zarro, GSFC/SAC, June 9 1998
;               Added recursive call for environment variables embedded
;               in input
;       Version 6, Zarro, GSFC/SAC, August 10 1998
;               Added recursive call for nested environment variables
;               (after RAS broke it)
;       Version 7, Zarro, SM&A/GSFC, 16 May 1999
;               Added check for "naked" "$" or "~" inputs
;       Version 8, Zarro, SM&A/GSFC, 10 June 1999
;               Added check for different OS delimiters and made Windows
;               friendly
;       Version 9, 9-Sep-1999, William Thompson, GSFC
;               Fixed bug with TRNLOG,FULL=FULL under version 4 in VMS.
;       Version 10, 14-dec-1999, richard.schwartz@gsfc.nasa.gov
;               Switched get_path_delim to get_delim and allowed
;               both slashes under Windows, '/' and '\'.
;       Version 11, 20-Dec-1999, Zarro
;               Fixed bug when recursing on delimited input
;	Version 12, 07-Mar-2000, William Thompson, GSFC
;		Don't translate terminal logical names in VMS, i.e. those which
;		end in the characters ".]"
;       Version 13, 25-April-2000, Zarro (SM&/GSFC)
;               Added another level of recursion for multiply-defined
;               env's, i.e., env's defined in terms of other env's, which
;               somehow stopped working after version 5.
;               e.g., $SSW_HESSI -> $SSW/hessi/idl -> /ssw/hessi/idl
;       Version 14, 28-Jul-2000, R.D.Bentley (MSSL)
;               Suppress replacement of \\ with \ for windows
;       Version 15, 22-Aug-2000, Zarro (EIT/GSFC)
;               Removed calls to DATATYPE
;       Version 16, 24-July-2002, Zarro (LAC/GSFC)
;               Replaced TRIM with faster TRIM2
;       Version 17, 4-Nov-2002, Zarro (EER/GSFC)
;               Removed checks for multiple delimiters in input
;       Modified, 24 October, 2007, Zarro (ADNET) 
;               - Removed executes and added local_name call
;       Modified, 10-Dec-2008, Kim Tolbert
;               Fixed bug with windows os switching of
;               forward/backward slash
;       11-Oct-2018, Zarro (ADNET)
;               Fixed bug with OS delimiter slashes being accidentally
;               switched
;               Added /FIX_DELIM for backwards-compatibility with
;               previous behavior
;       18-Jan-2020, Zarro (ADNET)
;               Added check for URL input
;       18-Jan-2020, Zarro (ADNET)
;               Moved URL check to FIX_SLASH
;               Made FIX_DELIM the default
;                   
;-                

   function chklog,var,os,norecurse=norecurse,delim=delim,full=full,$
                       preserve=preserve,fix_delim=fix_delim

   preserve=keyword_set(preserve)
 
   if ~is_string(var,/blank) then begin
    if exist(var) && preserve then return,var else return,''
   endif

   if is_number(fix_delim) then fix_delim= byte(0 > fix_delim < 1) else fix_delim=1b
   
   recurse=~keyword_set(norecurse)
   full=keyword_set(full)
   flim=get_delim()
   var=trim2(var)

;-- recurse on array inputs

   nvar=n_elements(var)
   if nvar gt 1 then begin
    for i=0,nvar-1 do begin
     out=chklog(var[i],os,norecurse=norecurse,delim=delim,full=full,preserve=preserve,fix_delim=fix_delim)
     ovar=append_arr(ovar,out,/no_copy)
    endfor
    return,ovar
   endif

;-- parse out delimiters
  
   if is_string(delim) then begin
    lvar=str2arr(var,delim=delim)
    if n_elements(lvar) gt 1 then begin
     result=chklog(lvar,os,norecurse=norecurse,full=full,/preserve,fix_delim=fix_delim)
     return,arr2str(result,delim=delim)
    endif
   endif
   
;-- check OS 

   os=strlowcase(os_family())
   vms=(os eq 'vms')

;-- check if recursing on delimited elements in string

   svar=var
   if fix_delim then svar=fix_slash(svar)
   dvar=str2arr(svar,delim=flim)
   nt=n_elements(dvar)
   
   if (nt gt 1) && (recurse) then begin
    for k=0,nt-1 do begin
     temp=chklog(dvar[k],os,full=full,/preserve,norecurse=(k gt 0),fix_delim=fix_delim)
     tvar=append_arr(tvar,temp,/no_copy)
    endfor
    name=arr2str(tvar,delim=flim)
    if name eq svar then name=''
    goto,done
   endif

;-- do VMS check

   name=''
   if os eq 'vms' then begin
    v=call_function('trnlog',svar,name,full=full)
    if (v mod 2) eq 0 then name='' 
    if strmid(name,strlen(name)-2,2) eq '.]' then name=''
    goto,done
   endif

;-- check for preceding $

   doll=strpos(svar,'$')
   if doll eq 0 then begin
    name=trim2(getenv(svar))
    if name eq '' then begin
     tvar=strmid(svar,1,strlen(svar))
     name=trim2(getenv(tvar))
    endif
   endif else begin
    if recurse then name=trim2(getenv(svar))
   endelse
   if fix_delim then name=fix_slash(name)

;-- finally expand tildes
   
   if os eq 'unix' then begin
    if name ne '' then temp=name else temp=svar
    tilde=strpos(temp,'~')
    if (tilde gt -1) then name=expand_tilde(temp)
   endif

done:
   name=trim2(name[0])
   translated=name ne ''
   if preserve && ~translated then name=var

;-- check for remaining $

   if (strpos(name,'$') eq 0) && translated then begin
    name=chklog(name,os,norecurse=norecurse,delim=delim,full=full,$
                       /preserve,fix_delim=fix_delim)
   endif

   return,name

   end
        
