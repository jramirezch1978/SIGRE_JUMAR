create or replace procedure usp_pla_cal_pre_gan(
   as_codtra      in maestro.cod_trabajador%type, 
   as_codusr      in usuario.cod_usr%type,
   ad_fec_proceso in date
   ) is  
   
   --  Realiza busqueda para primer nivel
   cursor c_concep ( as_nivel in string ) is 
      select cod_concepto
       from rrhh_parm_detalle
      where cod_nivel = as_nivel;
   
   ln_dia_vac    historico_calculo.dias_trabaj%type;  --Historico de Calculo
   ln_dia_vac1   inasistencia.dias_inasist%type;      --Inasistencia

   --  lc_vacaciones gen_pla.concep%type; 
   --  ls_ganvarvac  gen_pla.concep%type;

   lk_nivel1      constant rrhh_parm_nivel.cod_nivel%type := '001';
   lk_nivel2      constant rrhh_parm_nivel.cod_nivel%type := '002';
   ld_ran_ini    date;
   ld_ran_fin    date;
   ln_num_reg    number(5);
   ln_imp_soles  historico_calculo.imp_soles%type ;
   ln_imp_dolar  historico_calculo.imp_dolar%type ;
   ln_num_mes    integer;
   ln_acu_soles  historico_calculo.imp_soles%type ;
   ln_acu_dolar  historico_calculo.imp_dolar%type ;
   ln_tot_soles  historico_calculo.imp_soles%type ;
   ln_tot_dolar  historico_calculo.imp_dolar%type ;
   ld_fec_ingreso maestro.fec_ingreso%type ;
   ls_nivel1_concepto rrhh_parm_nivel.cod_concepto%type ;
   ls_nivel2_concepto rrhh_parm_nivel.cod_concepto%type ;
   ls_cod_labor maestro.cod_labor%type ;
   ls_cencos maestro.cencos%type ;
   ls_mes_ingreso char(2);
   ls_mes_proceso char(2);
   ls_dia_ingreso char(2);
   ls_year char(4);
   
