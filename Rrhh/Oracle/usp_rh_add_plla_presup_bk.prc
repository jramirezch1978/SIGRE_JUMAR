create or replace procedure usp_rh_add_plla_presup_bk(
          asi_origen          in origen.cod_origen%type ,
          asi_tipo_trabajador in tipo_trabajador.tipo_trabajador%type ,
          adi_fec_proceso     in date                   ,
          asi_usuario         in usuario.cod_usr%type                  ,
          asi_flag_presup     in varchar2
) is


--variables
ls_concepto_ing    concepto.concep%type      ;
ls_concepto_des    concepto.concep%type      ;
ls_concepto_pag    concepto.concep%type      ;
ls_concepto_apo    concepto.concep%type      ;
ln_ano             presupuesto_ejec.ano%type ;
ln_mes             number(2)                 ;
ls_tipo_doc        doc_tipo.tipo_doc%type    ;
ls_tdoc_old        doc_tipo.tipo_doc%type    ;
ln_importe         calculo.imp_dolar%type    ;
ls_cnta_prsp       presupuesto_cuenta.cnta_prsp%type   ;
ls_cnta_prsp_dist  presupuesto_cuenta.cnta_prsp%type   ;
ls_cencos          centros_costo.cencos%type           ;
ls_centro_benef    centro_beneficio.centro_benef%TYPE;
ld_fecha           date                                ;
ls_flag_control    presupuesto_partida.flag_ctrl%type  ;
ln_imp_control     number(13,2)                        ;
ln_imp_diferencia  number(13,2)                        ;
ln_nro_var         num_presup_variacion.ult_nro%type   ;
ls_nro_var         presup_variacion.nro_variacion%type ;
ls_desc_prsp_ejec  presupuesto_ejec.descripcion%TYPE;


ls_desc_variacion  constant varchar2(100) := 'AMPLIACION AUTOMATICA DE LA PLANILLA' ;
ln_count           number                                  ;
ln_count_gc        number                                  ;
ln_count_val       number                                  ;
ls_ganancias_fijas rrhhparam_cconcep.concep_gan_fij%type   ;
ls_concep_def      rrhhparam_cconcep.afect_ccosto_def%type ;
ls_g_dsc_ley       concepto.grupo_calc%type                ;
ls_g_dsc_fijo      concepto.grupo_calc%type                ;
ls_g_dsc_var       concepto.grupo_calc%type                ;
ls_g_dsc_jdc       concepto.grupo_calc%type                ;
ls_g_dsc_dias      concepto.grupo_calc%type                ;
ln_horas_x_pdiario   distribucion_cntble.nro_horas%type ;
ln_importe_x_porc    presupuesto_ejec.importe%TYPE ;
ln_tot_importe       presupuesto_ejec.importe%TYPE;
ls_ctrl_ampl         Char(1)       ;
ln_item              presupuesto_ejec.item_ref%TYPE;

ls_grp_concep_distrib      grupo_calculo.grupo_calculo%TYPE  := '804';  -- Este valor es manejado por sistemas 
ls_cnc_utilidades          concepto.concep%TYPE              := '1428'; -- Concepto de utilidades


--  Cursor del movimiento de la planilla mensual
cursor c_calculo is
  select cal.cod_trabajador, cal.concep, cal.imp_dolar,m.cencos,m.tipo_trabajador,tt.flag_tabla_origen, m.centro_benef
    from calculo             cal, 
         maestro             m,
         tipo_trabajador     tt,
         concepto            c
   where cal.cod_trabajador = m.cod_trabajador   
     and m.tipo_trabajador  = tt.tipo_trabajador 
     and cal.concep         = c.concep           
     and m.cod_origen       = asi_origen          
     and cal.fec_proceso    = adi_fec_proceso     
     and m.tipo_trabajador  = asi_tipo_trabajador 
     and m.cencos           is not null          
     and cal.concep         not in (ls_concepto_ing,ls_concepto_des,ls_concepto_pag,ls_concepto_apo)
     and c.grupo_calc       not in (ls_g_dsc_ley   ,ls_g_dsc_fijo ,ls_g_dsc_var,ls_g_dsc_jdc,ls_g_dsc_dias)
  order by cal.cod_trabajador, cal.concep ;

