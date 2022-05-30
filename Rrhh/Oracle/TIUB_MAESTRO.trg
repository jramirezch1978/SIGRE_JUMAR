create or replace trigger TIUB_MAESTRO
  before insert or update on maestro
  for each row
declare
  -- local variables here
begin
  -- Actulizo el dni

if :new.tipo_doc_ident_rtps = 1 and :new.nro_doc_ident_rtps is not null then
   :new.dni := substr(:new.nro_doc_ident_rtps,1,8);
end if;

end TIUB_MAESTRO;
/
