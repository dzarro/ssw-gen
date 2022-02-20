
FUNCTION cit_conv_latex_jnl, jnl

;+
; NAME:
;      CIT_CONV_LATEX_JNL
;
; PURPOSE:
;      Bibtex entries often give the journal name as a latex code
;      (e.g., \apj) so this routine converts them to the correct
;      name. 
;
; CATEGORY:
;      ADS; bibtex; format; journals.
;
; CALLING SEQUENCE:
;      Result = CIT_CONV_LATEX_JNL( Jnl )
;
; INPUTS:
;      Jnl:    A string containing the journal name.
;
; OUTPUTS:
;      If a Latex journal code is identified then the correct journal
;      name is returned. Otherwise the input JNL is returned.
;
; EXAMPLE:
;      IDL> print,cit_conv_latex_jnl('\apj')
;      ApJ
;
; MODIFICATION HISTORY:
;      Ver.1, 20-Jul-2017, Peter Young
;      Ver.2, 5-Sep-2019, Peter Young
;        added \procspie.
;-


CASE jnl OF
  '\aap': return,'A&A'
  '\aaps': return,'A&AS'
  '\apj': return,'ApJ'
  '\apjl': return,'ApJL'
  '\apjs': return,'ApJS'
  '\mnras': return,'MNRAS'
  '\pasj': return,'PASJ'
  '\solphys': return,'Solar Physics'
  '\ssr': return,'Sp. Sci. Rev.'
  '\ao': return,'Applied Optics'
  '\aj': return,'AJ'
  '\grl': return,'Geophysical Research Letters'
  '\pasp': return,'PASP'
  '\nat': return,'Nature'
  '\jgr': return,'JGR'
  '\icarus': return, 'Icarus'
  '\jqsrt': return,'JQSRT'
  '\pra': return,'Phys. Rev. A'
  '\prd': return,'Phys. Rev. D'
  '\pre': return,'Phys. Rev. E'
  '\araa': return,'ARA&A'
  '\apss': return,'Ap&SS'
  '\aapr': return,'A&ARv'
  '\na': return,'New Ast.'
  '\physscr': return,'Phys. Scripta'
  '\nar': return,'New Ast. Rev.'
  '\procspie': return,'Proc. SPIE'
  'Journal of Physics B Atomic Molecular Physics': return,'J. Phys. B'
  'Atomic Data and Nuclear Data Tables': return,'ADNDT'
  'Advances in Space Research': return,'Adv. Space Research'
  'Memorie della Societa Astronomica Italiana': return,'Mem. Soc. Ast. Ital.'
  'Nuclear Instruments and Methods in Physics Research A': return,'NIMPA'
  'Nuclear Instruments and Methods in Physics Research B': return,'NIMPB'
  'Space Science Reviews': return,'Sp. Sci. Rev.'
  'Physica Scripta Volume T': return,'Phys. Scripta'
  'Reviews in Modern Astronomy': return,'Rev. Mod. Ast.'
  'Optical Engineering': return,'Opt. Eng.'
  'Physics Education': return,'Phys. Ed.'
  'Review of Scientific Instruments': return,'Rev. Sci. Inst.'
  'New Astronomy Review': return,'New Ast. Rev.'
  'Journal of Optics A: Pure and Applied Optics': return,'J. Opt. A'
  'Royal Society of London Philosophical Transactions Series A': return,'Phil. Trans. Royal Soc. A'
  'Plasma Physics and Controlled Fusion': return,'Plas. Phys. Cont. Fusion'
  'Journal of Geophysical Research (Planets)': return,'JGR (Planets)'
  'Journal of Geophysical Research (Space Physics)': return,'JGR (Space Physics)'
  'Journal of Geophysical Research (Atmospheres)': return,'JGR (Atmospheres)'
  'Astronomy Letters': return,'Ast. Lett.'
  ELSE: return,jnl
ENDCASE

END
