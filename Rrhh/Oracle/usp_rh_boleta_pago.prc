create or replace procedure usp_rh_boleta_pago (

   asi_fecha_proceso in string,
   aso_fecha_actual out string
) is
   ld_calc_act date;
   ld_ult_calc date;
   ls_und_labor unidad.und%type;
   ln_cuenta number(10);
   ln_cant_destajada number(12,4);
   ls_concep_vacacion char(4);
   ls_concep_rem_bas char(4);
   ls_concep_ingreso char(4);
   ls_desc_labor varchar2(40);

   cursor lc_calculo is
      select t.trabajador, t.fecha, t.concepto, lbr.cod_labor
         from tt_rh_boleta_concepto t
            inner join labor lbr on t.concepto = lbr.concepto_rrhh
            inner join pd_ot_asist_destajo poad on poad.cod_trabajador = t.trabajador
            inner join pd_ot_det pod on poad.nro_parte = pod.nro_parte
               and poad.nro_item = pod.nro_item
            inner join pd_ot pd on pod.nro_parte = pod.nro_parte
         where pd.fecha between ld_ult_calc and ld_calc_act;
   cursor lc_vacaciones is
      select trbc.trabajador, trbc.fecha, trbc.concepto
         from tt_rh_boleta_concepto trbc
         where trbc.concepto = ls_concep_vacacion;


begin


   delete from tt_rh_boleta_cabecera;
   delete from tt_rh_boleta_concepto;
   delete from tt_rh_boleta_destajo;
   delete from tt_rh_boleta_vacacion;

   ld_calc_act := to_date(asi_fecha_proceso, 'dd/mm/yyyy');


