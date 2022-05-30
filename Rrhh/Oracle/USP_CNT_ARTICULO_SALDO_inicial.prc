create or replace procedure USP_CNT_ARTICULO_SALDO_inicial
  (an_ano in cntbl_asiento.ano%type,
  an_mes in cntbl_asiento.mes%type ) is
  
  ld_fecha_ini          date ;
  ld_fecha_fin          date ;
  ln_total_ing          number(15,4);     
  ln_total_egr          number(15,4); 
  ln_sldo_total         number(15,4);
  ln_total_compras      number(15,4);     
  ln_total_consumos     number(15,4); 
  ln_valor_com_total    number(15,4);
  ln_valor_cons_total   number(15,4);
  ln_valor_saldo_total  number(15,4);
  ln_valor_mes_ingr     number(15,4);
  ln_valor_mes_egr      number(15,4);
  ln_compra_total       number(15,4); 
  ln_precio_prom_sol    number(15,4); 
  lc_cons_interno       char (6)    ;
  lc_ing_oc             char (6)    ;
  lc_almacen            char (6)    ;
  lc_Articulo           char (12)   ;

  
  /* Captura los codigos de Almacen */
CURSOR c_almacen is 
SELECT distinct(almacen) as cod_almacen
  FROM tt_cntbl_almacen ;

  /* Captura los codigos de articulo */
CURSOR c_articulo is 
select distinct(cod_art) as cod_artic
FROM tt_cntbl_articulo
order by cod_art ;

BEGIN

DELETE FROM tt_cntbl_almacen;
DELETE FROM tt_cntbl_articulo;
DELETE FROM articulo_saldo_mensual asm WHERE asm.ano=an_ano AND asm.mes= an_mes ;

ld_fecha_ini := trunc(to_date( '01/'|| to_char(an_mes,'99') ||'/'|| to_char(an_ano,'9999') ,'dd/mm/yyyy'));
ld_fecha_fin := trunc( last_day(ld_fecha_ini) ) + 0.999 ;

/* Captura los datos de logparam , de compra y consumo */
   select oper_cons_interno, oper_ing_oc
     into lc_cons_interno, lc_ing_oc        
     from logparam 
    where reckey='1';


-- Actualizando temporal de Almacenes, de movimiento rango seleccionado
INSERT INTO tt_cntbl_almacen (ALMACEN)
 SELECT distinct(vm.almacen) 
  FROM vale_mov vm, articulo_mov am, almacen a
 WHERE vm.cod_origen = am.cod_origen and
       vm.nro_vale = am.nro_vale and
       vm.almacen = a.almacen and
       vm.flag_estado <> '0' and
      (vm.fec_registro BETWEEN ld_fecha_ini and ld_fecha_fin) and
       am.flag_estado <> '0' and
       a.flag_tipo_almacen = 'M' 
 order by vm.almacen ;
 
