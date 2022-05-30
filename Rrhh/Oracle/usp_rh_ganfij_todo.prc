create or replace procedure usp_rh_ganfij_todo(
   asi_nada in string
)
is
   ls_concepto25 char(4);
   ls_concepto30 char(4);
   ln_gan_desct_fijo_tot number(13,2);

-- ganancias finas, bonificación del 30%
   cursor lc_bonif30 is
      select gdf.cod_trabajador, sum(gdf.imp_gan_desc) * 0.30 as importe
         from gan_desct_fijo gdf 
            inner join maestro m on gdf.cod_trabajador = m.cod_trabajador 
         where gdf.concep in (select gcd.concepto_calc from grupo_calculo_det gcd where gcd.grupo_calculo = (select rc.bonificacion30 from rrhhparam_cconcep rc where rc.reckey = '1')) 
            and substr(gdf.concep,1,2) = (select rp.grc_gnn_fija from rrhhparam rp where rp.reckey = '1')
            and m.bonif_fija_30_25 = '1' 
         group by gdf.cod_trabajador;

-- ganancias finas, bonificación del 25%
   cursor lc_bonif25 is
      select gdf.cod_trabajador, sum(gdf.imp_gan_desc) * 0.25  as importe
         from gan_desct_fijo gdf 
            inner join maestro m on gdf.cod_trabajador = m.cod_trabajador 
         where gdf.concep in (select gcd.concepto_calc from grupo_calculo_det gcd where gcd.grupo_calculo = (select rc.bonificacion25 from rrhhparam_cconcep rc where rc.reckey = '1')) 
            and substr(gdf.concep,1,2) = (select rp.grc_gnn_fija from rrhhparam rp where rp.reckey = '1')
            and m.bonif_fija_30_25 = '2' 
         group by gdf.cod_trabajador;

begin
   delete from tt_rh_ganfij_todo;

   select gc.concepto_gen -- cocnepto de bonificación del 25%
      into ls_concepto25
      from grupo_calculo gc 
      where gc.grupo_calculo = (select rc.bonificacion25 from rrhhparam_cconcep rc where rc.reckey = '1');
   
   select gc.concepto_gen -- cocnepto de bonificación del 30%
      into ls_concepto30
      from grupo_calculo gc 
      where gc.grupo_calculo = (select rc.bonificacion30 from rrhhparam_cconcep rc where rc.reckey = '1');
      
   insert into tt_rh_ganfij_todo -- insertar todos las ganancais fijas
      (cod_trabajador,concep,importe)
      select gdf.cod_trabajador, gdf.concep, gdf.imp_gan_desc from gan_desct_fijo gdf where substr(gdf.concep,1,2) = (select rp.grc_gnn_fija from rrhhparam rp where rp.reckey = '1');

   for rs_25 in lc_bonif25 loop
      ln_gan_desct_fijo_tot := 0;
      
      select sum(gdf.imp_gan_desc) + rs_25.importe -- todas las ganancias + bonif 25%
         into ln_gan_desct_fijo_tot
         from gan_desct_fijo gdf 
         where substr(gdf.concep,1,2) = (select rp.grc_gnn_fija from rrhhparam rp where rp.reckey = '1') 
            and gdf.cod_trabajador = rs_25.cod_trabajador
         group by gdf.cod_trabajador;
         
      insert into tt_rh_ganfij_todo 
         (cod_trabajador, concep, importe)
      values
         (rs_25.cod_trabajador, ls_concepto25, ln_gan_desct_fijo_tot);
   end loop;      
   for rs_30 in lc_bonif30 loop
      ln_gan_desct_fijo_tot := 0;
      
      select sum(gdf.imp_gan_desc) + rs_30.importe -- todas las ganancias + bonif 30%
         into ln_gan_desct_fijo_tot
         from gan_desct_fijo gdf 
         where substr(gdf.concep,1,2) = (select rp.grc_gnn_fija from rrhhparam rp where rp.reckey = '1') 
            and gdf.cod_trabajador = rs_30.cod_trabajador
         group by gdf.cod_trabajador;
         
      insert into tt_rh_ganfij_todo 
         (cod_trabajador, concep, importe)
      values
         (rs_30.cod_trabajador, ls_concepto30, ln_gan_desct_fijo_tot);
   end loop;

   insert into tt_rh_ganfij_todo -- insertar todos las ganancais fijas
      (cod_trabajador,concep,importe)
      select gdf.cod_trabajador, gdf.concep, gdf.imp_gan_desc from gan_desct_fijo gdf where substr(gdf.concep,1,2) = (select rp.grc_dsc_fijo from rrhhparam rp where rp.reckey = '1');

  
   insert into tt_rh_ganfij_todo 
      (cod_trabajador, concep, importe)
      select trgt.cod_trabajador, '1099', sum(trgt.importe) from tt_rh_ganfij_todo trgt where substr(trgt.concep,1,2) = (select rp.grc_gnn_fija from rrhhparam rp where rp.reckey = '1') group by trgt.cod_trabajador;


   insert into tt_rh_ganfij_todo 
      (cod_trabajador, concep, importe)
      select trgt.cod_trabajador, '2299', sum(trgt.importe) from tt_rh_ganfij_todo trgt where substr(trgt.concep,1,2) = (select rp.grc_dsc_fijo from rrhhparam rp where rp.reckey = '1') group by trgt.cod_trabajador;
      

end usp_rh_ganfij_todo;
/
