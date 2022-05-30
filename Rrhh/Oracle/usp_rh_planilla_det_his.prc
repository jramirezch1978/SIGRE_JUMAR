create or replace procedure usp_rh_planilla_det_his (
   asi_origen  in string  , asi_tipo_trabajador in string  ,
   adi_proceso date       , ano_msg             out number ,
   aso_msg     out string  ) is

 
   ls_cod_trabajador char(8);
   ln_importe number;
--------------------------------------
   ls_codigo       char(8);
   ls_nro_dni      varchar2(12);
   ls_nro_essalud  varchar2(15);
   ls_nro_afp      varchar2(12);
   ls_ap_paterno   varchar2(30);
   ls_ap_materno   varchar2(30);
   ls_nombres      varchar2(60);
   ls_cod_cargo    cargo.cod_cargo%type;
   ls_cargo        varchar2(30);
   ls_cencos       centros_costo.cencos%type;
   ls_centro_costo varchar2(40);
   ls_cod_afp      char(2);
   ls_desc_afp     admin_afp.desc_afp%type;
   ld_fec_ingreso  date;
   ld_fec_cese     date;
   ld_fec_ini_vac  date;
   ld_fec_fin_vac  date;
   ln_dias_trab    number(7,2);
   ln_horas_trab   number(7,2);
   ln_basico      number(10,2);
   ln_valida       number;
   ls_fec_ingreso varchar2(30);
   ls_fec_cese    varchar2(30);
   ls_fec_ini_vac varchar2(30);
   ls_fec_fin_vac varchar2(30);
   ls_dias_trab   varchar2(30);
   ls_horas_trab  varchar2(30);
-------------------------------------
cursor lc_formato is
select pf.fila, pf.columna, pf.grupo_calculo
  from planilla_formato pf;

cursor lc_maestro is
select m.cod_trabajador
  from maestro m,historico_calculo c
 where trim(m.tipo_trabajador) = trim(asi_tipo_trabajador) and
       trim(m.cod_origen)      = trim(asi_origen)          and
       --m.flag_cal_plnlla       = '1'                       and
       m.cod_trabajador        = c.cod_trabajador          and
       trunc(c.fec_calc_plan)  = trunc(adi_proceso)        and
       c.concep                = (select cnc_total_ing from rrhhparam)
group by m.cod_trabajador ;

