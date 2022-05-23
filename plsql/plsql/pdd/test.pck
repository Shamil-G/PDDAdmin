create or replace package test is

  -- Author  : Shamil Gussseynov
  -- Created : 22.06.2021 16:13:21
  -- Purpose : ????????? ????????????

  -- Public type declarations
  procedure stop_random_fc(inum_order in number);
  procedure stop_testing(inum_order in number);  
  
  procedure stop_testing_lv(inum_order in number);
  procedure stop_testing_lz(inum_order in number);
  procedure stop_testing_fc(inum_order in number);
  procedure stop_testing_with_num_camera(iid_center in varchar2, 
    inum_camera in varchar2, ostatus out varchar2, image in blob);
  
  function get_remain_time(inum_order in number) return pls_integer;
  function get_answered_questions(inum_order in number, itheme_number in pls_integer) return varchar2;  
  function get_answered_questions(inum_order in number) return varchar2;
  
  procedure create_registration(inum_order in number, iip_addr in varchar2);

  procedure get_theme(inum_order in number, otheme_number out pls_integer, 
                        ocategory out nvarchar2, odescr out nvarchar2, 
                        ocount_question out number,                        
                        ostatus_testing out nvarchar2);

  procedure get_question(inum_order in number, oremain_time out number, 
                         oorder_num_question out number,
                         oquestion out nvarchar2, ourl_image out nvarchar2);

  function next_theme(iid_registration in number) return pls_integer;
  function navigate_question(inum_order in number, icommand in number) return number;
  procedure set_answer(inum_order in number, iorder_num_answer in number);
  procedure set_answer(inum_order in number, inum_order_question in number, iorder_num_answer in number);
  procedure jump_to_question(inum_order in number, order_num_question number);


  procedure calc_and_save_result(inum_order in number);
  procedure calc_and_save_result(inum_order in number, ores out varchar2);
  function finish_info(inum_order in number) return nvarchar2;
  function have_test(inum_order in number) return number;
--  function get_question(inum_order in number) return nvarchar2;

  procedure get_time_testing(inum_order in number,
            oused_minute out pls_integer,
            oused_seconds out pls_integer
            );

  procedure get_current_info(inum_order in number,

            otheme_number out number,
            ocurr_question out pls_integer,
            oremain_time out pls_integer,
            ocategory out nvarchar2,
            oiin  out varchar2,
            ofio out nvarchar2,
            ostatus out nvarchar2);


--Oaaeeou iinea oanoe?iaaiey get_current_info
  procedure get_result_part_1(inum_order in number, 
            ostatus out varchar2,
            otheme_number out number,
            ocategory out nvarchar2,
            oiin  out varchar2,
            ofio out nvarchar2
            );
  procedure get_result_part_2(inum_order in number, 
            ocount_question out number,
            ocount_success out number,
            otrue_result out varchar2,
            ofalse_result out varchar2
            );

  function get_result(iid_registration in number) return sys_refcursor;
  procedure get_user_login_info( inum_order in number, 
            ofio out nvarchar2,  oiin out varchar2, 
            ocategory out nvarchar2, ostatus out nvarchar2, omistake out varchar2);
  procedure get_personal_info( inum_order in number,
                             oiin out varchar2, otime_beg out date,
                             otime_end out date, ofio out nvarchar2 );

  procedure add_photo(inum_order in number, iip_addr in varchar2, 
            icipher in char, icode_mistake in number, iphoto in blob);

  function get_photo(inum_order in number, isrc in char, inum_photo in number) 
    return  clob;
  function count_photo(inum_order in number) return pls_integer;

  procedure get_person_photo(iiin in varchar2, status out char, ophoto out blob);
  procedure replace_person_photo(iiin in varchar2, iphoto in blob);
  procedure lf_fail_recognition(inum_order in number, icode_mistake in pls_integer);
  procedure finish_check_photos(inum_order in number, omistake out pls_integer);
  procedure get_photo_gbd_fl(inum_order in number, oblob out blob);
  procedure get_mistake(inum_order in number, ostatus out varchar2, oextend_status out varchar2, omistake out varchar2);

end test;
/
create or replace package body test is

  procedure log(itype in char, iproc in varchar2,
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg)
        values(systimestamp, itype, 'test', iproc, inum_order, imess);
    commit;
  end;

  function get_remain_time(last_time_access in timestamp, remain_time in pls_integer)
    return pls_integer
  is
  v_remain_time pls_integer;
  begin
    v_remain_time:= extract(second from coalesce(last_time_access,systimestamp) - systimestamp) +
              extract(minute from coalesce(last_time_access,systimestamp) - systimestamp)*60 +
              extract(hour from coalesce(last_time_access,systimestamp) - systimestamp)*3600 +
              remain_time;
    return case when v_remain_time<0 then 0 else v_remain_time end;
  end;

  function get_remain_time(inum_order in number) return pls_integer
  is
   r_testing  testing%rowtype;
   v_remain_time pls_integer;
  begin
    select * into r_testing from testing t where t.id_registration=inum_order;
    v_remain_time:=get_remain_time(r_testing.last_time_access, r_testing.remain_time);
    return v_remain_time;
  end;  

  procedure  correct_time_remain(inum_order in number, ilast_time_access in timestamp, iremain_time in pls_integer)
  is
    v_remain_time pls_integer default 0;
  begin
    v_remain_time := get_remain_time(ilast_time_access, iremain_time);

    update pdd.testing t
    set    t.remain_time=v_remain_time,
           t.last_time_access=systimestamp
    where  t.id_registration=inum_order;
    commit;    
  end;

  function correct_time_remain(inum_order in number, ilast_time_access in timestamp, iremain_time in pls_integer)
  return pls_integer
  is
    v_remain_time pls_integer default 0;
  begin
    v_remain_time := get_remain_time(ilast_time_access, iremain_time);

    update pdd.testing t
    set    t.remain_time=v_remain_time,
           t.last_time_access=systimestamp
    where  t.id_registration=inum_order;
    commit;    
    return v_remain_time;
  end;

  function get_answered_questions(inum_order in number, itheme_number in pls_integer) return varchar2
  is
  str varchar2(128);
  init pls_integer default 0;
  begin
    str:='';
    for cur in (
                select order_num_question as num
                from questions_for_testing q
                where id_registration=inum_order
                and   q.theme_number=itheme_number
                and q.id_answer is not null
                )
    loop
      if init!=0 then
         str:=str||','||cur.num;
      else
         str:=cur.num;
         init:=1;
      end if;
    end loop;
    return str;
  end; 

