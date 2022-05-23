create or replace package admin is

  -- Author  : Shamil Gusseynov
  -- Created : 21.06.2021 14:06:15
  -- Purpose :
  -- Public type declarations
  
  procedure clear_mistake_fc(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2);

 procedure clear_mistake_foreign_citizen(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2);

 procedure set_mistake_old_photo(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2);

  procedure set_permission_order(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2);
--/*
  procedure set_permission_order2(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2, iinfo in varchar2 default 'ACCEPT_RESULT_TEST');
--*/  
  procedure add_question(iid_task in pls_integer, 
                    itheme_number in pls_integer, 
                    iid_registration in number, 
                    iid_category in pls_integer);
  
  procedure clean_all;
  procedure clean_order(inum_order in number);
  procedure clean_order(inum_order in number, iid_user in pls_integer, iip_addr in varchar2);
  
  procedure new_order(inum_order in number, icode_center in nvarchar2, 
            icategory in varchar2, iiin in varchar2, ifio in nvarchar2,
            ostatus out nvarchar2);
  procedure close_order(inum_order in number, 
            iresult in varchar2, istatus_send in varchar2);
            
  procedure login(inum_order in varchar2, iip_addr in varchar2, ilang in varchar2,
        oiin out varchar2, oid_order out number, 
        oremain_time out number, omsg out nvarchar2);
        
  function new_registration(inum_order in number, ilang in varchar2, 
            iip_addr in varchar2) return nvarchar2;

  procedure get_double_ip(inum_order in number, 
            first_ip out varchar2, second_ip out varchar2);

  procedure add_test(iid_registration in number, iip_addr in varchar2, 
            ilang in varchar2, oerr_msg out varchar2);

  procedure add_test_2(iid_registration in number, iip_addr in varchar2, 
            ilang in varchar2, oerr_msg out varchar2);

  procedure add_fc_event(inum_order in number, itheme_number in pls_integer,
    icount_question in pls_integer, icnt_fc in pls_integer);  

  function get_answered_questions(inum_order in number, itheme_number in pls_integer) return varchar2;
  
  procedure force_complete(iid_region in pls_integer);
  
end admin;
/
create or replace package body admin is

  procedure log(itype in char, iproc in varchar2, 
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg) 
        values(systimestamp, itype, 'admin', iproc, 
                coalesce(inum_order,0), substr(imess, 1, 250));
    commit;
    exception when others then
        raise_application_error(-20000, 'LOG. inum_order: '||inum_order||
            ', mess: '||imess||', sqlerrm: '||sqlerrm);
  end;


 procedure set_permission_order2(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2, iinfo in varchar2)
  is
    r_person  cop.users%rowtype;
    r_testing pdd.testing%rowtype;
    v_code_center cop.list_workstation.code_center%type;  
  begin
    begin
        select * into r_person 
        from cop.users r where r.id_user=iid_user;
    exception when no_data_found then 
        log('E', 'set_permission_order', inum_order, 'NOT FOUND USER: '||iid_user);
        return;
    end;    
    
    begin
        select * into r_testing 
        from pdd.testing t 
        where t.id_registration=inum_order;
    exception when no_data_found then 
        log('E', 'set_permission_order', inum_order, 'NOT FOUND Testing: '||inum_order);
    end;    
    
    begin
        select code_center into v_code_center 
        from cop.list_workstation lw 
        where lw.ip_addr = iip_addr;
    exception when no_data_found then 
        log('E', 'set_permission_order', inum_order, 'NOT FOUND Code center for : '||iip_addr);
    end;
    
    insert into permitions p 
      (num_order, date_permit, iin, ip_addr, code_center, 
      current_theme, current_question, fio_oper, info)
    values(inum_order, sysdate, r_person.iin, iip_addr, v_code_center,
    coalesce(r_testing.current_theme_number,0), 
    coalesce(r_testing.current_num_question,0),
    r_person.lastname||' '||r_person.name||' '||r_person.middlename,
    iinfo);

    commit;
  end set_permission_order2;
  
 procedure set_permission_order(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2)
  is
    r_person  cop.users%rowtype;
    r_testing pdd.testing%rowtype;
    v_code_center cop.list_workstation.code_center%type;  
  begin
    begin
        select * into r_person 
        from cop.users r where r.id_user=iid_user;
    exception when no_data_found then 
        log('E', 'set_permission_order', inum_order, 'NOT FOUND USER: '||iid_user);
        return;
    end;    
    
    begin
        select * into r_testing 
        from pdd.testing t 
        where t.id_registration=inum_order;
    exception when no_data_found then 
        log('E', 'set_permission_order', inum_order, 'NOT FOUND Testing: '||inum_order);
    end;    
    
    begin
        select code_center into v_code_center 
        from cop.list_workstation lw 
        where lw.ip_addr = iip_addr;
    exception when no_data_found then 
        log('E', 'set_permission_order', inum_order, 'NOT FOUND Code center for : '||iip_addr);
    end;
    
    insert into permitions p 
    (num_order, date_permit, iin, ip_addr, code_center, 
    current_theme, current_question, fio_oper, info)
    values(inum_order, sysdate, r_person.iin, iip_addr, v_code_center,
    coalesce(r_testing.current_theme_number,0), 
    coalesce(r_testing.current_num_question,0),
    r_person.lastname||' '||r_person.name||' '||r_person.middlename,
    'ACCEPT_RESULT_TEST');

    commit;
  end set_permission_order;  

  procedure set_mistake_old_photo(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2)
  is
    r_person  cop.users%rowtype;
    v_code_center cop.list_workstation.code_center%type;  
   begin
    log('I', '1. set_mistake_old_photo', inum_order, 'SET OLD PHOTO. id-operaator: '||iid_user);
    begin
        select * into r_person 
        from cop.users r where r.id_user=iid_user;
    exception when no_data_found then 
        log('E', 'set_mistake_old_photo', inum_order, 'NOT FOUND USER: '||iid_user);
        return;
    end;    
    
    begin
        select code_center into v_code_center 
        from cop.list_workstation lw 
        where lw.ip_addr = iip_addr;
    exception when no_data_found then 
        log('E', 'set_mistake_old_photo', inum_order, 'NOT FOUND Code center for : '||iip_addr);
    end;
    
    update  pdd.orders o
    set     o.result = '',
            o.status = 'New',
            o.extend_status='',
            o.end_time_testing='',
            o.mistake='Old photo'
    where to_number(o.num_order) = inum_order;

    log('I', 'set_mistake_old_photo', inum_order, 'SET OLD PHOTO. id-operaator: '||iid_user);
    insert into permitions p 
    (num_order, date_permit, iin, ip_addr, code_center, 
    current_theme, current_question, fio_oper, info)
    values(inum_order, sysdate, r_person.iin, iip_addr, v_code_center,
    0, 0,
    r_person.lastname||' '||r_person.name||' '||r_person.middlename,
    'CONTINUE_TEST');

    commit;
   end set_mistake_old_photo;  
  
