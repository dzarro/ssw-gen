;+
; PROJECT:
;	SSW
; NAME:
;	PTR_CONCAT
;
; PURPOSE:
;	This function concatenates the contents of dereferenced pointers that
;	contain identical structures or identical fields(tags).
;
; CATEGORY:
; 	Structures, Pointers
;
; CALLING SEQUENCE:
;	Result =  Ptr_Concat(ptrarr, index, valid, nvalid)
;
; Example: 
;    IDL> help, *vcbe[ valid[0] ]
;    <PtrHeapVar960> STRUCT    = -> HSI_CALIBVIS_EVENT_STACK Array[32]
;    IDL> help, *vcbe[ valid[0] ],/st
;    ** Structure HSI_CALIBVIS_EVENT_STACK, 27 tags, length=152, data length=147:
;    ROLL_ANGLE      FLOAT           1.12901
;    MODAMP          FLOAT           1.00000
;    PHASE_MAP_CTR   FLOAT          -2.03764
;    GRIDTRAN        FLOAT          0.265301
;    FLUX_VAR        FLOAT           1.00000
;    BACKGROUND      FLOAT          0.000000
;    COUNT           FLOAT           2.55927
;    LIVETIME        FLOAT           67.9040
;    TIME_BIN        FLOAT       0.000488281
;    GAP             BYTE         0
;    ATTEN_STATE     INT              1
;    ISC             INT              0
;    HARM            INT              1
;    POSANG          FLOAT         0.0479101
;    ERANGE          FLOAT     Array[2]
;    TRANGE          DOUBLE    Array[2]
;    U               FLOAT          0.220757
;    V               FLOAT         0.0105846
;    OBSVIS          COMPLEX   (     -5.98881,      11.8825)
;    TOTFLUX         FLOAT           49.9419
;    SIGAMP          FLOAT           9.45125
;    CHI2            FLOAT           2.15237
;    XYOFFSET        FLOAT     Array[2]
;    TYPE            STRING    'photon'
;    UNITS           STRING    'Photons cm!u-2!n s!u-1!n'
;    COUNTSUM        FLOAT           192.251
;    NORM_PH_FACTOR  FLOAT           1.04096
;    
;    EXTRACT THE FIELD 'COUNT' from the structure inside the pointer array and concatenate
;    IDL> count=ptr_concat( vcbe, index, valid, nvalid, these_tag='count', /extract)
;    IDL> help, count, vcbe, index, valid, nvalid
;    COUNT           FLOAT     = Array[191]
;    VCBE            POINTER   = Array[9]
;    INDEX           LONG      = Array[10]
;    VALID           LONG      = Array[9]
;    NVALID          LONG      =            9
;    
; 
; INPUTS:
;       Ptrarr: array of pointers to be dereferenced
;
; OPTIONAL INPUTS:
;  	
;
; OUTPUTS:
;    Index - Lonarr of Nvalid elements.  Gives position in Result for each valid pointer
;	   Valid  - Selected valid pointers
;	   Nvalid - total number of valid pointers
;
; OPTIONAL OUTPUTS:
;	none
;
; KEYWORDS:
;  	CHECK_TYPE - only concatenate identical numerical datatypes.
;  	THESE_TAGS - only concatenate these specific tags
;  	EXTRACT    - if set and if there is only 1 tag, extract the field from the structure on return, def 0
; SIDE EFFECTS:
;	none
;
; RESTRICTIONS:
;	This functions only at the top level, nothing recursive
;
; PROCEDURE:
;	none
;
; MODIFICATION HISTORY:
;	10-feb-2009, Version 1, richard.schwartz@nasa.gov
;	30-oct-2017, richard.schwartz@nasa.gov, added EXTRACT keyword
;
;-

function ptr_concat, ptr, index, valid, nvalid, $
  extract = extract, $
  check_type = check_type, these_tags = these_tags, in_struct = in_struct
  
  default, extract, 0

  index = 0
  valid =where( size(/tname,ptr[0])  eq 'POINTER', nvalid)
  if nvalid then valid = where(ptr_valid(ptr), nvalid)
  if nvalid eq 0 then begin
    message,/cont, 'No valid pointers'
    return, 0
  endif
  index = lonarr( nvalid )
  first =(*ptr[valid[0]])[0]
  ttags = get_uniq(these_tags)
  if keyword_set( these_tags) then begin
    err_code = n_elements(get_tag_index(first,(ttags))) ne n_elements(ttags)
    if err_code then $
      err_msg='Not valid tags for structure found in pointer: '+arr2str(these_tags,' ')+'  not in ' +arr2str(tag_names(first))
    if not err_code then first = struct_subset( first, these_tags, /quiet, err_code=err_code, err_msg=err_msg)
    if err_code then begin
      message,/continue,err_msg
      return,0
    endif
  endif
  first_str = size(first, /str)
  pass = min(abs( [0,10,11] - first_str.type) < 1) ; all one's can be concatenated, 0's can't
  if not pass then begin
    message,/cont,'Data type cannot be concatenated, type = '+strtrim(first_str.type,2)
    return, 0
  endif
  default, check_type, 0
  check_type = first_str.type eq 8 ? 1 :check_type ;if we're concatenating structures the types must agree

  type = first_str.type
  for i=0L,nvalid-1 do begin
    nx_str =size(*ptr[valid[i]],/st)
    ntype= nx_str.type
    pass= (type eq 8) and (ntype eq 8) or $
      ( ((type ne 8) and (ntype ne 8)) and ( check_type? type eq ntype : 1) )
    if not pass then begin
      valid[i] = 0
    endif else begin
      index[i] = nx_str.n_elements
    endelse
  endfor



  sel = where(index<1, nvalid)
  valid = valid[sel]
  index = [0, index[sel]]

  index = long(total(index,/cum))

  
    ;In this branch we're pulling the structure fields out of the pointer and concatenating
    out = replicate( first[0], last_item(index))
    for i=0L, nvalid-1 do begin
      nx = *ptr[valid[i]]
      nx_str = size(/str, nx)
      temp = replicate( first[0], nx_str.n_elements)
      if 	((first_str.type eq 8 and nx_str.type eq 8) and $
        (first_str.structure_name eq '' or nx_str.structure_name eq '') ) $
        then begin
        struct_assign, nx, temp
        nx = temp
      endif
      out[index[i]] =nx
    endfor
    out = extract and n_tags( out ) eq 1 ? out.(0) : out
  return, out
end