-- True code
  function get_answered_questions(inum_order in number) return varchar2
  is
  str varchar2(128);
  init pls_integer default 0;
  row_t  pdd.testing%rowtype;
  begin
    select * into row_t from testing t where t.id_registration=inum_order;
    str:='';
    for cur in (
                select order_num_question as num, theme_number 
                from questions_for_testing q
                where id_registration=inum_order
                and   q.theme_number=row_t.current_theme_number
                and q.id_answer is not null
                )
    loop
      if init!=0 then
         str:=str||','||cur.num;
      else
         str:=cur.num;
         init:=1;
      end if;
    end loop;
    return str;
  end; 
    
  procedure jump_to_question(inum_order in number, order_num_question number)
  is
  begin
    update pdd.testing t
    set t.current_num_question=order_num_question
    where t.id_registration=inum_order;

    update pdd.face_control_event ev
    set    ev.status='W'
    where  ev.num_order=inum_order;    
    commit;
  end jump_to_question;

  procedure create_registration(inum_order in number, iip_addr in varchar2)
  is
    row_o pdd.orders%rowtype;
    row_p pdd.persons%rowtype;
  begin
    select * into row_o from pdd.orders o where o.num_order=inum_order;
    select * into row_p from pdd.persons p where p.iin=row_o.iin;
    insert into pdd.testing(id_registration, id_person, date_registration,
            date_testing, ip_addr)
            values(inum_order, row_p.id_person, row_o.date_order, sysdate, iip_addr);
    commit;
    exception when dup_val_on_index then null;
  end;

  procedure stop_random_fc(inum_order in number)
  is
  row_t pdd.testing%rowtype;
  begin
    select * into row_t from pdd.testing t where t.id_registration=inum_order;
    update pdd.testing t
    set t.last_time_access=systimestamp,
        t.status_testing='testing'
    where t.id_registration=inum_order;

    update pdd.face_control_event ev
    set ev.status='C'
    where ev.num_order=inum_order
    and   ev.theme_number=row_t.current_theme_number
    and   ev.num_question=row_t.current_num_question;
    commit;
  end;

-- E oaaeaie? iinea aiaa?aiey 404 ioeaee
  procedure stop_testing(inum_order in number)
  is
  begin
    update pdd.testing t set t.last_time_access='' where t.id_registration=inum_order;
    
    update pdd.orders o
    set o.status = 'Stopped',
        o.result = 'Stopped',
        o.mistake = 'Fail recognition'
    where o.num_order=inum_order;
    commit;
  end;

  procedure stop_testing(inum_order in number, mistake_info in varchar2)
  is
  v_mistake orders.mistake%type;
  begin
    update pdd.testing t set t.last_time_access='' where t.id_registration=inum_order;
    
    update pdd.orders o
    set o.status = 'Stopped',
        o.result = 'Stopped',
        o.mistake = mistake_info,
        o.old_photo = case when mistake_info = 'Old photo' then 'Y' else o.old_photo end,
        o.proctoring = case when mistake_info = 'Proctoring' then 'Y' else o.proctoring end,
        o.foreign_citizen = case when mistake_info = 'Foreign citizen' then 'Y' else o.foreign_citizen end
    where o.num_order=inum_order;
    commit;
  end stop_testing;

  procedure stop_testing_lz(inum_order in number)
  is
  begin
    stop_testing(inum_order, 'Fail recognition');
  end;

  procedure stop_testing_lv(inum_order in number)
  is
  begin
    stop_testing(inum_order, 'Fail recognition');
  end;

  procedure stop_testing_fc(inum_order in number)
  is
  begin
    stop_testing(inum_order, 'Foreign citizen');
  end;
--/*
  procedure stop_testing_with_num_camera(iid_center in varchar2, 
    inum_camera in varchar2, ostatus out varchar2, image in blob)
  is
    v_ip_addr varchar2(16);
    v_code_center varchar2(16);
    v_order_status pdd.orders.status%type;
    v_num_order pdd.orders.num_order%type;
  begin
    
    begin
      select l.ip_addr, l.code_center into v_ip_addr, v_code_center
      from   cop.list_workstation l, cop.centers c
      where l.code_center = c.code_center
      and   l.ip_addr like '%.'||inum_camera
      and   c.id_center = iid_center
      and   status='T';

    exception when no_data_found then 
      ostatus:='LOCK ORDER. PC NOT FOUND. id_center: '||iid_center||', num_camera: '||inum_camera;
      log('E', 'stop_testing_with_num_camera', inum_camera, ostatus);
      return;
    end;

    begin 
      select o.status, o.num_order 
      into v_order_status, v_num_order
      from pdd.testing t, orders o 
      where t.ip_addr=v_ip_addr 
      and   o.num_order=t.id_registration
      and   o.status = 'testing'
      and trunc(o.date_order)=trunc(sysdate);
    exception when no_data_found then 
        ostatus:='LOCK ORDER. ACTIVE ORDERS NOT FOUND. ip_addr: '||v_ip_addr||', code_center: '||v_code_center;
        log('E', 'stop_testing_with_num_camera', inum_camera, ostatus);
        return;
    end;

    if v_order_status != 'Stopped' then
        insert into photos ph (num_order, date_photo, num_photo, cipher, code_mistake, photo)
               values(v_num_order, sysdate, 1, 'LP', 406, image);
    else
        ostatus:='LOCK ORDER. TESTING already STOPPED. ip_addr: '||v_ip_addr||', code_center: '||v_code_center;
        log('I', 'stop_testing_with_num_camera', v_num_order, ostatus);
        return;
    end if;
    
    ostatus:='LOCK ORDER. TESTING LOCKED. ip_addr: '||v_ip_addr||', code_center: '||v_code_center;
    log('I', 'stop_testing_with_num_camera', v_num_order, ostatus);
-----------------------------------------------    
    -- Iinea ioeaaee aeie update oaaeeou
    -- e ?aneiiiaioe?iaaou ooieoe? stop_testing(...  
    update pdd.orders o
    set o.mistake = 'Proctoring',
        o.proctoring = 'Y'
    where o.num_order=v_num_order;
    
--    stop_testing(v_num_order, 'Proctoring');
-----------------------------------------------
    commit;
  end stop_testing_with_num_camera;
--*/  
  function  do_fc(inum_order in number) return pls_integer
  is
    row_t   pdd.testing%rowtype;
    row_fc  pdd.face_control_event%rowtype;
  begin
    select * into row_t from pdd.testing t where t.id_registration=inum_order;
    correct_time_remain(inum_order, row_t.last_time_access, row_t.remain_time);
    
--    log('I', 'do_fc', inum_order, 'status_testing: '||row_t.status_testing);

    select * into row_fc
    from pdd.face_control_event ev
    where ev.num_order=inum_order
    and ev.theme_number = row_t.current_theme_number
    and ev.num_question=row_t.current_num_question;

    if row_fc.status='C' then
        return 0;
    end if;
    if row_fc.status='W' then
       update pdd.face_control_event ev
       set ev.status='E'
       where ev.num_order=inum_order
       and ev.theme_number = row_t.current_theme_number
       and ev.num_question=row_t.current_num_question;

       update pdd.testing t
       set t.status_testing='CheckFC',
           t.last_time_access=systimestamp
       where t.id_registration=inum_order;
       commit;
    end if;
    return 1;
    exception when no_data_found then return 0;
  end;

  procedure get_theme(inum_order in number, otheme_number out pls_integer,
                        ocategory out nvarchar2, odescr out nvarchar2,
                        ocount_question out number,
                        ostatus_testing out nvarchar2)
  is
    row_t   pdd.testing%rowtype;
  begin
    select * into row_t from pdd.testing t where t.id_registration=inum_order;

    select o.category, th.descr, tft.count_question
    into ocategory, odescr, ocount_question
    from pdd_testing.themes th, pdd.themes_for_testing tft, pdd.orders o
    where th.id_theme=tft.id_theme
    and   tft.id_registration=inum_order
--    and t.id_registration=inum_order
    and tft.id_registration=o.num_order
    and tft.theme_number=row_t.current_theme_number;

