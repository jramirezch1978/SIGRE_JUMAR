create or replace procedure usp_rpt_emis_plan_descto
 ( as_codtra in maestro.cod_trabajador%type
  ) is

lk_n_snp constant char(3):='552';           lk_n_aporte_afp constant char(3):='553';   
lk_n_invalid_afp constant char(3):='554';   lk_n_comision_afp constant char(3):='555';   
lk_n_judicial constant char(3):='556';      lk_n_qta_categ constant char(3):='557'; 
lk_n_adel_gratif constant char(3):='558';   lk_n_adel_con_mes constant char(3):='559';     
lk_n_otros_desc constant char(3):='560';    lk_n_perm_partic constant char(3):='561';    
lk_n_tardanzas constant char(3):='562';     lk_n_comp_almace constant char(3):='563';   
lk_n_serv_telef constant char(3):='564';    lk_n_sindicato constant char(3):='565';   
lk_n_jud_deveng constant char(3):='566';    lk_n_prestamos constant char(3):='567';   
lk_n_adel_liqui constant char(3):='568';    lk_n_fact_hospit constant char(3):='569';   
lk_n_terr_vivie constant char(3):='570';    lk_n_ute_fonavi constant char(3):='571';   
lk_n_redond_ant constant char(3):='572';    lk_n_tot_desc constant char(3):='573';   
lk_n_tot_neto constant char(3):='574';      lk_n_redondeo constant char(3):='575';   
lk_n_campo77 constant char(3):='576';       lk_n_tot_pagado constant char(3):='577';   

--Variables de los importes de table de descuentos
ln_imp_snp  number(13,2)        ; ln_imp_aporte_afp  number(13,2);
ln_imp_invalid_afp number(13,2) ; ln_imp_comis_afp  number(13,2);
ln_imp_judicial number(13,2)    ; ln_imp_qta_categ number(13,2);
ln_imp_adel_gratif number(13,2) ; ln_imp_adel_con_mes number(13,2);
ln_imp_otros_desc number(13,2)  ; ln_imp_perm_partic number(13,2); 
ln_imp_tardanzas number(13,2)   ; ln_imp_com_almace number(13,2); 
ln_imp_sev_telef number(13,2)   ; ln_imp_sindicato number(13,2); 
ln_imp_jud_deveng number(13,2)  ; ln_imp_prestamos number(13,2); 
ln_imp_adel_liqui number(13,2)  ; ln_imp_fact_hospit number(13,2);  
ln_imp_terr_vivie number(13,2)  ; ln_imp_ute_fonavi number(13,2); 
ln_imp_redond_ant number(13,2)  ; ln_imp_tot_desc  number(13,2); 
ln_imp_tot_neto number(13,2)    ; ln_imp_redondeo  number(13,2); 
ln_imp_campo77 number(13,2)     ; ln_imp_tot_pagado number(13,2);   
  
