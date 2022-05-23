create or replace package admin is

  -- Author  : Shamil Gusseynov
  -- Created : 23.06.2021 17:37:04
  -- Purpose : Load testing's task with theme, categories

--  function add_question( iid_theme in number, iorder_num in number, 
--        iurl_image in varchar2, iquestion in nvarchar2)
--        return varchar2;
 
  procedure program_add(ilang in varchar2, iname_task in nvarchar2);
  procedure program_upd(iid_task in number, ilanguage in nvarchar2, 
                    iname_task in nvarchar2);
  procedure program_delete(iid_task in number);
  function get_name_program(iid_task in number) return nvarchar2;
  function theme_new(iid_task in number, theme_name in nvarchar2) return pls_integer;
  procedure theme_update(iid_task in number, iid_theme in number, itheme_name in varchar2, itheme_number in number,
            icount_question in number, icount_success in number );
  procedure theme_delete(iid_theme in number);
  
  procedure create_category;
  procedure create_theme_partition;
  procedure create_theme_subpartition;
  procedure create_rules_for_question;
  
end admin;
/
create or replace package body admin is

  procedure log(itype in char, iproc in varchar2, 
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg) 
        values(systimestamp, itype, 'admin', iproc, inum_order, imess);
    commit;
  end;

  function get_name_program(iid_task in number) return nvarchar2
  is
    v_name_task tasks.name_task%type;
  begin
    select t.name_task into v_name_task from tasks t where t.id_task=iid_task;
    return v_name_task;
  end get_name_program;

  procedure program_add(ilang in varchar2, iname_task in nvarchar2)
  is
    max_id_task pls_integer;
  begin
    select max(id_task) into max_id_task from tasks t;
    insert into tasks(id_task, language, name_task) 
        values(coalesce(max_id_task,0)+1, ilang, iname_task);
    commit;
  end program_add;

  procedure program_upd(iid_task in number, ilanguage in nvarchar2, 
                    iname_task in nvarchar2)
  is
  begin
    update tasks t
    set    t.language=ilanguage,
           t.name_task=iname_task
    where  t.id_task=iid_task;
    commit;
  end program_upd;

  procedure program_delete(iid_task in number)
  is
  begin
    delete from tasks t where t.id_task=iid_task;
    commit;
  end program_delete;

  function theme_new(iid_task in number, theme_name in nvarchar2) return pls_integer
  is
    v_id_theme pls_integer;
    v_num_theme pls_integer;
  begin
    select max(id_theme) into v_id_theme from pdd_testing.themes t;
    v_id_theme := coalesce(v_id_theme, 0)+1;
    select count(id_theme) into v_num_theme from themes t where t.id_task=iid_task;

    insert into pdd_testing.themes(id_theme, id_task, theme_number, 
                        count_question, count_success, period_for_testing, 
                        active, descr)
                values(v_id_theme, iid_task, v_num_theme+1, 
                        0, 0, 0,
                        'Y', theme_name);
    commit;
    return v_id_theme;
  end theme_new;

  procedure theme_update(iid_task in number, iid_theme in number, itheme_name in varchar2,
            itheme_number in number,
            icount_question in number , icount_success  in number )
  is
  begin
    update pdd_testing.themes t
    set    t.theme_number=itheme_number,
           t.count_question=icount_question,
           t.count_success=icount_success,
           t.descr=itheme_name
    where  t.id_theme=iid_theme
    and    t.id_task=iid_task;
    commit;
  end theme_update;

  procedure theme_delete(iid_theme in number)
  is
    v_exist_testing pls_integer default 0;
    r_themes    pdd_testing.themes%rowtype;
    r_tft       pdd.themes_for_testing%rowtype;
  begin
    select count(*) into v_exist_testing
    from pdd.themes_for_testing tft
    where tft.id_theme=iid_theme
    and rownum=1;

    select * into r_themes 
    from pdd_testing.themes tft
    where tft.id_theme=iid_theme;