--    log('I', 'get_theme', inum_order, 'theme_number: '||row_t.current_theme_number||
--        ', status_testing: '||row_t.status_testing);
    ostatus_testing:=row_t.status_testing;
    otheme_number:=row_t.current_theme_number;
    if do_fc(inum_order) > 0
    then
       ostatus_testing:='CheckFC';
       return;
    end if;
    exception when no_data_found then
    begin
        log('E', 'get_theme', inum_order, 'THEME NOT FOUND');
        otheme_number:=0;
        ocategory:='';
        odescr:='';
        ostatus_testing:='';
    end;
  end;

--  function get_question(inum_order in number) return nvarchar2
--  is
--  omess nvarchar2(128);
--  begin
--    select q.question
--    into omess
--    from pdd_testing.questions q,
--         pdd.questions_for_testing qft,
--         pdd.themes_for_testing tft,
--         pdd.testing t
--    where qft.id_question=q.id_question
--    and qft.id_registration=t.id_registration
--    and qft.order_num_question=t.current_num_question
--    and tft.id_registration=inum_order
--    and tft.theme_number=t.current_theme_number
--    and q.theme_number=tft.theme_number
--    and t.status='Active'
--    and t.id_registration=inum_order;
--
--    return omess;
--  end;

  procedure get_question(inum_order in number, oremain_time out number, 
                         oorder_num_question out number,
                         oquestion out nvarchar2, ourl_image out nvarchar2)
  is
    r_testing pdd.testing%rowtype;
  begin
    select * into r_testing 
    from testing t 
    where t.id_registration=inum_order
    and t.status='Active';
    oremain_time := correct_time_remain(inum_order, r_testing.last_time_access, r_testing.remain_time);

--    get_remain_time(r_testing.last_time_access, r_testing.remain_time);
    
    select qft.order_num_question, q.question, q.url_image
    into oorder_num_question, oquestion, ourl_image
    from pdd_testing.questions q, pdd.questions_for_testing qft
    where qft.id_question=q.id_question
    and qft.id_registration=inum_order
    and qft.order_num_question=r_testing.current_num_question
    and qft.theme_number = r_testing.current_theme_number;
    log('I', 'get_question', inum_order, 'Remain_time: '||oremain_time||
        ', Current_num_question: '||r_testing.current_num_question);

    exception when no_data_found then
    begin
        log('E', 'get_question', inum_order, 'Question NOT FOUND');
        oorder_num_question:=1;
        oquestion:='';
        ourl_image:='';
    end;
  end;

  procedure set_answer(inum_order in number, iorder_num_answer in number)
  is
    v_id_question_for_testing questions_for_testing.id_question_for_testing%type;
    v_id_answer  pls_integer;
    row_t        pdd.testing%rowtype;
    rem_time     pls_integer default 0;
  begin
    select * into row_t from pdd.testing t where t.id_registration=inum_order;
    rem_time:=get_remain_time(row_t.last_time_access, row_t.remain_time);
    if rem_time > 0
    then
        select  id_question_for_testing
        into    v_id_question_for_testing
        from    pdd.questions_for_testing qft
        where qft.id_registration=row_t.id_registration
        and   qft.order_num_question=row_t.current_num_question
        and   qft.theme_number=row_t.current_theme_number
        and   qft.id_registration=inum_order;

        select id_answer
        into v_id_answer
        from pdd.answers_in_testing ait
        where ait.order_num_answer=iorder_num_answer
        and   ait.id_question_for_testing = v_id_question_for_testing;

        update pdd.questions_for_testing qft
        set    qft.id_answer=v_id_answer,
               qft.time_reply=systimestamp
        where qft.id_question_for_testing=v_id_question_for_testing;
        commit;

        log('I', 'set_answer', inum_order, 'theme_number: '||row_t.current_theme_number||', remain_time:'||row_t.remain_time||
               ', Q_number: '||row_t.current_num_question||', A_number: '||iorder_num_answer||', Q_id: '||v_id_question_for_testing);
    else
        log('E', 'set_answer', inum_order, 'REMAN_TIME is OUT. theme_number: '||row_t.current_theme_number||', remain_time:'||row_t.remain_time||
               ', Q_number: '||row_t.current_num_question||', A_number: '||iorder_num_answer||', Q_id: '||v_id_question_for_testing);
    end if;
    exception when others then
      log('E', 'set_answer', inum_order, 'iorder_num_answer: '||iorder_num_answer||
               ', id_question_for_testing: '||v_id_question_for_testing||
               ', v_id_answer: '||v_id_answer||' : '||sqlerrm);
  end;

  procedure set_answer(inum_order in number, inum_order_question in number, iorder_num_answer in number)
  is
    v_id_question_for_testing questions_for_testing.id_question_for_testing%type;
    v_id_answer  pls_integer;
    row_t        pdd.testing%rowtype;
    rem_time     pls_integer default 0;
  begin
    select * into row_t from pdd.testing t where t.id_registration=inum_order;
    rem_time:=get_remain_time(row_t.last_time_access, row_t.remain_time);
    if rem_time > 0
    then
        select  id_question_for_testing
        into    v_id_question_for_testing
        from    pdd.questions_for_testing qft
        where qft.id_registration=inum_order
        and   qft.order_num_question=inum_order_question
        and   qft.theme_number=row_t.current_theme_number;

        select id_answer
        into v_id_answer
        from pdd.answers_in_testing ait
        where ait.order_num_answer=iorder_num_answer
        and   ait.id_question_for_testing = v_id_question_for_testing;

        update pdd.questions_for_testing qft
        set    qft.id_answer=v_id_answer,
               qft.time_reply=systimestamp
        where qft.id_question_for_testing=v_id_question_for_testing;
        commit;

        log('I', 'set_answer', inum_order, 'theme_number: '||row_t.current_theme_number||', remain_time:'||row_t.remain_time||
               ', Q_number: '||row_t.current_num_question||', A_number: '||iorder_num_answer||', Q_id: '||v_id_question_for_testing);
    else
        log('E', 'set_answer', inum_order, 'REMAN_TIME is OUT. theme_number: '||row_t.current_theme_number||', remain_time:'||row_t.remain_time||
               ', Q_number: '||row_t.current_num_question||', A_number: '||iorder_num_answer||', Q_id: '||v_id_question_for_testing);
    end if;
    exception when others then
      log('E', 'set_answer', inum_order, 'iorder_num_answer: '||iorder_num_answer||
               ', id_question_for_testing: '||v_id_question_for_testing||
               ', v_id_answer: '||v_id_answer||' : '||sqlerrm);
  end set_answer;


  function next_theme(iid_registration in number) return pls_integer
  is
    row_tft         themes_for_testing%rowtype;
    row_t           testing%rowtype;
  begin
    select * into row_t from pdd.testing t where t.id_registration=iid_registration;
    
--    log('I', 'next_theme', iid_registration, 'current_theme_number: '||row_t.current_theme_number);


    update pdd.themes_for_testing tft
    set tft.remain_time=row_t.remain_time,
        tft.status = 'Completed',
        tft.date_stop = sysdate
    where tft.id_registration=iid_registration
    and tft.theme_number=row_t.current_theme_number;
    commit;

    begin
        select  tft.* into row_tft
        from    pdd.themes_for_testing tft
        where tft.id_registration=iid_registration
        and   tft.theme_number=row_t.current_theme_number+1;

        update pdd.testing t
        set t.current_theme_number=row_tft.theme_number,
            t.remain_time = row_tft.period_for_testing,
            t.period_for_testing = row_tft.period_for_testing,
            t.last_time_access=systimestamp,
            t.current_num_question=1
        where t.id_registration=iid_registration;
        commit;
        return row_tft.remain_time;
    exception when no_data_found then return -100;
    end;
  end;