cursor c_historico is
  select hc.cod_trabajador, hc.concep, hc.imp_dolar,hc.cencos ,m.tipo_trabajador,tt.flag_tabla_origen, hc.centro_benef
    from historico_calculo hc, 
         maestro           m,
         tipo_trabajador   tt,
         concepto          c
   where hc.cod_trabajador = m.cod_trabajador   
     and m.tipo_trabajador = tt.tipo_trabajador 
     and hc.concep         = c.concep           
     and m.cod_origen      = asi_origen          
     and hc.fec_calc_plan  = adi_fec_proceso     
     and m.tipo_trabajador = asi_tipo_trabajador 
     and hc.cencos         is not null          
     and hc.concep         not in (ls_concepto_ing,ls_concepto_des,ls_concepto_pag,ls_concepto_apo)
     and c.grupo_calc      not in (ls_g_dsc_ley   ,ls_g_dsc_fijo ,ls_g_dsc_var,ls_g_dsc_jdc,ls_g_dsc_dias) 
   order by hc.cod_trabajador, hc.concep ;

--  Cursor de gastos por centros de costos y cuenta presupuestal
cursor c_gastos is
  select gm.ano, gm.cencos, gm.cnta_prsp, gm.fecha, gm.importe,gm.cod_trabajador, gm.centro_benef
    from tt_presupuesto_gasto_mes gm
  order by gm.cencos, gm.cnta_prsp, gm.centro_benef ;

-- Cursor de afectacion presupuetal
cursor c_gastos_afect is
  select gm.ano, gm.cencos, gm.cnta_prsp, gm.fecha, gm.cod_trabajador,
         m.apel_paterno || ' ' || m.apel_materno || ', ' || m.nombre1 as nom_trabajador,
         m.tipo_trabajador, 
         pc.descripcion as desc_cnta_prsp,
         gm.centro_benef,
         sum(gm.importe) as importe
    from tt_presupuesto_gasto_mes gm,
         maestro                  m,
         presupuesto_cuenta       pc
   where gm.cod_trabajador = m.cod_trabajador
     and gm.cnta_prsp      = pc.cnta_prsp
group by gm.ano, gm.cencos, gm.cnta_prsp, gm.fecha, gm.cod_trabajador,
         m.apel_paterno || ' ' || m.apel_materno || ', ' || m.nombre1,
         m.tipo_trabajador, 
         pc.descripcion,
         gm.centro_benef     
  order by gm.cencos, gm.cnta_prsp ;

--Distribucion Contable
cursor c_distribucion (as_cod_trabajador maestro.cod_trabajador%type) is
  select nvl(dc.nro_horas,0) as nro_horas, l.cnta_prsp, dc.cencos, dc.cod_labor, dc.centro_benef
    from distribucion_cntble dc ,
         labor               l
   where dc.cod_labor          = l.cod_labor       
     and dc.cod_trabajador     = as_cod_trabajador 
     and trunc(dc.fec_calculo) = adi_fec_proceso    
     and asi_flag_presup       = '1';

--Distribucion Contable Historica
cursor c_dist_hist (as_cod_trabajador maestro.cod_trabajador%type) is
  select nvl(dc.nro_horas,0) as nro_horas,l.cnta_prsp,dc.cencos,dc.cod_labor, dc.centro_benef  
    from historico_distrib_cntble dc ,
         labor                    l
   where dc.cod_labor           = l.cod_labor        
     and dc.cod_trabajador      = as_cod_trabajador  
     and trunc(dc.fec_calculo)  = adi_fec_proceso 
     and asi_flag_presup        = '1';


rc_gastos       c_gastos%rowtype ;

begin