begin

   delete from tt_rh_planilla_det;

   for rs_cm in lc_maestro loop

      ls_cod_trabajador := rs_cm.cod_trabajador;

      select m.cod_trabajador, m.nro_ipss, m.nro_afp_trabaj,m.apel_paterno, m.apel_materno,nvl(m.nombre1, '') || nvl(m.nombre2,''),
             m.cod_cargo, m.cencos, m.fec_ingreso, m.fec_cese, m.cod_afp
        into ls_codigo, ls_nro_essalud, ls_nro_afp,ls_ap_paterno, ls_ap_materno, ls_nombres,
             ls_cod_cargo, ls_cencos, ld_fec_ingreso, ld_fec_cese, ls_cod_afp
        from maestro m
       where trim(m.cod_trabajador) = trim(ls_cod_trabajador);


      select nvl(max(a.desc_afp), '----') into ls_desc_afp
         from admin_afp a where a.cod_afp = ls_cod_afp;

      select nvl(max(cc.desc_cencos), '---') into ls_centro_costo
         from centros_costo cc where trim(cc.cencos) = trim(ls_cencos);

      select nvl(max(c.desc_cargo), '---') into ls_cargo
         from cargo c where trim(c.cod_cargo) = trim(ls_cod_cargo);

      select count(*) into ln_valida from mov_mes_vacac_bonif v
         where trunc(adi_proceso) between trunc(v.fec_desde) and trunc(v.fec_hasta) and
               trim(v.cod_trabajador) = trim(ls_cod_trabajador) ;

      if ln_valida > 0 then
         select min(v.fec_desde), max(v.fec_hasta) into ld_fec_ini_vac, ld_fec_fin_vac
           from mov_mes_vacac_bonif v
          where trunc(adi_proceso) between trunc(v.fec_desde) and trunc(v.fec_hasta) and
                trim(v.cod_trabajador) = trim(ls_cod_trabajador);
      else
         ld_fec_ini_vac := null;
         ld_fec_fin_vac := null;
      end if;


      select nvl(max(hc.horas_trabaj), 0.00), nvl(max(hc.dias_trabaj), 0.00) into ln_horas_trab,ln_dias_trab
        from historico_calculo hc
       where trim(hc.cod_trabajador) = trim(ls_cod_trabajador)      and
             trim(hc.concep)         = (select trim(gc.concepto_gen)
                                          from grupo_calculo gc
                                         where gc.grupo_calculo = (select rp.remunerac_basica
                                                                     from rrhhparam_cconcep rp
                                                                    where rp.reckey  ='1'      ));

      if ls_codigo is null or trim (ls_codigo) = '' then
         ls_codigo := '----';
      end if ;

      if ls_nro_dni is null or trim (ls_nro_dni) = '' then
         ls_nro_dni := '----';
      end if ;

      if ls_nro_essalud is null or trim (ls_nro_essalud) = '' then
         ls_nro_essalud := '----';
      end if;

      if ls_nro_afp is null or trim (ls_nro_afp) = '' then
         ls_nro_afp := '----';
      end if;

      if ls_ap_paterno is null or trim (ls_ap_paterno) = '' then
         ls_ap_paterno := '----';
      end if;

      if ls_ap_materno is null or trim (ls_ap_materno) = '' then
         ls_ap_materno := '----';
      end if;

      if ls_nombres is null or trim (ls_nombres) = '' then
         ls_nombres := '----';
      end if;

      if ls_desc_afp is null or trim (ls_desc_afp) = '' then
         ls_desc_afp := '----';
      end if;

      if ls_cargo is null or trim (ls_cargo) = '' then
         ls_cargo := '----';
      end if;

      if ls_centro_costo is null or trim (ls_centro_costo) = '' then
         ls_centro_costo := '----';
      end if;

      ls_fec_ingreso := to_char(ld_fec_ingreso , 'dd/mm/yyyy');
      ls_fec_cese    := to_char(ld_fec_cese    , 'dd/mm/yyyy');
      ls_fec_ini_vac := to_char(ld_fec_ini_vac , 'dd/mm/yyyy');
      ls_fec_fin_vac := to_char(ld_fec_fin_vac , 'dd/mm/yyyy');
      ls_dias_trab   := to_char(ln_dias_trab   , '999999990.00');
      ls_horas_trab  := to_char(ln_horas_trab  , '999999990.00');

      if ls_fec_ingreso is null or trim (ls_fec_ingreso) = '' then
         ls_fec_ingreso := '----';
      end if;

      if ls_fec_cese is null or trim (ls_fec_cese) = '' then
         ls_fec_cese := '----';
      end if;

      if ls_fec_ini_vac is null or trim (ls_fec_ini_vac) = '' then
         ls_fec_ini_vac := '----';
      end if;

      if ls_fec_fin_vac is null or trim (ls_fec_fin_vac) = '' then
         ls_fec_fin_vac := '----';
      end if;

      if ls_dias_trab is null or trim (ls_dias_trab) = '' then
         ls_dias_trab := '0,00';
      end if;

      if ls_horas_trab is null or trim (ls_horas_trab) = '' then
         ls_horas_trab := '0,00';
      end if;

      insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 1, -3, ls_codigo);
      insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 2, -3, ls_nro_dni);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 3, -3, ls_nro_afp);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 4, -3, to_char(ln_basico, '999999990.00'));
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 1, -2, ls_ap_paterno);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 2, -2, ls_ap_materno);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 3, -2, ls_nombres);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 4, -2, ls_desc_afp);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 5, -2, lower(ls_cargo));
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 6, -2, lower(ls_centro_costo));
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 1, -1, ls_fec_ingreso);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 2, -1, ls_fec_cese);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 3, -1, ls_fec_ini_vac);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 4, -1, ls_fec_fin_vac);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 5, -1, ls_dias_trab);
     insert into tt_rh_planilla_det(cod_trabajador,fila,columna,importe)
         values(ls_cod_trabajador, 6, -1, ls_horas_trab);



      -- calculando importes de planilla
      for rs_fm in lc_formato loop

          select nvl(sum(hc.imp_soles), 0.00) into ln_importe from historico_calculo hc
          where hc.cod_trabajador       = ls_cod_trabajador  and
                trunc(hc.fec_calc_plan) = trunc(adi_proceso) and
                trim(hc.concep)         in (select trim(gcd.concepto_calc)
                                              from grupo_calculo_det gcd
                                             where gcd.grupo_calculo = rs_fm.grupo_calculo);

         insert into tt_rh_planilla_det
         (cod_trabajador,fila,columna,importe)
         values
         (ls_cod_trabajador ,rs_fm.fila ,rs_fm.columna , to_char(ln_importe,'999999990.00') );

      end loop;

--   commit;

   end loop;

exception
   when others then
      ano_msg := 1;
      aso_msg := 'ORACLE: Error en usp_rh_planilla_det';

end usp_rh_planilla_det_his;
/
