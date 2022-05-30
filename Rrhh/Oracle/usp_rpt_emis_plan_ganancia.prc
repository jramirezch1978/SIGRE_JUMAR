create or replace procedure usp_rpt_emis_plan_ganancia
( as_codtra in maestro.cod_trabajador%type
 ) is

lk_n_rem_basica constant char(3):='500';    lk_n_asig_merito constant char(3):='501';
lk_n_tran_recate constant char(3):='502';   lk_n_in_ley constant char(3):='503';
lk_n_in_dl constant char(3):='504';         lk_n_cta_categ constant char(3):='505';
lk_n_rem_gerencia constant char(3):='506';  lk_n_sem_inglesa constant char(3):='507';
lk_n_sobret constant char(3):='508';        lk_n_dom_trabaja constant char(3):='509';
lk_n_sob_dom constant char(3):='510';       lk_n_fer_trabaja constant char(3):='511';
lk_n_sob_tur_vac constant char(3):='512';   lk_n_asi_guardia constant char(3):='513';
lk_n_subsidio_ley constant char(3):='514';  lk_n_sub_cta_ipss constant char(3):='515';
lk_n_resp_direct constant char(3):='516';   lk_n_asig_espe constant char(3):='517';
lk_n_rein_inasis constant char(3):='518';   lk_n_perm_remune constant char(3):='519';
lk_n_otras_ganan constant char(3):='520';   lk_n_bonif_quinq constant char(3):='521';        
lk_n_afp_10 constant char(3):='522';        lk_n_afp_3 constant char(3):='523';   
lk_n_rac_trabaja constant char(3):='524';   lk_n_rem_deveng constant char(3):='525';   
lk_n_gratif_dev constant char(3):='526';    lk_n_vacaciones constant char(3):='527';   
lk_n_vac_deveng constant char(3):='528';    lk_n_asig_vacac constant char(3):='529';   
lk_n_gratif_jubil constant char(3):='530';  lk_n_int_legales constant char(3):='531';   
lk_n_gratificacion constant char(3):='532'; lk_n_v_per constant char(3):='533';   
lk_n_v_dev constant char(3):='534';         lk_n_a_vac constant char(3):='535';   
lk_n_bonif_30 constant char(3):='536';      lk_n_rac_azuxar constant char(3):='537';   
lk_n_pens_jubilac constant char(3):='538';  lk_n_bonif_25_jubi constant char(3):='539';   
lk_n_incremento_10 constant char(3):='540'; lk_n_prestamo constant char(3):='541';   
lk_n_campo43 constant char(3):='542';       lk_n_campo44 constant char(3):='543';   
lk_n_campo45 constant char(3):='544';       lk_n_campo46 constant char(3):='545';   
lk_n_campo47 constant char(3):='546';       lk_n_campo48 constant char(3):='547';    
lk_n_campo49 constant char(3):='548';       lk_n_campo50 constant char(3):='549';   
lk_n_campo51 constant char(3):='550';       lk_n_tot_ingreso constant char(3):='551';   

--Variables de los importes 
ln_imp_rem_bas number(13,2);      ln_imp_asig_merito number(13,2);
ln_imp_tran_recate number(13,2);  ln_imp_in_ley number(13,2);
ln_imp_in_dl number(13,2)  ;      ln_imp_cta_categ  number(13,2); 
ln_imp_rem_ger number(13,2);      ln_imp_sem_ingl number(13,2); 
ln_imp_sobret number(13,2) ;      ln_imp_dom_trab number(13,2);
ln_imp_sob_dom number(13,2);      ln_imp_fer_trab  number(13,2);
ln_imp_sob_tur_vac number(13,2);  ln_imp_asi_guardia number(13,2);
ln_imp_subs_ley number(13,2) ;    ln_imp_sub_cta_ipss  number(13,2);
ln_imp_resp_direc number(13,2);   ln_imp_asig_espe number(13,2);
ln_imp_rein_inasis number(13,2);  ln_imp_perm_remun number(13,2);
ln_imp_otras_gan number(13,2);    ln_imp_bonif_quinq number(13,2);
ln_imp_afp_10 number(13,2);       ln_imp_afp_3 number(13,2);
ln_imp_rac_trab number(13,2);     ln_imp_rem_deveng number(13,2);
ln_imp_gratif_dev number(13,2);   ln_imp_vacacion number(13,2);
ln_imp_vac_deveng number(13,2);   ln_imp_asig_vac number(13,2);
ln_imp_gratif_jubil number(13,2); ln_imp_int_leg number(13,2);
ln_imp_gratif number(13,2);       ln_imp_v_per number(13,2);  
ln_imp_v_dev number(13,2);        ln_imp_a_vac  number(13,2);
ln_imp_bonif_30 number(13,2);     ln_imp_rac_azu number(13,2);
ln_imp_pens_jubil number(13,2);   ln_imp_bonif_25_jubi number(13,2);
ln_imp_increm10 number(13,2);     ln_imp_prestamo  number(13,2);
ln_imp_campo43 number(13,2);      ln_imp_campo44 number(13,2); 
ln_imp_campo45 number(13,2);      ln_imp_campo46  number(13,2);
ln_imp_campo47 number(13,2);      ln_imp_campo48 number(13,2);
ln_imp_campo49 number(13,2);      ln_imp_campo50 number(13,2);
ln_imp_campo51 number(13,2);      ln_imp_tot_ing number(13,2);