--  *******************************************************************
--  ***   ADICIONA GASTOS MENSUALES DE LA PLANILLA AL PRESUPUESTO   ***
--  *******************************************************************
select p.cnc_total_ing, p.cnc_total_dsct, p.cnc_total_pgd, p.cnc_total_aport,p.doc_presup_plan,
       p.grc_dsc_ley  ,p.grc_dsc_fijo,p.grc_dsc_var,p.grc_dsc_jdc,p.grc_dsc_dias ,p.flag_genera_ampliacion
  into ls_concepto_ing, ls_concepto_des, ls_concepto_pag, ls_concepto_apo,ls_tdoc_old,
       ls_g_dsc_ley   ,ls_g_dsc_fijo ,ls_g_dsc_var,ls_g_dsc_jdc,ls_g_dsc_dias,ls_ctrl_ampl
  from rrhhparam p 
 where p.reckey = '1'  ;

select rc.afect_ccosto_def , rc.concep_gan_fij
  into ls_concep_def, ls_ganancias_fijas
  from rrhhparam_cconcep rc 
 where reckey = '1' ;
 
--recuperar documento por tipo trabajador
select tt.doc_afec_presup 
  into ls_tipo_doc 
  from tipo_trabajador tt 
 where tt.tipo_trabajador = asi_tipo_trabajador ;

if ls_tipo_doc is null then
   Raise_Application_Error(-20000,'Debe Definir Un tipo de Documento ' ||
                                  'para el Tipo de Trabajador: ' || asi_tipo_trabajador || 
                                  ' para realizar Afectacion Presupuestal, por favor coordinar con RRHH') ;
end if ;



ln_ano := to_number(to_char(adi_fec_proceso,'yyyy')) ;
ln_mes := to_number(to_char(adi_fec_proceso,'mm')) ;

----------------------------------------------------------------------

----------------------------------------------------------------------

--  Elimina movimiento mensual del presupuesto por fecha de proceso y tipo de trabajador y origen
delete presupuesto_ejec pe 
 where trunc(pe.fecha) = trunc(adi_fec_proceso)  
   and pe.tipo_doc_ref = ls_tipo_doc            
   and pe.cod_origen   = asi_origen;

delete from tt_presupuesto_gasto_mes ;

select count(*) 
  into ln_count
  from calculo cal, 
       maestro m
 where cal.cod_trabajador = m.cod_trabajador   
   and m.cod_origen       = asi_origen          
   and cal.fec_proceso    = adi_fec_proceso     
   and m.tipo_trabajador  = asi_tipo_trabajador ;

