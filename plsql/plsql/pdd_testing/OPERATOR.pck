CREATE OR REPLACE PACKAGE OPERATOR AS

  procedure user_info_result( inum_order in number, 
            ofio out nvarchar2,  oiin out varchar2, ocategory out nvarchar2,
            olang out varchar2, oordering_place out nvarchar2, 
            oexecuting_place out nvarchar2);

  procedure get_ca_summary_info(iid_region in pls_integer, idate in date,
                                ocnt_passed out pls_integer, ocnt_failed out pls_integer);
  procedure get_ca_region_info(iid_region in varchar2, icode_center in varchar2, 
            iorder_num in number, iiin in varchar2, 
            idate_calc in varchar2, cur out sys_refcursor);

  procedure get_summary_info(iid_center in pls_integer, idate in date, 
                                ocnt_passed out pls_integer, ocnt_failed out pls_integer);
  procedure get_local_center_info(iid_center in pls_integer, iorder_num in number, iiin in varchar2, 
       idate_calc in varchar2, cur out sys_refcursor);
--  procedure get_ca_region_info2(iid_region in varchar2, icode_center in varchar2, iorder_num in number, iiin in varchar2, 
--       idate_calc in varchar2, cur out sys_refcursor);
                                                
--  procedure get_ca_info(icode_center in varchar2, iorder_num in number, iiin in varchar2, 
--       idate_calc in varchar2, cur out sys_refcursor);

