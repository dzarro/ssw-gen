;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Document name: ellipse_calc.pro
; Created by:    Liyun Wang, GSFC/ARC, November 22, 1994
;
; Last Modified: 2021-08-11, William Thompson
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
PRO ELLIPSE_CALC, x, a, y, dyda
;+
; PROJECT:
;       SOHO - CDS
;
; NAME:
;       ELLIPSE_CALC
;
; PURPOSE: 
;       Return function value and its derivatives of an ellipse
;
; EXPLANATION:
;       
; CALLING SEQUENCE: 
;       ELLIPSE_CALC, x, a, y, dyda
;
; INPUTS:
;       X -- A two element vector for position of the point on the ellipse
;       A -- A four-element vector representing central position (x0, y0) and
;            semi-major and -minor axes (a0, b0) of the ellipse
;       
; OPTIONAL INPUTS: 
;       None.
;
; OUTPUTS:
;       Y    -- Function value of the ellipse equation.
;       DYDA -- Derivatives of the function
;
; OPTIONAL OUTPUTS:
;       None.
;
; KEYWORD PARAMETERS: 
;       None.
;
; CALLS:
;       None.
;
; COMMON BLOCKS:
;       None.
;
; RESTRICTIONS: 
;       None.
;
; SIDE EFFECTS:
;       None.
;
; CATEGORY:
;       Misc, user-supplied function
;       
; PREVIOUS HISTORY:
;       Written November 22, 1994, Liyun Wang, GSFC/ARC
;
; MODIFICATION HISTORY:
;       
; VERSION:
;       Version 1, November 22, 1994
;       Version 2, 2021-08-11, William Thompson, renamed to avoid conflict with
;               routine of same name in IDL distribution.
;-
;
   ON_ERROR, 2
   IF N_ELEMENTS(x) NE 2 OR N_ELEMENTS(a) NE 4 THEN $
      MESSAGE, 'Number of parameters wrong'
   xx02 = (x(0)-a(0))^2
   yy02 = (x(1)-a(1))^2
   a02 = a(2)*a(2)
   b02 = a(3)*a(3)
   y = xx02/a02+yy02/b02-1.0
   dyda = a
   dyda(0) = -2.0*(x(0)-a(0))/a02
   dyda(1) = -2.0*(x(1)-a(1))/b02
   dyda(2) = -2.0*xx02/(a02*a(2))
   dyda(3) = -2.0*yy02/(b02*a(3))
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of 'ellipse_calc.pro'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
