create or replace function USF_PLA_CAL_TIPO_CAMBIO(
  ad_fec_proceso  in date
  ) return number is

  ln_tipcam   calendario.vta_dol_prom%type ;
  ln_contador number(2) ;
  
begin

-- Determina el tipo de cambio del dolar
ln_contador := 0 ;
Select count(*)
  into ln_contador
  from calendario c
  where c.fecha = ad_fec_proceso ;
ln_contador := nvl(ln_contador,0) ;
If ln_contador > 0 then
Select c.vta_dol_prom
  into ln_tipcam
  from calendario c
  where c.fecha = ad_fec_proceso ;
End if ;
ln_tipcam := nvl( ln_tipcam,0) ;
return(ln_tipcam) ;
  
end USF_PLA_CAL_TIPO_CAMBIO ;
/
