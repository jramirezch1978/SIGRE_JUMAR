create or replace procedure usp_asi_genera_turnos (
  as_usuario in char, an_ano in number, an_sem_desde in number,
  an_sem_hasta in number ) is

--  Variables
ln_sem_ant        number(2) ;
ln_verifica       integer ;
ln_contador       integer ;
ls_carnet         char(10) ;
ls_turno          char(4) ;
ln_ano            number(4) ;
ln_nro_turno      number(2) ;
ls_nro_turno      char(2) ;
ln_nro_semana     number(2) ;
ld_fec_descanso   date ;

--  Lectura del personal con turnos rotativos
cursor c_maestro is
  select m.carnet_trabaj
  from  maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.turno = 'TR00' and m.carnet_trabaj <> ' ' ;

begin

--  Verifica que existan las semanas a generar
ln_verifica := 0 ;
select count(*)
  into ln_verifica
  from semanas s
  where s.ano = an_ano and s.semana between an_sem_desde and
        an_sem_hasta ;
  
if ln_verifica > 0 then

  ln_sem_ant := an_sem_desde - 1 ;
  if ln_sem_ant = 0 then
    ln_ano := an_ano - 1 ;
    select max(s.semana)
      into ln_sem_ant
      from semanas s
      where s.ano = ln_ano ;
  else
    ln_ano := an_ano ;
  end if ;

  delete from programacion_turnos t
    where t.ano = an_ano and t.semana between an_sem_desde and
          an_sem_hasta ;
        
  --  *****************************************************
  --  ***   LECTURA DEL PERSONAL CON TURNOS ROTATIVOS   ***
  --  *****************************************************
  for rc_mae in c_maestro loop

    ls_carnet := nvl(rc_mae.carnet_trabaj,' ') ;

    ln_contador := 0 ;
    select count(*)
      into ln_contador
      from programacion_turnos t
      where t.carnet_trabajador = ls_carnet and t.ano = ln_ano and
            t.semana = ln_sem_ant ;
            
    if ln_contador > 0 then

      select nvl(t.turno,' ')
        into ls_turno
        from programacion_turnos t
        where t.carnet_trabajador = ls_carnet and t.ano = ln_ano and
              t.semana = ln_sem_ant ;

      --  Genera programacion semanal por trabajador
      for x in an_sem_desde .. an_sem_hasta loop

        ln_nro_semana := x ;
        ln_nro_turno  := to_number(substr(ls_turno,3,2)) ;

        if ln_nro_turno = 1 or ln_nro_turno = 2 or ln_nro_turno = 3 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 0 then
            ln_nro_turno := 3 ;
          end if ;
        end if ;

        if ln_nro_turno = 4 or ln_nro_turno = 5 or ln_nro_turno = 6 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 3 then
            ln_nro_turno := 6 ;
          end if ;
        end if ;

        if ln_nro_turno = 7 or ln_nro_turno = 8 or ln_nro_turno = 9 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 6 then
            ln_nro_turno := 9 ;
          end if ;
        end if ;

        if ln_nro_turno = 12 or ln_nro_turno = 13 or ln_nro_turno = 14 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 11 then
            ln_nro_turno := 14 ;
          end if ;
        end if ;

        if ln_nro_turno = 10 or ln_nro_turno = 11 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 9 then
            ln_nro_turno := 11 ;
          end if ;
        end if ;

        if ln_nro_turno = 20 or ln_nro_turno = 21 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 19 then
            ln_nro_turno := 21 ;
          end if ;
        end if ;

        if ln_nro_turno = 23 or ln_nro_turno = 24 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 22 then
            ln_nro_turno := 24 ;
          end if ;
        end if ;

        if ln_nro_turno = 25 or ln_nro_turno = 26 then
          ln_nro_turno  := ln_nro_turno - 1 ;
          if ln_nro_turno = 24 then
            ln_nro_turno := 26 ;
          end if ;
        end if ;

        ls_nro_turno := lpad(to_char(ln_nro_turno),2,'0') ;
        ls_turno     := 'TR'||ls_nro_turno ;

        select s.fecha_inicio
          into ld_fec_descanso
          from semanas s
          where s.ano = an_ano and s.semana = ln_nro_semana ;
 
        insert into programacion_turnos (
          carnet_trabajador, ano, semana, turno, fecha_descanso,
          cod_usr )
        values (
          ls_carnet, an_ano, ln_nro_semana, ls_turno, ld_fec_descanso,
          as_usuario ) ;

      end loop ;
    
    end if ;

  end loop;

end if ;
    
end usp_asi_genera_turnos ;
/