-- Section Clear mistake 

   procedure clear_mistake(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2, imistake in varchar2)
  is
    r_person  cop.users%rowtype;
    r_testing pdd.testing%rowtype;
    v_code_center cop.list_workstation.code_center%type;  
  begin
    begin
        select * into r_person 
        from cop.users r where r.id_user=iid_user;
    exception when no_data_found then 
        log('E', 'clear_mistake', inum_order, 'NOT FOUND USER: '||iid_user);
        return;
    end;    
    
    begin
        select * into r_testing 
        from pdd.testing t 
        where t.id_registration=inum_order;
    exception when no_data_found then 
        log('E', 'clear_mistake', inum_order, 'NOT FOUND Testing: '||inum_order);
    end;    
    
    begin
        select code_center into v_code_center 
        from cop.list_workstation lw 
        where lw.ip_addr = iip_addr;
    exception when no_data_found then 
        log('E', 'clear_mistake', inum_order, 'NOT FOUND Code center for : '||iip_addr);
    end;

    update  pdd.orders o
    set     o.result = '',
            o.status = case when coalesce(r_testing.id_registration,0)=0 then 'New'
                            else 'testing' 
                       end,
            o.extend_status='',
            o.end_time_testing=''
    where to_number(o.num_order) = inum_order;

    if imistake = 'FaceControl' and coalesce(r_testing.id_registration,0)>0
    then
        update pdd.testing t 
        set t.status = 'Active',
            t.status_testing='CheckFC',
            t.end_time_testing=''
        where t.id_registration=inum_order;
    end if;    

    insert into permitions p 
    (num_order, date_permit, iin, ip_addr, code_center, 
    current_theme, current_question, fio_oper, info)
    values(inum_order, sysdate, r_person.iin, iip_addr, v_code_center,
    coalesce(r_testing.current_theme_number,0), 
    coalesce(r_testing.current_num_question,0),
    r_person.lastname||' '||r_person.name||' '||r_person.middlename,
    'CONTINUE_TEST');

    commit;
  end clear_mistake;
/*    
  procedure clear_mistake_fc(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2)
  is
    r_person  cop.users%rowtype;
    r_testing pdd.testing%rowtype;
    v_code_center cop.list_workstation.code_center%type;  
  begin
    begin
        select * into r_person 
        from cop.users r where r.id_user=iid_user;
    exception when no_data_found then 
        log('E', 'clear_mistake', inum_order, 'NOT FOUND USER: '||iid_user);
        return;
    end;    
    
    begin
        select * into r_testing 
        from pdd.testing t 
        where t.id_registration=inum_order;
    exception when no_data_found then 
        log('E', 'clear_mistake', inum_order, 'NOT FOUND Testing: '||inum_order);
    end;    
    
    begin
        select code_center into v_code_center 
        from cop.list_workstation lw 
        where lw.ip_addr = iip_addr;
    exception when no_data_found then 
        log('E', 'clear_mistake', inum_order, 'NOT FOUND Code center for : '||iip_addr);
    end;
    
    if coalesce(r_testing.id_registration,0)>0
    then
        update pdd.testing t 
        set t.status = 'Active',
            t.status_testing='CheckFC',
            t.end_time_testing=''
        where t.id_registration=inum_order;
    end if;    
        
    update  pdd.orders o
    set     o.result = '',
            o.status = case when coalesce(r_testing.id_registration,0)=0 then 'New'
                            else 'testing' 
                       end,
            o.extend_status='',
            o.end_time_testing=''
    where to_number(o.num_order) = inum_order;

    insert into permitions p 
    (num_order, date_permit, iin, ip_addr, code_center, 
    current_theme, current_question, fio_oper, info)
    values(inum_order, sysdate, r_person.iin, iip_addr, v_code_center,
    coalesce(r_testing.current_theme_number,0), 
    coalesce(r_testing.current_num_question,0),
    r_person.lastname||' '||r_person.name||' '||r_person.middlename,
    'CONTINUE_TEST');

    commit;
  end clear_mistake_fc;  
*/
 procedure clear_mistake_fc(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2)
  is
  begin
    clear_mistake(inum_order, iid_user, iip_addr, 'FaceControl');
  end clear_mistake_fc; 
  
  procedure clear_mistake_foreign_citizen(inum_order in number, 
        iid_user in pls_integer, iip_addr in varchar2)
  is
  begin
    clear_mistake(inum_order, iid_user, iip_addr, 'Foreign citizen');
  end clear_mistake_foreign_citizen; 