-- Ia eniieucoaony? Iaai i?ioanoe?iaaou
  procedure navigate_finish(iid_registration in number)
  is
  begin
       update pdd.testing t
       set    t.end_time_testing=systimestamp,
              t.status_testing='Completed'
       where  t.id_registration=iid_registration;

       update pdd.orders o
       set    o.status='Completed',
              o.end_time_testing = sysdate
       where  o.num_order=iid_registration;
       commit;
  end;

  function navigate_question(inum_order in number, icommand in number)
    return number
  is
   --v_status_testing  testing.status_testing%type;
   v_count_question pls_integer;
   v_cur_num_question pls_integer;
   v_remain_time      pls_integer;
   v_theme_number     pls_integer;
--   v_id_theme         pls_integer;
    row_t   pdd.testing%rowtype;
  begin
    begin
        select * into row_t 
        from pdd.testing t 
        where t.id_registration=inum_order
        and   t.status='Active';
    exception when no_data_found then
      log('E', 'navigate_question', inum_order, 'Error! Absent Active Tessing!');
      return 0;
    end;
    v_theme_number:=row_t.current_theme_number;
    v_remain_time:=correct_time_remain(inum_order, row_t.last_time_access, row_t.remain_time);

    v_remain_time:=case when v_remain_time<0 then 0 else v_remain_time end;
    if v_remain_time=0 then
      log('E', 'navigate_question', inum_order, 'TIME IS OUT. command: '||icommand||
              ', theme_number: '||row_t.current_theme_number||', num_question: '||
              row_t.current_num_question||', time remain: '||v_remain_time);
      return 0;
    end if;
    if row_t.status_testing='Completed' then
      log('E', 'navigate_question', inum_order, 'Testing Completed. command: '||icommand||
              ', theme_number: '||row_t.current_theme_number||', num_question: '||
              row_t.current_num_question||', time remain: '||v_remain_time);
      return 0;
    end if;

    /* Eaai a ia?aei, e ia?aiio iaioaa?aiiiio aii?ino */
    if icommand=5 or row_t.status_testing='checking' then
--    log('I', 'navigate_question', inum_order, '2. icommand: '||icommand);
       begin
          select order_num_question, theme_number
          into v_cur_num_question, v_theme_number
          from (
              select q.order_num_question, q.theme_number
              from pdd.testing t, pdd.questions_for_testing q
              where t.id_registration=q.id_registration
              and   t.id_registration=inum_order
              and t.status='Active'
              and coalesce(q.id_answer,0)=0
              order by theme_number, order_num_question
          )
          where rownum=1;

--          log('I', 'navigate_question','Commmand=5. Result. v_cur_num_question: '||v_cur_num_question||', id_theme: '||v_theme_number||', v_id_registration: '||v_id_registration);
          if row_t.status_testing!='checking'
          then
              update pdd.testing t
              set t.status_testing='checking'
              where t.id_registration=inum_order;
          end if;

       exception when no_data_found then
          if row_t.status_testing='checking'
          then
--              log('I', 'navigate_question', 'Commmand=5. Exception Finish.'|| v_id_registration);
              navigate_finish(inum_order);
              return -100; --Say WEB all was done
          else
              select order_num_question, theme_number
              into v_cur_num_question, v_theme_number
              from (
                  select q.order_num_question, q.theme_number
                  from  pdd.testing t, pdd.questions_for_testing q
                  where t.id_registration=q.id_registration
                  and   q.theme_number=t.current_theme_number
                  and   t.id_registration=inum_order
                  and   t.status='Active'
                  order by q.theme_number, q.order_num_question
              )
              where rownum=1;
          end if;

--          log('I', 'navigate_question', 'Commmand=5. Exception Select. v_cur_num_question: '||v_cur_num_question||', id_theme: '||v_theme_number||', v_id_registration: '||v_id_registration);
          update pdd.testing t
          set t.status_testing='full_checking'
          where t.id_registration=inum_order;
       end;

--       log('Commmand=5. Update. v_cur_num_question: '||v_cur_num_question||', id_theme: '||v_theme_number||', v_id_registration: '||v_id_registration);
       update pdd.testing t
       set    t.current_num_question=v_cur_num_question,
              t.current_theme_number=v_theme_number
       where  t.id_registration=inum_order;
       commit;
       return v_remain_time;
    end if;
    /* Go To start: First Theme, First Question */
    if icommand=0 then
       update pdd.testing t
       set    t.current_num_question=1,
              t.current_theme_number=1
       where  t.id_registration=inum_order;
    end if;
    /* Go To First Question */
    if icommand=1 then
       update pdd.testing t
       set    t.current_num_question=1
       where  t.id_registration=inum_order;

       update pdd.face_control_event ev
       set    ev.status='W'
       where  ev.num_order=inum_order;
    end if;

    begin
    /*Auoauei iauaa eiee?anoai aii?inia e inoaaoaany a?aiy aey oanoe?iaiey*/
     select tft.count_question into v_count_question
     from pdd.themes_for_testing tft
     where tft.id_registration=inum_order
     and   tft.theme_number=row_t.current_theme_number;

    exception when no_data_found then
      log('E', 'navigate_question', inum_order, 'Error! Absent Active Tessing!');
      return 0;
    end;

    /* Go To Last Question */
    if icommand=11 then
       update pdd.testing t
       set    t.current_num_question=v_count_question
       where  t.id_registration=inum_order;
    end if;
    /* */
    /* Go To Last Theme, First Question */
    if icommand=10 then
       select coalesce(max(theme_number),0)
       into v_theme_number
       from pdd.themes_for_testing tft
       where tft.id_registration=inum_order;

       update pdd.testing t
       set    t.current_num_question=1,
              t.current_theme_number=v_theme_number
       where  t.id_registration=inum_order;
    end if;
    /* Next Question */
    if icommand=12 then
--        log('I', 'navigate_question', inum_order, '3. icommand: '||icommand);
       if row_t.current_num_question<v_count_question then
          update pdd.testing t
          set   t.current_num_question=t.current_num_question+1
          where  t.id_registration=inum_order;
       end if;
    end if;
    /* Previous Question */
    if icommand=2 then
       if row_t.current_num_question>1 then
          update pdd.testing t
          set    t.current_num_question=t.current_num_question-1
          where  t.id_registration=inum_order;

          update pdd.face_control_event ev
          set    ev.status='W'
          where  ev.num_order=inum_order;
       end if;
    end if;

    commit;
    return v_remain_time;
  end;

  function finish_info(inum_order in number) return nvarchar2
  is
    v_unanswered       pls_integer;
  begin

      select count(q.id_question)
      into v_unanswered
      from pdd.questions_for_testing q, pdd.testing t
      where   q.id_registration=inum_order
      and   t.id_registration=q.id_registration
      and   t.current_theme_number = q.theme_number
      and coalesce(q.id_answer,0)=0;

      if v_unanswered>0 then
