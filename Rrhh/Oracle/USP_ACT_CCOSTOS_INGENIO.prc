create or replace procedure USP_ACT_CCOSTOS_INGENIO is

ls_cencos_new    char(10) ;
ln_contador      integer ;

-- Actualiza MAESTRO
cursor c_maestro is
  select t.cod_trabajador, t.cencos
  from maestro t
  where nvl(t.cencos,' ') <> ' '
  order by t.cod_trabajador ;

BEGIN

FOR rc_c in c_maestro loop

  ln_contador := 0 ;
  select count(*)
    into ln_contador from tt_cc_ingenio i
    where rtrim(i.old) = rtrim(rc_c.cencos) ;

  if ln_contador > 0 then

    select rtrim(i.new)
      into ls_cencos_new from tt_cc_ingenio i
      where rtrim(i.old) = rtrim(rc_c.cencos) ;

    UPDATE MAESTRO SET cencos = ls_cencos_new     
    WHERE cod_trabajador = rc_c.cod_trabajador ;

  else

    raise_application_error(-20000, 'Centro de Costo  '||rc_c.cencos||
    '  NO EXISTE') ;
  
  end if ;
     
END LOOP ;

end USP_ACT_CCOSTOS_INGENIO;







/*
create or replace procedure USP_ACT_CCOSTOS_INGENIO is

ls_cc_old char(10);
ls_cc_new char(10);


-- Actualiza MAESTRO
CURSOR  c_cb is
select t.cencos
from maestro t where t.cencos in(
select cc.cencos from centros_costo cc 
where cc.flag_tipo='X')
group by t.cencos;

BEGIN

FOR rc_c in c_cb loop
     -- Ubica equivalencia    
     
     ls_cc_old := Trim(rc_c.cencos);
    
     SELECT cc.new INTO ls_cc_new
     FROM TT_CC_INGENIO CC
     WHERE cc.Old = ls_cc_old ;

     -- Actualiza tabla
--     UPDATE MAESTRO SET cencos = ls_cc_new     
--     WHERE cod_trabajador = rc_c.cod_trabajador;
     
     
END LOOP ;




end USP_ACT_CCOSTOS_INGENIO;








*/
/
