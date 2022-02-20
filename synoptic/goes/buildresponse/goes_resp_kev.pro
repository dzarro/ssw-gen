;+
; :Description:
;    Integrate the GOES power (aka true_flux) over the soft x-ray spectrum
;    convolved with the transfer function (power efficiency) and scale
;    into units of Watts/m2 accounting for the flux into the detector aperture
;
;
;
; :Keywords:
;    sat - GOES satellite number 1-17 (July 2020)
;    photospheric - use default photospheric abundances
;    new_table - use chianti wavelength response using chianti vers 9.0.1, 21-jul-2020
;
; :Author: 05-Jul-2020, rschwartz70@gmail.com
;-
function goes_resp_kev, sat = sat, photospheric = photospheric, $
  plot_resp = plot_resp, new_table = new_table
  
  default, photospheric, 0
  default, plot_resp, 0
  default, sat, 15
  isat = sat - 1
  current_ab_type = ''
  if photospheric then begin
    current_ab_type = getenv('XR_AB_TYPE')
    set_xr_abundance, xr_ab_type=(['sun_coronal_ext','sun_photospheric'])[photospheric]

  endif

  ;Get the transfer function for the SAT satellite
  rr =goes_get_transfer(sat = sat, /calibrate, /interpolate)

  krange = chianti_kev_wvl_range( /kev)
  ;uaw the photon energy grid from 0.7 keV to 20 keV for the transfer function
  ;
  ;getenv('CHIANTI_LINES_FILE')== 'chianti_lines_07_12_unity_v901_t41.geny'

  edg2 = rr.ekev2 > krange[0] ;make sure energies are with database bounds

  edgm = get_edges(edg2,/mean)

  tsm = rr.tsme

  tlm = rr.tlme


  temp=goes_resp_mk_temp() ;101 temp
  ntemp = n_elements( temp )

  tempkev = temp/11.606
  nbins   = n_elements( edgm )
  ;  ephflxs = fltarr(nbins, ntemp)
  ;  for i=0,ntemp-1 do ephflxs[0,i]= edgm * f_vth( edg2, [1., tempkev[i]])
  ephflxs = f_vth( edg2, [1.0,1.0], multi_temp = tempkev)
  ;Restore abundance
  if keyword_set( current_ab_type ) then begin
     
    set_xr_abundance, xr_ab_type = current_ab_type

  endif

  ;ephflxs in kev / cm2 / sec / kev
  ;multiply by de, de is a constant by construction
  factor = avg(get_edges( edg2, /wid))
  ;now kev/cm2/sec
  ;convert kev/sec to watt
  factor *= 1.60218e-16
  ;now Watt/cm2
  ;convert to Watt / m2
  factor *= 1e4
  totpow = fltarr( 2, ntemp)
  totpow[0,*] = (edgm*tlm)#ephflxs
  totpow[1,*] = (edgm*tsm)#ephflxs
  totpow *= factor
  trueflx = fltarr(2,ntemp)

  for i=0,ntemp-1 do begin &$
    goes_fluxes, 11.606*tempkev[i],1.0, fl, fs, sat=sat <15, /true_flux, abund = photospheric, new_table = new_table &$
    trueflx[0,i] = [fl, fs] & endfor

  if keyword_set( current_ab_type ) then begin

    set_xr_abundance, xr_ab_type= current_ab_type

  endif


  if plot_resp then begin
    plot, tempkev, totpow[1,*]/totpow[0,*]

    oplot, tempkev[*], trueflx[1,*]/trueflx[0,*], thick=2
  endif
  ;we have to get the scaling between goes trueflx values and the
  ;corresponding totpow. Should be nearly constant for 1e49 cm-3 EM
  ratio = f_div( trueflx,totpow)
  out = {truflx: trueflx, tempkev:tempkev, ephflxs: ephflxs, edg2:edg2, edgm:edgm, totpow:totpow, $
    trnsfr: rr, ratio: ratio }
  return, out
end