--        log('I', 'finish_info', inum_order, 'Eia?ony iaioaa?aiiua aii?inu a eiee?anoaa: ' ||v_unanswered);
         return to_char(v_unanswered);
      end if;
      return '';
  end;

  function have_test(inum_order in number) return number
  is
    v_cnt        pls_integer;
  begin
    select t.period_for_testing into v_cnt
    from    pdd.testing t
    where t.status='Active'
    and   t.id_registration=inum_order;

    update  pdd.testing t
    set     t.last_time_access=systimestamp
    where   t.id_registration=inum_order;

    update pdd.testing t
    set t.beg_time_testing=systimestamp,
        t.status_testing='Testing'
    where t.status='Active'
    and   t.id_registration=inum_order;
    commit;
    return v_cnt;
    exception when no_data_found then return '';
  end;

  procedure get_user_login_info( inum_order in number,
            ofio out nvarchar2,  oiin out varchar2,
            ocategory out nvarchar2, ostatus out nvarchar2, omistake out varchar2)
  is
    v_hour number;
    v_id_region pls_integer default 0;
  begin
    select extract(hour from systimestamp)+6 + extract(minute from systimestamp)/100
            into v_hour 
    from dual;
    
    select p.fio, p.iin, o.category, c.id_region, o.status, o.mistake
    into   ofio, oiin, ocategory, v_id_region, ostatus, omistake
    from   pdd.persons p, pdd.orders o, cop.centers c
    where  o.num_order=inum_order
    and    p.iin=o.iin
    and    o.id_center=c.id_center;
--  Define work time for different region  
--/*
    if inum_order!=9 and inum_order!=13  and inum_order!=100000000035 then
      if ( v_id_region in (20, 19, 12, 7, 11) and ( v_hour>18.30 or v_hour<10 ) )
          or 
         ( v_id_region not in (20, 19, 12, 7, 11) and (v_hour>17.30 or v_hour<9 ))
      then    
          ostatus := 'WORK_TIME_OUT';
      end if;
    end if;
--*/
    log('I', 'get_user_login_info', inum_order, 'iin: '||oiin||', ofio: '||ofio);
    
    exception when no_data_found then
        log('E', 'get_user_login_info', inum_order, 'iin: '||oiin||', ofio: '||ofio);
        ostatus:='ABSENT';
  end;


  procedure get_personal_info( inum_order in number,
                             oiin out varchar2, otime_beg out date,
                             otime_end out date, ofio out nvarchar2 )
  is
  begin
    select p.iin, beg_time_testing, end_time_testing, fio
    into oiin, otime_beg, otime_end, ofio
    from pdd.persons p, pdd.testing t
    where t.id_registration=inum_order
    and   p.id_person=t.id_person
    and   t.status='Active';
    exception when no_data_found
      then begin
        oiin:='';
        otime_beg:='';
        otime_end:='';
        ofio:='';
      end;
  end;


  function get_result(iid_registration in number) return sys_refcursor
  is
    rf_cur sys_refcursor;
  begin
      open rf_cur for
          select theme_number, descr, count_question, count_success,
                 sum(true_result) true_score,
                 sum(false_result) false_score
          from(
          select qft.theme_number, th.descr, tft.count_question, tft.count_success,
                 case when correctly='Y' then 1 else 0 end true_result,
                 case when correctly!='Y' then 1 else 0 end false_result
          from pdd.questions_for_testing qft, pdd_testing.answers a,
               pdd.themes_for_testing tft, pdd_testing.themes th
          where qft.id_registration=tft.id_registration
          and   qft.theme_number=th.theme_number
          and   a.id_answer(+)=qft.id_answer
          and   tft.id_registration=iid_registration
          and   tft.id_theme=th.id_theme
          )
          group by theme_number, count_question, count_success, descr;
      return rf_cur;
  end;

  procedure get_time_testing(inum_order in number,
            oused_minute out pls_integer,
            oused_seconds out pls_integer
            )
  is
  begin
    select floor(sum(tft.period_for_testing-tft.remain_time)/60) used_minute,
           mod(sum(tft.period_for_testing-tft.remain_time),60) used_second
           into oused_minute, oused_seconds
    from    pdd.themes_for_testing tft
    where tft.id_registration=inum_order;
  end;
  
  procedure get_current_info(inum_order in number,
            otheme_number out number,
            ocurr_question out pls_integer,
            oremain_time out pls_integer,
            ocategory out nvarchar2,
            oiin  out varchar2,
            ofio out nvarchar2,
            ostatus out nvarchar2
            )
  is
    row_testing pdd.testing%rowtype;
    row_order  pdd.orders%rowtype;
    row_person  pdd.persons%rowtype;
  begin
    select * into row_testing from testing t where t.id_registration=inum_order;
    select * into row_order from orders o where o.num_order=inum_order;    
    select * into row_person from persons p where p.id_person=row_testing.id_person;    

    otheme_number:=row_testing.current_theme_number;
    ocurr_question:=row_testing.current_num_question;
    oremain_time:=get_remain_time(row_testing.last_time_access,row_testing.remain_time);
    ocategory:=row_order.category;
    oiin:=row_person.iin;
    ofio:=row_person.fio;
    ostatus:=row_order.status;

    exception when no_data_found then
    begin
        otheme_number:=0;
        ocurr_question:=0;
        oremain_time:=0;
        ocategory:='';
        oiin:='';
        ofio:='';
        ostatus:='';
        log('E', 'get_current_info', inum_order, 'ERROR. INFORMATION not found');
    end;
  end;

  procedure get_current_info2(inum_order in number,
            otheme_number out number,
            ocurr_question out pls_integer,
            oremain_time out pls_integer,
            ocategory out nvarchar2,
            oiin  out varchar2,
            ofio out nvarchar2,
            ostatus out nvarchar2,
            list_answered_questions out varchar2
            )
  is
  begin
    get_current_info(inum_order, otheme_number, ocurr_question, oremain_time, ocategory, oiin, ofio, ostatus);
    list_answered_questions := get_answered_questions(inum_order);
    --list_answered_questions(inum_order, otheme_number);
    null;
  end;



  procedure get_result_part_1(inum_order in number,
            ostatus out varchar2,
            otheme_number out number,
            ocategory out nvarchar2,
            oiin  out varchar2,
            ofio out nvarchar2
            )
  is
  begin
    select case
                when sum(true_result)<count_success
                then 'failed'
                else 'passed'
           end status, category, theme_number, iin, FIO
    into ostatus, ocategory, otheme_number, oiin, ofio
    from(
    select tft.theme_number, p.fio, p.iin, o.category, tft.count_success,
         case when correctly='Y' then 1 else 0 end true_result,
         case when correctly!='Y' then 1 else 0 end false_result,
         (tft.period_for_testing-tft.remain_time) testing_time
    from pdd.questions_for_testing qft, pdd_testing.answers a, pdd.testing t,
         pdd.themes_for_testing tft, pdd.orders o,
         pdd_testing.themes th, pdd.persons p
    where qft.id_registration=tft.id_registration
    and   qft.theme_number=th.theme_number
    and   a.id_answer(+)=qft.id_answer
    and   tft.id_theme=th.id_theme
    and   t.current_theme_number=tft.theme_number
    and   t.id_registration=inum_order
    and   p.id_person=t.id_person
    and   t.id_registration=tft.id_registration
    and   t.id_registration=o.num_order
    )
    group by theme_number, iin, fio, category, count_success;

    exception when no_data_found then
    begin
        ostatus:='Oaeouee oano o?a caaa?oai';
        otheme_number:=0;
        ocategory:='';
        oiin:='';
        ofio:='';
        log('I', 'get_result_part_1', inum_order, 'Status: '||ostatus);
    end;
  end;

  procedure get_result_part_2(inum_order in number,
            ocount_question out number,
            ocount_success out number,
            otrue_result out varchar2,
            ofalse_result out varchar2
            )
  is
  begin
    select   count_question,
             count_success,
             to_char(sum(true_result)) true_score,
             to_char(sum(false_result)) false_score
    into ocount_question,
         ocount_success,
         otrue_result, ofalse_result
    from(
    select p.fio, p.iin,
         qft.theme_number, th.descr as theme_name,
         tft.count_question, tft.count_success,
         case when correctly='Y' then 1 else 0 end true_result,
         case when correctly!='Y' then 1 else 0 end false_result
    from pdd.questions_for_testing qft, pdd.testing t, pdd.themes_for_testing tft,
       pdd_testing.themes th, pdd_testing.answers a, pdd.persons p
    where qft.id_registration=tft.id_registration
    and   qft.theme_number=th.theme_number
    and   a.id_answer(+)=qft.id_answer
    and   tft.id_theme=th.id_theme
    and   t.current_theme_number=tft.theme_number
    and   t.id_registration=inum_order
    and   p.id_person=t.id_person
    and   t.id_registration=tft.id_registration
    )
    group by fio, iin, theme_number, count_question, count_success, theme_name;
