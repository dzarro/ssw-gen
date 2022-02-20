

PRO cit_instr_check_year, year=year, data_struc=data_struc, $
                          instr_name=instr_name, bcode_instr=bcode_instr, $
                          bib_save_dir=bib_save_dir, $
                          abs_search_string=abs_search_string, $
                          update=update, new_bibcodes=new_bibcodes, $
                          preprints=preprints, database_all=database_all

;+
; NAME:
;     CIT_INSTR_CHECK_YEAR
;
; PURPOSE:
;     For the specified year and mission, this routine checks if there
;     are new publications compared to a save file containing previous
;     results.
;
;     For how to use routine, check
;       https://pyoung.org/quick_guides/mission_pub_lists.html
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     CIT_INSTR_CHECK_YEAR
;
; INPUTS:
;     None.
;
; OPTIONAL INPUTS:
;     Year:    A year in integer or string format. If not specified,
;              then the current year is assumed.
;     Data_Str: A structure containing the tags:
;                bib_save_dir - directory to save the bibcode save
;                               files
;                instr_name - the name of the instrument
;                bcode_instr - the bibcode for the instrument paper
;                abs_search_string - string to use when searching
;                              abstracts.
;     Bib_Save_Dir: Directory for bibcode save files (not needed if
;                   DATA_STR given).
;     Instr_Name: The name of the instrument (not needed if DATA_STR
;                 given). 
;     Bcode_Instr: The bibcode for the instrument paper  (not needed
;                  if DATA_STR  given).
;     Abs_Search_String: String to use when searching abstracts (not
;                        needed if DATA_STR  given).
;	
; KEYWORD PARAMETERS:
;     UPDATE:  By default the routine only checks for new entries but
;              does not update the bibcode save files. Setting this
;              keyword does the update.
;     PREPRINTS: If set, then include preprints in the check.
;     DATABASE_ALL: If set, then search all of the ADS databases, not
;              just astronomy.
;
; OUTPUTS:
;     The routine prints a list of URLs giving the ADS pages of new
;     publications that have been found since the last time the
;     routine was used. The user should then check these pages, to
;     make sure the papers actually used the instrument data. For
;     papers that don't, the user should put the bibcode in a
;     "remove" file (BIB_SAVE_DIR/remove_[YEAR].txt).
;
;     Once all papers have been checked, the user should run the
;     routine again, but with the /update keyword. This will update
;     the file BIB_SAVE_DIR/bibcode_list_[YEAR].txt. New entries in
;     this file will be appended with "*".
;
;     If the bibcode_list file didn't previously exist, then it
;     will be created.
;
;     When the bibcode_list file is updated the previous version is
;     copied to BIB_SAVE_DIR/backup and the date/time is appended to
;     the filename.
;
; OPTIONAL OUTPUTS:
;     New_Bibcodes:  A string array containing the bibcodes of the new
;                    papers (if any).
;
; EXAMPLE:
;     IDL> s=eis_pub_info()
;     IDL> cit_instr_check_year, data_str=s
;     IDL> cit_instr_check_year, data_str=s, /update
;
; MODIFICATION HISTORY:
;     Ver.1, 10-Sep-2019, Peter Young
;     Ver.2, 14-Jan-2020, Peter Young
;        Added /preprints and /database_all keywords.
;-



IF n_tags(data_struc) NE 0 THEN BEGIN
  IF tag_exist(data_struc,'bib_save_dir') THEN bib_save_dir=data_struc.bib_save_dir
  IF tag_exist(data_struc,'instr_name') THEN instr_name=data_struc.instr_name
  IF tag_exist(data_struc,'bcode_instr') THEN bcode_instr=data_struc.bcode_instr
  IF tag_exist(data_struc,'abs_search_string') THEN abs_search_string=data_struc.abs_search_string
ENDIF


;
; If year not specified, then use current year (extracted from the
; output of the systime routine). I also construct 'datestr' which is
; used when creating a backup file later.
;
s=systime(/julian)
caldat,s,mm,dd,yy,hh,min,sec
datestr=trim(yy)+strpad(trim(mm),2,fill='0')+strpad(trim(dd),2,fill='0')+'_'+strpad(trim(hh),2,fill='0')+ $
        strpad(trim(min),2,fill='0')+strpad(trim(round(sec)),2,fill='0')
IF n_elements(year) EQ 0 THEN year=yy


;savefile='bib_savefile_'+trim(year)+'.save'
biblist_file='bibcode_list_'+trim(year)+'.txt'
IF n_elements(bib_save_dir) NE 0 THEN biblist_file=concat_dir(bib_save_dir,biblist_file)
chck=file_info(biblist_file)
IF chck.exists NE 1 THEN BEGIN
  print,'% CIT_INSTR_CHECK_YEAR: the bibcode save file does not exist for this mission-year combination.'
  print,'                        If any publications are found, then they will all be new.'
  print,'                        Call the routine again with the /UPDATE keyword to write the new bibcode'
  print,'                        save file.'
  new_file=1
  biblist=''   ; set to an empty string
ENDIF ELSE BEGIN
  new_file=0
  openr,lin,biblist_file,/get_lun
  str1=''
  WHILE eof(lin) NE 1 DO BEGIN
    readf,lin,format='(a19)',str1
    IF trim(str1) NE '' THEN BEGIN 
      IF n_elements(biblist) EQ 0 THEN biblist=trim(str1) ELSE biblist=[biblist,trim(str1)]
    ENDIF 
  ENDWHILE 
  free_lun,lin
 ;
  print,'% CIT_INSTR_CHECK_YEAR: no. of publications in save file = '+trim(n_elements(biblist))