begin
 --Determinamos los Importes de Descuentos
 
   --Imp SNP 
  select sum(c.imp_soles)
   into ln_imp_snp
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_snp and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_snp := nvl(ln_imp_snp,0);
   
  --Imp Aporte AFP 
  select sum(c.imp_soles)
   into ln_imp_aporte_afp
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_aporte_afp and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_aporte_afp := nvl(ln_imp_aporte_afp,0);
  
  --Imp Invalid AFP 
  select sum(c.imp_soles)
   into ln_imp_invalid_afp
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_invalid_afp and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_invalid_afp := nvl(ln_imp_invalid_afp,0);
  
  --Imp Comision AFP 
  select sum(c.imp_soles)
   into ln_imp_comis_afp
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_comision_afp and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_invalid_afp := nvl(ln_imp_invalid_afp,0);
  
  --Imp Judicial
  select sum(c.imp_soles)
   into ln_imp_judicial
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_judicial and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_judicial := nvl(ln_imp_judicial,0);
  
  --Imp Qta Categ 
  select sum(c.imp_soles)
   into ln_imp_qta_categ
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_qta_categ and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_qta_categ := nvl(ln_imp_qta_categ,0);
  
  --IMP Adel Gratif
  select sum(c.imp_soles)
   into ln_imp_adel_gratif
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_adel_gratif and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_adel_gratif := nvl(ln_imp_adel_gratif,0);

  --Imp Adel Con Mes 
  select sum(c.imp_soles)
   into ln_imp_adel_con_mes
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel =   lk_n_adel_con_mes and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_adel_con_mes := nvl(ln_imp_adel_con_mes,0);

  --Imp Otros Desctos 
  select sum(c.imp_soles)
   into ln_imp_otros_desc
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_otros_desc and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_otros_desc := nvl(ln_imp_otros_desc,0);
  
  --Imp perm Partic
  select sum(c.imp_soles)
   into ln_imp_perm_partic
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_perm_partic and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_perm_partic := nvl(ln_imp_perm_partic,0);
  
  --Imp Tardanzas 
  select sum(c.imp_soles)
   into ln_imp_tardanzas
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_tardanzas and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tardanzas := nvl(ln_imp_tardanzas,0);
  
  --Imp Comp Almace 
  select sum(c.imp_soles)
   into ln_imp_com_almace
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_comp_almace and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_com_almace := nvl(ln_imp_com_almace,0);
  
  --Imp Ssrv Telef
  select sum(c.imp_soles)
   into ln_imp_sev_telef
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_serv_telef and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sev_telef := nvl(ln_imp_sev_telef,0);
  
  --Imp Sindicato 
  select sum(c.imp_soles)
   into ln_imp_sindicato
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sindicato and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sindicato := nvl(ln_imp_sindicato,0);
  
  --Imp Jud Deveng
  select sum(c.imp_soles)
   into ln_imp_jud_deveng
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_jud_deveng and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_jud_deveng := nvl(ln_imp_jud_deveng,0);
  
  --Imp Prestamos  
  select sum(c.imp_soles)
   into ln_imp_prestamos
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_prestamos and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_prestamos := nvl(ln_imp_prestamos,0);
  
  --Imp Adel Liqui 
  select sum(c.imp_soles)
   into ln_imp_adel_liqui
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_adel_liqui and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_adel_liqui := nvl(ln_imp_adel_liqui,0);
  
  --Imp fact Hospital 
  select sum(c.imp_soles)
   into ln_imp_fact_hospit
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_fact_hospit and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_fact_hospit := nvl(ln_imp_fact_hospit,0);
  
  --Imp Terr Vivi 
  select sum(c.imp_soles)
   into ln_imp_terr_vivie
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_terr_vivie and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_terr_vivie := nvl(ln_imp_terr_vivie,0);
  
  --Imp Ute Fonavi
  select sum(c.imp_soles)
   into ln_imp_ute_fonavi
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_ute_fonavi and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_ute_fonavi := nvl(ln_imp_ute_fonavi,0);
  
  --Imp Redondeo Ant
  select sum(c.imp_soles)
   into ln_imp_redond_ant
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_redond_ant and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_redond_ant := nvl(ln_imp_redond_ant,0);
  
  --Imp Tot Descto 
  select sum(c.imp_soles)
   into ln_imp_tot_desc
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_tot_desc and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tot_desc := nvl(ln_imp_tot_desc,0);
  
  --Imp Tot Neto
  select sum(c.imp_soles)
   into ln_imp_tot_neto
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_tot_neto and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tot_neto := nvl(ln_imp_tot_neto,0);
  
  --Imp Redondeo 
  select sum(c.imp_soles)
   into ln_imp_redondeo
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_redondeo and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tot_neto := nvl(ln_imp_tot_neto,0);
  
  --Imp Campo77
  select sum(c.imp_soles)
   into ln_imp_campo77
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo77 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo77 := nvl(ln_imp_campo77,0);
  
  --Imp de Tot Pagado
  select sum(c.imp_soles)
   into ln_imp_tot_pagado
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_tot_pagado and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tot_pagado := nvl(ln_imp_tot_pagado,0);
  
  --Actualiza la Tabla tt_rpt_emis_plan
  update tt_rpt_emis_plan 
     set snp          = ln_imp_snp          , aporte_afp   = ln_imp_aporte_afp   ,
         invalid_afp  = ln_imp_invalid_afp  , comision_afp = ln_imp_comis_afp    ,
         judicial     = ln_imp_judicial     , qta_categ    = ln_imp_qta_categ    ,
         adel_gratif  = ln_imp_adel_gratif  , adel_con_mes = ln_imp_adel_con_mes ,
         otros_desc   = ln_imp_otros_desc   , perm_partic  = ln_imp_perm_partic  , 
         tardanzas    = ln_imp_tardanzas    , comp_almace  = ln_imp_com_almace   ,
         serv_telef   = ln_imp_sev_telef    , sindicato    = ln_imp_sindicato    ,
         jud_deveng   = ln_imp_jud_deveng   , prestamos    = ln_imp_prestamos    ,
         adel_liquid  = ln_imp_adel_liqui   , fact_hospit  = ln_imp_fact_hospit  , 
         terr_vivie   = ln_imp_terr_vivie   , ute_fonavi   = ln_imp_ute_fonavi   ,
         redondeo_ant = ln_imp_redond_ant   , tot_desc     = ln_imp_tot_desc     ,
         tot_neto     = ln_imp_tot_neto     , redondeo     = ln_imp_redondeo     ,
         campo77      = ln_imp_campo77      , tot_pagado   = ln_imp_tot_pagado  
  where cod_trabajador = as_codtra ;
  
  
  


  
end usp_rpt_emis_plan_descto;
/
