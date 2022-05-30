create or replace procedure usp_rh_destajo_carga (

   asi_cod_usr in string,
   asi_cod_origen in string,
   adi_ini in date,
   adi_fin in date,
   ano_cuenta out number,
   ado_fecha_act out string,
   aso_msg out string,
   ano_msg out number

) is

   ls_doc_dstj rrhhparam.doc_dstj%type;
   ld_fecha_act date;
   
   cursor lc_destajo is
      select distinct pdad.nro_parte, pdad.nro_item, pdad.cod_trabajador
         from pd_ot pd
            inner join pd_ot_det pdd on pd.nro_parte = pdd.nro_parte
            inner join pd_ot_asist_destajo pdad on pdd.nro_parte = pdad.nro_parte and pdd.nro_item = pdad.nro_item
         where trunc(pd.fecha) between trunc(adi_ini) and trunc(adi_fin)
            and pdad.flag_procesado = '0'
            and substr(pd.nro_parte, 1, 2) = asi_cod_origen;
            
            
   cursor lc_concepto_labor is
      select l.cod_labor, l.desc_labor
         from pd_ot pd
            inner join pd_ot_det pdd on pd.nro_parte = pdd.nro_parte
            inner join pd_ot_asist_destajo pdad on pdd.nro_parte = pdad.nro_parte and pdd.nro_item = pdad.nro_item
            inner join labor l on pdd.cod_labor = l.cod_labor
         where trunc(pd.fecha) between trunc(adi_ini) and trunc(adi_fin)
            and pdad.flag_procesado = '0'
            and substr(pd.nro_parte, 1, 2) = asi_cod_origen
            and l.concepto_rrhh is null or trim(l.concepto_rrhh) = '';
         
begin
   aso_msg := '';
   ano_msg := 0;
   -- verifica que todos las labores tengan concepto
   for rs_cl in lc_concepto_labor loop
      aso_msg := aso_msg || chr(13) ||rs_cl.cod_labor || ': ' || rs_cl.desc_labor;
      ano_msg := 1;
   end loop;
   if ano_msg = 1 then
      aso_msg := 'ORACLE:'|| chr(13) ||'Las siguientes labores no tienen conceptos asignados ' || aso_msg;
      return;
   end if;
   --captura la fecha del sistema
   select sysdate
      into ld_fecha_act
      from dual;

   -- captura el tipo de documento de generación automática
   select rhp.doc_dstj
      into ls_doc_dstj
      from rrhhparam rhp
      where rhp.reckey = '1';
      
   -- graba los destajos como movimientos variables
   insert into gan_desct_variable 
      (cod_trabajador, fec_movim, concep, cencos, cod_usr, tipo_doc, imp_var)
      select pdad.cod_trabajador, pd.fecha, l.concepto_rrhh, pdd.cencos, asi_cod_usr, ls_doc_dstj, sum(nvl(pdad.cant_destajada,0) * nvl(pdad.tarifa_normal,0) * nvl(pdad.factor_calculo,0)) as monto
      from pd_ot pd
         inner join pd_ot_det pdd on pd.nro_parte = pdd.nro_parte
         inner join pd_ot_asist_destajo pdad on pdd.nro_parte = pdad.nro_parte and pdd.nro_item = pdad.nro_item
         inner join labor l on pdd.cod_labor = l.cod_labor
      where trunc(pd.fecha) between trunc(adi_ini) and trunc(adi_fin)
         and pdad.flag_procesado = '0'
         and substr(pd.nro_parte, 1, 2) = asi_cod_origen
      group by l.concepto_rrhh, pdad.cod_trabajador, pdd.cencos,pd.fecha;

   ano_cuenta := 0;

   for rs_dj in lc_destajo loop   
  
      update pd_ot_asist_destajo poad
         set poad.flag_procesado = '1'
         where poad.nro_parte = rs_dj.nro_parte
            and poad.nro_item = rs_dj.nro_item
            and poad.cod_trabajador = rs_dj.cod_trabajador;

      ano_cuenta := ano_cuenta + 1 ;

   end loop;
   
   commit;
   
   ado_fecha_act := to_char(ld_fecha_act, 'dd/mm/yyyy hh:mi:ss');
   
   
exception
   when others then
   aso_msg := 'ORACLE: Error en proceimiento usp_rh_destajo_carga ';
   ano_msg := 1;
   RAISE_APPLICATION_ERROR(-20000,  SQLERRM );
   
end usp_rh_destajo_carga;
/
