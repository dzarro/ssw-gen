FUNCTION cit_convert_latex, str

;+
; NAME:
;      CIT_CONVERT_LATEX
;
; PURPOSE:
;      Take a string and convert common latex characters into text
;      that prints correctly in html. For example, Greek letters.
;
; CATEGORY:
;      String processing; latex.
;
; CALLING SEQUENCE:
;      Result = CIT_CONVERT_LATEX( Str )
;
; INPUTS:
;      Str:   A string.
;
; OUTPUTS:
;      Returns the input string but with certain types of latex
;      commands converted to html format.
;
; EXAMPLE:
;      IDL> print,cit_convert_latex('$\epsilon$')
;            &epsilon;
;
; MODIFICATION HISTORY:
;      Ver.1, 21-Oct-2016, Peter Young
;         This routine used to be a subroutine in make_bib_structure
;         called 'tidy_string'.
;-


str=repstr(str,'$\epsilon$','&epsilon;')
str=repstr(str,'$\kappa$','&kappa;')
str=repstr(str,'$\alpha$','&alpha;')
str=repstr(str,'$\beta$','&beta;')
str=repstr(str,'$\kappa$','&kappa;')
str=repstr(str,'$\lambda$','&lambda;')
str=repstr(str,'$\gamma$','&gamma;')
str=repstr(str,'$\xi$','&xi;')
str=repstr(str,'$\eta$','&eta;')
str=repstr(str,'$\backslash$','')
str=repstr(str,'\~o','&otilde;')
str=repstr(str,'\~','££')
str=repstr(str,'\&','&')
str=repstr(str,'\^','^')
str=repstr(str,'\_','_')
str=repstr(str,'~',' ')
str=repstr(str,'££','~')
str=repstr(str,"\'e",'&eacute;')
str=repstr(str,"\`e",string(233b))
str=repstr(str,"\'a",'&aacute;')
str=repstr(str,"\'y",string(253b))
str=repstr(str,"\'c",'c')
str=repstr(str,"\c c",string(231b))
str=repstr(str,"\`o",'&ograve;')
str=repstr(str,"\'o",'&oacute;')
str=repstr(str,'\"o','&ouml;')
str=repstr(str,'\O',string(216b))
str=repstr(str,'\"u','&uuml;')
str=repstr(str,'\"a','&auml;')
str=repstr(str,'\" ','')
str=repstr(str,'\` ','')
str=repstr(str,'\'' ','')
str=repstr(str,'\v ','')
str=repstr(str,'\gt','>')
str=repstr(str,'\nbsp',' ')
str=repstr(str,'\amp','and')
str=repstr(str,'\ndash','-')
str=repstr(str,'\mdash','-')
str=repstr(str,'_e','<sub>e</sub>')
str=repstr(str,'\lt=','&le;')
str=repstr(str,"\'\i",'i')
str=repstr(str,'\AA',string(197b))
str=repstr(str,'\times','x')

return,str

END
