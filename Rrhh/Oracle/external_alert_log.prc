create or replace procedure external_alert_log as
  path_bdump varchar2(4000);
  name_alert varchar2(100);
begin

  select 
    value into path_bdump 
  from 
    sys.v_$parameter
  where
    name = 'background_dump_dest';

  select
    'alert_' || value || '.log' into name_alert
  from
    sys.v_$parameter
  where
    name = 'db_name';

  execute immediate 'create or replace directory background_dump_dest_dir as ''' || 
    path_bdump || '''';

  execute immediate 
    'create table alert_log_external '              ||
    ' (line  varchar2(4000) ) '                     ||
    '  organization external '                      ||
    ' (type oracle_loader '                         ||
    '  default directory background_dump_dest_dir ' ||
    '  access parameters ( '                        ||
    '    records delimited by newline '             ||
    '    nobadfile '                                ||
    '    nologfile '                                ||
    '    nodiscardfile '                            ||
    '    fields terminated by ''#$~=ui$X'''         ||
    '    missing field values are null '            ||
    '    (line)  '                                  ||
    '  ) '                                          ||
    '  location (''' || name_alert || ''') )'       ||
    '  reject limit unlimited ';
end;
/
