create or replace procedure usp_rpt_emis_plan_aporte
 ( as_codtra in maestro.cod_trabajador%type
  ) is
 
lk_n_ipss constant char(3):='578';          lk_n_ies constant char(3):='579';   
lk_n_senati constant char(3):='580';        lk_n_sctr_ipss constant char(3):='581';   
lk_n_sctr_onp constant char(3):='582';      lk_n_campo84 constant char(3):='583';   
lk_n_campo85 constant char(3):='584';       lk_n_campo86 constant char(3):='585';    
lk_n_campo87 constant char(3):='586';       lk_n_campo88 constant char(3):='587';   
lk_n_campo89 constant char(3):='588';       lk_n_campo90 constant char(3):='589';    
lk_n_tot_patronal constant char(3):='590'; 
 
--Variables de los Importes Aportes 
ln_imp_ipss   number(13,2)   ; ln_imp_ies number(13,2) ;
ln_imp_senati number(13,2)   ; ln_imp_sctr_ipss number(13,2);
ln_imp_sctr_onp number(13,2) ; ln_imp_campo84 number(13,2);
ln_imp_campo85 number(13,2)  ; ln_imp_campo86 number(13,2);
ln_imp_campo87 number(13,2)  ; ln_imp_campo88 number(13,2);
ln_imp_campo89 number(13,2)  ; ln_imp_campo90 number(13,2);
ln_imp_tot_patronal number(13,2);
begin

  --Imp IPSS
  select sum(c.imp_soles)
   into ln_imp_ipss
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_ipss and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_ipss := nvl(ln_imp_ipss,0);

  --Imp IES 
  select sum(c.imp_soles)
   into ln_imp_ies
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_ies and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_ies := nvl(ln_imp_ies,0);
  
  --Imp SENATI
  select sum(c.imp_soles)
   into ln_imp_senati
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_senati and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_senati := nvl(ln_imp_senati,0);
 
  --Imp SCTR IPSS
  select sum(c.imp_soles)
   into ln_imp_sctr_ipss
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sctr_ipss and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sctr_ipss := nvl(ln_imp_sctr_ipss,0);
  
  --Imp SCTR ONP
  select sum(c.imp_soles)
   into ln_imp_sctr_onp
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_sctr_onp and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_sctr_onp := nvl(ln_imp_sctr_onp,0);
  
  --Imp campo84
  select sum(c.imp_soles)
   into ln_imp_campo84
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo84 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo84 := nvl(ln_imp_campo84,0);
    
  --Imp campo85
  select sum(c.imp_soles)
   into ln_imp_campo85
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo85 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo85 := nvl(ln_imp_campo85,0);

    --Imp campo86
  select sum(c.imp_soles)
   into ln_imp_campo86
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo86 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo86 := nvl(ln_imp_campo86,0);

  --Imp campo87
  select sum(c.imp_soles)
   into ln_imp_campo87
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo87 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo87 := nvl(ln_imp_campo87,0);
  
  --Imp campo88
  select sum(c.imp_soles)
   into ln_imp_campo88
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo88 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo88 := nvl(ln_imp_campo88,0);
  
  --Imp campo89
  select sum(c.imp_soles)
   into ln_imp_campo89
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo89 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo89 := nvl(ln_imp_campo89,0);
  
  --Imp campo90
  select sum(c.imp_soles)
   into ln_imp_campo90
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo90 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo90 := nvl(ln_imp_campo90,0);
 
  --Imp Tot Patronal
  select sum(c.imp_soles)
   into ln_imp_tot_patronal
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_tot_patronal and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_tot_patronal := nvl(ln_imp_tot_patronal,0);
  
  --Actualizacion de datos en tt_rpt_emis_plan
  update tt_rpt_emis_plan
     set ipss     = ln_imp_ipss     , ies       = ln_imp_ies       ,
         senati   = ln_imp_senati   , sctr_ipss = ln_imp_sctr_ipss , 
         sctr_onp = ln_imp_sctr_onp , campo84   = ln_imp_campo84   ,
         campo85  = ln_imp_campo85  , campo86   = ln_imp_campo86   ,
         campo87  = ln_imp_campo87  , campo88   = ln_imp_campo88   ,
         campo89  = ln_imp_campo89  , campo90   = ln_imp_campo90   ,
         tot_patronal = ln_imp_tot_patronal
  where cod_trabajador = as_codtra ;
  
end usp_rpt_emis_plan_aporte;
/
