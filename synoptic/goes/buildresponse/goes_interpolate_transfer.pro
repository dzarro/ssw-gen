;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    rr
;
; :Keywords:
;    lamrange
;    kevrange
;    nbins
;    interpol
;    _extra
;
; :Author: richard
;-
function goes_interpolate_transfer, rr, lamrange = lamrange, kevrange = kevrange, $
  nbins = nbins,  _extra = _extra

  cnv = 12.39854
  usekev = keyword_set( kevrange ) ;interpolate in energy space, order by energy
  default, kevrange, [0.7, 20.]
  default, lamrange, reverse( cnv/kevrange )
  default, nbins, 2000


  gs = rr.gbshort
  
  gl = rr.gblong
  ts = rr.tsm
  tl = rr.tlm
  ws = rr.wsm
  wl = rr.wlm
  q = where( ts gt 0)

  ts = ts[q] & ws = ws[q]
  q = where( tl gt 0)
  tl = tl[q] & wl = wl[q]

  ews = cnv/ws
  ewl = cnv/wl
 
  ;amir_load,/reload
  ;abundance=xr_rd_abundance(reload=1)


  ;Set up the photon energy grid from 0.7 keV to 50 keV
  edg2 = get_edges(/edges_2, interpol(kevrange, nbins+1))
  wdg2 = get_edges(/edges_2, interpol(lamrange, nbins+1))

  edgm = get_edges(edg2, /mean)
  wsm = get_edges(wdg2, /mean)

  tsme = interpol( ts, ews, edgm,  _extra = _extra)>0

  tlme = interpol(tl, ewl, edgm,  _extra = _extra)>0

  tsmw = interpol( ts, ws, wsm, _extra = _extra)>0
  tlmw = interpol( tl, wl, wsm, _extra = _extra)>0


  result = { ws: ws, wl: wl, ts: ts, tl: tl, tsme: tsme, tlme: tlme, tsmw: tsmw, tlmw: tlmw, wsm: wsm, wlm: wsm, $
    wave2: wdg2, ekev2: edg2, ekevm: edgm, ews: ews, ewl: ewl, gbshort: rr.gbshort, $
    gblong: rr.gblong, calibrated: rr.calibrated, w2ecnv: cnv, sat: rr.sat}
  return, result
end