-- End clear section 

  procedure clean_all
  is
  begin
    delete from photos;
    delete from face_control_event;
    delete from testing;
    delete from answers_in_testing;
    delete from questions_for_testing;
    delete from themes_for_testing;
    update orders o set o.status='New', o.result='', 
            o.extend_status='', o.time_send='', o.status_send='', o.end_time_testing='';
    commit;
  end;

-- I?enoea anao cayaie ia ia?eia Ieeioa
  procedure clean_order(inum_order in number)
  is
  begin
    delete from photos p where p.num_order=inum_order;
    delete from face_control_event fc where fc.num_order=inum_order;
    delete from testing t where t.id_registration=inum_order;
    delete from answers_in_testing a where a.id_question_for_testing in (
                select id_question_for_testing from questions_for_testing qft
                where qft.id_registration=inum_order);
    delete from questions_for_testing qft where qft.id_registration=inum_order;
    delete from themes_for_testing tft where tft.id_registration=inum_order;
    update orders o set o.status='New', o.result='', o.mistake='', date_order=sysdate,
            o.extend_status='', o.time_send='', o.status_send='', o.end_time_testing=''
    where o.num_order=inum_order;
    update random_place rp set rp.lck='N', rp.ip_addr='' where rp.num_order=inum_order;
    commit;
  end;


  procedure clean_order(inum_order in number, iid_user in pls_integer, iip_addr in varchar2)
  is
  begin
    set_permission_order2(inum_order => inum_order, iid_user => iid_user, iip_addr => iip_addr, iinfo => 'CLEANED_ORDER');
    clean_order(inum_order);
  end;
  
-- Iiaay Cayaea
  procedure new_order(inum_order in number, 
            icode_center in nvarchar2,
            icategory in varchar2,
            iiin in varchar2, 
            ifio    in nvarchar2,
            ostatus out nvarchar2)
  is
    r_centers   cop.centers%rowtype;
  begin
    if iiin is null 
    then 
        ostatus:='IIN empty. Code_Center: '||icode_center||', order_num: '||inum_order;
        log('E', 'new_order', inum_order, 'IIN empty. Code_Center: '||icode_center);
        return; 
    end if;
    begin
        select * into r_centers from cop.centers c where c.code_center=icode_center;
    exception when no_data_found then    
        log('E', 'new_order', inum_order, 'Code Center not found: '||icode_center||', iin: '||iiin);
        ostatus:='Mistake Code Center: '||icode_center;
        return;
    end;    
    begin
        insert into pdd.persons (id_person, iin, fio) 
            values(seq_persons.nextval, iiin, ifio);
    exception when dup_val_on_index then
        log('I', 'new_order', inum_order, 'person: '||iiin||' already exist'||', code_center: '||icode_center);
    end;

    insert into orders o(id_order, date_order, id_center, num_order, iin, category, status)
                values(seq_order.nextval, systimestamp, r_centers.id_center, 
                        inum_order, iiin, 
                        case when icategory='undefined' then 'B' else icategory end, 
                        'New');
    ostatus:='';
    commit;
    log('I', 'new_order', inum_order, 'ADDED NEW ORDER. IIN: '||iiin||', code_center: '||icode_center);
    exception when dup_val_on_index then
        log('E', 'new_order', inum_order, 'ORDER ALREADY EXISTS. IIN: '||iiin||', code_center: '||icode_center);
        ostatus:='Order already exists: '||inum_order;
  end;

  procedure close_order(inum_order in number, iresult in varchar2, istatus_send in varchar2)
  is
  begin
    update orders o 
    set o.time_send=sysdate,
        o.status='Completed',
        o.result=coalesce(iresult,o.result),
        o.status_send='sent_'||istatus_send
    where o.num_order=inum_order;
/*    
    insert into permitions p 
    (num_order, date_permit, iin, ip_addr, code_center, 
    current_theme, current_question, fio_oper)
    values(inum_order, sysdate, r_person.iin, iip_addr, v_code_center,
    coalesce(r_testing.current_theme_number,0), 
    coalesce(r_testing.current_num_question,0),
    r_person.lastname||' '||r_person.name||' '||r_person.middlename);
*/
    commit;
        
  end;

  function get_language_test(inum_order in number) return varchar2
  is
    err_msg varchar2(32);
  begin
    select t.language into err_msg 
    from pdd.testing t 
    where t.id_registration=inum_order;
    if err_msg is not null then
        return 'LANG='||err_msg;
    end if;
    return '';
    exception when no_data_found then return '';
  end get_language_test;
  
  function new_registration(inum_order in number, ilang in varchar2, 
            iip_addr in varchar2)
            return nvarchar2
  as
