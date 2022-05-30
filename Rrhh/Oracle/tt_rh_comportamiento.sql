--drop table tt_rh_comportamiento

create global temporary table tt_rh_comportamiento
(
cod_competencia             char(3),
cod_comport                 char(5),
desc_competencia            varchar2(25),
desc_comport                varchar2(400)
 ) ;
