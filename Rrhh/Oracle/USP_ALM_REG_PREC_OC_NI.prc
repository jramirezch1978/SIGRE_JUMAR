create or replace procedure USP_ALM_REG_PREC_OC_NI(
       adi_fecha1  in date,
       adi_fecha2  in date
) is

cursor c_mov is 
  select vm.nro_vale, 
         vm.fec_registro, 
         vm.tipo_mov, 
         am.cod_art, 
         am.cant_procesada,
         am.precio_unit as precio_unit_ni, 
         amp.precio_unit as precio_unit_oc, 
         oc.cod_moneda, 
         amp.decuento,
         a.desc_art,
  		   a.und,
         round(usf_fl_conv_mon(amp.precio_unit - amp.decuento, oc.cod_moneda, am.cod_moneda, vm.fec_registro),4) as precio_unit2,
         am.nro_mov, 
         am.cod_origen,
         am.nro_mov_proy, 
         am.origen_mov_proy,
         amp.tipo_doc, 
         amp.nro_doc
  from articulo_mov am,
       vale_mov     vm,
       articulo_mov_proy amp,
       orden_compra      oc,
  	  articulo			  a
  where am.nro_vale = vm.nro_vale
    and amp.nro_mov = am.nro_mov_proy
    and amp.cod_origen = am.origen_mov_proy
    and amp.tipo_doc = (select doc_oc from logparam where reckey = '1')
    and oc.nro_oc    = amp.nro_doc
    and a.cod_art    = amp.cod_art
    and am.flag_estado <> '0'
    and vm.flag_estado <> '0'
    and vm.tipo_refer = (select doc_oc from logparam where reckey = '1')    
    and round(usf_fl_conv_mon(amp.precio_unit - amp.decuento, oc.cod_moneda, am.cod_moneda, vm.fec_registro),4) <> am.precio_unit
    and trunc(vm.fec_registro) >= trunc(adi_fecha1)
    and trunc(vm.fec_registro) <= trunc(adi_fecha2);

cursor c_art is 
select cod_art
from tt_edg1;

  ls_mensaje  string(3000);
  li_ok       integer;
  
begin

   delete tt_edg1;
   
   for r_mov in c_mov loop
       update articulo_mov am
          set am.precio_unit = r_mov.precio_unit2,
              am.precio_unit_ant = r_mov.precio_unit_ni,
              am.flag_replicacion = '1'
        where am.nro_mov = r_mov.nro_mov
          and am.cod_origen = r_mov.cod_origen;
       
       commit;

       usp_alm_act_valor_x_art_alm(r_mov.cod_art, adi_fecha1, ls_mensaje, li_ok);
       if li_ok <> 1 then
          RAISE_APPLICATION_ERROR(-20000, ls_mensaje);
       end if;
       usp_alm_act_valor_x_art(r_mov.cod_art, ls_mensaje, li_ok);
       if li_ok <> 1 then
          RAISE_APPLICATION_ERROR(-20000, ls_mensaje);
       end if;
      
       commit;
       
   end loop;
end USP_ALM_REG_PREC_OC_NI;
/