------------------------------------------------------------------------------------------
----------------------------    B    A    S    I    C    O    ----------------------------
------------------------------------------------------------------------------------------

   select p.cnc_total_ing
     into ls_concep_ingreso
     from rrhhparam p
     where p.reckey = '1' ;
     
   select gc.concepto_gen
      into ls_concep_rem_bas
      from grupo_calculo gc
      where gc.grupo_calculo = (select rcc.remunerac_basica from rrhhparam_cconcep rcc where rcc.reckey = '1');

   insert into tt_rh_boleta_cabecera(trabajador, basico, fecha, mes, semana, nombre, nacionalidad, cod_area, cod_seccion, fec_nacimiento, flag_sexo, direccion, dni, desc_cargo, fecha_ingreso, fecha_cese, nro_ips, nro_afp, cencos, cod_categ_sal, desc_afp, empresa_nombre, empresa_dir_calle, cod_origen, nombre_origen, tipo_trabajador, desc_tipo_trabajador, cod_afp)

   select clc.cod_trabajador, gf.imp_gan_desc, clc.fec_proceso, to_number(to_char(clc.fec_proceso, 'mm')), to_number(rpad(to_char(c.ano_calc),4,'0') || lpad(to_char(c.semana_calc),2,'0')), cr.nombre, p.nacionalidad, m.cod_area, m.cod_seccion, m.fec_nacimiento, m.flag_sexo, m.direccion, m.dni, crg.desc_cargo, m.fec_ingreso, m.fec_cese, m.nro_ipss, m.nro_afp_trabaj, m.cencos, m.cod_categ_sal, afp.desc_afp, emp.nombre, trim(emp.dir_calle)||' '||trim(emp.dir_distrito), m.cod_origen, o.nombre, m.tipo_trabajador, tt.desc_tipo_tra, m.cod_afp
      from calculo clc
         left outer join calendario c on trunc(clc.fec_proceso) = trunc(c.fecha)
         inner join codigo_relacion cr on clc.cod_trabajador = cr.cod_relacion
         inner join maestro m on clc.cod_trabajador = m.cod_trabajador
         left outer join gan_desct_fijo gf on ( clc.cod_trabajador = gf.cod_trabajador and gf.concep = ls_concep_rem_bas )
         left outer join pais p on m.cod_pais = p.cod_pais
         inner join cargo crg on m.cod_cargo = crg.cod_cargo
         left outer join admin_afp afp on m.cod_afp = afp.cod_afp
         inner join empresa emp on m.cod_empresa = emp.cod_empresa
         inner join origen o on m.cod_origen = o.cod_origen
         inner join tipo_trabajador tt on m.tipo_trabajador = tt.tipo_trabajador
      where clc.fec_proceso = ld_calc_act
         and clc.concep = ls_concep_ingreso

   union all

   select hcl.cod_trabajador, gf.imp_gan_desc, hcl.fec_calc_plan, to_number(to_char(hcl.fec_calc_plan, 'mm')), to_number(rpad(to_char(c.ano_calc),4,'0') || lpad(to_char(c.semana_calc),2,'0')), cr.nombre, p.nacionalidad, m.cod_area, m.cod_seccion, m.fec_nacimiento, m.flag_sexo, m.direccion, m.dni, crg.desc_cargo, m.fec_ingreso, m.fec_cese, m.nro_ipss, m.nro_afp_trabaj, m.cencos, m.cod_categ_sal, afp.desc_afp, emp.nombre, trim(emp.dir_calle)||' '||trim(emp.dir_distrito), m.cod_origen, o.nombre, m.tipo_trabajador, tt.desc_tipo_tra, m.cod_afp
      from historico_calculo hcl
         left outer join calculo clc on hcl.cod_trabajador = clc.cod_trabajador
            and hcl.concep = clc.concep
            and trunc(hcl.fec_calc_plan) = trunc(clc.fec_proceso)
         left outer join calendario c on trunc(hcl.fec_calc_plan) = trunc(c.fecha)
         inner join codigo_relacion cr on hcl.cod_trabajador = cr.cod_relacion
         inner join maestro m on hcl.cod_trabajador = m.cod_trabajador
         left outer join gan_desct_fijo gf on ( hcl.cod_trabajador = gf.cod_trabajador and gf.concep = ls_concep_rem_bas )
         left outer join pais p on m.cod_pais = p.cod_pais
         inner join cargo crg on m.cod_cargo = crg.cod_cargo
         left outer join admin_afp afp on m.cod_afp = afp.cod_afp
         inner join empresa emp on m.cod_empresa = emp.cod_empresa
         inner join origen o on m.cod_origen = o.cod_origen
         left outer join tipo_trabajador tt on m.tipo_trabajador = tt.tipo_trabajador
      where hcl.fec_calc_plan = ld_calc_act
         and hcl.concep = ls_concep_ingreso
         and clc.concep is null;

------------------------------------------------------------------------------------------
---------------------------  C   O   N   C   E   P   T  O   S   --------------------------
------------------------------------------------------------------------------------------
   --Calculando importes por conceptos en planilla

   insert into tt_rh_boleta_concepto (trabajador, concepto, fecha, importe, horas, dias, desc_concepto)

   select clc.cod_trabajador, clc.concep, clc.fec_proceso, clc.imp_soles, clc.horas_trabaj, clc.dias_trabaj, cpto.desc_breve
      from calculo clc
         left outer join concepto cpto on clc.concep = cpto.concep
      where trunc(clc.fec_proceso) = trunc(ld_calc_act)
            and nvl(clc.imp_soles,0) <> 0

   union all

   select hcl.cod_trabajador, hcl.concep, hcl.fec_calc_plan, hcl.imp_soles, hcl.horas_trabaj, hcl.dias_trabaj, cpto.desc_breve
      from historico_calculo hcl
         left outer join concepto cpto on hcl.concep = cpto.concep
         left outer join calculo clc on hcl.cod_trabajador = clc.cod_trabajador
            and hcl.concep = clc.concep
            and trunc(hcl.fec_calc_plan) = trunc(clc.fec_proceso)
      where trunc(hcl.fec_calc_plan) = trunc(ld_calc_act)
         and clc.concep is null
         and nvl(hcl.imp_soles,0) <> 0 ;




