;+
; Name:
;  GOES_TEM_CALC
;
; Purpose:
;  GOES_TEM_CALC calculates the temperature and emission measure from the theoretical response
;  of the GOES ionization X-ray chamber flux values
;
; Explanation:
;  This procedure organizes the inputs and outputs into the GOES_MEWE_TEM and GOES_CHIANTI_TEM procedures.
;  NOTE: GOES_MEWE_TEM is still available, but is unsupported. We recommend using GOES_CHIANTI_TEM.
;  Those routines interpolate on the ratio between the long and short wavelength channel fluxes using
;  pre-calcuated tables for the fluxes at a series of temperatures for fixed emission measure.
;  Note that ratios which lie outside of the default lower limits for the fluxes,
;  and particularly negative values in the case of background subtracted inputs, are
;  returned with fixed values of 4.0 MegaKelvin and 1.0e47 cm-3 for the temperature and emission measure.
;  Normally, those limits are 1e-8 and 1e-10 for the long and short wavelength channel inputs.
;
; Input Argument:
;  GFLUX -  goes fluxes organized as a 2 x N or N x 2 array where the long wavelength channel is the
;    first of the two.  If two by two, the long wavelength values are large than the short wavelength
;    values.
;
; Optional Input Keywords:
;  SAT - GOES series, default is 8, takes precedence if SAVESAT is also present
;  DATE - date in anytim format if tarray is not fully qualified (only sec of day)
;  CHIANTI - use CHIANTI synthetic flux to determine response, set to 0 for MAYER/MEWE, default is 1
;  PHOTOSPHERIC - default is 0, only applies to CHIANTI, use photospheric abundance if set
;  CUTOFF - values below which the data are thought unreliable and the temperature is set to 4MK
;    and the emission measure to .01 (* 1e49 cm-3)
;  REMOVE_SCALING - see header to goes_chianti_tem for explanation
;
; Output Arguments;
;  TE - temperature in Megakelvin,
;  EM - emission measure in 1e49 cm-3,
;
; Common Blocks:
;  None
;
; Calls:
;  goes_mewe_tem, goes_chianti_tem
;
; History:
; RAS, 23-oct-2006
; 04-Jun-2020, Kim. Added remove_scaling keyword, and pass through to chianti and mewe routines
; 10-aug-2020, RAS. Added _extra to call to goes_chianti_tem, eg to control the use of the newly computed
;   tables (new_table=1, default) used therein. The new_table includes 16&17 (must use there) and all of
;   the earlier ones but with Chianti v 9.0.1 used to compute the input flux
; 14-Oct-2020, Kim. Cleaned up/ clarified header doc.
;-

pro goes_tem_calc, gflux, te, em, $
  sat=sat, $
  date=date, $
  chianti=chianti, $
  photospheric=photospheric, $
  cutoff=cutoff, $
  remove_scaling=remove_scaling, $
  _extra=_extra

  default, photospheric,0
  default, chianti, 1
  default, sat, 10
  default, date, '12-feb-2002'
  sz = size(/str, gflux)
  dim= sz.dimensions>1
  case 1 of
    dim[0]*dim[1] eq 2: begin
      fl = gflux[0]
      fs = gflux[1]
    end
    dim[0] ge 3: begin
      fl = gflux[*,0]
      fs = gflux[*,1]
    end
    dim[1] ge 3: begin
      fl = gflux[0,*]
      fs = gflux[1,*]
    end
    avg(gflux[0,*]) gt avg(gflux[1,*]) : begin
      fl = gflux[0,*]
      fs = gflux[1,*]
    end
    else: begin
      fl = gflux[*,1]
      fs = gflux[*,0]
    end
  endcase


  cutoff0 = 1.0e-7/10.
  cutoff1 = 1.0e-9/10.
  default, cutoff, [cutoff0, cutoff1]
  q = where( fl lt cutoff[0] or fs lt cutoff[1], nq)

  if keyword_set(chianti) then $
    goes_chianti_tem, fl, fs, te, em, satellite = sat, date = date, photospheric = photospheric, $
    remove_scaling = remove_scaling, _extra = _extra $
  else $
    goes_mewe_tem,  fl, fs, te, em, satellite=sat,  date=date, remove_scaling=remove_scaling

  te = reform(te, /over)
  em = reform(em, /over)
  if nq ge 1 then begin
    te[q] = 4.0
    em[q] = .01
  endif

end