--    log('I', 'theme_delete', iid_theme, '1. THEME DELETE. count used theme: '||v_exist_testing);

    if v_exist_testing=0 then
       delete from pdd_testing.answers a 
       where a.id_question in ( select id_question 
                                from questions q 
                                where q.id_task=r_themes.id_task
                                and   q.theme_number=r_themes.theme_number);

        delete from pdd_testing.questions q 
                where q.id_task=r_themes.id_task
                and   q.theme_number=r_themes.theme_number;
        log('I', 'theme_delete', iid_theme,'THEME DELETE. delete from themes.');
        delete from pdd_testing.themes t where t.id_theme=iid_theme;
        commit;
    end if;
    exception when no_data_found 
        then null;
  end theme_delete;

 
  procedure create_category
  is 
  begin
    insert into categories(id_category, category) values(1, '"A1"A"B1"' );
    insert into categories(id_category, category) values(2, '"B"BE"' );
    insert into categories(id_category, category) values(3, '"C"C1"' );
    insert into categories(id_category, category) values(4, '"D"D1"Tb"' );
    insert into categories(id_category, category) values(5, '"C1E"CE"D1E"DE"' );
    insert into categories(id_category, category) values(6, '"Tm"' );
    commit;
  end create_category;

  procedure create_theme_partition
  is
  begin
    insert into theme_partition(partition_number, theme_number, partition_name) 
            values(1, 2,  'ÏÄÄ — Ïðàâèëà äîðîæíîãî äâèæåíèÿ');
    insert into theme_partition(partition_number, theme_number, partition_name) 
            values(2, 2,  'ÎÁÄ — Îñíîâû áåçîïàñíîñòè äâèæåíèÿ');
    insert into theme_partition(partition_number, theme_number, partition_name) 
            values(3, 2,  'ÌÅÄ — Ìåäèöèíà');
    insert into theme_partition(partition_number, theme_number, partition_name) 
            values(4, 2,  'ÀÄÌ — Àäìèíèñòðàòèâíàÿ îòâåòñòâåííîñòü');
    insert into theme_partition(partition_number, theme_number, partition_name) 
            values(5, 2,  'ÑÏÏÄÄ — Ñïåöèàëüíûå ÏÄÄ');
    insert into theme_partition(partition_number, theme_number, partition_name) 
            values(6, 2,  'ÑÏÎÁÄ — Ñïåöèàëüíûå îñíîâû áåçîïàñíîñòè äâèæåíèÿ');
    commit;
  end create_theme_partition;

  procedure create_theme_subpartition
  is
  begin
    for i in 1..14     
    loop
        insert into theme_subpartition(id_subpartition, partition_number, 
                    subpartition_number, subpartition_name) 
                values(i, 1, i, 'Ðàçäåë '||i);
    end loop;
    for i in 1..6     
    loop
        insert into theme_subpartition(id_subpartition, partition_number, 
                    subpartition_number, subpartition_name) 
                values(14+i, 5, i, 'Ïîäðàçäåë '||i);
    end loop;
    for i in 1..6
    loop
        insert into theme_subpartition(id_subpartition, partition_number, 
                    subpartition_number, subpartition_name) 
                values(20+i, 6, i, 'Ïîäðàçäåë '||i);
    end loop;
    commit;
  end create_theme_subpartition;
  
  procedure create_rules_for_question
  is
    rule_number pls_integer default 0;
  begin
--  1 Ãðóïïà: id_category = 1 - À1, À, Â1
--  ÏÄÄ: id_partition=1, id_subpartition=1..14
     for x in 1..6 -- Ãðóïïû, êàòåãîðèè
     loop
        rule_number:=1;
        for i in 1..14 -- ïîäêàòåãîðèè
        loop
            insert into rules_for_questions(rule_number, id_category, 
                    partition_number, subpartition_number, count_question_partition,
                    count_question_subpartition)
            values (rule_number, x, 1, i, 0, 2);
            rule_number:=rule_number+1;
        end loop;
     end loop;
--  ÎÁÄ: id_partition=2, id_subpartition=null
    for x in 1..6
    loop
        insert into rules_for_questions(rule_number, id_category, 
                partition_number, subpartition_number, count_question_partition,
                count_question_subpartition)
        values (rule_number, x, 2, null, 4, 0);
    end loop;
    rule_number:=rule_number+1;
--  MED: id_partition=3, id_subpartition=null
    for x in 1..6
    loop
        insert into rules_for_questions(rule_number, id_category, 
                partition_number, subpartition_number, count_question_partition,
                count_question_subpartition)
        values (rule_number, x, 3, null, 2, 0);
    end loop;
    rule_number:=rule_number+1;
--  ADM: id_partition=4, id_subpartition=null
    for x in 1..6
        loop
        insert into rules_for_questions(rule_number, id_category, 
                partition_number, subpartition_number, count_question_partition,
                count_question_subpartition)
        values (rule_number, x, 4, null, 2, 0);
    end loop;
    rule_number:=rule_number+1;
--  ÑÏÏÄÄ: id_partition=5, id_subpartition=1..6
     for x in 1..6 -- Ãðóïïû, êàòåãîðèè
     loop
            insert into rules_for_questions(rule_number, id_category, 
                    partition_number, subpartition_number, count_question_partition,
                    count_question_subpartition)
            values (rule_number, x, 5, x, 0, case when x=2 then 4 else 2 end);
            rule_number:=rule_number+1;
     end loop;
--  ÑÏÎÁÄ: id_partition=6, id_subpartition=1..6
     for x in 1..6 -- Ãðóïïû, êàòåãîðèè
     loop
            insert into rules_for_questions(rule_number, id_category, 
                    partition_number, subpartition_number, count_question_partition,
                    count_question_subpartition)
            values (rule_number, x, 6, x, 0, case when x=2 then 0 else 2 end);
            rule_number:=rule_number+1;
     end loop;
     
    commit;
    exception when dup_val_on_index then
        raise_application_error(-20000, '---> I: '||rule_number);
  end create_rules_for_question;
  

begin
  -- Initialization
  null;
end admin;
/