------------------------------------------------------------------------------------------
------------------------------   D   E   S   T   A   J   O   -----------------------------
------------------------------------------------------------------------------------------

   for rs_calc in lc_calculo loop
      --Última fecha de cálculo de planilla, para buscar destajos en caso de tenerlos
      select nvl(max(hc.fec_calc_plan), to_date('01/01/2000', 'dd/mm/yyyy'))
         into ld_ult_calc
         from historico_calculo hc
         where hc.cod_trabajador = rs_calc.trabajador
            and hc.concep = rs_calc.concepto
            and hc.fec_calc_plan < rs_calc.fecha;

      --Destajos en el rango de fecha: ultimo proceso - proceso actual
      select count(*)
         into ln_cuenta
         from pd_ot_asist_destajo poad
            inner join pd_ot_det pod on poad.nro_parte = pod.nro_parte
               and poad.nro_item = pod.nro_item
            inner join pd_ot pd on pd.nro_parte = pod.nro_parte
         where pd.fecha between ld_ult_calc and ld_calc_act
            and pod.cod_labor = rs_calc.cod_labor
            and poad.cod_trabajador = rs_calc.trabajador;
      if ln_cuenta > 0 then
         select pod.und_labor, lbr.desc_labor, sum(poad.cant_destajada)
            into ls_und_labor, ls_desc_labor, ln_cant_destajada
            from pd_ot_asist_destajo poad
               inner join pd_ot_det pod on poad.nro_parte = pod.nro_parte and poad.nro_item = pod.nro_item
               inner join pd_ot pd on pd.nro_parte = pod.nro_parte
               left outer join labor lbr on pod.cod_labor = lbr.cod_labor
            where pd.fecha between ld_ult_calc and ld_calc_act
               and pod.cod_labor = rs_calc.cod_labor
               and poad.cod_trabajador = rs_calc.trabajador
            group by pod.und_labor, lbr.desc_labor;

         insert into tt_rh_boleta_destajo (trabajador, concepto, labor, cantidad_destajo, unidad_destajo, fecha_desde, fecha_hasta, desc_labor )
            values (rs_calc.trabajador, rs_calc.concepto, rs_calc.cod_labor, ln_cant_destajada, ls_und_labor, ld_ult_calc, ld_calc_act, ls_desc_labor);
      end if;
   end loop;



------------------------------------------------------------------------------------------
-------------------  P  E  R  I  O  D  O     V  A  C  A  C  I  O  N  ---------------------
------------------------------------------------------------------------------------------
   select gc.concepto_gen
      into ls_concep_vacacion
      from grupo_calculo gc
      where gc.grupo_calculo = (select rc.gan_fij_calc_vacac from rrhhparam_cconcep rc where rc.reckey = '1');

   for rs_lv in lc_vacaciones loop

      select nvl(max(hc.fec_calc_plan), to_date('01/01/2000', 'dd/mm/yyyy'))
         into ld_ult_calc
         from historico_calculo hc
         where hc.cod_trabajador = rs_lv.trabajador
            and hc.concep = rs_lv.concepto
            and hc.fec_calc_plan < rs_lv.fecha;

      insert into tt_rh_boleta_vacacion
         (trabajador, inicio_vacacion, fin_vacacion)
         select i.cod_trabajador, i.fec_desde, i.fec_hasta
            from inasistencia i
            where i.concep = ls_concep_vacacion
               and i.cod_trabajador in (select distinct trbc.trabajador from tt_rh_boleta_concepto trbc)
               and i.fec_movim between ld_ult_calc and ld_calc_act;
   end loop;

   select to_char(sysdate, 'dd/mm/yyyy')
      into aso_fecha_actual
      from dual;

end usp_rh_boleta_pago;
/
