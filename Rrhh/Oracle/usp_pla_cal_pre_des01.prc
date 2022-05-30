create or replace procedure usp_pla_cal_pre_des01(
   as_codtra      in maestro.cod_trabajador%type,
   as_codusr      in usuario.cod_usr%type,
   ad_fec_proceso in rrhhparam.fec_proceso%type,
   an_imp_sindic  in rrhhparam.imp_sindic_obre%type
   ) is

   --  Busca concepto de sindicato
   lk_sin_emplea     constant char(3) := '030' ;
   lk_sin_obrero     constant char(3) := '031' ;

   ls_tiptra         maestro.tipo_trabajador%type;
   ls_flag_sindicato maestro.flag_sindicato%type;
   ls_concep         concepto.concep%type;
   ls_cencos         maestro.cencos%type;
   ls_cod_nivel      char(3);
   ln_registro       number(15) ;

begin

Select m.flag_sindicato, m.tipo_trabajador, m.cencos
  into ls_flag_sindicato, ls_tiptra, ls_cencos
  from maestro m
  where m.cod_trabajador = as_codtra and
        m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' ;
ls_flag_sindicato := nvl( ls_flag_sindicato, '0' ) ;
ls_tiptra         := nvl( ls_tiptra, 'EMP' ) ;

If ls_flag_sindicato = '1' Then
  If ls_tiptra = 'EMP' Then
    ls_cod_nivel := lk_sin_emplea;
  Else
    ls_cod_nivel := lk_sin_obrero;
  End if;

  Select rhpn.concep
    into ls_concep
    from rrhh_nivel rhpn
    where rhpn.cod_nivel = ls_cod_nivel;
  ls_concep := nvl( ls_concep, 'ds01' );

  ln_registro := 0 ;
  Select count(*)
    Into ln_registro
    From gan_desct_variable gdv
    Where gdv.cod_trabajador = as_codtra and
          gdv.fec_movim = ad_fec_proceso and
          gdv.concep = ls_concep ;

  If ln_registro > 0 then

     Update gan_desct_variable
       Set imp_var = imp_var + an_imp_sindic
     Where cod_trabajador = as_codtra and
           fec_movim = ad_fec_proceso and
           concep = ls_concep ;
  Else
     Insert into gan_desct_variable
       ( cod_trabajador, fec_movim  , concep,
         nro_doc       , imp_var    , cencos,
         cod_labor     , cod_usr    , proveedor,
         tipo_doc )
     Values ( as_codtra  , ad_fec_proceso, ls_concep,
         'autom'         , an_imp_sindic , ls_cencos ,
         ''  , ''        , ''            ,
         'auto' );
  End if ;

End If;

End usp_pla_cal_pre_des01;
/