if ln_count = 0 then
   select count(*) 
     into ln_count
     from historico_calculo hc, 
          maestro           m
    where hc.cod_trabajador  = m.cod_trabajador   
      and m.cod_origen       = asi_origen          
      and hc.fec_calc_plan   = adi_fec_proceso     
      and m.tipo_trabajador  = asi_tipo_trabajador ;
   
   if ln_count = 0 then
      RAISE_APPLICATION_ERROR(-20000, 'No existen cálculos de planilla para el periodo indicado'
                        || chr(13) || 'Origen: ' || asi_origen
                        || chr(13) || 'Tipo Trabajador: ' || asi_tipo_trabajador
                        || chr(13) || 'Fec Proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
   end if;
end if;


 --  Adiciona gastos del mes de proceso
 for rc_cal in c_calculo loop
     ln_importe  := nvl(rc_cal.imp_dolar,0) * -1 ;

     if rc_cal.cencos is null then
        --'Llenar Tabla temporal con problema de cento de costo'
        Insert Into tt_rh_valid_presup (cod_trabajador,observaciones)
        Values (rc_cal.cod_trabajador,'Trabajador no tiene Centro de Costo Asignado Verificar!') ;
        return ;
     end if ;

     select count(*) 
       into ln_count 
       from concepto_tip_trab_cnta c
      where c.concep          = rc_cal.concep          
        and c.tipo_trabajador = rc_cal.tipo_trabajador;

     if ln_count > 0 then --buscar si tiene cuenta presupuestal
        select c.cnta_prsp
          into ls_cnta_prsp 
          from concepto_tip_trab_cnta c
         where c.concep          = rc_cal.concep 
           and c.tipo_trabajador = rc_cal.tipo_trabajador;

        if ls_cnta_prsp is not null and ln_importe <> 0 then --afecta apresupuesto
            --realizar distribucion por centro de costo
            select Count(*) 
              into ln_count 
              from distribucion_cntble dc
             where dc.cod_trabajador     = rc_cal.cod_trabajador and
                   trunc(dc.fec_calculo) = adi_fec_proceso;

            select Count(*) 
              into ln_count_gc
              from grupo_calculo_det gcd
             where gcd.grupo_calculo = ls_concep_def 
               and gcd.concepto_calc = rc_cal.concep;
               
            --que concepto no sea de vacaciones o feriados para aplicar distribucion contable
            if ln_count > 0 and ln_count_gc = 0 and asi_flag_presup = '1' then --realiza distribucion si existe informacion y concepto de calculo no sea de vacaciones o feriados
                                 --
               --INICIALIZACION DE VARIABLES
               ln_tot_importe := 0.00;

               --total de horas por DISTRIBUCION
               select Sum(dc.nro_horas) 
                 into ln_horas_x_pdiario 
                 from distribucion_cntble dc
                where dc.cod_trabajador = rc_cal.cod_trabajador 
                  and trunc(dc.fec_calculo) = adi_fec_proceso
               group by dc.cod_trabajador ;

               --inicializa variables
               for rc_distrib in c_distribucion (rc_cal.cod_trabajador) loop
                   ln_importe_x_porc := round( ln_importe * rc_distrib.nro_horas / ln_horas_x_pdiario, 2);

                   --colocar cuenta presupuestal
                   select Count (*) 
                     into ln_count 
                     from grupo_calculo_det gcd
                    where gcd.grupo_calculo = ls_grp_concep_distrib  
                      AND gcd.concepto_calc = rc_cal.concep;

                   if ln_count > 0 then --asigana nueva cuenta presupuestal
                      ls_cnta_prsp_dist := rc_distrib.cnta_prsp ;
                   else
                      ls_cnta_prsp_dist := ls_cnta_prsp         ;
                   end if ;
                   
                   if Abs(ln_tot_importe) + Abs(ln_importe_x_porc) > Abs(ln_importe) then
                      ln_importe_x_porc := (Abs(ln_importe) - Abs(ln_tot_importe)) * -1;
                   end if;
                   
                   --insert presupuesto
                   insert into tt_presupuesto_gasto_mes (
                           ano, cencos, cnta_prsp, fecha, importe ,cod_trabajador, centro_benef )
                   values (
                          ln_ano, rc_distrib.cencos, ls_cnta_prsp_dist, adi_fec_proceso, 
                          ln_importe_x_porc , rc_cal.cod_trabajador, rc_distrib.centro_benef) ;

                   --totaliza porcentajes
                   ln_tot_importe := Abs(ln_tot_importe) + Abs(ln_importe_x_porc) ;
                   ls_cencos := rc_distrib.cencos;

                end loop ;

                if Abs(ln_tot_importe) <> Abs(ln_importe) then 
                   ln_importe_x_porc := Abs(ln_importe) - Abs(ln_tot_importe);

                   --presupuesto de centro de costo por defecto
                   insert into tt_presupuesto_gasto_mes (
                          ano, cencos, cnta_prsp, fecha, importe ,cod_trabajador, centro_benef )
                   values (
                          ln_ano, ls_cencos, ls_cnta_prsp, adi_fec_proceso, Abs(ln_importe_x_porc) * -1,
                          rc_cal.cod_trabajador, rc_cal.centro_benef) ;
                    
                end if;
                
                ls_cencos := NULL;


            else
               insert into tt_presupuesto_gasto_mes (
                      ano, cencos, cnta_prsp, fecha, importe ,cod_trabajador, centro_benef )
               values (
                      ln_ano, rc_cal.cencos, ls_cnta_prsp, adi_fec_proceso, 
                      Abs(ln_importe) * -1 ,rc_cal.cod_trabajador, rc_cal.centro_benef) ;
            end if ;

        else --tipo de concepto y tipo de trabajador no existe verifique
           select count(*) 
             into ln_count 
             from tt_rh_valid_presup
            where concepto         = rc_cal.concep         
              and tipo_trabajador  = rc_cal.tipo_trabajador
              and cencos           = rc_cal.cencos;

           if ln_count_val = 0 and ln_importe <> 0 then --inserta registro
              Insert Into tt_rh_valid_presup (
                     concepto,tipo_trabajador,cencos,observaciones)
              Values (
                     rc_cal.concep,rc_cal.tipo_trabajador,rc_cal.cencos,
                     'Tipo de Trabajador y Concepto no tiene Cuenta Presupuestal') ;
           end if ;

        end if ;
     end if ;
end loop ;

-- Adiciona gastos de meses anteriores del historico de calculo
for rc_hc in c_historico loop
    ln_importe  := nvl(rc_hc.imp_dolar,0) * -1 ;

    if rc_hc.cencos is null then
       --'Llenar Tabla temporal con problema de cento de costo'
       Insert Into tt_rh_valid_presup (
               cod_trabajador,observaciones)
       Values (
               rc_hc.cod_trabajador,'Trabajador no tiene Centro de Costo Asignado Verificar!') ;
       return ;
    end if ;

     select count(*) 
       into ln_count 
       from concepto_tip_trab_cnta c
      where c.concep          = rc_hc.concep          
        and c.tipo_trabajador = rc_hc.tipo_trabajador;

     if ln_count > 0 then --buscar si tiene cuenta presupuestal
        select c.cnta_prsp
          into ls_cnta_prsp 
          from concepto_tip_trab_cnta c
         where c.concep = rc_hc.concep 
           and c.tipo_trabajador = rc_hc.tipo_trabajador;

        if ls_cnta_prsp is not null and ln_importe <> 0 then --afecta apresupuesto
           --realizar distribucion por centro de costo
           select Count(*) 
             into ln_count 
             from historico_distrib_cntble dc
            where dc.cod_trabajador = rc_hc.cod_trabajador 
              and trunc(dc.fec_calculo) = adi_fec_proceso;

           select Count(*) 
             into ln_count_gc
             from grupo_calculo_det gcd
            where gcd.grupo_calculo = ls_concep_def
              and gcd.concepto_calc = rc_hc.concep;


           if ln_count > 0 and ln_count_gc = 0 and asi_flag_presup = '1' then --realiza distribucion
              --total de horas por parte diario
              select Sum(dc.nro_horas) 
                into ln_horas_x_pdiario 
                from historico_distrib_cntble dc
               where dc.cod_trabajador     = rc_hc.cod_trabajador
                 and trunc(dc.fec_calculo) = adi_fec_proceso  
               group by dc.cod_trabajador ;
               
              --inicializa variables
              ln_tot_importe := 0;

              for rc_hdistrib in c_dist_hist (rc_hc.cod_trabajador) loop
                  ln_importe_x_porc := round(  ln_importe * rc_hdistrib.nro_horas / ln_horas_x_pdiario  ,2);

                  --colocar cuenta presupuestal
                  select Count (*) 
                    into ln_count 
                    from grupo_calculo_det gcd
                   where gcd.grupo_calculo = ls_grp_concep_distrib         
                     AND gcd.concepto_calc = rc_hc.concep ;

                  if ln_count > 0 then --asigana nueva cuenta presupuestal
                     ls_cnta_prsp_dist := rc_hdistrib.cnta_prsp ;
                  else
                     ls_cnta_prsp_dist := ls_cnta_prsp         ;
                  end if ;
                  
                  if abs(ln_tot_importe) + abs(ln_importe_x_porc) > abs(ln_importe) then
                     ln_importe_x_porc := (abs(ln_importe) - abs(ln_tot_importe)) * -1;
                  end if;

                  --insert presupuesto
                  insert into tt_presupuesto_gasto_mes (
                         ano, cencos, cnta_prsp, fecha, importe ,cod_trabajador, centro_benef )
                  values (
                         ln_ano, rc_hdistrib.cencos, ls_cnta_prsp_dist, 
                         adi_fec_proceso, abs(ln_importe_x_porc) * -1 ,rc_hc.cod_trabajador, 
                         rc_hdistrib.centro_benef) ;

                  --totaliza porcentajes
                  ln_tot_importe := abs(ln_tot_importe) + abs(ln_importe_x_porc) ;
                  ls_cencos := rc_hdistrib.cencos;
              end loop ;

              if abs(ln_tot_importe) <> abs(ln_importe) then --si es menor del 100% asignar diferencia a centro de costo por defecto
                 ln_importe_x_porc := abs(ln_importe) - abs(ln_tot_importe);


                 --presupuesto de centro de costo por defecto
                 insert into tt_presupuesto_gasto_mes (
                        ano, cencos, cnta_prsp, fecha, importe ,cod_trabajador, centro_benef)
                 values (
                        ln_ano, ls_cencos, ls_cnta_prsp, adi_fec_proceso, 
                        abs(ln_importe_x_porc) * -1,rc_hc.cod_trabajador, rc_hc.centro_benef) ;
                 
                 
              end if;
              
              ls_cencos := null;
            else


               insert into tt_presupuesto_gasto_mes (
                      ano, cencos, cnta_prsp, fecha, importe ,cod_trabajador, centro_benef )
               values (
                      ln_ano, rc_hc.cencos, ls_cnta_prsp, adi_fec_proceso, 
                      ln_importe ,rc_hc.cod_trabajador, rc_hc.centro_benef) ;
            end if ;

        else
          IF rc_hc.concep <> ls_cnc_utilidades THEN  -- No considera utilidades
             select count(*) 
               into ln_count_val 
               from tt_rh_valid_presup
              where concepto         = rc_hc.concep         
                and tipo_trabajador  = rc_hc.tipo_trabajador
                and cencos           = rc_hc.cencos;

             if ln_count_val = 0 and ln_importe <> 0 then --inserta registro
                Insert Into tt_rh_valid_presup (
                       concepto,tipo_trabajador,cencos,observaciones)
                Values (
                       rc_hc.concep,rc_hc.tipo_trabajador,rc_hc.cencos,
                       'Tipo de Trabajador y Concepto no tiene Cuenta Presupuestal') ;
             end if ;
          END IF ;
        end if ;
     end if ;

end loop ;



--  *****************************************************************
--  ***   GENERA AMPLIACION SI EL GASTO ES MAYOR AL PRESUPUESTO   ***
--  *****************************************************************
open c_gastos ;
fetch c_gastos into rc_gastos ;

while c_gastos%found loop
  ln_ano        := rc_gastos.ano       ;
  ls_cencos     := rc_gastos.cencos    ;
  ls_cnta_prsp  := rc_gastos.cnta_prsp ;
  ld_fecha      := rc_gastos.fecha     ;
  ls_centro_benef := rc_gastos.centro_benef;

  ln_importe := 0 ;
  while rc_gastos.cencos = ls_cencos and rc_gastos.cnta_prsp = ls_cnta_prsp and c_gastos%found loop
  
        ln_importe := ln_importe + (nvl(rc_gastos.importe,0) * -1) ;
        
  fetch c_gastos into rc_gastos ;
  end loop ;

  select count(*) 
    into ln_count 
    from presupuesto_partida pp  
   where pp.ano       = ln_ano      
     and pp.cencos    = ls_cencos   
     and pp.cnta_prsp = ls_cnta_prsp ;

  if ln_count = 0 then
     --llenar tabla temporal avisando que partida no existe
     Insert Into tt_rh_valid_presup (cencos,cnta_prsp,observaciones)
     Values (ls_cencos,ls_cnta_prsp,'Partida Presupuestal No Existe ,Verifique!') ;
  else
     select nvl(pp.flag_ctrl,'0') into ls_flag_control
       from presupuesto_partida pp
      where pp.ano = ln_ano and pp.cencos = ls_cencos and pp.cnta_prsp = ls_cnta_prsp ;

      if ls_flag_control <> '0' then
         ln_imp_control := 0 ;
         if ls_flag_control = '1' then
            ln_imp_control := usf_pto_acumulado_anual(ln_ano, ls_cencos, ls_cnta_prsp) ;
         elsif ls_flag_control = '2' then
            ln_imp_control := usf_pto_acumulado_a_la_fecha(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp) ;
         elsif ls_flag_control = '3' then
            ln_imp_control := usf_pto_acumulado_mensual(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp) ;
         elsif ls_flag_control = '4' then
            ln_imp_control := usf_pto_acumulado_trimestre(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp);
         elsif ls_flag_control = '5' then
             ln_imp_control := usf_pto_acumulado_semestral(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp);
         end if ;


         --verificar parametros
         if ln_importe > ln_imp_control and ls_ctrl_ampl = '1' then
            ln_imp_diferencia := ln_importe - ln_imp_control ;
            --contador de variacion
            select np.ult_nro into ln_nro_var from num_presup_variacion np
             where np.origen = asi_origen for update ;

            ls_nro_var := asi_origen||lpad(trim(to_char(ln_nro_var)),8,'0')  ;

            insert into presup_variacion (
                   ano             , cencos_origen , cnta_prsp_origen , mes_origen , fecha          ,
                   flag_automatico , importe       , descripcion      , cod_usr    , tipo_variacion ,
                   nro_variacion   , centro_benef)
            values (
                   ln_ano , ls_cencos, ls_cnta_prsp, ln_mes, ld_fecha,'0',
                   ln_imp_diferencia, ls_desc_variacion, asi_usuario, 'A', ls_nro_var,
                   ls_centro_benef ) ;

            --incrementa numerador de variacion
            update num_presup_variacion set ult_nro = NVL(ult_nro,0) + 1
            where origen = asi_origen ;

         elsif ln_importe > ln_imp_control and ls_ctrl_ampl = '0' then --no genera ampliaciones
            ln_imp_diferencia := ln_importe - ln_imp_control ;

            --llenar tabla temporal avisando que partida no existe
            Insert Into tt_rh_valid_presup (
                   cencos,cnta_prsp,observaciones)
            Values (
                   ls_cencos,ls_cnta_prsp,'Se Excede Importe Planilla : '||to_char(ln_imp_diferencia)|| ', Verifique!') ;


         end if ;
      end if ;

  end if ;

  end loop ;

close c_gastos ;


--  ***************************************************************
--  ***   GRABA GASTOS DEL PRESUPUESTO MENSUAL DE LA PLANILLA   ***
--  ***************************************************************
ln_item := 1;
for lc_reg in c_gastos_afect loop
    ls_desc_prsp_ejec := substr( lc_reg.tipo_trabajador || ': ' || lc_reg.nom_trabajador,1,100);
  
    Insert into presupuesto_ejec(
         cod_origen, ano       , cencos      , cnta_prsp  , fecha      ,descripcion ,
         importe   , origen_ref, tipo_doc_ref, nro_doc_ref, item_ref  ,flag_replicacion ,
         cod_usr   , centro_benef  )
    Values(           
         asi_origen  ,lc_reg.ano    ,lc_reg.cencos   ,lc_reg.cnta_prsp , lc_reg.fecha ,ls_desc_prsp_ejec ,
         lc_reg.importe ,asi_origen ,ls_tipo_doc , lc_reg.cod_trabajador,  ln_item         ,'1'      ,
         asi_usuario, lc_reg.centro_benef      ) ;
    ln_item := ln_item + 1;
end loop;

commit;

end usp_rh_add_plla_presup_bk ;
/