--    r_orders    pdd.orders%rowtype;
    r_tasks     pdd_testing.tasks%rowtype;
    v_id_person pdd.persons.id_person%type;
    err_msg nvarchar2(64);
  begin
    begin
        select * into r_tasks from pdd_testing.tasks t where t.language = ilang;
    exception when no_data_found then
        err_msg:='ABSENT Program for lang: '||ilang;
        update pdd.orders o 
        set o.status='ERROR Program',
            o.extend_status=err_msg
        where to_number(o.num_order)=inum_order;
        log('E', 'new_registration', inum_order, err_msg);
        return err_msg;
    end;

    begin
        select id_person into v_id_person
        from pdd.persons p, pdd.orders o
        where p.iin=o.iin
        and   to_number(o.num_order)=inum_order;
    exception when no_data_found then
        err_msg:='Person is missing in database';
        update pdd.orders o set o.status='ERROR Person' where o.num_order=inum_order;
        log('E', 'new_registration', inum_order, err_msg);
        return err_msg;
    end;
    begin
        insert into pdd.testing(id_registration, id_person, date_registration,
                    current_theme_number, current_num_question, date_testing, 
                    ip_addr, status, status_testing )
               values( inum_order, v_id_person, sysdate, 
                       1, 1, sysdate,
                       iip_addr, 'Active', 'ready for testing' );
    exception when dup_val_on_index then      
        log('E', 'new_registration', inum_order, 'Try create DOUBLE registration');
        err_msg := get_language_test(inum_order);
        if err_msg is not null then
            return err_msg;
        end if;
    end;                   
    update pdd.orders o
    set o.status='registration'
    where to_number(o.num_order)=inum_order;
    commit;    
    return '';
  end;

  procedure login(inum_order in varchar2, iip_addr in varchar2, ilang in varchar2,
        oiin out varchar2,
        oid_order out number, oremain_time out number, omsg out nvarchar2)
  is
    r_orders    pdd.orders%rowtype;
    r_testing   pdd.testing%rowtype;
    r_person    pdd.persons%rowtype;
    msg         nvarchar2(128);
    exist_ip    pls_integer;
    v_num_order number;
--  PRAGMA AUTONOMOUS_TRANSACTION
  begin

    begin
        v_num_order:=to_number(inum_order);
    exception when others then
        log('E', 'login', inum_order, 'NUM_ORDER non digit: '||inum_order);
        oid_order:=0;
        oremain_time:=-200;
        return;
    end;

    begin
        select * into r_orders from pdd.orders o where to_number(o.num_order)=v_num_order;
        oid_order:=r_orders.id_order;
        oiin:=r_orders.iin;
--        log('I', 'login', inum_order, 'ORDERS EXISTS. IIN: '||r_orders.iin);
    exception when no_data_found then
      begin
        log('E', 'login', inum_order, 'Absent Order: '||inum_order);
        oid_order:=0;
        oremain_time:=-200;
        return;
      end;        
    end;
    if  lower(r_orders.status)='registration' or lower(r_orders.status)='biometrica' 
    then
        oremain_time:=10;
        return;
    end if;

--    log('I', 'login', inum_order, 'Id_order: '||r_orders.id_order||', r_orders.status: '||r_orders.status||', r_orders.iin: '||r_orders.iin );
    if  r_orders.status='New'
    then
        select count(id_pc) 
        into exist_ip
        from cop.centers c, cop.list_workstation l
        where c.id_center=r_orders.id_center
        and   c.code_center = l.code_center
        and   c.active='Y'
        and   l.active='Y'
        and   l.status='T'
        and   l.ip_addr=iip_addr;

        if exist_ip=0 then
            msg := 'Attempting to login from a non-existent IP address: '||iip_addr||', code_center: '||
                   r_orders.id_center||', num_order: '||r_orders.num_order;
            log('E', 'login', inum_order, msg);
            oid_order:=0;
            oremain_time:=0;
            omsg:=msg;
            return;
        end if;

        if msg is not null then
--            log('I', 'login', inum_order, 'STATUS=NEW. id_order: '||oid_order||', remain_time: '||oremain_time||' MSG: '||msg );
            oid_order:=0;
            oremain_time:=0;
            omsg:=msg;
        else 
--            log('I', 'login', inum_order, 'STATUS=NEW. NEW Registration. r_orders.status: '||r_orders.status);
            oremain_time:=1;
        end if;
--        log('I', 'login', inum_order, 'STATUS=NEW. Login. remain_time: '||oremain_time);
        return;
    end if;

    begin
        select * into r_testing from pdd.testing t where t.id_registration=v_num_order;
    exception when no_data_found then
        begin
            log('E', 'login', inum_order, 'TESTING not found');
            oid_order:=0;
            oremain_time:=0;
            oiin:='';
            return;
        end;
    end;

    if r_testing.ip_addr != iip_addr then
        omsg:='Changed IP ADDR from '||r_testing.ip_addr||' to '||iip_addr||', iin: '||r_orders.iin;
        log('E', 'login', inum_order, omsg);
        oid_order:=0;
        oremain_time:=0;
        oiin:='';
        update  pdd.orders o
        set     o.result = 'failed',
                o.status = 'Completed',
                o.end_time_testing=sysdate,
                o.extend_status='IP changed',
                o.mistake='IP changed',
                o.ip_addr_second=iip_addr
        where to_number(o.num_order) = v_num_order;
        commit;

        update pdd.testing t 
        set t.remain_time=0,
            t.status = 'failed',
            t.status_testing='IP changed',
            t.ip_addr_second=iip_addr
        where t.id_registration=v_num_order;
        commit;        

        return;
    end if;

    begin
        select * into r_person  from pdd.persons p  where p.id_person=r_testing.id_person;
        oiin:=r_person.iin;
