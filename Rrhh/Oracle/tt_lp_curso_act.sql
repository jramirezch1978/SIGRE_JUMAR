create global temporary table tt_lp_curso_act
(
 cod_trabajador         char(8),
 desc_curso             varchar2(50),
 tema                   varchar2(50),
 nom_expositor          varchar2(30),
 nom_entidad            varchar2(30),
 direccion              varchar2(100),
 nro_horas              number(5,2),
 fec_expos              date,   
 flg_int_ext            char(1)
 ) ;