begin
     --  1416 - Promedio de ganancias variables para vacaciones
          
     --  Obtenemos el concepto para este nivel
     select rhpn.cod_concepto
     into ls_nivel1_concepto
     from rrhh_parm_nivel rhpn
     where rhpn.cod_nivel = lk_nivel1;

     --  Verifica el concepto del nivel1
     ls_nivel1_concepto := nvl(ls_nivel1_concepto, '0');
 
     --  Obtiene los conceptos para las vacaciones 
     select rhpn.cod_concepto
     into ls_nivel2_concepto
     from rrhh_parm_nivel rhpn
     where rhpn.cod_nivel = lk_nivel2;
     
     --  Verifica el concepto del nivel2
     ls_nivel2_concepto := nvl(ls_nivel2_concepto, '0');
          
     --  Obtiene la fecha de ingreso de un trabajador, etc.
     select m.fec_ingreso, m.cod_labor, m.cencos
     into ld_fec_ingreso, ls_cod_labor, ls_cencos
     from maestro m 
     where m.cod_trabajador = as_codtra;
     
     ls_cod_labor:=nvl(ls_cod_labor,'0');
     ls_cencos:=nvl(ls_cencos,'0');
     --  Mes de ingreso
     ls_mes_ingreso := to_char(ld_fec_ingreso,'MM');
     ls_dia_ingreso := to_char(ld_fec_ingreso,'DD');
     
     ls_mes_proceso :=to_char(ad_fec_proceso, 'MM') ;   
     ls_year :=to_char(ad_fec_proceso,'YYYY'); 
     --  Obtiene dias de vacaciones de la tabla Historico Calculo
     If to_number(ls_mes_ingreso) <= to_number(ls_mes_proceso) then
        ld_fec_ingreso :=to_date(ls_dia_ingreso||'/'||ls_mes_ingreso||'/'
                                  ||ls_year,'DD/MM/YYYY');
                         
        select sum(hc.dias_trabaj)
        into ln_dia_vac
        from historico_calculo hc
        where hc.cod_trabajador = as_codtra and 
              hc.concep=ls_nivel2_concepto and
              hc.fec_calc_plan between 
              ld_fec_ingreso and ad_fec_proceso;
    end if;
    
    If to_number(ls_mes_ingreso) > to_number(ls_mes_proceso) then
       ls_year:=to_char(to_number(ls_year)-1);
       ld_fec_ingreso :=to_date(ls_dia_ingreso||'/'||ls_mes_ingreso||'/'
                                ||ls_year,'DD/MM/YYYY');           
    
       select sum(hc.dias_trabaj)
       into ln_dia_vac
       from historico_calculo hc
       where hc.cod_trabajador = as_codtra and 
             hc.concep=ls_nivel2_concepto and
             hc.fec_calc_plan between
             ld_fec_ingreso and ad_fec_proceso;
    end if;
     
    --  Asegura valor para dias de vacaciones acumuladas (dia_vac)
     ln_dia_vac := nvl( ln_dia_vac, 0 );
     
     select sum(i.dias_inasist)
     into  ln_dia_vac1
     from inasistencia i
     where i.cod_trabajador = as_codtra and 
           i.concep = ls_nivel2_concepto and
           to_char(i.fec_movim, 'MM') = to_char(ad_fec_proceso,'MM');
     
     --  Asegurar valor para dias de vacaciones por inasistencias (dia_vac1)
     ln_dia_vac1 := nvl(ln_dia_vac1,0);
     
     --  Suma los dias de vacaciones
     ln_dia_vac := ln_dia_vac + ln_dia_vac1;
     
     --  Procesar si cumplio 30 dias exactos de vacaciones
     if ln_dia_vac = 30 Then 
        ln_tot_soles := 0 ;
        ln_tot_dolar := 0 ;
        For rc_concep in c_concep ( lk_nivel1 )
        Loop
            --  Ultimo dia del mes
            ld_ran_ini := add_months(ad_fec_proceso, - 1);
            ln_num_mes := 0 ;  --  Contador de meses a promediar
            ln_acu_soles := 0 ;
            ln_acu_dolar := 0 ;
            
            For x in reverse 1 .. 6 Loop
                ld_ran_fin := ld_ran_ini ;
                ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
                
                --  Determina si hay registros en ese mes
                Select count( hc.imp_soles )
                  into ln_num_reg
                  from historico_calculo hc 
                 where hc.concep = rc_concep.cod_concepto and 
                       hc.cod_trabajador = as_codtra and 
                       hc.fec_calc_plan between 
                       ld_ran_ini and ld_ran_fin;
                --  Determina importes del mes 
                ln_num_reg := nvl ( ln_num_reg , 0 ) ;
                if ln_num_reg > 0 then 
                   Select sum( hc.imp_soles), sum ( hc.imp_dolar )
                     into ln_imp_soles, ln_imp_dolar
                     from historico_calculo hc 
                    where hc.concep = rc_concep.cod_concepto and
                          hc.cod_trabajador = as_codtra and
                          hc.fec_calc_plan between 
                          ld_ran_ini and ld_ran_fin;
                end if;
                ln_imp_soles := nvl ( ln_imp_soles , 0 ) ;
                ln_imp_dolar := nvl ( ln_imp_dolar , 0 ) ;
                --  Acumula para promediar
                if ln_imp_soles > 0 or ln_imp_dolar>0 then 
                   ln_num_mes := ln_num_mes + 1;
                   ln_acu_soles := ln_acu_soles + ln_imp_soles;
                   ln_acu_dolar := ln_acu_dolar + ln_imp_soles;
                end if; 
                
                ld_ran_ini := ld_ran_ini - 1 ;
            End Loop ;
            --  Si puede promediarse, acumula el concepto
            If ln_num_mes > 2 Then  --  Minimo 3 meses
               ln_tot_soles := ln_tot_soles + (ln_acu_soles / 6 );
               ln_tot_dolar := ln_tot_dolar + (ln_acu_dolar / 6 );
            End If;
        
        End Loop;
        --  Insertar 1416 - Ganancias Variables Vacaciones -> GasVar
        Insert into gan_desct_variable 
               ( cod_trabajador, fec_movim  , concep, 
                 nro_doc       , imp_var    , cencos, 
                 cod_labor     , cod_usr    , proveedor,
                 tipo_doc ) 
        values ( as_codtra     , ad_fec_proceso, ls_nivel1_concepto,
                 'autom'       , ln_tot_soles  , ls_cencos       ,
                 ls_cod_labor  , ''            , ''              , 
                 'auto' );
        
     end if;
     
end usp_pla_cal_pre_gan;
/
