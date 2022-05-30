create or replace procedure usp_alm_act_ult_sal_x_alm(
       asi_nada             in  string,
       aso_mensaje          out string,
       aio_ok               out integer
) is

  /*
     Procedimiento que Actualiza la fecha de ultima salida en la
     tabla articulo_almacen
  */

  cursor c_Articulos is
    select distinct  aa.cod_Art, aa.almacen
    from articulo_almacen  aa
    where aa.fec_ult_salida is null;

  ld_fec_ult_sal             articulo_almacen.fec_ult_salida%TYPE;

begin

    /* delete tt_edg1;
     commit;*/

     for lc_reg in c_articulos loop

         ld_fec_ult_sal := usf_alm_fec_ult_sal(lc_reg.cod_Art , lc_reg.almacen);

         if ld_fec_ult_sal is not null then
            update articulo_almacen aa
               set aa.fec_ult_salida = ld_fec_ult_sal
             where aa.cod_art = lc_reg.cod_art
               and aa.almacen = lc_reg.almacen;

            commit;
         end if;

/*         insert into tt_edg1(cod_art)
         values(lc_reg.cod_art);
         commit;
*/
         

     end loop;

end usp_alm_act_ult_sal_x_alm;
/
