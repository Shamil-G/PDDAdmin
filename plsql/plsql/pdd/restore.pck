create or replace package restore is

  -- Author  : ADMIN
  -- Created : 04-oaa-22 15:08:59
  -- Purpose : restore order
  
  -- Public function and procedure declarations
  procedure restore_order(inum_order in number, iid_center in pls_integer, icategory in varchar2);

end restore;
/
create or replace package body restore is

/*
  procedure restore(inum_order in number)
  is 
   i pls_integer default 200;
   res varchar2(32);  
   cnt_themes pls_integer default 0;
  begin
--    delete from orders o where o.id_order between 200 and 210;
  for cur0 in ( select p.iin, t.id_registration as num_order, t.*  
               from testing t, persons p 
               where t.id_registration in (004031322677, 004031326936, 004031327992, 004031329959, 004031330290, 004031331647, 00403133370)
               and p.id_person=t.id_person
               )
  loop
    insert into orders(id_order, date_order, end_time_testing, id_center, num_order, iin, category, status, result, extend_status, time_send, status_send, mistake)
    values(i, cur0.date_registration, cur0.end_time_testing, 2, cur0.id_registration, cur0.iin, 'B', 'Completed', '', '', '', '', ''); 
    
    i:=i+1;
    res:='passed';
    for cur in (
            select tft.theme_number, tft.count_success, count(a.correctly) scores
            from pdd.questions_for_testing qft,
                 pdd_testing.answers a, pdd.themes_for_testing tft
            where qft.id_registration=cur0.num_order
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
      where tft.id_registration = cur0.id_registration
      and   tft.theme_number = cur.theme_number;
      if cur.theme_number=2 and cur.scores<cur.count_success then
        res:='failed';
      end if;
    end loop;

    update pdd.orders o
    set o.status='Completed',
        o.result=res,
        o.end_time_testing=systimestamp
    where o.num_order=cur0.id_registration;

    update pdd.testing t
    set   t.status_testing='Completed',
          t.status = res,
          t.end_time_testing=systimestamp
    where t.id_registration=cur0.id_registration;  

    update pdd.themes_for_testing tft
    set tft.remain_time=cur0.remain_time,
        tft.date_stop = sysdate,
        tft.status='Completed'
    where tft.id_registration=inum_order
    and tft.theme_number=cur0.current_theme_number;
    
  end loop;
  commit;
  end restore;
*/
  procedure restore_order(inum_order in number, iid_center in pls_integer, icategory in varchar2)
  is 
   res varchar2(32);  
  begin
  for cur0 in ( select p.iin, t.id_registration as num_order, t.*  
               from testing t, persons p 
               where t.id_registration = inum_order
               and p.id_person=t.id_person
               )
  loop
    res:='passed';
    for cur in (
            select tft.theme_number, tft.count_success, count(a.correctly) scores
            from pdd.questions_for_testing qft,
                 pdd_testing.answers a, pdd.themes_for_testing tft
            where qft.id_registration=cur0.num_order
            and   coalesce(qft.id_answer,0)=a.id_answer(+)
            and   qft.id_registration=tft.id_registration
            and   qft.theme_number=tft.theme_number
            and   a.correctly='Y'
            group by tft.theme_number, tft.count_success
            )
    loop
      update pdd.themes_for_testing tft
      set tft.scores = cur.scores
      where tft.id_registration = cur0.id_registration
      and   tft.theme_number = cur.theme_number;
      
      if cur.theme_number=2 and cur.scores<cur.count_success then
        res:='failed';
      end if;
    end loop;
    if res='passed' and cur0.status_testing='Fail recognition' then
      insert into orders(id_order, date_order, end_time_testing, id_center, num_order, iin, category, status, result, extend_status, time_send, status_send, mistake)
      values(seq_order.nextval, 
             cur0.date_registration, cur0.end_time_testing, 
             iid_center, 
             cur0.id_registration, cur0.iin, 
             icategory, 'Completed', 'suspend', 
             cur0.status_testing, '', '', cur0.status_testing); 
    else
      insert into orders(id_order, date_order, end_time_testing, id_center, num_order, iin, category, status, result, extend_status, time_send, status_send, mistake)
      values(seq_order.nextval, 
             cur0.date_registration, cur0.end_time_testing, 
             iid_center, 
             cur0.id_registration, cur0.iin, 
             icategory, 'Completed', res, 
             cur0.status_testing, '', '', cur0.status_testing); 
    end if;
    
  end loop;
  commit;
  end restore_order;


begin
  null;
end restore;
/
