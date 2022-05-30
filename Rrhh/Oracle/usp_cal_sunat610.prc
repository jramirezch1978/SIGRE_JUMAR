create or replace procedure usp_cal_sunat610
 ( as_codemp    in empresa.cod_empresa%type ) is
     
ls_ruc_emp      char(11) ;
ls_seccion      seccion.cod_seccion%type ;
ls_porc_ipss    char(6) ;
ln_porc_ipss    seccion.porc_sctr_ipss%type ;
ls_codtra       maestro.cod_trabajador%type ;
ls_dni          char(15) ;
ln_imp_ipss     number(15) ;
ls_imp_ipss     char(15) ;
ls_sunat        char(55) ;
ln_contador     number(15) ;
    
--  Cursor para ubicar la seccion  
Cursor c_seccion is 
  select s.cod_seccion, s.porc_sctr_ipss
  from seccion s ;
  
--  Busca trabajadores para una determinada seccion 
Cursor c_trabaj (ls_seccion in seccion.cod_seccion%type) is 
  select m.cod_trabajador, m.dni  
  from maestro m
  where m.cod_seccion = ls_seccion and
        m.cod_empresa = as_codemp and
        m.flag_estado = '1' ;
  
begin

--  Elimina registros de la tabla temporal
delete from  tt_sunat610 ;

--  Obtiene R.U.C. de la empresa
Select e.ruc
  into ls_ruc_emp
  from empresa e
  where e.cod_empresa = as_codemp ;

--  Busca secciones afectas al SCTR.IPSS
For rc_s in c_seccion loop

  ln_porc_ipss := nvl(rc_s.porc_sctr_ipss,0) ;

  If ln_porc_ipss <> 0 then

    ls_seccion := nvl(rc_s.cod_seccion,' ') ;
    For rc_t in c_trabaj(ls_seccion ) loop

      ls_codtra := rc_t.cod_trabajador ;
      ls_dni    := nvl(rc_t.dni,' ') ;
        
      --  Procesa informacion del S.C.T.R. I.P.S.S.
      If ln_porc_ipss <> 0 then
        ln_contador := 0 ;
        Select count(*) 
          into ln_contador
          from calculo c 
          where c.cod_trabajador = ls_codtra and
                substr(c.concep,1,1) = '1' and
                c.flag_e_sctr_ipss = '1' ;
        ln_contador := nvl(ln_contador,0) ;
        If ln_contador > 0 Then
          Select sum(c.imp_soles)
            into ln_imp_ipss
            from calculo c 
            where c.cod_trabajador = ls_codtra and
                  substr(c.concep,1,1)= '1' and
                  c.flag_e_sctr_ipss = '1' ;
          ls_imp_ipss := to_char(ln_imp_ipss) ;
          ls_imp_ipss := nvl(ls_imp_ipss,' ') ;
             
          ls_porc_ipss := to_char(ln_porc_ipss,'99.99') ;
          ls_sunat := '1'||'|'||rpad(ls_dni,15,' ')||'|'||
                      rpad(ls_ruc_emp,11,' ')||'|'||'01'||'|'||
                      lpad(trim(ls_porc_ipss),5,'0')||'|'||
                      lpad(trim(ls_imp_ipss),15,' ')||'|' ;
          Insert into tt_sunat610(col_sunat)
          Values(ls_sunat) ;
        End if ;
      End if ;
         
    End loop ;
  
  End if ;

End loop ;

End usp_cal_sunat610 ;
/
