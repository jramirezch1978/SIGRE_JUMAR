create or replace procedure usp_pla_cal_pre_des02(
   as_codtra      in maestro.cod_trabajador%type, 
   as_codusr      in usuario.cod_usr%type,
   ad_fec_proceso in rrhhparam.fec_proceso%type,
   ad_feriado1    in rrhhparam.dia_feriado1%type,
   ad_feriado2    in rrhhparam.dia_feriado2%type,
   ad_feriado3    in rrhhparam.dia_feriado3%type,
   ad_feriado4    in rrhhparam.dia_feriado4%type,
   ad_feriado5    in rrhhparam.dia_feriado5%type
   ) is

   --  Busca conceptos de ganancias fijas
   lk_inasist constant char(3) := '040' ; 
   lk_gan_fij constant char(3) := '041' ; 

   ld_ran_ini        rrhhparam.fec_desde%type;
   ld_ran_fin        rrhhparam.fec_desde%type;
   ls_bonificacion   maestro.bonif_fija_30_25%type;

   Cursor c_inasist  is 
   Select i.fec_movim, i.fec_desde, i.fec_hasta, i.dias_inasist
     from inasistencia i
     where i.cod_trabajador = as_codtra 
           and ( i.fec_movim between ld_ran_ini 
           and ld_ran_fin )
           and i.concep in (
           Select rhpd.concep
             from rrhh_nivel_detalle rhpd
             where rhpd.cod_nivel = lk_inasist) ;

   ls_concep   concepto.concep%type;
   ln_faltas   number(7,2); 
   ld_falta    date;        
   ld_fecha_d  date;
   ln_dias     inasistencia.dias_inasist%type;
   ln_valor    gan_desct_fijo.imp_gan_desc%type;
   ls_cencos   maestro.cencos%type;
   ln_contador number(15);
   
begin

--  Determina rangos de generacion
Select rh.fec_desde, rh.fec_hasta
  into ld_ran_ini, ld_ran_fin
  from rrhhparam rh
  where rh.reckey = '1' ;
      
ln_faltas := 0 ; ln_dias := 0 ;
For rc_ina in c_inasist Loop
--  ln_dias  := rc_ina.fec_hasta - rc_ina.fec_desde + 1 ;
  ln_dias    := rc_ina.dias_inasist ;
  ld_fecha_d := rc_ina.fec_movim ;
  For x in 1 .. ln_dias Loop
    ld_falta := rc_ina.fec_desde + x - 1 ;
    If ld_falta = ld_fecha_d then
      ln_faltas := ln_faltas + ln_dias ;
    End if ;
    If ld_falta < ad_feriado1 or ld_falta < ad_feriado2 or 
      ld_falta < ad_feriado3 or ld_falta < ad_feriado4 or 
      ld_falta < ad_feriado5 Then
      ln_faltas := ln_faltas + 1 ;
    End If;
  End Loop ;
End Loop ;
   
Select sum(gdf.imp_gan_desc)
  into ln_valor
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = as_codtra 
        and gdf.flag_estado = '1'
        and gdf.flag_trabaj = '1'
        and gdf.concep in (
        Select rhpd.concep
          from rrhh_nivel_detalle rhpd
          where rhpd.cod_nivel = lk_gan_fij ) ;
  ln_valor := nvl( ln_valor, 0 ) ;
  ln_faltas := nvl( ln_faltas, 0 ) ;
   
Select m.bonif_fija_30_25
  into ls_bonificacion
  from maestro m
  where m.cod_trabajador = as_codtra and
        m.flag_estado = '1' ;
  ls_bonificacion := nvl( ls_bonificacion, ' ' ) ;
/*
If ls_bonificacion = '1' then
  ln_valor := ln_valor * 1.30 ;
Elsif ls_bonificacion = '2' then
  ln_valor :=  ln_valor * 1.25 ;
End if ;
*/
  If ln_faltas > 0 and ln_faltas < 30 Then 
      
    Select rhpn.concep
      into ls_concep
      from rrhh_nivel rhpn
      where rhpn.cod_nivel = lk_inasist  ;
      
    Select m.cencos
      into ls_cencos
      from maestro m
      where m.cod_trabajador = as_codtra ;

    --  El concepto 2304 dice a la letra:
    --  " Se descuenta 1/30 avo de la remuneracion diaria "
    ln_valor := ln_valor / 30 / 30 * ln_faltas ;
      
    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from gan_desct_variable gdv
      where gdv.cod_trabajador = as_codtra and
            gdv.concep = ls_concep ;
    ln_contador := nvl(ln_contador,0) ;
    If ln_contador > 0 then
      Update gan_desct_variable
      Set imp_var = imp_var + ln_valor
      where cod_trabajador = as_codtra and
            concep = ls_concep ;
    Else
      Insert into gan_desct_variable 
        ( cod_trabajador, fec_movim  , concep, 
          nro_doc       , imp_var    , cencos, 
          cod_labor     , cod_usr    , proveedor,
          tipo_doc ) 
      Values ( as_codtra , ad_fec_proceso, ls_concep,
          'autom'        , ln_valor  , ls_cencos ,
          ''  , ''       , ''              , 
          'auto' );
    End if ;
    
  End if ;

End usp_pla_cal_pre_des02;
/