--        log('I', 'login', inum_order, 'PERSON FOUND: '||r_person.iin);
        exception when no_data_found then
        begin
            log('E', 'login', inum_order, 'In "pdd.persons" absent IIN : '||r_person.iin);
            oid_order:=0;
            oremain_time:=-100;
            return;
        end;
    end;
    
--  Test stopped
    if r_orders.status='Stopped' then
        oremain_time:=0;
        return;
    end if;    
    if r_orders.status='testing' 
    then
        oremain_time :=r_testing.remain_time + 
                        ( extract(second from coalesce(r_testing.LAST_TIME_ACCESS,systimestamp) - systimestamp) +
                          extract(minute from coalesce(r_testing.last_time_access,systimestamp) - systimestamp)*60 +
                          extract(hour from coalesce(r_testing.last_time_access,systimestamp) - systimestamp)*3600 );
        if oremain_time<0 then oremain_time:=0; end if;
    else -- Completed, Archived ...
        oremain_time:=0;
        return;
    end if;
    log('I', 'login', inum_order, 'FINISH. REMAIN TIME: '||oremain_time);
  end login;

  procedure get_double_ip(inum_order in number, first_ip out varchar2, second_ip out varchar2) AS
  BEGIN
      select ip_addr, coalesce(ip_addr_second, '222-333')
      into  first_ip, second_ip
      from pdd.testing t
      where t.id_registration=inum_order;
  exception when no_data_found then 
    begin
        first_ip:='';
        second_ip:='';
    end;
  END get_double_ip;
  

  procedure add_fc_event(inum_order in number, itheme_number in pls_integer,
    icount_question in pls_integer, icnt_fc in pls_integer)
  is
      l_seed            VARCHAR2(100);
      val_low       pls_integer default 1;
      random_size   pls_integer default 0;
      random_number pls_integer default 0;
      val_lag       pls_integer default 1;
  begin
--    log('D', 'add_fc_event', inum_order, 'theme_number: '||itheme_number||
--        ', count_question: '||icount_question||', cnt_fc: '||icnt_fc);
    if coalesce(icnt_fc,0) > 0 then
        l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
        DBMS_RANDOM.seed (val => l_seed);
        random_size:=icount_question/icnt_fc;
        val_lag:=icount_question/10;
        while val_low<icount_question
        loop
            select dbms_random.value(val_low+val_lag,val_low+random_size-val_lag-1) into random_number from dual;
--            log('D', 'add_fc_event', inum_order, 'val_low: '||val_low||', random_size: '||random_size||', upper: '||(val_low+random_size-val_lag-1)||
--                ', random_number: '||random_number||', cnt_fc: '||icnt_fc);
            val_low:=val_low+random_size;
            insert into face_control_event(num_order, theme_number, num_question,status)
            values(inum_order, itheme_number, random_number, 'W');
        end loop;
        commit;    
    end if;
--    exception when others then 
--        log('E', 'add_fc_event', inum_order, 'theme_number: '||itheme_number||
--            ', icount_question: '||icount_question||', icnt_fc: '||icnt_fc||
--            ', sqlerrm: '||sqlerrm);
  end add_fc_event;  
-- Nicaaiea oanoiauo caaaiee
  procedure add_test_2(iid_registration in number, iip_addr in varchar2, 
            ilang in varchar2, oerr_msg out varchar2)
  is
    v_id_person       persons.id_person%type;
    random_number     pls_integer;
    random_size       pls_integer;
    target_size       pls_integer;
    order_number      pls_integer;
    l_seed            VARCHAR2(100);
    v_id_question     pdd_testing.questions.id_question%type;
    v_id_answer       pdd_testing.answers.id_answer%type;
    v_count_registr   pls_integer;
    r_orders          pdd.orders%rowtype;
    r_tasks           pdd_testing.tasks%rowtype;
    err_msg           varchar2(128);

    type id_question_table is table of pdd_testing.questions.id_question%type index by pls_integer;
    input_array_questions id_question_table;

    type id_answer_table is table of pdd_testing.answers.id_answer%type index by pls_integer;
    input_array_answers id_answer_table;
  begin
    begin
--    Check exists ORDER
        select * into r_orders from pdd.orders o 
        where o.num_order = to_char(iid_registration);
    exception when no_data_found then
        err_msg:='ORDER NOT FOUND. IP_ADDR: '||iip_addr||', lang: '||ilang;
        log('E', 'add_test', iid_registration, err_msg);
        oerr_msg:=err_msg;
        return;
    end;
--    Check Task
    begin
        select * into r_tasks from pdd_testing.tasks t 
        where t.language=ilang;
    exception when no_data_found then
        err_msg:='Task not found for category: '||r_orders.category||', lang: '||ilang;
        log('E', 'add_test', iid_registration, err_msg);
        oerr_msg:=err_msg;
        return;
    end;

    /* Check Exist Testing */
    select coalesce(count(id_registration),0) into v_count_registr
    from pdd.testing t
    where t.status='Active'
    and t.id_registration=iid_registration;

    if v_count_registr>1 then
        select 'LANG='||t.language into oerr_msg
        from pdd.testing t
        where t.id_registration=iid_registration;
       log('I', 'add_test', iid_registration, 'ADD TEST. Person with id_registration:  '||iid_registration||' has an outstanding task ');
       return;
    end if;

    /* I?iaa?ei iaee?ea naaia?e?iaaiiuo oanoiauo caaaiee */
    select coalesce(count(id_registration),0) into v_count_registr
    from pdd.themes_for_testing t
    where t.id_registration=iid_registration;
    if v_count_registr>0 then
       log('I', 'add_test', iid_registration, 'ADD TEST. Person has testing already. IP_ADDR: '||iip_addr||', LANG: '||oerr_msg);
       return;
    end if;

    log('I', 'add_test', iid_registration, 'ADD TEST. Person id_registration:  '||iid_registration||
                         ', id_task: '||r_tasks.id_task||', v_count_registr: '||v_count_registr);
