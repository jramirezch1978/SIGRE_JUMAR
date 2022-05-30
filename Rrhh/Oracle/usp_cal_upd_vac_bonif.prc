create or replace procedure usp_cal_upd_vac_bonif
  (as_codtra maestro.cod_trabajador%type) is
  
ln_dias         vacac_bonif_deveng.sldo_dias_vacacio%type;
ln_dias_vac     vacac_bonif_deveng.sldo_dias_vacacio%type;
ln_dias_act     vacac_bonif_deveng.sldo_dias_vacacio%type;
ln_dias_bonif   vacac_bonif_deveng.sldo_dias_bonif%type;
ln_count        number(4,2);
ld_fec_proceso  date ;
ls_origen       char(2) ;
    
--  Cursor del movimiento mensual de vacaciones y bonificaciones
Cursor c_vacbon is
  Select vb.per_vac_bonif, vb.flag_vac_bonif, 
         vb.fec_desde, vb.fec_hasta
    From  mov_mes_vacac_bonif vb
    Where vb.cod_trabajador = as_codtra and
          to_char(vb.fec_hasta,'mm/yyyy') = to_char(ld_fec_proceso,'mm/yyyy') ;
  
BEGIN 

select p.cod_origen
  into ls_origen
  from genparam p
  where p.reckey = '1' ;
  
select p.fec_proceso
  into ld_fec_proceso
  from rrhh_param_org p
  where p.origen = ls_origen ;
  

--select p.fec_proceso
--  into ld_fec_proceso
--  from rrhhparam p
--  where p.reckey = '1' ;
  
For rc_vb in c_vacbon Loop

  --  Calcula numero de dias
  ln_dias := TO_DATE(rc_vb.fec_hasta) - TO_DATE(rc_vb.fec_desde) + 1 ;
  Select count(*)
    into ln_count 
    from vacac_bonif_deveng bd
    where bd.cod_trabajador = as_codtra and
          bd.periodo = rc_vb.per_vac_bonif ;
           
  --  1 = Vacaciones y 2 = Bonificaciones
  IF ln_count = 0 then

    IF  rc_vb.flag_vac_bonif = '1' then
      INSERT INTO vacac_bonif_deveng 
        ( cod_trabajador, periodo, flag_estado,
          sldo_dias_vacacio, sldo_dias_bonif )
      VALUES 
        ( as_codtra, rc_vb.per_vac_bonif, '1',
          ln_dias, 0 );
      COMMIT; 
    END IF;
    IF rc_vb.flag_vac_bonif = '2' THEN
      INSERT INTO vacac_bonif_deveng 
        ( cod_trabajador, periodo, flag_estado,
          sldo_dias_vacacio, sldo_dias_bonif )
      VALUES 
        ( as_codtra, rc_vb.per_vac_bonif, '1',
          0, ln_dias );                
      COMMIT;
    END IF;

  END IF;
     
  IF ln_count <> 0 THEN
     
    Select bd.sldo_dias_vacacio, bd.sldo_dias_bonif
      into ln_dias_vac, ln_dias_bonif  
      from vacac_bonif_deveng bd
      where bd.cod_trabajador = as_codtra and
            bd.periodo = rc_vb.per_vac_bonif ; 
             
    ln_dias_vac := nvl(ln_dias_vac, 0);      
    ln_dias_bonif := nvl(ln_dias_bonif, 0);      
       
    IF  rc_vb.flag_vac_bonif = '1' then
      ln_dias_act := ln_dias_vac - ln_dias ;
      IF ln_dias_act <= 0 THEN
        ln_dias_act := 0;
      END IF  ;  
      UPDATE vacac_bonif_deveng  
        SET sldo_dias_vacacio = ln_dias_act 
        WHERE cod_trabajador =  as_codtra  and 
             periodo =  rc_vb.per_vac_bonif ;
    END IF;
    IF rc_vb.flag_vac_bonif = '2' then
      ln_dias_act := ln_dias_bonif - ln_dias ;
      IF ln_dias_act <= 0 THEN
        ln_dias_act := 0;
      END IF    ;
      UPDATE vacac_bonif_deveng  
         SET sldo_dias_bonif = ln_dias_act 
         WHERE cod_trabajador =  as_codtra  and 
             periodo =  rc_vb.per_vac_bonif ;
    END IF;

  END IF;

END LOOP;

END usp_cal_upd_vac_bonif;
/
