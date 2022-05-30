create or replace function USF_RH_REM_BRUTA(
       asi_codtra in maestro.cod_trabajador%TYPE,
       adi_fecha1 in date,
       adi_fecha2 in date
) return number is
  ln_Result number := 0;
begin
  select NVL(sum(NVL(b.cant_producida,0) * NVL(a.precio_unit,0)),0)
    into ln_Result
    from tg_pd_destajo a,
         tg_pd_destajo_det b
   where a.nro_parte = b.nro_parte
     and b.cod_trabajador = asi_codtra
     and trunc(a.fec_parte) between trunc(adi_fecha1) and trunc(adi_fecha2);
  return(ln_Result);
end USF_RH_REM_BRUTA;
/
