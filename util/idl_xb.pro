function idl_xb, im, s, beta_tmp, dim_mtrx, mtrx, g, model
  ;+
  ; NAME:
  ; idl_xb
  ; PURPOSE:
  ; return the product between the circulant diffraction matrix and beta_tmp according to IDL indexes g
  ; EXPLANATION:
  ; compute the product between the sparse matrix mtrx (built following the MATLAB lexicographic order)
  ; and the array beta_tmp (ordered according to the IDL lexicographic order).
  ; We remark that if model is equal to 1 the product between mtrx and beta_tmp has to be cut in the
  ; first n_g indexes (where n_g is the number of diffraction fringes pixels g) since the
  ; matrix mtrx is built so that it includes both the diffraction model and the energy constraint along the
  ; saturated image columns
  ; CALLING SEQUENCE:
  ; Xb_tmp = idl_xb( im, s, beta_tmp, dim_mtrx, mtrx, g, model )
  ; INPUTS:
  ; im = image
  ; s  = saturation pixels (according to the IDL lexicographic order)
  ; beta_tmp = photon flux array (on the saturation pixels s)
  ; dim_mtrx = size of the matrix mtrx
  ; mtrx = sparse matrix
  ; g = diffraction fringes pixels (according to the IDL lexicographic order)
  ; model = 1 if the energy constraint along the image columns is requested
  ; OUTPUTS:
  ; Xb_tmp = array of the same size of g which is the product between the matrix
  ;          mtrx and beta_tmp
  ; CALLED BY:
  ;   dst_PRiL_EM_glmnet
  ; CALLS:
  ;   matlab_reordering, matlab_index, matlab_set_val
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ;
  ;-
  ; Re-order beta_tmp according to the matlab lexicographic order
  beta_tmp_m = matlab_reordering(im, s, beta_tmp)
  aux_tmp = make_array(dim_mtrx,/DOUBLE) & aux_tmp[0]=beta_tmp_m ; necessary step to do product with sparse matrix
  Xb_tmp_m = sprsax(mtrx,aux_tmp)
  g_m = matlab_index(im, g)
  n_g = n_elements(g)
  if model then begin
    ; cut
    Xb_tmp_m_g = Xb_tmp_m[0:n_g-1]
    Xb_tmp_g = matlab_set_val(im, g_m, Xb_tmp_m_g, g)
    Xb_tmp = [Xb_tmp_g, Xb_tmp_m[n_g:dim_mtrx-1]]
  endif else begin
    Xb_tmp = matlab_set_val(im, g_m, Xb_tmp_m, g)
  endelse


  return, Xb_tmp
end
