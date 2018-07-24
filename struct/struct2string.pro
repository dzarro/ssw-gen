;+
; Name: struct2string
;
; Project: RHESSI
; 
; Purpose: Construct the string array of commands necessary to create the structure passed in. Useful for constructing
;  a script with commands needed to set variables in a structure.  Can handle named structures and an array of structures, 
;  but can not handle nested structures.
;  
; Calling Sequence:  commands = struct2string(str [, varname=varname, exec=exec])
;
; Input Arguments:
;   str - input structure (named or not, scalar or array)
;
; Input Keywords:
;   varname - string containing name of variable that will be set when commands are executed. Default is 'z'.
;   exec - if set, returns a scalar string suitable for use in execute command (only works if str is not an array of structures). Default is 0.
;
; Output: string array of commands necessary to create str
;
; Restrictions: Will not handle nested structures.
;
; Examples:
;   a = {aa:1, bb:2}
;   commands = struct2string(a,varname='structure')
;   help, commands
;     <Expression>    STRING    = Array[4]
;   prstr, /nomore, commands
;      structure = { $
;       AA: 1, $
;       BB: 2 $
;      }
;      
;   Using exec will force output to be a scalar string suitable for use in execute:
;   a = {aa:1, bb:2}
;   command = struct2string(a,varname='structure', /exec)
;   help,command
;     COMMAND         STRING    = 'structure = {  AA: 1,  BB: 2 }'
;   result = execute(command)
;   help, structure
;     ** Structure <2ee6ed80>, 2 tags, length=4, data length=4, refs=1:
;        AA              INT              1
;        BB              INT              2
;
; Written: Kim Tolbert 27-Jul-2017
; Modifications:
;
;-

function struct2string, str, varname=varname, exec=exec

  checkvar, varname, 'z'
  checkvar, exec, 0

  if ~is_struct(str) then return, ' '

  nstruct = n_elements(str)
  if nstruct gt 1 and exec then begin
    message, /info, 'Can only use exec option for a single element structure. Returning blank string'
    return, ''
  endif

  some_bad = 0
  ntags = n_tags(str)
  tagnames = tag_names(str)

  str_name = size(str, /sname)

  name = str_name eq '' ? '' : str_name + ','
  out = varname + ' = {' + name + ' $'
  for i=0,ntags-1 do begin
    sval = val2string(str[0].(i))
    if ~stregex(sval, 'BAD', /bool) then out = [out, ' ' + tagnames[i] + ': ' + sval + ', $'] else $
      some_bad = 1
  endfor
  nout = n_elements(out)
  out[nout-1] = str_replace(out[nout-1], ', $', ' }') ; on last line replace continuation with close bracket

  if nstruct gt 1 then begin
    out = [out, varname + '= replicate(' + varname + ',' + trim(nstruct) + ')']
    for j = 1,nstruct-1 do begin
      for i=0,ntags-1 do begin
        sval = val2string(str[j].(i))
        if ~stregex(sval, 'BAD', /bool) then out = [out,  varname + '[' + trim(j) + '].' + tagnames[i] + ' = ' + sval] else $
          some_bad = 1
      endfor
    endfor
  endif

  if some_bad then message, /info, 'Some of the structure fields could not be included in string (nested structures, object, pointer, etc?).' 
  if exec then out = arr2str(str_replace(out,'$'), '')
  return,out
end