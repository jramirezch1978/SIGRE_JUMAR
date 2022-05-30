create or replace function usf_prod_serv_fijo_dia(
       asi_empacadora      in ap_empacadora.cod_empacadora%TYPE,
       adi_fecha           in date,
       asi_moneda          in moneda.cod_moneda%TYPE
) return number is
  ln_servicios1    number := 0;
  ln_servicios2    number := 0;
  ln_Result        number := 0;
  
  ln_tot_cajas     number;
  ln_cajas         number;
begin
  
  -- Obtengo el total de cajas
  select nvl(sum(apr.cant_cajas),0)
    into ln_tot_cajas
    from ap_control_cosecha acc,
         ap_recibo_cajas    apr,
         ap_empacadora      ae
   where acc.nro_parte      = apr.nro_parte
     and acc.cod_empacadora = ae.cod_empacadora
     and acc.flag_estado <> '0'
     and apr.flag_estado <> '0'
     and to_char(acc.fec_parte, 'yyyymm') = to_char(adi_fecha, 'yyyymm');
  
  -- Obtengo el nro de cajas en el día por la empacadora
  select nvl(sum(apr.cant_cajas),0)
    into ln_cajas
    from ap_control_cosecha acc,
         ap_recibo_cajas    apr
   where acc.nro_parte      = apr.nro_parte
     and acc.flag_estado <> '0'
     and apr.flag_estado <> '0'
     and trunc(acc.fec_parte) = adi_fecha
     and acc.cod_empacadora   = asi_empacadora;  


  select nvl(sum(usf_fl_conv_mon(osd.importe, os.cod_moneda, asi_moneda, osd.fec_proyect)),0)
    into ln_Servicios1
    from orden_servicio_det osd,
         orden_servicio     os,
         operaciones        op,
         orden_trabajo      ot,
         (select nro_orden from orden_trabajo
           minus
          select nro_orden
            from ap_empacadora_ot
           minus
          select distinct ot.nro_orden
            from orden_trabajo ot,
                 orden_venta   ov
          where ot.nro_orden = ov.ot_gastos) qry1,
         (select distinct ot_adm from orden_trabajo
           minus
          select ot_adm from ap_empacadora where ot_adm is not null) qry2
   where os.nro_os              = osd.nro_os
     and osd.oper_sec           = op.oper_sec
     and op.nro_orden           = ot.nro_orden
     and to_char(osd.fec_proyect, 'yyyymm') = to_char(adi_fecha, 'yyyymm')
     and ot.ot_adm              = qry2.ot_adm
     and ot.nro_orden           = qry1.nro_orden
     and osd.flag_estado     <> '0'
     and os.flag_estado      <> '0';

  select nvl(sum(usf_fl_conv_mon(osd.importe, os.cod_moneda, asi_moneda, osd.fec_proyect)),0)
    into ln_Servicios2
    from orden_servicio_det osd,
         orden_servicio     os
   where os.nro_os              = osd.nro_os
     and osd.oper_sec           is null
     and to_char(osd.fec_proyect, 'yyyymm') = to_char(adi_fecha, 'yyyymm')
     and osd.flag_estado     <> '0'
     and os.flag_estado      <> '0';

  if ln_tot_cajas > 0 then
     ln_Result := (ln_Servicios1 + ln_Servicios2) * ln_cajas / ln_tot_cajas;
  else
     ln_Result := 0;
  end if;
  
  return(ln_Result);
end usf_prod_serv_fijo_dia;
/
