create or replace procedure usp_sunat600
 ( ad_fec_proceso in control.fec_proceso%type,
   as_codemp in empresa.cod_empresa%type 
   )
 is

--Variables de Procedimiento
lk_con_dias_trab constant char(4):='1001';--Concepto Dias Trab
lk_ganan constant char(1):='1'; 
lk_con_quinta constant char(4):='2010';--Conce de Quinta Categ 
ls_dni maestro.dni%type;
ln_dias calculo.dias_trabaj%type;
ls_dias char(6);
ls_nro_afp admin_afp.cod_afp%type;
ln_imp_essalud_emp  calculo.imp_soles%type;
ls_imp_essalud_emp char(15);
ln_snp_no_afp calculo.imp_soles%type;
ls_snp_no_afp char(15);
ln_snp_afp calculo.imp_soles%type;
ls_snp_afp char(15);
ls_artista char(15);   --Importe a pagar a los artistas
ln_imp_quinta calculo.imp_soles%type;
ls_imp_quinta char(15);
ln_desc_quinta number(15);
ls_desc_quinta char(15);
ls_sunat char(110);
 
--Cursor de Trabaj de la Tabla Calculo
Cursor c_trabaj is 
 select distinct c.cod_trabajador
 from calculo c, maestro m
 where m.cod_trabajador = c.cod_trabajador and 
       m.cod_empresa = as_codemp;

begin
--Lecture del Cursor
For rc_t in c_trabaj Loop
  --Obtenemos su DNI
  select m.dni
   into ls_dni
   from maestro m 
  where m.cod_trabajador = rc_t.cod_trabajador;
        ls_dni:=nvl(ls_dni,' ');

  --Los dias trabajados 
  select  c.dias_trabaj 
   into ln_dias
   from calculo c
  where c.concep = lk_con_dias_trab and 
        c.cod_trabajador = rc_t.cod_trabajador;
  ls_dias:=TO_CHAR(ln_dias);
        
  --Las ganancias de trabajadores que poseen flag
  --de f_e_essalud       
  select sum(c.imp_soles)
   into ln_imp_essalud_emp
   from calculo c
  where SUBSTR(c.concep,1,1) =  lk_ganan and 
        c.flag_e_essalud = '1' and
        c.cod_trabajador = rc_t.cod_trabajador ;
  ls_imp_essalud_emp:=TO_CHAR(ln_imp_essalud_emp);
     
  --Las ganancias de Trabaj que estan afectos al flag de 
  --snp f_t_snp, pero que no esten en una afp     
  select m.nro_afp_trabaj
   into ls_nro_afp
   from maestro m
  where m.cod_trabajador = rc_t.cod_trabajador ;
  
  If ls_nro_afp is null or ls_nro_afp=' ' Then
     select sum(c.imp_soles)
       into ln_snp_no_afp
       from calculo c
     where c.cod_trabajador = rc_t.cod_trabajador and
           SUBSTR(c.concep,1,1) = lk_ganan and  
           c.flag_t_snp = '1' ;
    ls_snp_no_afp:=TO_CHAR(ln_snp_no_afp);      
  Else 
    ls_snp_no_afp:=' ';
  End if;     
   --Las ganancias de Trabaj que estan afectas al flag de 
   --snp f_t_snp, incluidos las afp
  select sum(c.imp_soles)
   into ln_snp_afp
   from calculo c
  where c.cod_trabajador = rc_t.cod_trabajador and
        SUBSTR(c.concep,1,1) = lk_ganan and  
        c.flag_t_snp = '1' ;
  ls_snp_afp:=TO_CHAR(ln_snp_afp); 
  ls_artista:=' ';
  
  --Ganancias afectas a 5ta Categoria por el Flag de 
  --de f_t_quinta_categroia
  select sum(c.imp_soles)
   into ln_imp_quinta
   from calculo c 
  where c.cod_trabajador = rc_t.cod_trabajador and 
        SUBSTR(c.concep,1,1) = lk_ganan and 
        c.flag_t_quinta = '1';
  ls_imp_quinta:=TO_CHAR(ln_imp_quinta);      
  --Retencion de 5ta Categoria, deacuerdo al concepto  
  --de Quinta Categoria.
  select sum(c.imp_soles)
   into ln_desc_quinta
   from calculo c
  where  c.cod_trabajador = rc_t.cod_trabajador and
         c.concep = lk_con_quinta ;
  ls_desc_quinta:=TO_CHAR(ln_desc_quinta);  
   
  --Uniendo la informacion 
  ls_sunat:='1'||'|'||RPAD(ls_dni,15,' ')||'|'||ls_dias||
            '|'||RPAD(ls_imp_essalud_emp,15,' ')||'|'||
            RPAD(ls_snp_no_afp,15,' ')||'|'||RPAD(ls_snp_afp,
            15,' ')||'|'||RPAD(ls_artista,15,' ')||'|'||
            RPAD(ls_imp_quinta,15,' ')||'|'||RPAD(ls_desc_quinta,
            15,' ')||'|';
  
  insert into tt_sunat600(col_sunat)
  values (ls_sunat);
  
  END LOOP;
  
end usp_sunat600;
/
