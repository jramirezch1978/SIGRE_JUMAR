--drop table tt_eval_desempeno_det

create global temporary table tt_eval_desempeno_det
(
 cod_trabajador char(8),
 cod_competencia char(3),
 desc_competencia varchar2(25),
 cod_comport char(5),
 desc_comport varchar2(400),
 puntaje number(2)
 );

