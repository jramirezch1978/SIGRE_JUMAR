create or replace procedure usp_pla_cal_cta_cte_post01
   (   as_codtra maestro.cod_trabajador%type ,
       as_tipdoc cnta_crrte.tipo_doc%type,
       as_nrodoc cnta_crrte.nro_doc%type,
       ad_fec_proceso control.fec_proceso%type,
       an_imp_dscto cnta_crrte_detalle.imp_dscto%type
       ) is

ln_id cnta_crrte_detalle.nro_dscto%type;
       
begin
--Creamos una coluimna secuencial Cnta_Crrte_Detalle 
select max(ccd.nro_dscto)
into ln_id
from cnta_crrte_detalle ccd;

--aumentamos en uno para el ln_id
ln_id := ln_id + 1;

insert into cnta_crrte_detalle
  (cod_trabajador  , tipo_doc   ,
   nro_doc         , nro_dscto  ,
   fec_dscto       , imp_dscto  )
values
  (as_codtra       , as_tipdoc  ,
   as_nrodoc       , ln_id      ,
   ad_fec_proceso  , an_imp_dscto );
  
end usp_pla_cal_cta_cte_post01;
/
