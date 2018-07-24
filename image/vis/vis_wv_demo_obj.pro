pro vis_wv_demo_obj

  search_network, /enable

  ; number of wavelet scales
  nscales = 3

  ; rhessi event params
  imsize = [128, 128]
  pixel = [1.0, 1.0]
  mapcenter=[-869,-239]
  time_interval=['2002-Jul-23 00:29:10', '2002-Jul-23 00:30:19']
  epsmin=36
  epsmax=41
  detectors=[0,0,1,1,1,1,1,1,1]

  ; download the data and generate the visibil ity
  io = hsi_image()
  io->set, DET_INDEX_MASK=detectors,$
    image_dim=imsize,$
    pixel_size=pixel,$
    xyoffset=mapcenter, $
    im_time_interval=time_interval,$
    phz_n_roll_bins_min=6, $
    phz_n_roll_bins_max=64,$
    im_energy_binning=[epsmin,epsmax], $
    vis_conjugate=0, $
    vis_normalize=1, $
    vis_edit=1, $
    use_phz_stacker= 1L, $
    modpat_skip= 4

  res = io->getdata(image_alg='vis_wv', vis_wv_nscales=3, /vis_wv_autolam)

  window, 0
  loadct, 5
  io->plot

end