create or replace procedure usp_rpt_inasistencia
 ( ad_mes in inasistencia.fec_movim%type 
  ) is
 --Definicion de variables de Entrada 
 ls_cod_trabajador varchar2(8);
 ls_concep char;
 ld_fec_movim date;
 ln_dias_inasist number:=0;
 ls_nombre  varchar2(100);
 
 --Creacion de un Cursor para la Inasistencia
 cursor c_inasistencia is 
  select cod_trabajador, concep,
         fec_movim, dias_inasist
  from inasistencia
  where TO_CHAR(fec_movim,'MM') = TO_CHAR(ad_mes,'MM')
  order by cod_trabajador ;
 
 begin 
     for rc_inasistencia in c_inasistencia LOOP
         IF rc_inasistencia.concep in ('1401','1402','1413','1414','1415','1421',
                                        '2401','2402','2304') then
            ls_nombre:=usf_nombre_trabajador(rc_inasistencia.cod_trabajador) ;
            insert into tt_rpt_inasistencia
              ( cod_trabajador                , nombre,
                concep                        , fec_movim,
                dias_inasist)
            values
              ( rc_inasistencia.cod_trabajador, ls_nombre,
               rc_inasistencia.concep         , rc_inasistencia.fec_movim,
               rc_inasistencia.dias_inasist);
         END IF;
     end loop;
     COMMIT;
 end usp_rpt_inasistencia;
/