For c_al in c_almacen loop
 

     -- Actualizando temporal de articulos, de movimiento rango seleccionado
     INSERT INTO tt_cntbl_articulo
     SELECT distinct(am.cod_art)
     FROM vale_mov vm, articulo_mov am, almacen a
     WHERE vm.cod_origen = am.cod_origen and
       vm.nro_vale = am.nro_vale and
       vm.almacen = a.almacen and
       vm.flag_estado <> '0' and
      (vm.fec_registro BETWEEN ld_fecha_ini and ld_fecha_fin) and
       am.flag_estado <> '0' and
       a.flag_tipo_almacen = 'M' AND
       vm.almacen = c_al.cod_almacen ;
    

    For c_a in c_articulo loop

    ln_total_egr        := 0 ;
    ln_valor_mes_egr    := 0 ;
    ln_total_ing        := 0 ;
    ln_valor_mes_ingr   := 0 ;
    ln_total_compras    := 0 ;
    ln_valor_com_total  := 0 ;
    ln_total_consumos   := 0 ;
    ln_valor_cons_total := 0 ; 

     /****** Se calcula ,Cantidad_Egreso , Valor_egreso , Cantidad_ingresos, Valor_ingreso, *********************/

     SELECT vm.almacen, am.cod_art,
            sum(decode(amt.factor_sldo_total,-1, nvl(am.cant_procesada,0),0)) as Cantidad_Egreso, 
       
       sum(decode(amt.flag_ajuste_valorizacion, '1', 
       decode(amt.factor_sldo_total,-1, nvl(am.precio_unit,0)), 
       decode(amt.factor_sldo_total,-1, nvl(am.precio_unit,0)*nvl(am.cant_procesada,0),0)) ) as Valor_egreso, 
       
       sum(decode(amt.factor_sldo_total,1, nvl(am.cant_procesada,0),0)) as Cantidad_ingresos,
       
       sum(decode(amt.flag_ajuste_valorizacion, '1', 
       decode(amt.factor_sldo_total,1, nvl(am.precio_unit,0)), 
       decode(amt.factor_sldo_total,1, nvl(am.precio_unit,0)*nvl(am.cant_procesada,0),0)) ) as Valor_ingreso, 
       
       sum(decode(vm.tipo_mov,lc_ing_oc, nvl(am.cant_procesada,0),0)) as cant_compra,       
       
       sum(decode(vm.tipo_mov,lc_ing_oc, nvl(am.precio_unit,0)*nvl(am.cant_procesada,0),0)) as Valor_compra,       
       
       sum(decode(vm.tipo_mov,lc_cons_interno, nvl(am.cant_procesada,0),0)) as cant_consumo,       
       
       sum(decode(vm.tipo_mov,lc_cons_interno, nvl(am.precio_unit,0)*nvl(am.cant_procesada,0),0)) as Valor_consumo       
       
       INTO lc_almacen,lc_Articulo,ln_total_egr, ln_valor_mes_egr , ln_total_ing , ln_valor_mes_ingr, ln_total_compras ,
            ln_valor_com_total,  ln_total_consumos , ln_valor_cons_total
       FROM vale_mov vm, articulo_mov am, almacen a, articulo_mov_tipo amt
       WHERE vm.cod_origen = am.cod_origen and
              vm.nro_vale = am.nro_vale and
              vm.almacen = a.almacen and
              vm.tipo_mov = amt.tipo_mov and
              vm.tipo_mov <> 'I12   ' and
              vm.flag_estado <> '0' and
             (vm.fec_registro BETWEEN (ld_fecha_ini) and (ld_fecha_fin)) and
              am.cod_art = c_a.cod_artic  AND
              am.flag_estado <> '0' and
              a.flag_tipo_almacen = 'M' AND
              vm.almacen = c_al.cod_almacen
     group by vm.almacen, am.cod_art ;

      /*--- Calcula  Total Valor Ingreso - Total Valor Egreso----*/
--       ln_sldo_total := ln_total_ing - ln_total_egr ; 
     
      /*---- Calcula Valor de compras - Valor de consumos ----*/
--       ln_valor_saldo_total := nvl(ln_valor_com_total,0) - nvl(ln_valor_cons_total,0);
     
     /* Carga Articulo_saldo_mensual */
     
      INSERT INTO articulo_saldo_mensual (
                  almacen,
                  cod_art,
                  ano,
                  mes,
                  total_mes_ingr,
                  total_mes_egr ,
                  compras_totales,
                  consumos_totales,
                  valor_cons_total,
                  valor_comp_total,
                  valor_mes_egr,
                  valor_mes_ingr)
                  
           VALUES (c_al.cod_almacen, c_a.cod_artic, an_ano, an_mes ,
                   ln_total_ing, ln_total_egr ,
                   ln_total_compras ,ln_total_consumos, 
                   ln_valor_cons_total , ln_valor_com_total ,
                   ln_valor_mes_egr, ln_valor_mes_ingr ); 
                  
   END LOOP ;
   
   DELETE FROM tt_cntbl_articulo;
   
END LOOP ;

--close c_articulo;
commit ;                               
end USP_CNT_ARTICULO_SALDO_inicial;
/
