create or replace function USF_RRHH_NUM_MAESTRO(
       asi_origen origen.cod_origen%type
)return varchar2 is

  ls_ult_nro     maestro.cod_trabajador%type ;
  ln_ult_nro     num_maestro.ult_nro%type ;
  ln_count       number;                     
begin
  -- Verifico que exista el numerador para el origen
  select count(*)
    into ln_count
    from num_maestro np
   where np.origen = asi_origen;
  
  if ln_count = 0 then
     RAISE_APPLICATION_ERROR(-20000, 'No ha especificado un numerador para el origen '
                                     || asi_origen || ' en el maestro de trabajadores,' 
                                     || ' por favor verifique.');
  end if;
  
  --numerador de detraccion
  select NVL(np.ult_nro,0)
    into ln_ult_nro
    from num_maestro np
   where (np.origen = asi_origen)
   for update nowait;

  --se concatena con origen
  ls_ult_nro := rtrim(ltrim(to_char(ln_ult_nro))) ;

  --actualiza información e numeradores
  update num_maestro np
     set np.ult_nro = Nvl(np.ult_nro,0) + 1
   where (np.origen = asi_origen ) ;

  return(ls_ult_nro);

end USF_RRHH_NUM_MAESTRO ;
/