--    log('I', 'get_result_part_1', 'Get Result Part. Count Success: '||ocount_success);
  end;

  procedure add_photo(inum_order in number, iip_addr in varchar2,
            icipher in char, icode_mistake in number, iphoto in blob)
  is
  v_count_photo pls_integer default 0;
  begin
    log('I', 'add_photo', inum_order, 'ip_addr: '||iip_addr||', cipher: '||icipher||', mistake: '||icode_mistake);
    v_count_photo:=count_photo(inum_order);
    begin
        insert into photos (num_order, date_photo, num_photo, cipher, code_mistake, photo)
            values(inum_order, sysdate, v_count_photo+1, icipher, icode_mistake, iphoto);
    exception
        when dup_val_on_index then
            log('E', 'add_photo', inum_order, 'Duplicate Photo. ip_addr: '||iip_addr||
                     ', num_photo: '||(v_count_photo+1)||
                     ', cipher: '||icipher||', mistake: '||icode_mistake);
--            insert into photos (num_order, date_photo, num_photo, cipher, code_mistake, photo)
--                values(inum_order, sysdate, v_count_photo+1, icipher, icode_mistake, iphoto);
            null;
    end;
    if icode_mistake>0 and icipher='LV' then
        log('E', 'add_photo', inum_order, 'Fail Recogniiton. ip_addr: '||iip_addr||
                 ', cipher: '||icipher||', mistake: '||icode_mistake);
        update pdd.orders o
        set o.end_time_testing=systimestamp,
            o.status = 'Completed',
            o.result = 'failed',
            o.extend_status='Fail recognition',
            o.mistake = 'Fail recognition'
        where o.num_order=inum_order;

        begin
            update pdd.testing t
            set     t.status_testing='Fail recognition',
                    t.status='failed',
                    t.end_time_testing=systimestamp
            where   t.id_registration=inum_order;
            exception when no_data_found then null;
        end;
    end if;
    commit;
  end;

  procedure get_person_photo(iiin in varchar2, status out char, ophoto out blob)
  is
  begin
--    v_photo:=0;
    select photo into ophoto
    from pdd.persons_photo p
    where p.iin = iiin;
    status:='S';
  exception when no_data_found then status:='F';
  end;

  procedure save_person_photo(iiin in varchar2, iphoto in blob)
  is
  begin
--    v_photo:=0;
    insert into pdd.persons_photo(iin, date_op, photo) values(iiin, sysdate, iphoto);
    commit;    
    log('I', 'save_person_photo', 0, 'Saved photo for '||iiin);
    exception when dup_val_on_index then null;
  end;

  procedure del_person_photo(iiin in varchar2)
  is
  begin
--    v_photo:=0;
    delete from pdd.persons_photo p where p.iin = iiin;
    log('I', 'del_person_photo', 0, 'Deleted photo for '||iiin);
    exception when no_data_found then null;
  end;

  procedure replace_person_photo(iiin in varchar2, iphoto in blob)
  is
    v_date pdd.persons_photo.date_op%type;
  begin
    if length(iphoto)> 512 then
        select date_op into v_date from pdd.persons_photo p where p.iin=iiin;
        if add_months(v_date,1)<sysdate then
            del_person_photo(iiin);
            save_person_photo(iiin, iphoto);
        end if;
    else
        log('E', 'replace_person_photo', 0, 'Mistake length photo for: '||iiin);
    end if;
    exception when no_data_found then
        save_person_photo(iiin, iphoto);
  end;

  function get_photo(inum_order in number, isrc in char, inum_photo in number)
            return clob
  is
  v_photo clob;
  begin
--    v_photo:=0;
    select photo into v_photo
    from pdd.photos p
    where p.num_order = inum_order
    and   p.cipher=coalesce(isrc,'LZ')
    and   p.num_photo = coalesce(inum_photo,1);
    return v_photo;
  end;

  function count_photo(inum_order in number) return pls_integer
  is
  v_count pls_integer;
  begin
    select coalesce(max(num_photo),0)
    into v_count
    from pdd.photos p where p.num_order=inum_order;
    return v_count;
  end;

 procedure calc_and_save_result(inum_order in number, ores out varchar2)
  is
    rec_testing     testing%rowtype;
    res             orders.result%type;
    cnt_themes      pls_integer default 0;
  begin
    begin
      --  In slow channel function may be called few times
      select * into rec_testing
      from pdd.testing t
      where t.id_registration=inum_order;

      if rec_testing.status_testing='Completed' then
           ores:=rec_testing.status;
           log('I', 'calc_and_save_result', inum_order, 'status: '||rec_testing.status||', remain_time: '||rec_testing.remain_time);
            return;
      end if;
      correct_time_remain(inum_order, rec_testing.last_time_access, rec_testing.remain_time);
    exception when no_data_found then
        ores:='Order not found: '||inum_order;
        log('I', 'calc_and_save_result', inum_order, 'TESTING not found');
        return;
    end;
    
    if rec_testing.status='Active' and rec_testing.status_testing!='Completed'
    then
        res:='failed';
        for cur in (
                select tft.theme_number, tft.count_success, count(a.correctly) scores
                from pdd.questions_for_testing qft,
                     pdd_testing.answers a, pdd.themes_for_testing tft
                where qft.id_registration=inum_order
                and   coalesce(qft.id_answer,0)=a.id_answer(+)
                and   qft.id_registration=tft.id_registration
                and   qft.theme_number=tft.theme_number
                and   a.correctly='Y'
                group by tft.theme_number, tft.count_success
                )
        loop
          cnt_themes:=cnt_themes+1;
          update pdd.themes_for_testing tft
          set tft.scores = cur.scores
          where tft.id_registration = inum_order
          and   tft.theme_number = cur.theme_number;
          if  cur.theme_number=2 and cur.scores>=cur.count_success then
            res:='passed';
          end if;
        end loop;

        ores:=res;
        update pdd.orders o
        set o.status='Completed',
            o.result=res,
            o.end_time_testing=systimestamp
        where o.num_order=inum_order;

        update pdd.testing t
        set   t.status_testing='Completed',
              t.status = res,
              t.end_time_testing=systimestamp
        where t.id_registration=rec_testing.id_registration;
        log('I', 'calc_and_save_result', inum_order, 'status: '||rec_testing.status||', remain_time: '||rec_testing.remain_time);
    else
        log('I', 'calc_and_save_result', inum_order, 'status: '||rec_testing.status||', status_testing: '||rec_testing.status_testing||', remain_time: '||rec_testing.remain_time);
    end if;

    update pdd.themes_for_testing tft
    set tft.remain_time=rec_testing.remain_time,
        tft.date_stop = sysdate,
        tft.status='Completed'
    where tft.id_registration=inum_order
    and tft.theme_number=rec_testing.current_theme_number;


    commit;
  end calc_and_save_result;
