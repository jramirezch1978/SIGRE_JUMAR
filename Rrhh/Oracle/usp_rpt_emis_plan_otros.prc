create or replace procedure usp_rpt_emis_plan_otros
 ( as_codtra in maestro.cod_trabajador%type
  ) is

lk_n_dias_trabaj constant char(3):='591';     
lk_n_horas_trabaj constant char(3):='592';  lk_n_horas_extras constant char(3):='593';    
lk_n_campo95 constant char(3):='594';       lk_n_campo96 constant char(3):='595';    
lk_n_campo97 constant char(3):='596';       lk_n_campo98 constant char(3):='597';    
lk_n_campo99 constant char(3):='598';       lk_n_campo100 constant char(3):='599';    
lk_n_campo101 constant char(3):='600';      lk_n_campo102 constant char(3):='601';    
lk_n_campo103 constant char(3):='602';      lk_n_campo104 constant char(3):='603';    

--Otros NIveles de los OBREROS para el calculo
lk_n_pago_destaj constant char(3):='604';    lk_n_reint_sobret constant char(3):='605';    
lk_n_doble_guard  constant char(3):='606';   lk_n_rac_cocida constant char(3):='607';    
lk_n_trab_espec constant char(3):='608';     lk_n_rein_tarea constant char(3):='609';    
lk_n_riesgo constant char(3):='610';         lk_n_toxico constant char(3):='611';    
lk_n_turnos constant char(3):='612';          lk_n_obr_campo42 constant char(3):='613'; 

--Importe de la variables de otros pagos 
ln_dias_trabaj number(13,2);  ln_horas_trabaj number(13,2);
ln_horas_extras number(13,2); ln_imp_campo95  number(13,2);
ln_imp_campo96 number(13,2);  ln_imp_campo97  number(13,2);
ln_imp_campo98 number(13,2);  ln_imp_campo99  number(13,2);
ln_imp_campo100 number(13,2); ln_imp_campo101 number(13,2);
ln_imp_campo102 number(13,2); ln_imp_campo103 number(13,2);
ln_imp_campo104 number(13,2); ln_imp_pago_destj number(13,2);
ln_imp_rein_sobr number(13,2);  ln_imp_doble_guard number(13,2);
ln_imp_rac_cocida number(13,2); ln_imp_trab_espec number(13,2);
ln_imp_rein_tare number(13,2); ln_imp_riesgo number(13,2);
ln_imp_toxico number(13,2);    ln_imp_turnos number(13,2);
ln_imp_obr_campo42 number(13,2);