ENDELSE

;
; Retrieve the lists of papers for the current year (cyear)
;
IF n_elements(bcode_instr) NE 0 THEN BEGIN
  blist1=cit_get_citing_papers(bcode_instr,year=year,preprints=preprints,database_all=database_all)
ENDIF ELSE BEGIN
  blist1=''
ENDELSE
;
IF n_elements(abs_search_string) NE 0 THEN BEGIN
  blist2=cit_instr_abs_search(year,abs_search_string,preprints=preprints,database_all=database_all)
ENDIF ELSE BEGIN
  blist2=''
ENDELSE 

blist=[blist1,blist2]
k=where(blist NE '',nk)
IF nk EQ 0 THEN BEGIN
  print,'% CIT_INSTR_CHECK_YEAR: no publications found for this year. Returning...'
  return 
ENDIF
blist=blist[k]

;
; Remove duplicate entries
;
blist=blist[uniq(blist,sort(blist))]
n1=n_elements(blist)
print,'% CIT_INSTR_CHECK_YEAR: no. of publications found for this year = '+trim(n1)

;
; Now check for any bibcode entries in the 'remove' file.
;
remove_file='remove_'+trim(year)+'.txt'
IF n_elements(bib_save_dir) NE 0 THEN remove_file=concat_dir(bib_save_dir,remove_file)
chck=file_info(remove_file)
IF chck.exists EQ 1 THEN BEGIN
  openr,lun,remove_file,/get_lun
  str1=''
  WHILE eof(lun) NE 1 DO BEGIN
    readf,lun,str1
    i=where(trim(str1) EQ blist,ni)
    IF ni GT 0 THEN BEGIN
      j=where(str1 NE blist,nj)
      IF nj GT 0 THEN blist=blist[j] ELSE blist=''
    ENDIF
  ENDWHILE
  free_lun,lun
ENDIF
;
n2=n_elements(blist)
IF n1 NE n2 THEN print,'% CIT_INSTR_CHECK_YEAR: no. of entries removed (from remove_file) = '+trim(n1-n2)

IF blist[0] EQ '' THEN BEGIN
  print,'% CIT_INSTR_CHECK_YEAR: no papers found for this year. Returning...'
  return 
ENDIF 

;
; Check if the old bib list has entries that the new one
; doesn't have. This doesn't necessarily indicate a problem. For
; example, some bibcodes may have been manually entered because
; they didn't satisfy the search criteria. 
;
IF biblist[0] NE '' AND n2 NE 0 THEN BEGIN
  n=n_elements(biblist)
  bcode_save=''
  FOR i=0,n-1 DO BEGIN
    k=where(biblist[i] EQ blist,nk)
    IF nk EQ 0 THEN bcode_save=[bcode_save,biblist[i]]
  ENDFOR
  k=where(bcode_save NE '',nk)
  IF nk NE 0 THEN BEGIN
    bcode_save=bcode_save[k]
    print,'% CIT_INSTR_CHECK_YEAR: the bibcode save file has entries not found in the current search. These entries are:'
    FOR i=0,nk-1 DO print,'   https://ui.adsabs.harvard.edu/abs/'+bcode_save[i]
  ENDIF 
ENDIF 

nb=n_elements(blist)
bcode_save=''
FOR i=0,nb-1 DO BEGIN
  k=where(blist[i] EQ biblist,nk)
  IF nk EQ 0 THEN bcode_save=[bcode_save,blist[i]]
ENDFOR
IF n_elements(bcode_save) GT 1 THEN BEGIN
  bcode_save=bcode_save[1:*]
  nb=n_elements(bcode_save)
  print,'% CIT_INSTR_CHECK_YEAR: there are '+trim(nb)+' new publications:'
  FOR j=0,nb-1 DO BEGIN
    print,'   https://ui.adsabs.harvard.edu/abs/'+trim(bcode_save[j])
  ENDFOR
 ;
 ; The following updates the bibcode save list.
 ;
  IF keyword_set(update) THEN BEGIN
   ;
   ; First make a copy of the current file and put it in the 'backup'
   ; directory.
   ;
    IF new_file EQ 0 THEN BEGIN 
      backup_dir=concat_dir(bib_save_dir,'backup')
      chck=file_info(backup_dir)
      IF chck.exists EQ 0 THEN file_mkdir,backup_dir
      backup_file='bibcode_list_'+trim(year)+'_backup_'+datestr+'.txt'
      backup_file=concat_dir(backup_dir,backup_file)
      file_move,biblist_file,backup_file
    ENDIF 
   ;
   ; Now write the updated file. The new bibcodes are indicated with '*'.
   ;
    openw,lout,biblist_file,/get_lun
    n_orig=n_elements(biblist)
    FOR i=0,n_orig-1 DO printf,lout,trim(biblist[i])
    FOR i=0,nb-1 DO printf,lout,bcode_save[i]+'*'
    free_lun,lout
  ENDIF
 ;
  IF keyword_set(new_file) AND keyword_set(update) THEN BEGIN
    openw,lout,biblist_file,/get_lun
    FOR i=0,nb-1 DO printf,lout,bcode_save[i]+'*'
    free_lun,lout
  ENDIF 
 ;
  new_bibcodes=bcode_save
ENDIF ELSE BEGIN
  print,'% CIT_INSTR_CHECK_YEAR: no new publications found for this year.'
  IF n_elements(biblist) GT nb THEN BEGIN
    print,'% CIT_INSTR_CHECK_YEAR: WARNING - the save file has more publications than were found in the current search!'
  ENDIF
ENDELSE 
    
END