--  procedure get_summary_info(iid_center in pls_integer, idate in date, 
--                ocnt_passed out pls_integer, ocnt_failed out pls_integer);

 
END OPERATOR;
/
CREATE OR REPLACE PACKAGE BODY OPERATOR AS

  procedure log(itype in char, iproc in varchar2, 
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg) 
        values(systimestamp, itype, 'operator', iproc, inum_order, imess);
    commit;
  end;

  procedure get_ca_info(icode_center in varchar2, iorder_num in number, iiin in varchar2, 
       idate_calc in varchar2, cur out sys_refcursor)
  is
    cmd varchar2(4000);
    add_cmd varchar2(512);
    v_code_center varchar2(32) default '';
  begin
    cmd := 'select num_order, fio, date_testing, code_center, iin, category, 
                       result, status_testing, mistake, ip_addr,
                       floor((time_testing/60))||'' min. ''||mod(time_testing, 60)||'' sec.'' as time_testing,
                       status_send
                from (
                     select lpad(o.num_order, 12, ''0'') num_order, p.fio,
                         coalesce(o.end_time_testing, o.date_order) as date_testing,
                         c.code_center as code_center,
                         o.iin, o.category, o.result result,
                         case when o.result is null then o.status
                         when o.result = ''passed'' then ''''
                         when o.result = ''failed'' then o.extend_status
                         else o.status
                         end as status_testing, o.mistake,
                         t.ip_addr, coalesce((t.period_for_testing - t.remain_time), 0) as time_testing, o.status_send
                     from pdd.orders o, pdd.testing t, pdd.persons p, cop.centers c
                     where o.num_order = t.id_registration
                     and o.id_center = c.id_center
                     and o.iin = p.iin
                     and o.status != ''New''
                     and c.code_center = nvl(:icode_center, c.code_center)

                     union
                     select lpad(o.num_order, 12, ''0'') num_order, p.fio, o.date_order as date_testing,
                     c.code_center as code_center,
                     o.iin, o.category, '''' result, o.status, '''' mistake, '''' as ip_addr, 0 as time_testing, '''' as status_send
                     from pdd.orders o, pdd.persons p, cop.centers c
                     where o.id_center = c.id_center
                     and o.iin = p.iin
                     and o.status in (''New'', ''Stopped'', ''absence'')
                     and c.code_center = nvl(:icode_center, c.code_center)
                ) ';

    if iorder_num is not null then
       add_cmd := ' where num_order like ''%' ||iorder_num || '%'' ';
    elsif iiin is not null then
       add_cmd := ' where iin like ''%' ||iiin|| '%'' ';
    elsif idate_calc is not null then
       add_cmd := ' where to_char(date_testing,''dd.mm.yyyy'') = '''||idate_calc||''' ';
    end if;
    
    if add_cmd is null then
      v_code_center := 'ZZZ';
    else 
      v_code_center := icode_center;
    end if;   
    
    cmd:=cmd||add_cmd||' order by date_testing desc';
    open cur for cmd using v_code_center, v_code_center;
  
  end get_ca_info;

  procedure get_ca_region_info(iid_region in varchar2, icode_center in varchar2, iorder_num in number, iiin in varchar2, 
       idate_calc in varchar2, cur out sys_refcursor)
  is
    cmd varchar2(4000);
  begin
    cmd := 'select num_order, fio, date_testing, code_center, iin, category, 
                   result, status_testing, mistake, ip_addr,
                   floor((time_testing/60))||'' min. ''||mod(time_testing, 60)||'' sec.'' as time_testing,
                   status_send, proctoring, old_photo, foreign_citizen
            from (
                 select lpad(o.num_order, 12, ''0'') num_order, p.fio,
                     coalesce(cast(o.end_time_testing as date), o.date_order) as date_testing,
                     c.code_center as code_center,
                     o.iin, o.category, o.result result,
                     case when o.result is null then o.status
                     when o.result = ''passed'' then ''''
                     when o.result = ''failed'' then o.extend_status
                     else o.status
                     end as status_testing, o.mistake,
                     t.ip_addr, coalesce((t.period_for_testing - t.remain_time), 0) as time_testing, o.status_send,
                     o.proctoring, o.old_photo, o.foreign_citizen
                 from pdd.orders o, pdd.testing t, pdd.persons p, cop.centers c
                 where o.num_order = t.id_registration
                 and o.id_center = c.id_center
                 and o.iin = p.iin
                 and o.status not in (''New'', ''absence'', ''Stopped'')';

    if iorder_num is not null then
       cmd := cmd||'and o.num_order like ''%' ||iorder_num || '%'' ';
    elsif iiin is not null then
       cmd := cmd||'and o.iin like ''%' ||iiin|| '%'' ';
    elsif iid_region is not null then
        cmd:=cmd||'and c.id_region='||iid_region||' ';
    elsif icode_center is not null then
        cmd:=cmd||'and o.code_center='||icode_center||' ';
    end if;


    if iorder_num is null and iiin is null then
      if idate_calc is not null then
         cmd := cmd||'and to_char(o.date_order,''dd.mm.yyyy'') = '''||idate_calc||''' ';
      else
         cmd := cmd||'and trunc(o.date_order) = trunc(sysdate) ';
      end if;
    end if;
    
    cmd:=cmd||' union
                     select lpad(o.num_order, 12, ''0'') num_order, p.fio, o.date_order as date_testing,
                         c.code_center as code_center,
                         o.iin, o.category, o.status as result, 
                         o.status, o.mistake, '''' as ip_addr, 0 as time_testing, '''' as status_send,
                         o.proctoring, o.old_photo, o.foreign_citizen
                     from pdd.orders o, pdd.persons p, cop.centers c
                     where o.id_center = c.id_center
                     and o.iin = p.iin
                     and o.status in (''New'', ''absence'', ''Stopped'') ';

    if iorder_num is not null then
       cmd := cmd||'and o.num_order like ''%' ||iorder_num || '%'' ';
    elsif iiin is not null then
       cmd := cmd||'and o.iin like ''%' ||iiin|| '%'' ';
    elsif iid_region is not null then
        cmd:=cmd||'and c.id_region='||iid_region||' ';
    elsif icode_center is not null then
        cmd:=cmd||'and o.code_center='||icode_center||' ';
    end if;
    
    if iorder_num is null and iiin is null then
      if idate_calc is not null then
         cmd := cmd||'and to_char(o.date_order,''dd.mm.yyyy'') = '''||idate_calc||''' ';
      else
         cmd := cmd||'and trunc(o.date_order) = trunc(sysdate) ';
      end if;
    end if;


    cmd:=cmd||')  order by date_testing desc';
--    log('I', 'get_ca_center_info2', iorder_num, 'cmd:  '||cmd);
--    log('I', 'get_ca_region_info', iid_region, 'id_region: '||iid_region||', code_center: '||icode_center||', iin: '||iiin);
    open cur for cmd;
  end get_ca_region_info;

  procedure get_local_center_info(iid_center in pls_integer, iorder_num in number, iiin in varchar2, 
       idate_calc in varchar2, cur out sys_refcursor)
  is
    cmd varchar2(4000);
  begin
    cmd := 'select num_order, fio, date_testing, code_center, iin, category, 
                   result, status_testing, mistake, ip_addr,
                   floor((time_testing/60))||'' min. ''||mod(time_testing, 60)||'' sec.'' as time_testing,
                   status_send, proctoring, old_photo, foreign_citizen
            from (
                 select lpad(o.num_order, 12, ''0'') num_order, p.fio,
                     coalesce(cast(o.end_time_testing as date), o.date_order) as date_testing,
                     c.code_center as code_center,
                     o.iin, o.category, o.result result,
                     case when o.result is null then o.status
                     when o.result = ''passed'' then ''''
                     when o.result = ''failed'' then o.extend_status
                     else o.status
                     end as status_testing, o.mistake,
                     t.ip_addr, coalesce((t.period_for_testing - t.remain_time), 0) as time_testing, o.status_send,
                     o.proctoring, o.old_photo, o.foreign_citizen
                 from pdd.orders o, pdd.testing t, pdd.persons p, cop.centers c
                 where o.num_order = t.id_registration
                 and o.id_center = c.id_center
                 and o.iin = p.iin
                 and o.status not in (''New'', ''absence'', ''Stopped'')
                 and o.id_center='||iid_center||' '; 
    if iorder_num is not null then
       cmd := cmd||'and o.num_order like ''%' ||iorder_num || '%'' ';
    elsif iiin is not null then
       cmd := cmd||'and o.iin like ''%' ||iiin|| '%'' ';
    end if;
    
    if iorder_num is null and iiin is null then
      if idate_calc is not null then
         cmd := cmd||'and to_char(o.date_order,''dd.mm.yyyy'') = '''||idate_calc||''' ';
      else
         cmd := cmd||'and trunc(o.date_order) = trunc(sysdate) ';
      end if;
    end if;
    
    cmd:=cmd||'union
                 select lpad(o.num_order, 12, ''0'') num_order, p.fio, o.date_order as date_testing,
                     c.code_center as code_center,
                     o.iin, o.category, '''' result, o.status, '''' mistake, '''' as ip_addr, 0 as time_testing, '''' as status_send,
                     o.proctoring, o.old_photo, o.foreign_citizen
                 from pdd.orders o, pdd.persons p, cop.centers c
                 where o.id_center = c.id_center
                 and o.iin = p.iin
                 and o.status in (''New'', ''absence'', ''Stopped'') 
                 and o.id_center='||iid_center||' ';
    if iorder_num is not null then
       cmd := cmd||'and num_order like ''%' ||iorder_num || '%'' ';
    elsif iiin is not null then
       cmd := cmd||'and iin like ''%' ||iiin|| '%'' ';
    end if;
    
    if iorder_num is null and iiin is null then
      if idate_calc is not null then
         cmd := cmd||'and to_char(o.date_order,''dd.mm.yyyy'') = '''||idate_calc||''' ';
      else
         cmd := cmd||'and trunc(o.date_order) = trunc(sysdate) ';
      end if;
    end if;

    cmd:=cmd||')  order by date_testing desc';

--    log('I', 'get_local_center_info2', iorder_num, 'cmd:  '||cmd);
--    log('E', 'user_info_result', iorder_num, 'sqlerrm: '||sqlerrm);
    open cur for cmd;
  end get_local_center_info;  

--/*
  procedure get_ca_summary_info(iid_region in pls_integer, idate in date,
                                ocnt_passed out pls_integer, ocnt_failed out pls_integer)
  is
  begin
    select coalesce(sum(pass),0) as cnt_passed, coalesce(sum(fail),0) as cnt_failed
    into   ocnt_passed, ocnt_failed
    from( 
          select case when o.result = 'passed' then 1 else 0 end as pass 
          , case when o.result = 'failed' then 1 else 0 end as fail 
          from pdd.orders o, cop.centers c
          where trunc(end_time_testing)=trunc(nvl(idate,sysdate))
          and  o.id_center=c.id_center
          and c.id_region = nvl(iid_region, c.id_region)
    );
    exception when no_data_found then
        log('E', 'get_ca_summary_info', iid_region, 'iid_region: '||iid_region||', ocnt_passed: '||ocnt_passed||', ocnt_failed'||ocnt_failed);
        ocnt_passed:=0;
        ocnt_failed:=0;
  end;

 --/*
  procedure get_summary_info(iid_center in pls_integer, idate in date,
                                ocnt_passed out pls_integer, ocnt_failed out pls_integer)
  is
  begin
    select coalesce(sum(pass),0) as cnt_passed, coalesce(sum(fail),0) as cnt_failed
    into   ocnt_passed, ocnt_failed
    from( 
          select case when o.result = 'passed' then 1 else 0 end as pass 
          , case when o.result = 'failed' then 1 else 0 end as fail 
          from pdd.orders o, cop.centers c
          where trunc(end_time_testing)=trunc(nvl(idate,sysdate))
          and  o.id_center=c.id_center
          and o.id_center = iid_center
    );
    exception when no_data_found then
        log('E', 'get_summary_info', iid_center, 'iid_center: '||iid_center||', ocnt_passed: '||ocnt_passed||', ocnt_failed'||ocnt_failed);
        ocnt_passed:=0;
        ocnt_failed:=0;
  end;
 
  --*/
  -- 
  procedure user_info_result( inum_order in number, 
            ofio out nvarchar2,  oiin out varchar2, ocategory out nvarchar2,
            olang out varchar2, oordering_place out nvarchar2, 
            oexecuting_place out nvarchar2)
  is
  begin
    select p.fio, p.iin, o.category, t.language,
           case when t.language='ru' then c.name_ru 
                when t.language='ru' then c.name_kz
           end ordering_place,
           case when t.language='ru' then c.name_short_ru 
                when t.language='ru' then c.name_short_ru 
           end executing_place    
    into   ofio, oiin, ocategory, olang, oordering_place, oexecuting_place
    from   pdd.persons p, pdd.orders o, pdd.testing t, cop.centers c
    where  o.num_order=t.id_registration
    and    t.id_registration=inum_order
    and    o.id_center=c.id_center    
    and    p.iin=o.iin;
    
    exception when no_data_found then
        log('E', 'user_info_result', inum_order, 'sqlerrm: '||sqlerrm);
        ofio:=''; oiin:=''; ocategory:='';
  end;

END OPERATOR;
/
