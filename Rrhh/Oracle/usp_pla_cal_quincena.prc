create or replace procedure usp_pla_cal_quincena
 ( ld_fec_proceso      in adelanto_quincena.fec_proceso%type ,
   ln_adelanto         in adelanto_quincena.imp_adelanto%type ,
   ln_porcentaje       in number ,
   ls_cod_trabajador   in adelanto_quincena.cod_trabajador%type
 ) is

ln_quincena          adelanto_quincena.imp_adelanto%type ;
ls_concepto          concepto.concep%type ;
ls_flag_quincena     concepto.flag_t_pago_quincena%type ;
ln_importe           gan_desct_fijo.imp_gan_desc%type ;
ln_porc_judicial     maestro.porc_judicial%type ;
ls_bonif_30_25       maestro.bonif_fija_30_25%type ;
ls_cta_ahorro        maestro.nro_cnta_ahorro%type ;
ln_imp_control       number(4,2) ;
ls_importe           varchar2(20) ;
ln_contador          number(15) ;

--  Cursor de la tabla Maestro
Cursor c_maestro is 
 Select m.cod_trabajador, m.porc_judicial, m.bonif_fija_30_25,
        m.nro_cnta_ahorro
   From maestro m
   Where m.flag_estado = '1' and
         m.flag_cal_plnlla = '1' and
         m.flag_quincena = '1' and
         m.cod_trabajador = ls_cod_trabajador ;

Cursor c_ganancias is
  Select gdf.concep, gdf.imp_gan_desc
    From gan_desct_fijo gdf
    Where gdf.cod_trabajador = ls_cod_trabajador and
          substr(gdf.concep,1,1) = '1' and
          gdf.flag_estado = '1' and
          gdf.flag_trabaj = '1' ;

begin
  
If ln_adelanto > 0 then

  For c_rm in c_maestro Loop
    Insert into adelanto_quincena
    ( cod_trabajador, concep, 
      fec_proceso   , imp_adelanto )
    Values
    ( ls_cod_trabajador, '2310',
      ld_fec_proceso   , ln_adelanto ) ;
  End Loop ;

Else

  If ln_porcentaje > 0 then

    For c_rm in c_maestro Loop
      ln_quincena      := 0 ;
      ln_contador      := 0 ;
      ln_porc_judicial := c_rm.porc_judicial ;      
      ls_bonif_30_25   := c_rm.bonif_fija_30_25 ;
      ls_cta_ahorro    := c_rm.nro_cnta_ahorro ;
      ln_porc_judicial := nvl(ln_porc_judicial,0) ;
      ls_bonif_30_25   := nvl(ls_bonif_30_25,'0') ;
      ls_cta_ahorro    := nvl(ls_cta_ahorro,' ') ;

      For c_rg in c_ganancias Loop
        ls_concepto := c_rg.concep ;
        ln_importe  := c_rg.imp_gan_desc ;
        ln_importe  := nvl(ln_importe,0) ;
        Select c.flag_t_pago_quincena
          Into ls_flag_quincena
          From concepto c
          Where c.concep = ls_concepto ;
        ls_flag_quincena := nvl(ls_flag_quincena,'0') ;
        If ls_flag_quincena = '1' then
          ln_quincena := ln_quincena + ln_importe ;
        End if ;
      End Loop ;

      ln_quincena := nvl(ln_quincena,0) ;
      --  Calcula 30% o 25%
      If ls_bonif_30_25 = '1' then
        ln_quincena := ln_quincena * 1.30 ;
      Else
        If ls_bonif_30_25 = '2' then
          ln_quincena := ln_quincena * 1.25 ;
        End if ;
      End if;
      ln_quincena := ( ln_quincena * ln_porcentaje ) / 100 ;
      --  Redondeo del adelanto de quincena
      ln_imp_control := 0 ;
      ls_importe     := ' ' ;
      ls_importe     := to_char(ln_quincena,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-5,5)),'99.99') ;
      If ln_imp_control < 25.00 then
        ln_quincena := ln_quincena - ln_imp_control ;
      Elsif ln_imp_control >= 25.00 and ln_imp_control < 75.00 then
        ln_quincena := (ln_quincena - ln_imp_control) + 50.00 ;
      Elsif ln_imp_control >= 75.00 then
        ln_quincena := (ln_quincena - ln_imp_control) + 100.00 ;
      End if ;
      --  No paga adelanto de quincena
      If ln_porc_judicial > 0 then
        ln_quincena := 0 ;
      Elsif ls_cta_ahorro = ' ' then
        ln_quincena := 0 ;
      End if ;
      ln_contador := 0 ;
      Select count(*)
        Into ln_contador
        From diferido d
        Where d.cod_trabajador = ls_cod_trabajador and
              d.fec_proceso = add_months(ld_fec_proceso,-1) ;
      If ln_contador > 0 then
        ln_quincena := 0 ;
      End if ;
      --  Inserta registros
      If ln_quincena > 0 then
        Insert into adelanto_quincena
        ( cod_trabajador, concep, 
          fec_proceso   , imp_adelanto )
        Values
        ( ls_cod_trabajador, '2310',
          ld_fec_proceso   , ln_quincena ) ;
      End if ;
    End Loop ;
    
  End if ;
End if ;

end usp_pla_cal_quincena ;
/
