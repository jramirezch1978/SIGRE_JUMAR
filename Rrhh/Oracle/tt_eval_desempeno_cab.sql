--drop table tt_eval_desempeno_cab

create global temporary table tt_eval_desempeno_cab
(
 cod_trabajador char(8) primary key,
 nom_trabajador char(120),
 cod_area char(1),
 desc_area varchar2(30),
 cod_cargo char(8),
 desc_cargo varchar2(30),
 fecha date
 );