begin
 --Importe de las Ganancias del Trabajador 
 --Imp de Rem basica
  select sum(c.imp_soles)
   into ln_imp_rem_bas
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_rem_basica and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_rem_bas := nvl(ln_imp_rem_bas,0);        
         
  --Imp Asig Merito 
  select sum(c.imp_soles)
   into ln_imp_asig_merito
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_asig_merito and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_asig_merito := nvl(ln_imp_asig_merito,0);
  
  --Imp Tran Recate
  select sum(c.imp_soles)
   into ln_imp_tran_recate
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_tran_recate and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tran_recate := nvl(ln_imp_tran_recate,0);
  
  --Imp In Ley 
  select sum(c.imp_soles)
   into ln_imp_in_ley
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_in_ley and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_in_ley := nvl(ln_imp_in_ley,0);
  
  --Imp In DL 
  select sum(c.imp_soles)
   into ln_imp_in_dl
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_in_dl and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_in_dl := nvl(ln_imp_in_dl,0);
  
  --Imp cta categ
  select sum(c.imp_soles)
   into ln_imp_cta_categ
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_cta_categ and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_cta_categ := nvl(ln_imp_cta_categ,0);
  
  --Imp Rem Gerencia
  select sum(c.imp_soles)
   into ln_imp_rem_ger
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_rem_gerencia and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_rem_ger := nvl(ln_imp_rem_ger,0);
  
  --Imp Sem Inglesa
  select sum(c.imp_soles)
   into ln_imp_sem_ingl
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sem_inglesa and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sem_ingl := nvl(ln_imp_sem_ingl,0);
  
  --Imp Sobretiempo
  select sum(c.imp_soles)
   into ln_imp_sobret
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sobret and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sobret := nvl(ln_imp_sobret,0);
  
  --Imp Dom Trabaja 
  select sum(c.imp_soles)
   into ln_imp_dom_trab
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_dom_trabaja and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_dom_trab := nvl(ln_imp_dom_trab,0);

  --Imp Sob Dom 
  select sum(c.imp_soles)
   into ln_imp_sob_dom
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sob_dom and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sob_dom := nvl(ln_imp_sob_dom,0);
  
  --Imp fer Trabaja
  select sum(c.imp_soles)
   into ln_imp_fer_trab
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_fer_trabaja and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_fer_trab := nvl(ln_imp_fer_trab,0);
   
  --Imp Sob Tur vac
  select sum(c.imp_soles)
   into ln_imp_sob_tur_vac
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sob_tur_vac and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sob_tur_vac := nvl(ln_imp_sob_tur_vac,0);
  
  --Imp Asig Guardia 
  select sum(c.imp_soles)
   into ln_imp_asi_guardia
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_asi_guardia and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_asi_guardia := nvl(ln_imp_asi_guardia,0);
  
  --Imp Subsidio Ley         
  select sum(c.imp_soles)
   into ln_imp_subs_ley
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_subsidio_ley and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_subs_ley := nvl(ln_imp_subs_ley,0);
  
  --Imp  Sub Cta Ipss
  select sum(c.imp_soles)
   into ln_imp_sub_cta_ipss
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sub_cta_ipss   and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sub_cta_ipss := nvl(ln_imp_sub_cta_ipss,0);
  
  --imp Resp Direct 
  select sum(c.imp_soles)
   into ln_imp_resp_direc
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_resp_direct and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_resp_direc := nvl(ln_imp_resp_direc,0);
  
  --Imp Asig Espe
  select sum(c.imp_soles)
   into ln_imp_asig_espe
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_asig_espe and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_asig_espe := nvl(ln_imp_asig_espe,0);
  
  --Imp Rein Inasis 
  select sum(c.imp_soles)
   into ln_imp_rein_inasis
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_rein_inasis and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_rein_inasis := nvl(ln_imp_rein_inasis,0);
  
  --Imp Perm Remune
  select sum(c.imp_soles)
   into ln_imp_perm_remun
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_perm_remune and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_perm_remun := nvl(ln_imp_perm_remun,0);
  
  --Imp Otras Ganan 
  select sum(c.imp_soles)
   into ln_imp_otras_gan
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_otras_ganan and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_otras_gan := nvl(ln_imp_otras_gan,0);
   
  --Imp Bonif Quinq 
  select sum(c.imp_soles)
   into ln_imp_bonif_quinq
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_bonif_quinq and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_bonif_quinq := nvl(ln_imp_bonif_quinq,0);
  
  --Imp Afp 10
  select sum(c.imp_soles)
   into ln_imp_afp_10
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_afp_10 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_afp_10 := nvl(ln_imp_afp_10,0);
  
  --IMp Afp 3
  select sum(c.imp_soles)
   into ln_imp_afp_3
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_afp_3 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_afp_3 := nvl(ln_imp_afp_3,0);
  
  --Imp Rac Trabaja
  select sum(c.imp_soles)
   into ln_imp_rac_trab
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_rac_trabaja and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_rac_trab := nvl(ln_imp_rac_trab,0);
  
  --Imp Rem Devenga
  select sum(c.imp_soles)
   into ln_imp_rem_deveng
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_rem_deveng and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_rem_deveng := nvl(ln_imp_rem_deveng,0);
  
  --Imp Gratif Dev 
  select sum(c.imp_soles)
   into ln_imp_gratif_dev
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_gratif_dev and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_gratif_dev := nvl(ln_imp_gratif_dev,0);
  
  --Imp Vacaciones 
  select sum(c.imp_soles)
   into ln_imp_vacacion
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_vacaciones and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_vacacion := nvl(ln_imp_vacacion,0);
  
  --Imp Vac Deveng 
  select sum(c.imp_soles)
   into ln_imp_vac_deveng 
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_vac_deveng and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_vac_deveng := nvl(ln_imp_vac_deveng,0);
  
  --Imp Asig vacac
  select sum(c.imp_soles)
   into ln_imp_asig_vac
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_asig_vacac and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_asig_vac := nvl(ln_imp_asig_vac,0);
  
  --Imp Gratif Jubil 
  select sum(c.imp_soles)
   into ln_imp_gratif_jubil
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_gratif_jubil and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_gratif_jubil := nvl(ln_imp_gratif_jubil,0);
  
  --Imp int legales 
  select sum(c.imp_soles)
   into ln_imp_int_leg
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_int_legales and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_int_leg := nvl(ln_imp_int_leg,0);
  
  --Imp Gratificacion
  select sum(c.imp_soles)
   into ln_imp_gratif
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_gratificacion and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_gratif := nvl(ln_imp_gratif,0);
  
  --Imp V Per 
  select sum(c.imp_soles)
   into ln_imp_v_per
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_v_per and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_v_per := nvl(ln_imp_v_per,0);
  
  --Imp V Dev 
  select sum(c.imp_soles)
   into ln_imp_v_dev
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_v_dev and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_v_dev := nvl(ln_imp_v_dev,0);
  
  --Imp A vac 
  select sum(c.imp_soles)
   into ln_imp_a_vac
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_a_vac and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_a_vac := nvl(ln_imp_a_vac,0);
  
  --Imp Bonif 30
  select sum(c.imp_soles)
   into ln_imp_bonif_30
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_bonif_30 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_bonif_30 := nvl(ln_imp_bonif_30,0);
  
  --Imp Rac Azucar
  select sum(c.imp_soles)
   into ln_imp_rac_azu
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_rac_azuxar and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_rac_azu := nvl(ln_imp_rac_azu,0);
  
  --Imp Pens Jubilac
  select sum(c.imp_soles)
   into ln_imp_pens_jubil
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_pens_jubilac and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_pens_jubil := nvl(ln_imp_pens_jubil,0);
  
  --Imp Bonif 25 Jubi
  select sum(c.imp_soles)
   into ln_imp_bonif_25_jubi
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_bonif_25_jubi and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_bonif_25_jubi := nvl(ln_imp_bonif_25_jubi,0);
  
  --Imp Incremento 10 
  select sum(c.imp_soles)
   into ln_imp_increm10
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_incremento_10 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_increm10 := nvl(ln_imp_increm10,0);
  
  --Imp Prestamo
  select sum(c.imp_soles)
   into ln_imp_prestamo
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_prestamo and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_prestamo := nvl(ln_imp_prestamo,0);
  
  --Imp Campo43
  select sum(c.imp_soles)
   into ln_imp_campo43
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo43 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo43 := nvl(ln_imp_campo43,0);
   
  --Imp Campo44
  select sum(c.imp_soles)
   into ln_imp_campo44
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo44 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo44 := nvl(ln_imp_campo44,0);
  
  --Imp Campo45
  select sum(c.imp_soles)
   into ln_imp_campo45
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo45 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo45 := nvl(ln_imp_campo45,0);
  
    --Imp Campo46
  select sum(c.imp_soles)
   into ln_imp_campo46
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo46 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo46 := nvl(ln_imp_campo46,0);
  
    --Imp Campo47
  select sum(c.imp_soles)
   into ln_imp_campo47
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo47 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo47 := nvl(ln_imp_campo47,0);

  --Imp Campo48
  select sum(c.imp_soles)
   into ln_imp_campo48
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo48 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo48 := nvl(ln_imp_campo48,0);

    --Imp Campo49
  select sum(c.imp_soles)
   into ln_imp_campo49
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo49 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo49 := nvl(ln_imp_campo49,0);

  --Imp Campo50
  select sum(c.imp_soles)
   into ln_imp_campo50
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo50 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo50 := nvl(ln_imp_campo50,0);

  --Imp Campo51
  select sum(c.imp_soles)
   into ln_imp_campo51
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo51 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo51 := nvl(ln_imp_campo51,0);
  
  --Imp Tot Ingreso 
  select sum(c.imp_soles)
   into ln_imp_tot_ing
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_tot_ingreso and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tot_ing := nvl(ln_imp_tot_ing,0);
  
  --Actual del regis de la TT_RPT_EMIS_PLAN
  update tt_rpt_emis_plan 
    set rem_basica   = ln_imp_rem_bas     , asig_merito   = ln_imp_asig_merito  ,
        tran_recate  = ln_imp_tran_recate , in_ley        = ln_imp_in_ley       ,
        in_dl        = ln_imp_in_dl       , cta_categ     = ln_imp_cta_categ    ,
        rem_gerencia = ln_imp_rem_ger     , sem_inglesa   = ln_imp_sem_ingl     ,
        sobret       = ln_imp_sobret      , dom_trabaj    = ln_imp_dom_trab     ,
        sob_dom      = ln_imp_sob_dom     , fer_trabaj    = ln_imp_fer_trab     ,
        sob_tur_vac  = ln_imp_sob_tur_vac , asig_guardia  = ln_imp_asi_guardia  ,
        subsidio_ley = ln_imp_subs_ley    , sub_cta_ipss  = ln_imp_sub_cta_ipss ,
        resp_direct  = ln_imp_resp_direc  , asig_espe     = ln_imp_asig_espe    ,
        rein_inasis  = ln_imp_rein_inasis , perm_remun    = ln_imp_perm_remun   ,
        otras_gan    = ln_imp_otras_gan   , bonif_quinq   = ln_imp_bonif_quinq  ,
        afp_10       = ln_imp_afp_10      , afp_3         = ln_imp_afp_3        ,
        rac_trabaj   = ln_imp_rac_trab    , rem_deveng    = ln_imp_rem_deveng   ,
        gratif_dev   = ln_imp_gratif_dev  , vacaciones    = ln_imp_vacacion     ,
        vac_deveng   = ln_imp_vac_deveng  , asig_vacac    = ln_imp_asig_vac     ,
        gratif_jubil = ln_imp_gratif_jubil, int_legales   = ln_imp_int_leg      ,
        gratificacion= ln_imp_gratif      , v_per         = ln_imp_v_per        , 
        v_dev        = ln_imp_v_dev       , a_vac         = ln_imp_a_vac        ,
        bonif_30     = ln_imp_bonif_30    , rac_azucar    = ln_imp_rac_azu      ,
        pens_jubilac = ln_imp_pens_jubil  , bonif_25_jubi = ln_imp_bonif_25_jubi,
        increm_10    = ln_imp_increm10    , prestamo      = ln_imp_prestamo     , 
        campo43      = ln_imp_campo43     , campo44       = ln_imp_campo44      ,
        campo45      = ln_imp_campo45     , campo46       = ln_imp_campo46      ,
        campo47      = ln_imp_campo47     , campo48       = ln_imp_campo48      ,
        campo49      = ln_imp_campo49     , campo50       = ln_imp_campo50      ,
        campo51      = ln_imp_campo51     , tot_ingreso   = ln_imp_tot_ing 
  where cod_trabajador = as_codtra ;
  
  
  
  
  
end usp_rpt_emis_plan_ganancia;
/