--  Iiaaioiaei oaaeeoo o?aoa i?ioi?aaiey oai     
    for cur in ( select bt.*
                 from  pdd_testing.themes bt
                 where bt.id_task=r_tasks.id_task)
    loop
      insert into pdd.themes_for_testing(
            id_registration, id_theme, theme_number, 
            count_question, count_success, period_for_testing, scores, 
            remain_time, status)
      values ( iid_registration, cur.id_theme, cur.theme_number, 
            cur.count_question, cur.count_success, cur.period_for_testing, 0, 
            cur.period_for_testing, 0);

      add_fc_event(iid_registration, cur.theme_number, cur.count_question, cur.count_fc);
    end loop;

--    log('I', 'add_test', iid_registration, 'ADD TEST. Themes for testing loaded. Person id_registration:  '||iid_registration);
/* Caa?ocei aii?inu aey ea?aie oaiu */
    for cur in ( select * from pdd.themes_for_testing tt 
                 where tt.id_registration=iid_registration)
    loop
--        select q.id_question
--        bulk collect into input_array_questions
--        from pdd_testing.questions q
--        where q.id_theme=cur.id_theme;

        random_size:=input_array_questions.count;
        if random_size=0 THEN
           log('I', 'add_test', iid_registration, 'ADD TEST. THEME with id_theme: '||cur.id_theme||' has an outstanding questions');
           return;
        end if;
        target_size := cur.count_question;

        order_number:=0;
        l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
        DBMS_RANDOM.seed (val => l_seed);

        while order_number<target_size and target_size<=random_size
        loop
          select dbms_random.value(1,random_size) into random_number from dual;
          if input_array_questions.exists(random_number)
          then
             v_id_question:=input_array_questions(random_number);
             input_array_questions.delete(random_number);
             order_number:=order_number+1;

            begin
             insert into pdd.questions_for_testing( id_question_for_testing,
                         id_registration, theme_number,
                         order_num_question, id_question,
                         id_answer, time_reply)
             values( seq_question_testing.nextval,
                     iid_registration, cur.theme_number, order_number, v_id_question, null, null);
--             exception when others then
--                                 log('error load iid_registration: '||iid_registration||
--                            ', cur.id_theme: '||cur.id_theme||
--                            ', order_number: '||order_number||
--                            'v_id_question: '||v_id_question);
            end;
          end if;
        end loop;
    end loop;

--    log('I', 'add_test', 'ADD TEST. Question for testing loaded. Person id_order:  '||iid_registration);
/* Caa?ocei aa?eaiou ioaaoia  */
--/*
    for cur in ( select * from pdd.questions_for_testing qt 
                 where qt.id_registration=iid_registration 
                 order by qt.theme_number, qt.order_num_question )
    loop
        select a.id_answer
        bulk collect into input_array_answers
        from pdd_testing.answers a
        where a.id_question=cur.id_question;

        random_size:=input_array_answers.count;
        if random_size=0 THEN return; end if;
        target_size := random_size;

        order_number:=0;
        l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
        DBMS_RANDOM.seed (val => l_seed);

        while order_number<target_size
        loop
          select dbms_random.value(1,random_size) into random_number from dual;
          if input_array_answers.exists(random_number)
          then
             v_id_answer:=input_array_answers(random_number);
             input_array_answers.delete(random_number);
             order_number:=order_number+1;

             insert into pdd.answers_in_testing( id_question_for_testing,
                         id_answer,
                         order_num_answer)
             values( cur.id_question_for_testing,
                     v_id_answer,
                     order_number);
          end if;
        end loop;
    end loop;

--    log('I', 'add_test', 'ADD TEST. Answers in testing loaded. Person id_order:  '||iid_registration);
    /* Ioi?aaei a a?oea i?aauaouea oanoe?iaaiey */
    select id_person into v_id_person
    from pdd.orders o, pdd.persons p
    where o.num_order=to_char(iid_registration)
    and   o.iin=p.iin;
    
    update pdd.testing t
    set    t.status='Archived'
    where  t.id_person=v_id_person
    and    t.status='Completed';
    /* Aiaaaei iiaia oanoe?iaaiea */    
    
    update pdd.testing t
    set period_for_testing = ( select period_for_testing 
                     from themes_for_testing bt
                     where  bt.id_registration=iid_registration
                     and    bt.theme_number=1),
        remain_time = ( select period_for_testing 
                     from themes_for_testing bt
                     where  bt.id_registration=iid_registration
                     and    bt.theme_number=1),
        beg_time_testing = sysdate,
        last_time_access = sysdate,
        language = ilang,
        status_testing = 'testing'
    where id_registration=iid_registration;
    update orders o set o.status='testing' where o.num_order=iid_registration;
    commit;

  end;

  procedure add_question(iid_task in pls_integer, 
                    itheme_number in pls_integer, 
                    iid_registration in number, 
                    iid_category in pls_integer)
  is
    target_size       pls_integer;
    v_order_number_question   pls_integer;    
  begin
        /*                              
       log('I', 'add_question', iid_registration, 
        'ID_TASK: '||iid_task||', theme_number: '||itheme_number||
        ', iid_category: '||iid_category);
        */
        -- fetch categories
        v_order_number_question:=0;
        for cur in (select r.* 
                    from pdd_testing.rules_for_questions r, 
                         pdd_testing.categories c, pdd.orders o
                    where r.id_category = c.id_category
                    and   o.num_order=iid_registration
                    and c.category like '%"'||o.category||'"%'
                    )
        loop
            target_size := coalesce(cur.count_question_partition,0) +
                           coalesce(cur.count_question_subpartition,0);
            -- fetch random questions by categories
             log('I', 'add_question', iid_registration,'---> ID_TASK: '||iid_task||', theme_number: '||itheme_number||
              ', iid_category: '||iid_category||', target_size: '||target_size||', v_order_number_question: '||v_order_number_question||
              ', partition_number: '||cur.partition_number||', subpartition_number: '||cur.subpartition_number);
            for cur2 in (   
                select * from (         
                  select id_question, rownum as row_num
                  from (
                      select q.id_question
                      from   pdd_testing.questions q
                      where q.id_task=iid_task
                      and   q.theme_number=itheme_number
                      and   q.partition_number=cur.partition_number
                      and   q.subpartition_number=coalesce(cur.subpartition_number,0)
                      ORDER BY dbms_random.value
                  )
                ) where row_num<=target_size
            )
            loop
              v_order_number_question:=v_order_number_question+1;
              /*
              log('I', 'add_question', iid_registration,'--------> ID_TASK: '||iid_task||', theme_number: '||itheme_number||
              ', iid_category: '||iid_category||', target_size: '||target_size||
              ', v_order_number_question: '||v_order_number_question||', id_question: '||cur2.id_question);
              */
              begin
                insert into pdd.questions_for_testing( id_question_for_testing,
                         id_registration, theme_number,
                         id_question, order_num_question, 
                         id_answer, time_reply)
                values( seq_question_testing.nextval,
                     iid_registration, itheme_number, 
                     cur2.id_question, v_order_number_question, 
                     null, null);
              exception when others then
                  log('E', 'add_question', iid_registration, 
                  '---> ERROR INSERT Questions. count_questions: '||v_order_number_question||' sqlerrm: '||sqlerrm);
              end;
            end loop;
        end loop;
        