-- I?iaa?eou ia oaaeaiea, 06.04.2022
 procedure calc_and_save_result(inum_order in number)
  is
    rec_testing     testing%rowtype;
    res             orders.result%type;
    cnt_themes      pls_integer default 0;
  begin
    begin
      select * into rec_testing
      from pdd.testing t
      where t.id_registration=inum_order
      and t.status='Active';
    exception when no_data_found then
         log('E', 'finish', inum_order, 'Order not found: '||rec_testing.status);
         null;
    end;
    log('I', 'finish', inum_order, '-----> Order status: '||rec_testing.status||
        ', rec_testing.status_testing: '||rec_testing.status_testing);

        --  IF calculated then return result   
        if rec_testing.status_testing!='Completed'
        then
            res:='failed';
            for cur in (
                    select tft.theme_number, tft.count_success, count(a.correctly) scores
                    from pdd.questions_for_testing qft,
                         pdd_testing.answers a, pdd.themes_for_testing tft
                    where qft.id_registration=inum_order
                    and   coalesce(qft.id_answer,0)=a.id_answer(+)
                    and   qft.id_registration=tft.id_registration
                    and   qft.theme_number=tft.theme_number
                    and   a.correctly='Y'
                    group by tft.theme_number, tft.count_success
                    )
            loop
              cnt_themes:=cnt_themes+1;
              update pdd.themes_for_testing tft
              set tft.scores = cur.scores
              where tft.id_registration = inum_order
              and   tft.theme_number = cur.theme_number;
              if  cur.theme_number=2 and cur.scores>=cur.count_success then
                res:='passed';
              end if;
            end loop;

            update pdd.orders o
            set o.status='Completed',
                o.result=res,
                o.end_time_testing=systimestamp
            where o.num_order=inum_order;

            update pdd.testing t
            set   t.status_testing='Completed',
                  t.status = res,
                  t.end_time_testing=systimestamp
            where t.id_registration=rec_testing.id_registration;
        end if;
--    end if;

    update pdd.themes_for_testing tft
    set tft.remain_time=rec_testing.remain_time,
        tft.date_stop = sysdate,
        tft.status='Completed'
    where tft.id_registration=inum_order
    and tft.theme_number=rec_testing.current_theme_number;

   log('I', 'finish', inum_order, 'remain_time: '||rec_testing.remain_time);

    commit;
  end;
  
  procedure set_lr_fail_recognition(inum_order in number)
  is
    rec_testing     testing%rowtype;
    rec_orders      orders%rowtype;
  begin
    select * into rec_orders from orders o where o.num_order=inum_order;
    if rec_orders.result='passed' and rec_orders.status='Completed' then
    begin
        select * into rec_testing
        from pdd.testing t
        where t.id_registration=inum_order;
        
        update pdd.orders o
        set o.end_time_testing=systimestamp,
            o.status = 'Completed',
            o.result = 'suspend',
            o.extend_status='Fail recognition',
            o.mistake = 'Fail recognition'
        where o.num_order=inum_order;
    
        update pdd.testing t
        set     t.status_testing='Fail recognition',
                t.status='failed',
                t.end_time_testing=systimestamp
        where   t.id_registration=inum_order;
    
        update pdd.themes_for_testing tft
        set tft.remain_time=rec_testing.remain_time,
            tft.date_stop = sysdate,
            tft.status='Completed'
        where tft.id_registration=inum_order
        and tft.theme_number=rec_testing.current_theme_number;
        
        commit;
        log('E', 'fail_recognition', inum_order, 'remain_time: '||rec_testing.remain_time);
    end;    
    end if;  
    log('I', 'fail_recognition', inum_order, 'result: '||rec_orders.result||
        'status: '||rec_orders.status||', remain_time: '||rec_testing.remain_time);
  end;
  
  procedure set_lf_fail_recognition(inum_order in number)
  is
    rec_testing     testing%rowtype;
    rec_orders      orders%rowtype;
  begin
    select * into rec_orders from orders o where o.num_order=inum_order;

    select * into rec_testing
    from pdd.testing t
    where t.id_registration=inum_order;
    
    update pdd.orders o
    set o.end_time_testing=systimestamp,
        o.status = 'Completed',
        o.result = 'failed',
        o.extend_status='Fail recognition',
        o.mistake = 'Fail recognition'
    where o.num_order=inum_order;

    update pdd.testing t
    set     t.status_testing='Fail recognition',
            t.status='failed',
            t.end_time_testing=systimestamp
    where   t.id_registration=inum_order;

    update pdd.themes_for_testing tft
    set tft.remain_time=rec_testing.remain_time,
        tft.date_stop = sysdate,
        tft.status='Completed'
    where tft.id_registration=inum_order
    and tft.theme_number=rec_testing.current_theme_number;
    
    commit;
    log('I', 'lf_fail_recognition', inum_order, 'result: '||rec_orders.result||
        'status: '||rec_orders.status||', remain_time: '||rec_testing.remain_time);
  end;
  
  procedure lf_fail_recognition(inum_order in number, icode_mistake in pls_integer)
  is
    v_count_photo pls_integer default 0;
  begin
    v_count_photo:=count_photo(inum_order);
    
    insert into photos (num_order, date_photo, num_photo, cipher, code_mistake)
        values(inum_order, sysdate, v_count_photo+1, 'LF', icode_mistake);
    commit;    
    if icode_mistake > 0 then
        set_lf_fail_recognition(inum_order);
        log('E', '---> lf_fail_recognition', inum_order, 'mistake: '||icode_mistake);
    else
        log('I', 'lf_fail_recognition', inum_order, 'icode_mistake: '||icode_mistake);
    end if;    
    exception when dup_val_on_index then 
        log('E', 'lf_fail_recognition', inum_order, 'DUPLICATE PHOTOS with code_mistake: '||icode_mistake);
  end lf_fail_recognition;
  
  procedure finish_check_photos(inum_order in number, omistake out pls_integer)
  is
    cnt_lr pls_integer default 0;
    low_boundry pls_integer default 0;
    
    cnt_mistake_lr_1 pls_integer default 0; -- Another man
    cnt_mistake_lr_2_3 pls_integer default 0; -- Absent or 2 (more) man
    mistake pls_integer default 0;
    v_mistake varchar2(64);
    procent pls_integer default 10;
  begin
    select mistake into v_mistake from orders o where to_number(o.num_order)=inum_order;
    if v_mistake in ('Old photo', 'Proctoring') then
      omistake:=1;
      return;
    end if;
        
    select count(ph.code_mistake) into cnt_lr
    from photos ph
    where ph.num_order=inum_order
    and   ph.cipher = 'LR';
    
    select count(ph.code_mistake)
    into cnt_mistake_lr_1
    from photos ph
    where ph.num_order=inum_order
    and   ph.cipher = 'LR'
    and   code_mistake = 1;
    
    low_boundry := (cnt_lr * procent) / 100;
    if cnt_mistake_lr_1 > low_boundry then
       mistake:=1;
    end if;

    if mistake=0 then
        select count(ph.code_mistake)
        into cnt_mistake_lr_2_3
        from photos ph
        where ph.num_order=inum_order
        and   ph.cipher = 'LR'
        and   code_mistake in (2,3);
        
        low_boundry := (cnt_lr * procent) / 100;
        if cnt_mistake_lr_2_3 > low_boundry then
           mistake:=1;
        end if;
    end if;

    log('I', 'check_photos_recognition', inum_order, '---> mistake: '||mistake||', low_boundry: '||low_boundry||
             ', mistake_lr_1: '||cnt_mistake_lr_1||', cnt_mistake_lr_2_3: '||cnt_mistake_lr_2_3 );

    if mistake>0 then
        set_lr_fail_recognition(inum_order);
    end if;    
    omistake:=mistake;
  end;

  procedure get_mistake(inum_order in number, ostatus out varchar2, oextend_status out varchar2, omistake out varchar2)
  is
  begin
    select status, extend_status, mistake into ostatus, oextend_status, omistake
    from orders o
    where o.num_order=inum_order;
  end;

  procedure get_photo_gbd_fl(inum_order in number, oblob out blob)
  is
  begin
    select photo into oblob 
    from orders o, persons_photo ph
    where o.num_order=inum_order
    and   o.iin=ph.iin;
  end;

    
