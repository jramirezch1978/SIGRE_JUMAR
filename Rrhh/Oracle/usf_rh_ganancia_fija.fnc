create or replace function usf_rh_ganancia_fija (
  as_cod_trabajador in maestro.cod_trabajador%type )
  return varchar2 is

ln_monto number ;

begin

select sum(g.imp_gan_desc) 
into ln_monto 
from gan_desct_fijo g
where g.cod_trabajador=as_cod_trabajador 
  and substr(g.concep,1,1)='1' ;

  return(ln_monto) ;

end usf_rh_ganancia_fija;
/