--            log('I', 'add_question', iid_registration, 
--            '-----> random_size: '||random_size||', in partition_number: '||
--            cur.partition_number||', subpartition_number: '||cur.subpartition_number||
--            ', target_size: '||(coalesce(cur.count_question_partition,0) +
--                               coalesce(cur.count_question_subpartition,0)));
        commit;
        log('I', 'add_question', iid_registration, '---> loaded '||v_order_number_question||' questions');
  end add_question;
  
  
-- Nicaaiea oanoiauo caaaiee 2
  procedure add_test(iid_registration in number, iip_addr in varchar2, 
            ilang in varchar2, oerr_msg out varchar2)
  is
    v_id_person       persons.id_person%type;
    v_count_registr   pls_integer;
    v_id_category     pls_integer;  
    r_orders          pdd.orders%rowtype;
    r_tasks           pdd_testing.tasks%rowtype;
    err_msg           varchar2(128);
    v_order_number    pls_integer;
  begin
    begin
        select * into r_orders from pdd.orders o 
        where o.num_order = to_char(iid_registration);
    exception when no_data_found then
        err_msg:='Absent order: '||iid_registration||', ip_addr: '||iip_addr;
        log('E', 'add_test', iid_registration, err_msg);
        oerr_msg:=err_msg;
        return;
    end;
    err_msg:=new_registration(iid_registration, ilang, iip_addr);
    if err_msg is not null then
       oerr_msg:=err_msg;
       return;
    end if;    
--/*
--    log('I', 'add_test', iid_registration, '----> LANG: '||ilang);
    begin
        select * into r_tasks from pdd_testing.tasks t where t.language=ilang;
    exception when no_data_found then
        err_msg:='Absent program: '||ilang;
        log('E', 'add_test', iid_registration, err_msg);
        oerr_msg:=err_msg;
        return;
    end;
--*/
    /* Check Active testing */
    select coalesce(count(id_registration),0) into v_count_registr
    from pdd.testing t
    where t.status='Active'
    and t.id_registration=iid_registration;

    if v_count_registr>1 then
       oerr_msg:=get_language_test(iid_registration);
       log('I', 'add_test', iid_registration, 'ADD TEST. Person has an outstanding task. Language: '||oerr_msg);
       return;
    end if;

    /* Continue testing */
    select coalesce(count(id_registration),0) into v_count_registr
    from pdd.themes_for_testing t
    where t.id_registration=iid_registration;
    if v_count_registr>0 then
        update pdd.orders o set o.status='testing' 
        where to_number(o.num_order)=iid_registration;
        commit;
        oerr_msg:=get_language_test(iid_registration);
        log('I', 'add_test', iid_registration, '2. ADD TEST. Person has testing already. id_registration:  '||iid_registration||', language: '||oerr_msg);
        return;
    end if;

--    Exists ID_CATEGORY
    begin
        select c.id_category into v_id_category from pdd_testing.categories c 
        where  c.category like '%"'||r_orders.category||'"%';
    exception when no_data_found then
        err_msg:='No category '||r_orders.category||' in table pdd_testing.categories';
        log('E', 'add_test', iid_registration, err_msg);
        oerr_msg:=err_msg;
        return;
    end;

