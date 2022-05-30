create or replace procedure usp_rh_cal_add_diferi_quincena (
       asi_codtra       in maestro.cod_trabajador%TYPE,
       asi_codusr       in usuario.cod_usr%TYPE,
       adi_fec_proceso  in date,
       asi_doc_autom    in doc_tipo.tipo_doc%TYPE
) is

lk_horas_permiso     grupo_calculo.grupo_calculo%TYPE ;
lk_desct_permiso     grupo_calculo.grupo_calculo%TYPE ;

ln_count             number ;


--  Lectura de adelanto de remuneraciones
cursor c_quincena is
  select aq.cod_trabajador, aq.concep, aq.fec_proceso, aq.imp_adelanto
    from adelanto_quincena aq
   where aq.cod_trabajador = asi_codtra
     and nvl(aq.imp_adelanto,0) <> 0
     and to_char(aq.fec_proceso, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm');

begin

select c.hora_permiso_part, c.descto_perm_part
  into lk_horas_permiso, lk_desct_permiso
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

-- Elimino los conceptos de Adelanto de Quincena de
-- Las Ganancias y descuentos fijos
delete gan_desct_variable t
 where t.cod_trabajador = asi_codtra
   and t.concep in ( select distinct aq.concep
                       from adelanto_quincena aq
                      where aq.cod_trabajador = asi_codtra
                        and nvl(aq.imp_adelanto,0) <> 0
                        and trunc(aq.fec_proceso) = trunc(adi_fec_proceso));

--  *************************************************************
--  ***   ADICIONA MOVIMIENTO DE ADELANTO DE REMUNERACIONES   ***
--  *************************************************************
for rc_qui in c_quincena loop
    select count(*)
      into ln_count
      from gan_desct_variable g
     where g.cod_trabajador = asi_codtra
       and g.fec_movim      = rc_qui.fec_proceso
       and g.concep         = rc_qui.concep ;

    if ln_count > 0 then
       update gan_desct_variable
          set imp_var = rc_qui.imp_adelanto,
              flag_replicacion = '1'
        where cod_trabajador = asi_codtra
          and fec_movim      = rc_qui.fec_proceso
          and concep         = rc_qui.concep ;
    else
       insert into gan_desct_variable (
              cod_trabajador, fec_movim, concep, imp_var,
              cod_usr, tipo_doc, flag_replicacion )
       values (
              asi_codtra , rc_qui.fec_proceso, rc_qui.concep, rc_qui.imp_adelanto,
              asi_codusr, asi_doc_autom, '1' ) ;
    end if ;
end loop ;

end usp_rh_cal_add_diferi_quincena ;
/