-- procedure finish(inum_order in number)
--  is
--    rec_testing     testing%rowtype;
--    res             orders.result%type;
--    cnt_themes      pls_integer default 0;
--  begin
--    begin
--      select * into rec_testing
--      from pdd.testing t
--      where t.id_registration=inum_order;
--    exception when no_data_found then
--         log('E', 'finish', inum_order, 'Order not found');
--         null;
--    end;
--
----    if finish_recognition(inum_order)>0 then
--        log('I', '1. finish', inum_order, 'rec_testing.status_testing: '||
--            rec_testing.status_testing||'remain_time: '||rec_testing.remain_time);
--        if rec_testing.status_testing!='Completed'
--        then
--           log('I', '2. finish', inum_order, 'remain_time: '||rec_testing.remain_time);
--        
--            res:='passed';
--            admin2.analyze(inum_order);
--            for cur in (
--                    select tft.theme_number, tft.count_success, count(a.correctly) scores
--                    from pdd.questions_for_testing qft,
--                         pdd_testing.answers a, pdd.themes_for_testing tft
--                    where qft.id_registration=inum_order
--                    and   coalesce(qft.id_answer,0)=a.id_answer(+)
--                    and   qft.id_registration=tft.id_registration
--                    and   qft.theme_number=tft.theme_number
--                    and   a.correctly='Y'
--                    group by tft.theme_number, tft.count_success
--                    )
--            loop
--              cnt_themes:=cnt_themes+1;
--              update pdd.themes_for_testing tft
--              set tft.scores = cur.scores
--              where tft.id_registration = inum_order
--              and   tft.theme_number = cur.theme_number;
--              if cur.theme_number=2 and cur.scores<cur.count_success then
--                res:='failed';
--              end if;
--            end loop;
--
--            update pdd.orders o
--            set o.status='Completed',
--                o.result=res,
--                o.end_time_testing=systimestamp
--            where o.num_order=inum_order;
--
--            update pdd.testing t
--            set   t.status_testing='Completed',
--                  t.status = res,
--                  t.end_time_testing=systimestamp
--            where t.id_registration=rec_testing.id_registration;
--        end if;
----    end if;
--
--    update pdd.themes_for_testing tft
--    set tft.remain_time=rec_testing.remain_time,
--        tft.date_stop = sysdate,
--        tft.status='Completed'
--    where tft.id_registration=inum_order
--    and tft.theme_number=rec_testing.current_theme_number;
--
--   log('I', 'finish', inum_order, 'remain_time: '||rec_testing.remain_time);
--
--    commit;
--  end;
--
--
--  procedure fail_recognition(inum_order in number)
--  is
--    rec_testing     testing%rowtype;
--  begin
--    select * into rec_testing
--    from pdd.testing t
--    where t.status='Active'
--    and t.id_registration=inum_order;
--    
--    update pdd.orders o
--    set o.end_time_testing=systimestamp,
--        o.status = 'Completed',
--        o.result = 'failed',
--        o.extend_status='Fail recognition',
--        o.mistake = 'Fail recognition'
--    where o.num_order=inum_order;
--
--    update pdd.testing t
--    set     t.status_testing='Fail recognition',
--            t.status='failed',
--            t.end_time_testing=systimestamp
--    where   t.id_registration=inum_order;
--
--    update pdd.themes_for_testing tft
--    set tft.remain_time=rec_testing.remain_time,
--        tft.date_stop = sysdate,
--        tft.status='Completed'
--    where tft.id_registration=inum_order
--    and tft.theme_number=rec_testing.current_theme_number;
--
--    commit;
--    
--    log('E', 'fail_recognition', inum_order, 'remain_time: '||rec_testing.remain_time);
--    
--    exception when no_data_found then null;
--  end;
--
--  procedure lf_fail_recognition(inum_order in number, icode_mistake in pls_integer)
--  is
--    v_count_photo pls_integer default 0;
--  begin
--    v_count_photo:=count_photo(inum_order);
--    
--    insert into photos (num_order, date_photo, num_photo, cipher, code_mistake)
--        values(inum_order, sysdate, v_count_photo+1, 'LF', icode_mistake);
--    
--    if icode_mistake>0 then
--        fail_recognition(inum_order);
--    end if;
--    log('E', 'lf_fail_recognition', inum_order, 'mistake: '||icode_mistake);
--  end lf_fail_recognition;
--
--  procedure check_photos_recognition(inum_order in number, omistake out pls_integer)
--  is
--    cnt_lr pls_integer default 0;
--    low_boundry pls_integer default 0;
--    
--    cnt_mistake_lr_1 pls_integer default 0; -- Another man or not identified
--    cnt_mistake_lr_2_3 pls_integer default 0; -- Absent or 2 (more) man
--    mistake pls_integer default 0;
--    procent_mistake pls_integer default 20;
--  begin
--    select count(ph.code_mistake) into cnt_lr
--    from photos ph
--    where ph.num_order=inum_order
--    and   ph.cipher = 'LR';
--    
--    select count(ph.code_mistake)
--    into cnt_mistake_lr_1
--    from photos ph
--    where ph.num_order=inum_order
--    and   ph.cipher = 'LR'
--    and   code_mistake = 1;
--    
--    low_boundry := (cnt_lr * procent_mistake) / 100;
--    if cnt_mistake_lr_1 > low_boundry then
--       mistake:=1;
--    end if;
--
--    if mistake=0 then
--        select count(ph.code_mistake)
--        into cnt_mistake_lr_2_3
--        from photos ph
--        where ph.num_order=inum_order
--        and   ph.cipher = 'LR'
--        and   code_mistake in (2,3);
--        
--        low_boundry := (cnt_lr * procent_mistake) / 100;
--        if cnt_mistake_lr_2_3 > low_boundry then
--           mistake:=1;
--        end if;
--    end if;
--
--    log('I', 'check_photos_recognition', inum_order, 'mistake: '||mistake||', low_boundry: '||low_boundry||
--             ', mistake_lr_1: '||cnt_mistake_lr_1||', cnt_mistake_lr_2_3: '||cnt_mistake_lr_2_3 );
--
--    if mistake>0 then
----        fail_recognition(inum_order);
--        null;
--    end if;    
--    omistake:=mistake;
--  end;

begin
  null;
end test;
/
