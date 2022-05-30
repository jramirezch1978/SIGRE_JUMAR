create or replace procedure usp_rpt_aporte_afp
  ( as_tipo_trabajador  maestro.tipo_trabajador%type ) is
 
lk_apor_oblig       constant char(4):='2002';  
lk_apor_seguro      constant char(4):='2003';  
lk_apor_comis       constant char(4):='2004';  
ls_codtra           maestro.cod_trabajador%type;
ls_nombre           varchar2(100);              
ls_tipo_trabajador  maestro.tipo_trabajador%type;
ls_afp              admin_afp.cod_afp%type;
ls_nro_afp_trab     maestro.nro_afp_trabaj%type;
ls_desc_afp         admin_afp.desc_afp%type;
ln_apor_oblig       tt_rpt_aporte_afp.aporte_oblig%type;
ln_tot_fon_pens     tt_rpt_aporte_afp.fondo_pension%type;
ln_apor_seguro      tt_rpt_aporte_afp.aporte_seguro%type;
ln_apor_comis       tt_rpt_aporte_afp.aporte_comision%type;
ln_tot_ret_red      tt_rpt_aporte_afp.retenc_distrib%type;
ln_contador         number(15);

--  Cursor de de lectura de la tabla calculo
Cursor c_cal is 
 select c.cod_trabajador, c.fec_proceso,
        sum(c.imp_soles) as remun_aseg 
 from calculo c 
 where substr(c.concep,1,1)='1' and 
       c.flag_t_afp = '1'
 group by c.cod_trabajador, c.fec_proceso ;

begin

delete from tt_rpt_aporte_afp ;

For rc_c in c_cal Loop

  ls_codtra := rc_c.cod_trabajador;
  ls_nombre := usf_nombre_trabajador(ls_codtra);
 
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from maestro m
    where m.cod_trabajador = ls_codtra and
          m.flag_estado = '1' and
          m.cod_afp <> ' ' ;
  ln_contador := nvl(ln_contador,0) ;
 
  If ln_contador > 0 then
  
  Select m.tipo_trabajador
    into ls_tipo_trabajador
    from maestro m
    where m.cod_trabajador = ls_codtra and
          m.flag_estado = '1' and
          m.cod_afp <> ' ' ;
 
  If ls_tipo_trabajador = as_tipo_trabajador Then 
  
    Select m.cod_afp, m.nro_afp_trabaj, 
           a.desc_afp
      into ls_afp, ls_nro_afp_trab, 
           ls_desc_afp
      from maestro m, admin_afp a
      where m.cod_afp = a.cod_afp (+) and 
            m.cod_trabajador = ls_codtra and 
            m.flag_estado = '1';
   
    If ls_afp is not null or ls_nro_afp_trab is not null Then 

      --  Importe de Aporte Obligatorio 
      ln_contador := 0 ; ln_apor_oblig := 0 ;
      Select count(*)
        into ln_contador
        from calculo c
        where c.concep = lk_apor_oblig and 
              c.cod_trabajador = ls_codtra;
      If ln_contador > 0 then
        Select c.imp_soles 
          into ln_apor_oblig
          from calculo c
          where c.concep = lk_apor_oblig and 
                c.cod_trabajador = ls_codtra;
      End if ;
      --  Total de Fondo de Pensiones
      ln_tot_fon_pens:=ln_apor_oblig; 
      --  Importe de Aporte del Seguro 
      ln_contador := 0 ; ln_apor_seguro := 0 ;
      Select count(*)
        into ln_contador
        from calculo c
        where c.concep = lk_apor_seguro and 
              c.cod_trabajador = ls_codtra;
      If ln_contador > 0 then
        Select c.imp_soles 
          into ln_apor_seguro
          from calculo c
          where c.concep = lk_apor_seguro and 
                c.cod_trabajador = ls_codtra;
      End if ;
      --  Importe de Comision
      ln_contador := 0 ; ln_apor_comis := 0 ;
      Select count(*)
        into ln_contador
        from calculo c
        where c.concep = lk_apor_comis and 
              c.cod_trabajador = ls_codtra;
      If ln_contador > 0 then
        Select c.imp_soles 
          into ln_apor_comis
          from calculo c
          where c.concep = lk_apor_comis and 
                c.cod_trabajador = ls_codtra;
      End if ;
      --  Total Retencion de Retribucion
      ln_tot_ret_red := ln_apor_seguro + ln_apor_comis;
      
      --  Inserta datos en la tabla tt_rpt_aporte_afp
      Insert into tt_rpt_aporte_afp (
        cod_trabajador  , cod_empresa       , cod_afp          ,
        desc_afp        , nro_afp           , nombre           ,
        fec_proceso     , remun_asegur      , aporte_oblig     ,
        fondo_pension   , aporte_seguro     , aporte_comision  , 
        retenc_distrib  )
      Values (
        ls_codtra        , 'AIPSA'           , ls_afp           ,
        ls_desc_afp      , ls_nro_afp_trab   , ls_nombre        , 
        rc_c.fec_proceso , rc_c.remun_aseg   , ln_apor_oblig    ,
        ln_tot_fon_pens  , ln_apor_seguro    , ln_apor_comis    ,
        ln_tot_ret_red   );       
        
    End if;

  End if;

  End if ;
  
end loop;  

end usp_rpt_aporte_afp;
/