--    log('I', 'add_test', iid_registration, 'ADD TEST. Person id_registration:  '||iid_registration||', id_task: '||r_tasks.id_task||', v_count_registr: '||v_count_registr);
/* ADD themes for testing */
    for cur in ( select bt.*
                 from  pdd_testing.themes bt
                 where bt.id_task=r_tasks.id_task
                 and   bt.active='Y')
    loop
      insert into pdd.themes_for_testing(
            id_registration, id_theme, theme_number, 
            count_question, count_success, period_for_testing, scores, 
            remain_time, status)
      values ( iid_registration, cur.id_theme, cur.theme_number, 
            cur.count_question, cur.count_success, cur.period_for_testing, 0, 
            cur.period_for_testing, 0);
      add_fc_event(iid_registration, cur.theme_number, cur.count_question, cur.count_fc);
    end loop;

--    log('I', 'add_test', iid_registration, 'ADD TEST. Themes for testing loaded. Person id_registration:  '||iid_registration);

/* ADD random questions */
    for cur in ( select * from pdd.themes_for_testing tt 
                 where tt.id_registration=iid_registration)
    loop
        if cur.theme_number = 2 then
           add_question(r_tasks.id_task, cur.theme_number, iid_registration, v_id_category);
        end if;
        if cur.theme_number = 1 then
           v_order_number:=0;
           for cur2 in (  select q.id_question
                          from   pdd_testing.questions q
                          where q.id_task=r_tasks.id_task
                          and   q.theme_number=1
                          ORDER BY dbms_random.value
                      )
            loop
                v_order_number:=v_order_number+1;
                begin
                  insert into pdd.questions_for_testing( id_question_for_testing,
                           id_registration, theme_number,
                           id_question, order_num_question, 
                           id_answer, time_reply)
                  values( seq_question_testing.nextval,
                       iid_registration, cur.theme_number, 
                       cur2.id_question, v_order_number, 
                       null, null);
                exception when others then
                    log('E', 'add_test', iid_registration, 
                    '---> ERROR INSERT Questions. count_questions: '||v_order_number||' sqlerrm: '||sqlerrm);
                end;
            end loop;
        end if;    
    end loop;

--    log('I', 'add_test', iid_registration, 'ADD TEST. Question for testing loading. Person id_order:  '||iid_registration);
/* ADD random answers */
    for cur in ( select * from pdd.questions_for_testing qt 
                 where qt.id_registration=iid_registration 
                 order by qt.theme_number, qt.order_num_question )
    loop
        v_order_number:=0;
        for cur2 in ( select a.id_answer
                      from pdd_testing.answers a
                      where a.id_question=cur.id_question
                      ORDER BY dbms_random.value
                    )
        loop
            v_order_number:=v_order_number+1;
            log('I', 'add_test', iid_registration, 'ADD TEST. ADD ANSWER.  id_question_for_testing: '||
                     cur.id_question_for_testing||', id_answer: '||cur2.id_answer||', v_order_number: '||v_order_number);
             insert into pdd.answers_in_testing( id_question_for_testing,
                         id_answer,
                         order_num_answer)
             values( cur.id_question_for_testing,
                     cur2.id_answer,
                     v_order_number);
        end loop;
    end loop;

    log('I', 'add_test', iid_registration, 'ADD TEST. Answers in testing loaded. '||v_order_number);
    select id_person into v_id_person
    from pdd.orders o, pdd.persons p
    where o.num_order=to_char(iid_registration)
    and   o.iin=p.iin;
    
    update pdd.testing t
    set    t.status='Archived'
    where  t.id_person=v_id_person
    and    t.status='Completed';
    
    update pdd.testing t
    set period_for_testing = ( select period_for_testing 
                     from themes_for_testing bt
                     where  bt.id_registration=iid_registration
                     and    bt.theme_number=1),
        remain_time = ( select period_for_testing 
                     from themes_for_testing bt
                     where  bt.id_registration=iid_registration
                     and    bt.theme_number=1),
        beg_time_testing = sysdate,
        last_time_access = sysdate,
        language = ilang,
        status_testing = 'testing'
    where id_registration=iid_registration;
    update orders o set o.status='testing' where o.num_order=iid_registration;
    commit;
    log('I', 'add_test', iid_registration, 'ADD TEST. FINISH create Test.');

  end add_test;

--/*  
  function get_answered_questions(inum_order in number, itheme_number in pls_integer) return varchar2
  is
  str varchar2(128);
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
      str:=str||cur.num||',';
    end loop;
    return str;
  end;  
--*/
-- For Operator. Close uncompleted orders
  procedure force_complete(iid_region in pls_integer)
    is
  begin
    for cur in (select c.id_center from cop.centers c where c.id_region=iid_region)
    loop
      for cur_order in (select * 
          from orders o 
          where o.id_center=cur.id_center
          and   o.status='New'
          and   trunc(o.date_order)<trunc(sysdate)
          )
      loop
        update orders o 
        set o.time_send=sysdate,
            o.status='Completed',
            o.result='absence'
        where o.id_order=cur_order.id_order;
            
      end loop;
    end loop;
/*
    for cur in (select c.id_center from cop.centers c where c.id_region=iid_region)
    loop
      for cur_order in (select * 
          from orders o 
          where o.id_center=cur.id_center
          and   o.status in ('testing')
          and   trunc(o.date_order)<trunc(sysdate)
          )
      loop
          test.finish(cur_order.num_order);
      end loop;
    end loop;
*/    
    commit;
  end;
 
--*/
begin
  null;
end admin;
/