begin

 --Dias Trabaj
  select sum(c.imp_soles)
   into ln_dias_trabaj
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_dias_trabaj and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_dias_trabaj := nvl(ln_dias_trabaj,0);

  --Horas Trabajadas
  select sum(c.imp_soles)
   into ln_horas_trabaj
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_horas_trabaj and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_horas_trabaj := nvl(ln_horas_trabaj,0);
  
  --Horas Extras 
  select sum(c.imp_soles)
   into ln_horas_extras
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_horas_extras and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_horas_extras := nvl(ln_horas_extras,0);
  
  --Imp campo95
  select sum(c.imp_soles)
   into ln_imp_campo95
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo95 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo95 := nvl(ln_imp_campo95,0);
  
  --Imp campo96
  select sum(c.imp_soles)
   into ln_imp_campo96
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo96 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo96 := nvl(ln_imp_campo96,0);
    
  --Imp campo97
  select sum(c.imp_soles)
   into ln_imp_campo97
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo97 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo97 := nvl(ln_imp_campo97,0);
  
  --Imp campo98
  select sum(c.imp_soles)
   into ln_imp_campo98
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo98 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo98 := nvl(ln_imp_campo98,0);
  
  --Imp campo99
  select sum(c.imp_soles)
   into ln_imp_campo99
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo99 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo99 := nvl(ln_imp_campo99,0);
  
  --Imp Campo100
  select sum(c.imp_soles)
   into ln_imp_campo100
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo100 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo100 := nvl(ln_imp_campo100,0);
  
  --Imp campo101
  select sum(c.imp_soles)
   into ln_imp_campo101
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo101 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo101 := nvl(ln_imp_campo101,0);
   
  --Imp campo102
  select sum(c.imp_soles)
   into ln_imp_campo102
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo102 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo102 := nvl(ln_imp_campo102,0);
  
  --Imp campo103
  select sum(c.imp_soles)
   into ln_imp_campo103
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo103 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo103 := nvl(ln_imp_campo103,0);
  
  --Imp Campo104
  select sum(c.imp_soles)
   into ln_imp_campo104
   from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
  where c.cod_trabajador = as_codtra and 
        rhn.cod_nivel = lk_n_campo104 and 
        rhn.cod_nivel = rhd.cod_nivel and 
        rhd.concep = c.concep;
  ln_imp_campo104 := nvl(ln_imp_campo104,0);
  
  --****************************************
  --IMPORTES DE LOS OBREROS 
  --****************************************
    --Imp de Pago Destajo
    select sum(c.imp_soles)
     into ln_imp_pago_destj
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_pago_destaj and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_pago_destj := nvl(ln_imp_pago_destj,0);
  
    --Imp de Rein Sobret 
    select sum(c.imp_soles)
     into ln_imp_rein_sobr
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_reint_sobret and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_rein_sobr := nvl(ln_imp_rein_sobr,0);
  
    --Imp Doble Guardia 
    select sum(c.imp_soles)
     into ln_imp_doble_guard
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_doble_guard and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_doble_guard := nvl(ln_imp_doble_guard,0);
  
    --Imp Rac Cocida 
    select sum(c.imp_soles)
     into ln_imp_rac_cocida
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_rac_cocida and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_rac_cocida := nvl(ln_imp_rac_cocida,0);
    
    --Imp Trab Especial
    select sum(c.imp_soles)
     into ln_imp_trab_espec
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_trab_espec and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_trab_espec := nvl(ln_imp_trab_espec,0);

    --Imp Rein Tareas
    select sum(c.imp_soles)
     into ln_imp_rein_tare
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_rein_tarea and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_rein_tare := nvl(ln_imp_rein_tare,0);
    
    --Imp Riesgo
    select sum(c.imp_soles)
     into ln_imp_riesgo
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_riesgo and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_riesgo := nvl(ln_imp_riesgo,0);
    
    --Imp Toxico 
    select sum(c.imp_soles)
     into ln_imp_toxico
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_toxico and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_toxico := nvl(ln_imp_toxico,0);
    
    --Imp Turnos 
    select sum(c.imp_soles)
     into ln_imp_turnos
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_turnos and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_turnos := nvl(ln_imp_turnos,0);

    --Imp Obr campo42
    select sum(c.imp_soles)
     into ln_imp_obr_campo42
     from calculo c, rrhh_nivel rhn, rrhh_nivel_detalle rhd   
    where c.cod_trabajador = as_codtra and 
          rhn.cod_nivel = lk_n_obr_campo42 and 
          rhn.cod_nivel = rhd.cod_nivel and 
          rhd.concep = c.concep;
    ln_imp_obr_campo42 := nvl(ln_imp_obr_campo42,0);
  --****************************************
  --FIN de LOS IMPORTES DE OBREROS 
  --****************************************

  --Actualiz de la Tabla tt_rpt_emis_plan
  update tt_rpt_emis_plan
     set dias_trabaj    = ln_dias_trabaj   , horas_trabaj   = ln_horas_trabaj   ,
         horas_extras   = ln_horas_extras  , campo95        = ln_imp_campo95    ,
         campo96        = ln_imp_campo96   , campo97        = ln_imp_campo97    ,
         campo98        = ln_imp_campo98   , campo99        = ln_imp_campo99    ,
         campo100       = ln_imp_campo100  , campo101       = ln_imp_campo101   ,
         campo102       = ln_imp_campo102  , campo103       = ln_imp_campo103   ,
         campo104       = ln_imp_campo104  , obr_pag_destaj = ln_imp_pago_destj ,
         obr_reint_sobr = ln_imp_rein_sobr , obr_dobl_guard = ln_imp_doble_guard,
         obr_rac_cocida = ln_imp_rac_cocida, obr_trab_espec = ln_imp_trab_espec ,
         obr_rein_tarea = ln_imp_rein_tare , obr_riesgo     = ln_imp_riesgo     ,
         obr_toxico     = ln_imp_toxico    , obr_turnos     = ln_imp_turnos     ,
         obr_campo42    = ln_imp_obr_campo42
  where cod_trabajador = as_codtra; 
  
end usp_rpt_emis_plan_otros;
/
