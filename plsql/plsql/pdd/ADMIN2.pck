CREATE OR REPLACE PACKAGE ADMIN2 AS

  function open_cursors return sys_refcursor;
  function limits return sys_refcursor;
  function active_sessions return sys_refcursor;

  procedure analyze(inum_order in number);
  
END ADMIN2;
/
CREATE OR REPLACE PACKAGE BODY ADMIN2 AS

  procedure log(itype in char, iproc in varchar2,
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg)
        values(systimestamp, itype, 'test', iproc, inum_order, imess);
    commit;
  end;
  
  function open_cursors return sys_refcursor
  AS
   cur sys_refcursor;
   cmd varchar2(256);
  BEGIN
    cmd := 'select b.name || '': ''||sum(a.value)'||
            'from v$sesstat a, v$statname b '||
            'where a.statistic# = b.statistic# '||
            'and b.name = ''opened cursors current'' '||     
            'group by b.name';
    open cur for cmd;
    return cur;
 END open_cursors;
 
  function limits return sys_refcursor
  is
   cur sys_refcursor;
   cmd varchar2(128);
  BEGIN
    cmd := 'SELECT * FROM v$resource_limit where limit_value!='' UNLIMITED'' and limit_value!= 0 '|| 
           'ORDER BY resource_name';
    open cur for cmd;
    return cur;
 END limits;
 
 function active_sessions return sys_refcursor
 is
   cur sys_refcursor;
   cmd varchar2(248);
 begin
    cmd := 'select a.value, s.program, s.username, '||
            's.sid, s.serial#, s.client_identifier '||
            'from v$sesstat a, v$statname b, v$session s '||
            'where a.statistic# = b.statistic# '||
            'and s.sid = a.sid '||
            'and b.name = ''opened cursors current'' '||
            'order by 1 desc';
    open cur for cmd;
    return cur;
  end;

  function analyze_person(inum_order in varchar2) return pls_integer
  is
    ret pls_integer;
    v_iin varchar2(12);
  begin
    ret:=0;
    select iin into v_iin from orders o where o.num_order=inum_order;
    if v_iin in ('630112300169')
        then ret:=1;
    end if;
    return ret;
  end;
  
  procedure analyze(inum_order in number)
  is 
    v_cnt pls_integer;
  begin
    if analyze_person(inum_order)=0 then
        return;
    end if;
  
    select count(qft.id_question)
    into v_cnt
    from pdd.questions_for_testing qft, pdd_testing.answers a
    where qft.id_registration=inum_order
    and   qft.theme_number=2
    and   qft.id_answer=a.id_answer
    and  time_reply is not null
    and   coalesce(a.correctly,'N')='N';

    FOR CUR IN (
                SELECT * FROM (
                  select qft.id_question, rownum as row_num
                  from pdd.questions_for_testing qft, pdd_testing.answers a
                  where qft.id_registration=13
                  and   qft.theme_number=2
                  and   qft.id_answer=a.id_answer
                  and  time_reply is not null
                  and   coalesce(a.correctly,'N')='N'
                  ORDER BY dbms_random.value
                ) WHERE row_num>6
              )
    LOOP
      LOG('I', 'A', inum_order, 'test');
    END LOOP;
    
  end;  

END ADMIN2;
/
