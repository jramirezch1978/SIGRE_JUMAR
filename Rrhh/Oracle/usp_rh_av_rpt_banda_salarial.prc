create or replace procedure usp_rh_av_rpt_banda_salarial (
  an_ano in number, an_mes in number ) is

lk_administrativo      constant char(3) := 'ADM' ;
lk_operativo           constant char(3) := 'OPE' ;
lk_objetivo            constant char(3) := 'OBJ' ;
lk_desempeno           constant char(3) := 'DES' ;

ln_verifica            integer ;
ln_imp_adm             number(13,2) ;
ln_imp_ope             number(13,2) ;
ln_por_obj             number(5,3) ;
ln_por_des             number(5,3) ;

--  Lectura de bandas salariales
cursor c_banda_salarial is
  select bs.banda, bs.descripcion
  from rrhh_banda_salarial bs
  where bs.flag_estado = '1'
  order by bs.banda ;

begin

--  ***********************************************************
--  ***   GENERA REPORTE DE BANDAS SALARIALES POR NIVELES   ***
--  ***********************************************************

delete from tt_av_rpt_banda_salarial ;

for rc_ban in c_banda_salarial loop

  ln_imp_adm := 0 ; ln_imp_ope := 0 ;
  ln_por_obj := 0 ; ln_por_des := 0 ;
    
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_tope t
    where t.banda = rc_ban.banda and t.contra = lk_administrativo ;
  if ln_verifica > 0 then
    select nvl(t.tope,0) into ln_imp_adm from rrhh_banda_salarial_tope t
      where t.banda = rc_ban.banda and t.contra = lk_administrativo ;
  end if ;
      
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_tope t
    where t.banda = rc_ban.banda and t.contra = lk_operativo ;
  if ln_verifica > 0 then
    select nvl(t.tope,0) into ln_imp_ope from rrhh_banda_salarial_tope t
      where t.banda = rc_ban.banda and t.contra = lk_operativo ;
  end if ;
    
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_distrib d
    where d.banda = rc_ban.banda and d.calif_tipo = lk_objetivo ;
  if ln_verifica > 0 then
    select nvl(d.porcentaje,0) into ln_por_obj from rrhh_banda_salarial_distrib d
      where d.banda = rc_ban.banda and d.calif_tipo = lk_objetivo ;
  end if ;
        
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_distrib d
    where d.banda = rc_ban.banda and d.calif_tipo = lk_desempeno ;
  if ln_verifica > 0 then
    select nvl(d.porcentaje,0) into ln_por_des from rrhh_banda_salarial_distrib d
      where d.banda = rc_ban.banda and d.calif_tipo = lk_desempeno ;
  end if ;

  insert into tt_av_rpt_banda_salarial (
    codigo, descripcion, imp_adm, imp_ope,
    por_obj, por_des )
  values (    
    rc_ban.banda, rc_ban.descripcion, ln_imp_adm, ln_imp_ope,
    ln_por_obj, ln_por_des ) ;

end loop ;

end usp_rh_av_rpt_banda_salarial ;
/
