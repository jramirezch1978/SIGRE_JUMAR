create or replace procedure usp_cal_sunat600
 ( ad_fec_proceso   in rrhhparam.fec_proceso%type , 
   as_codemp        in empresa.cod_empresa%type ) is
 
ls_dni                char(15) ;
ls_cod_afp            maestro.cod_afp%type ;
lk_con_quinta         constant char(4) := '2010' ;
ln_dias               number(2) ;
ls_dias               char(2) ;
ln_imp_essalud_emp    number(15) ;
ls_imp_essalud_emp    char(15) ;
ln_imp_snp_no_afp     number(15) ;
ls_imp_snp_no_afp     char(15) ;
ln_imp_snp_afp        number(15) ;
ls_imp_snp_afp        char(15) ;
ls_imp_artista        char(15) ;
ln_imp_quinta         number(15) ;
ls_imp_quinta         char(15) ;
ln_desc_quinta        number(15) ;
ls_desc_quinta        char(15) ;

ls_sunat              char(117) ;
ls_cod_trab           maestro.cod_trabajador%type ;
ls_tipo_trab          maestro.tipo_trabajador%type ;
ln_dias_mes           rrhhparam.dias_mes_obrero%type ;
  
Cursor c_trabaj is 
  select distinct c.cod_trabajador
  from calculo c, maestro m 
  where m.cod_trabajador = c.cod_trabajador and
        m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and
        m.cod_empresa = as_codemp ;
        
begin

--  Elimina informacion de la tabla temporal
delete from tt_sunat600 ;
        
For rc_t in c_trabaj Loop 

  Select nvl(m.dni,' '), nvl(m.cod_afp,' '),
         nvl(m.tipo_trabajador,' ')
    into ls_dni, ls_cod_afp, ls_tipo_trab  
    from maestro m
    where m.cod_trabajador = rc_t.cod_trabajador ;
/*          
  If ls_tipo_trab = 'EMP' Then
    ln_dias_mes := 30 ;
  Elsif ls_tipo_trab = 'OBR' Then
    ln_dias_mes := 31 ;
  End if ;
*/

  if to_char(ad_fec_proceso,'MM') = '01' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 31 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '02' then
    ln_dias_mes := to_number(to_char(ad_fec_proceso,'DD')) ;
  elsif to_char(ad_fec_proceso,'MM') = '03' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 31 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '04' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 30 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '05' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 31 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '06' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 30 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '07' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 31 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '08' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 31 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '09' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 30 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '10' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 31 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '11' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 30 ;
    end if ;
  elsif to_char(ad_fec_proceso,'MM') = '12' then
    if ls_tipo_trab = 'EMP' Then
      ln_dias_mes := 30 ;
    elsif ls_tipo_trab = 'OBR' Then
      ln_dias_mes := 31 ;
    end if ;
  end if ;



         
  ls_cod_trab := rc_t.cod_trabajador ;
  ln_dias     := usf_pla_cal_dia_tra_sun(ls_cod_trab,ln_dias_mes) ;
  ls_dias     := to_char(ln_dias) ;
  
  --  Suma importe afecto a essalud
  Select sum(c.imp_soles)
    into ln_imp_essalud_emp
    from calculo c
    where c.cod_trabajador = rc_t.cod_trabajador and 
          substr(c.concep,1,1) = '1' and
          to_char(c.fec_proceso,'MM')= to_char(ad_fec_proceso,'MM') and
          c.flag_e_essalud = '1' ;
  ln_imp_essalud_emp := nvl(ln_imp_essalud_emp,0) ;
        
  If ln_imp_essalud_emp > 0 then

    ls_imp_essalud_emp := to_char(ln_imp_essalud_emp) ;
    --  Suma importe afecto al S.N.P.
    If ls_cod_afp = '  ' then
      Select sum(c.imp_soles)
        into  ln_imp_snp_no_afp
        from calculo c
        where c.cod_trabajador = rc_t.cod_trabajador and 
              substr(c.concep,1,1) = '1' and 
              to_char(c.fec_proceso,'MM')= to_char(ad_fec_proceso,'MM') and 
              c.flag_t_snp = '1' ;
      ls_imp_snp_no_afp := to_char(ln_imp_snp_no_afp) ;
      ls_imp_snp_no_afp := nvl(ls_imp_snp_no_afp,' ') ;
    Else
      ls_imp_snp_no_afp := ' ' ;
    End if ;
      
    --  Suma importe afectos al S.N.P.
    Select sum(c.imp_soles)
      into  ln_imp_snp_afp
      from calculo c
      where c.cod_trabajador = rc_t.cod_trabajador and 
            substr(c.concep,1,1) = '1' and 
            to_char(c.fec_proceso,'MM')= to_char(ad_fec_proceso,'MM') and
            c.flag_t_snp = '1' ;
    ls_imp_snp_afp := to_char(ln_imp_snp_afp) ;
    ls_imp_snp_afp := nvl(ls_imp_snp_afp,' ') ;
       
    --  Inicializa datos del artista
    ls_imp_artista := ' ' ;
     
    --  Suma conceptos afectos a 5ta. categoria 
    Select  sum(c.imp_soles)
      into ln_imp_quinta
      from calculo c
      where c.cod_trabajador = rc_t.cod_trabajador and
            substr(c.concep,1,1) = '1' and
            to_char(c.fec_proceso,'MM') = to_char(ad_fec_proceso,'MM') and
            c.flag_t_quinta = '1' ;
    ls_imp_quinta := to_char(ln_imp_quinta) ;
    ls_imp_quinta := nvl(ls_imp_quinta,' ') ;
       
    --  Suma montos afectos al descuento de quinta categoria
    Select sum(c.imp_soles) 
      into ln_desc_quinta 
      from calculo c 
      where c.cod_trabajador = rc_t.cod_trabajador and
            c.concep = lk_con_quinta ;
    ls_desc_quinta := to_char(ln_desc_quinta) ;
    ls_desc_quinta := nvl(ls_desc_quinta,'0') ;
     
    --  Une informacion para generacion de registros
    ls_sunat := '1'||'|'||ls_dni||'|'||ls_dias||'|'||
                ls_imp_essalud_emp||'|'||
                ls_imp_snp_no_afp||'|'||
                ls_imp_snp_afp||'|'||
                ls_imp_artista||'|'||
                ls_imp_quinta||'|'||ls_desc_quinta||'|' ;
            
    --  Inserta registro en la tabla temporal
    Insert into tt_sunat600(col_sunat)
    Values (ls_sunat) ;
    
  End if ;  

End loop ;
  
End usp_cal_sunat600 ;
/
