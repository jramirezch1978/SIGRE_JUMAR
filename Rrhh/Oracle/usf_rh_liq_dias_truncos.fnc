create or replace function usf_rh_liq_dias_truncos (
  ad_fec_desde in date, ad_fec_hasta in date ) return number is

ld_fec_inicio           date ;
ln_sw                   integer ;
ln_nro_dias             number(5,2) ;
ln_dias                 number(5,2) ;

begin

--  **********************************************************************
--  ***   CALCULA DIAS TRUNCAS - C.T.S. VACACIONES Y GRATIFICACIONES   ***
--  **********************************************************************

ld_fec_inicio := trunc(ad_fec_desde) ;

ln_sw := 0 ; ln_nro_dias := 0 ;

for x in 1 .. 100 loop

  if to_char(ld_fec_inicio,'mm/yyyy') = to_char(ad_fec_hasta,'mm/yyyy') then
    if to_number(to_char(ad_fec_hasta,'dd')) >= to_number(to_char(ld_fec_inicio,'dd')) and
       ln_sw = 0 then
      if to_number(to_char(ad_fec_hasta,'dd')) > 30 then
        ln_dias := 30 ;
      elsif to_char(ad_fec_hasta,'dd/mm') = '29/02' then
        ln_dias := 30 ;
      elsif to_char(ad_fec_hasta,'dd/mm') = '28/02' then
        ln_dias := 30 ;
      else
        ln_dias := to_number(to_char(ad_fec_hasta,'dd')) ;
      end if ;
      ln_nro_dias := ln_nro_dias + ( ln_dias - to_number(to_char(ld_fec_inicio,'dd')) ) + 1 ;
    else
      if to_number(to_char(ad_fec_hasta,'dd')) > 30 then
        ln_dias := 30 ;
      else
        ln_dias := to_number(to_char(ad_fec_hasta,'dd')) ;
      end if ;
      ln_nro_dias := ln_nro_dias +  ln_dias ;
    end if ;
    exit ;
  end if ;

  if ln_sw = 0 then
    if to_char(ld_fec_inicio,'dd') = '01' then
      ln_nro_dias := 30 ;
    else
      ln_nro_dias := ( 30 - to_number(to_char(ld_fec_inicio,'dd')) ) + 1 ;
    end if ;
    ln_sw := 1 ;
  else
    ln_nro_dias := ln_nro_dias + 30 ;
  end if ;

  ld_fec_inicio := add_months(ld_fec_inicio,1) ;

end loop ;

return(ln_nro_dias) ;

end usf_rh_liq_dias_truncos ;
/
