create or replace procedure usp_rpt_deposito_cts
( ad_fec_proceso   in date ) is

ls_codigo         maestro.cod_trabajador%type ;
ls_nombres        varchar2(40) ;
ls_seccion        maestro.cod_seccion%type ;
ls_desc_seccion   varchar2(40) ;
ls_cencos         maestro.cencos%type ;
ls_desc_cencos    varchar2(40) ;
ln_imp_cts        prov_cts_gratif.prov_cts_01%type ;
ln_dias           number(6,2) ;

--  Cursor para leer todos los activos del maestro
cursor c_maestro is 
  Select m.cod_trabajador, m.cod_seccion, m.cencos
  from maestro m
  where m.flag_estado     = '1' and
        m.flag_cal_plnlla = '1'
  order by m.cod_seccion, m.cod_trabajador ;

--  Cursor para leer provisiones de C.T.S.
cursor c_provision is 
  Select p.cod_trabajador, p.dias_trabaj,
         p.prov_cts_01, p.prov_cts_02, p.prov_cts_03,
         p.prov_cts_04, p.prov_cts_05, p.prov_cts_06
  from prov_cts_gratif p
  where p.cod_trabajador = ls_codigo ;

begin

delete from tt_rpt_deposito_cts ;

For rc_mae in c_maestro Loop

  ls_codigo   := rc_mae.cod_trabajador ;
  ls_seccion  := rc_mae.cod_seccion ;
  ls_cencos   := rc_mae.cencos ;
  ls_nombres  := usf_nombre_trabajador(ls_codigo) ;
       
  If ls_seccion  is not null Then
    Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
  Else 
    ls_seccion := '0' ;
  End if ;
  ls_desc_seccion := nvl(ls_desc_seccion,' ') ;

  If ls_cencos is not null then
    Select cc.desc_cencos
    into ls_desc_cencos
    from centros_costo cc
    where cc.cencos = ls_cencos ;
  Else
    ls_cencos := '0' ;
  End if ;
  ls_desc_cencos := nvl(ls_desc_cencos,' ') ;
  
  For rc_pro in c_provision Loop

    ln_dias    := rc_pro.dias_trabaj ;
    ln_imp_cts := rc_pro.prov_cts_01 + rc_pro.prov_cts_02 +
                  rc_pro.prov_cts_03 + rc_pro.prov_cts_04 +
                  rc_pro.prov_cts_05 + rc_pro.prov_cts_06 ;
    ln_dias    := nvl(ln_dias,0) ;
    ln_imp_cts := nvl(ln_imp_cts,0) ;

    --  Insertar los Registro en la tabla tt_rpt_deposito_cts
    If ln_imp_cts <> 0 then
      Insert into tt_rpt_deposito_cts
        (codigo, nombres, cod_seccion,
         desc_seccion, cencos, desc_cencos,
         imp_cts, dias, fecha_proceso)
      Values
        (ls_codigo, ls_nombres, ls_seccion,
         ls_desc_seccion, ls_cencos, ls_desc_cencos,
         ln_imp_cts, ln_dias, ad_fec_proceso) ;
    End if ;

  End loop ;     

End loop ;

End usp_rpt_deposito_cts ;
/
