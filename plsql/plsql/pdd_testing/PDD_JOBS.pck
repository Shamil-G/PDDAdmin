CREATE OR REPLACE PACKAGE PDD_JOBS AS

  procedure force_finish;
  function get_result_test(inum_order in pls_integer) return varchar2;
  procedure send_results;

END PDD_JOBS;
/
CREATE OR REPLACE PACKAGE BODY PDD_JOBS AS
a
  procedure log(itype in char, iproc in varchar2, 
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg) 
        values(systimestamp, itype, 'pdd_jobs', iproc, inum_order, imess);
    commit;
  end;
  
  procedure force_finish
  is
    v_systime  TIMESTAMP;
    v_time  pls_integer default 0;
    v_last_time pls_integer default 0;
  begin
    for cur in (
        select t.*
        from pdd.testing t
        where status!='Сдан'
        and status!='Не сдан'
    )
    loop
        select systimestamp into v_systime from dual;

        v_time := (extract(hour from v_systime) * 3600 + 
                    extract(minute from v_systime) * 60 + 
                    extract(second from v_systime));

        v_last_time :=(extract(hour from cur.beg_time_testing) * 3600 + 
                        extract(minute from cur.beg_time_testing) * 60 + 
                        extract(second from cur.beg_time_testing)) 
                        + cur.period_for_testing + 240;
        if v_time > v_last_time
        then
        log('I', 'force_finish', cur.id_registration, 
            '------------> : FORCE FINISH: '||', v_last_time: '||v_last_time);
            pdd.test.finish(cur.id_registration);
        end if;
    end loop;
  end;
  
  function get_result_test(inum_order pls_integer) return varchar2
  is 
    ret varchar2(512);
    v_theme_name pdd_testing.themes.descr%type;
    v_date_stop  date;
  begin
    select json_object(
             'applicationId' value id_registration, 
             'testType' value theme_number, 
             'result' value case when true_score >= count_success then 'passed' else 'fail' end,
             'totalQuestion' value count_question,
             'correctAnswers' value true_score,
             'incorrectAnswers' value false_score,
             'skippedAnswers' value miss_score
             ),
             theme_name, date_stop 
    into ret, v_theme_name, v_date_stop
    from (
      select id_registration, theme_number, theme_name, count_question, count_success, date_stop,
      sum(true_result) true_score, sum(false_result) false_score, sum(miss_result) miss_score
      from ( 
       select tft.id_registration, qft.theme_number, to_char(th.descr) theme_name, tft.date_stop, tft.count_question, 
       tft.count_success, case when correctly = 'Y' then 1 else 0 end true_result, 
       case when correctly != 'Y' then 1 else 0 end false_result, 
       case when correctly is null then 1 else 0 end miss_result 
       from pdd.questions_for_testing qft, pdd.themes_for_testing tft, 
            pdd_testing.answers a, pdd_testing.themes th 
       where qft.id_registration = tft.id_registration
         and qft.theme_number = tft.theme_number
         and a.id_answer(+) = qft.id_answer
         and tft.id_registration = inum_order
         and tft.id_theme = th.id_theme
    )
    group by id_registration, theme_number, theme_name, date_stop, count_question, count_success 
    order by theme_number desc
    ) where rownum=1;
    
  return ret;
  
  end;

/*
  procedure grant_access(host in varchar2, 
            low_port in varchar2, 
            upper_port in varchar2, 
            uname in varchar2)
  is
  BEGIN
  
    DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
    acl => 'Connect_Access.xml',
    description => 'Connect Network',
    principal => 'PDD_TESTING',
    is_grant => TRUE,
    privilege => 'resolve',
    start_date => NULL,
    end_date => NULL);

    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL ( acl => 'Connect_Access.xml',
    host => '*',
    lower_port => low_port,
    upper_port => upper_port);


--  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
--  acl => 'Connect_Access.xml',
--  principal => 'SH',
--  is_grant => TRUE,
--  privilege => 'connect',
--  position => NULL,
--  start_date => NULL,
--  end_date => NULL);
 
  END;
*/


  procedure send_results 
  is
    http_req utl_http.req;
    http_res utl_http.resp;  
    result  nvarchar2(512);
    answer  nvarchar2(128);
    status  varchar2(128);
    url_send varchar2(128) default 'http://10.51.203.140:4200/sendResult';
  begin
    http_req := utl_http.begin_request( 
            url => url_send, method => 'POST');
--    utl_http.set_body_charset(http_req, 'utf-8');
    utl_http.set_header(http_req, 'Content-Type', 'application/json');
  
    for cur in (select * from pdd.orders o 
        where o.status='Completed'
        and   o.status_send is null)
    loop
        if cur.extend_status is null then
            result:=get_result_test(cur.num_order);
        else
            result:='{"applicationId":'||cur.num_order||',"result":"fail"}';
        end if;
        log('I', 'send_result', cur.num_order, 'length: '||length(result)||',result: '||result);
        utl_http.set_header(http_req, 'Content-Length', length(result));  
        utl_http.write_text(http_req, result);
        http_res := utl_http.get_response(http_req);
        log('I', 'send_result', cur.num_order, ' HTTP RESPONSE: ');
        begin
        loop
            utl_http.read_line(http_res, answer);
            log('I', 'send_result', cur.num_order, 'ANSWER: '||answer);
            if answer = 'YES' then
                pdd.admin.close_order(cur.num_order, 'success by DB');
            end if;
        end loop;
        exception when utl_http.end_of_body then
                    utl_http.end_response(http_res);  
            
            log('E', 'send_result', cur.num_order, 'ANSWER: '||answer||', sqlerrm: '||sqlerrm);
            RETURN;            
        end;
        
    end loop;
  end;
  
END PDD_JOBS;
/
