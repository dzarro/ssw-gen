;+
; PROJECT:
;	SSW
; NAME:
;	DEREF1
; PURPOSE:
;	This function returns either the argument unchanged or if it's a pointer, the
;	dereferenced pointer.  It is not recursive.
; CATEGORY:
;	UTIL, POINTERS
;
; CALLING SEQUENCE:
;	deref_value = Deref1( arg)
;		If a is a non-pointer, arg is returned
;		If a is a valid pointer, then *arg is returned
;		If arg is not a valid pointer, then the invalid keyword's value is returned
;			If INVALID is not defined, its default is '<nullpointer>'
; CALLS:
;
; INPUTS:
;       Arg - input, valid pointer or non-pointer variable
;
; OPTIONAL INPUTS:
;
;
; OUTPUTS:
;       none explicit, only through commons;
;
; OPTIONAL OUTPUTS:
;	none
;
; KEYWORDS:
;	INVALID - returned value on null pointer for Arg.  Defaults to '<nullpointer>'
; COMMON BLOCKS:
;	none
;
; SIDE EFFECTS:
;	none
;
; RESTRICTIONS:
;	one level of dereferencing only
;
; PROCEDURE:
;	Checks the type of the argument, if it's a pointer it returns the dereferenced value, otherwise
;	the argument is returned
;
; MODIFICATION HISTORY:
;
;	11-may-2010, richard.schwartz@nasa.gov
;-
function deref1, arg, invalid=invalid
default, invalid, '<NullPointer>'
return,	size(/tname,arg) eq 'POINTER'? ( ptr_valid(arg)? *arg : invalid) : arg
end
