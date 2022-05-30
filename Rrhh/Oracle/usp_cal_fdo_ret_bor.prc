create or replace procedure usp_cal_fdo_ret_bor (
  ad_fec_proceso in date ) is
  
ls_mes         char(2) ;
ls_year        char(4) ;

begin

ls_mes  := to_char(ad_fec_proceso, 'MM') ;
ls_year := to_char(ad_fec_proceso, 'YYYY') ;
 
--  Elimina registros mensuales del fondo de retiro
delete from fondo_retiro fr
  where to_char(fr.fec_proceso, 'MM')   = ls_mes and
        to_char(fr.fec_proceso, 'YYYY') = ls_year ;

commit ;
    
end usp_cal_fdo_ret_bor ;
/
