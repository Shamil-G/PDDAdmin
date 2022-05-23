create or replace package assign_place is

  -- Author  : S.Gusseynov
  -- Created : 24-oaa-22 9:22:22
  -- Purpose : Assign random place


  -- Public function and procedure declarations
  procedure get_place(inum_order in number, mask_ip in varchar2, ret_ip_addr out varchar2, ostatus out varchar2);

  procedure free_place(inum_order in number);
  procedure lock_place(iip_addr in varchar2);
  procedure unlock_place(iip_addr in varchar2);
  

end assign_place;
/
create or replace package body assign_place is

  procedure log(itype in char, iproc in varchar2,
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg)
        values(systimestamp, itype, 'ASSIGN_PLACE', iproc, inum_order, imess);
    commit;
  end;

  procedure lock_place(iip_addr in varchar2) 
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    update random_place rp set rp.lck='Y' where rp.ip_addr=iip_addr;
    commit;
  end;

  procedure unlock_place(iip_addr in varchar2) 
  is
   r_random_place random_place%rowtype;
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    select * into r_random_place from random_place rp where rp.ip_addr=iip_addr;
    insert into random_place_hist rh values r_random_place;
    update random_place rp set rp.num_order = null, date_assign = null, rp.lck='N' where rp.ip_addr=iip_addr;
    commit;
  end;

  procedure free_place(inum_order in number)
  is
   r_random_place random_place%rowtype;
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    select * into r_random_place from random_place rp where rp.num_order=inum_order;
    insert into random_place_hist rh values r_random_place;
    update random_place rp set rp.num_order = null, date_assign = null, lck = 'N' where rp.num_order=inum_order;
    commit;
  end;

  procedure init_place(iid_center in pls_integer)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    delete from random_place rp where rp.id_center=iid_center;

    for cur in (
        select lw.*
        from   cop.list_workstation lw , cop.centers c
        where c.code_center=lw.code_center
        and   c.active='Y'
        and   lw.active='Y'
        and   lw.status='T'
        and   c.id_center=iid_center
        )
    loop
      insert into random_place(id_center, ip_addr, lck) values(iid_center, cur.ip_addr, 'N');
    end loop;
--      raise_application_error(-20000, '1. INIT PLACE. RET: '||cur.ip_addr);
    commit;
  end init_place;

  function get_free_addr(iid_center in pls_integer) return varchar2
  is
    ret varchar2(16);
  begin
    select ip_addr into ret
    from (
    select rank() over(ORDER BY DBMS_RANDOM.RANDOM) num,
           ip_addr
    FROM   random_place rp
    where rp.id_center=iid_center
    and   24*60*(sysdate-rp.date_assign) > 35
    and   rp.lck not in ('Y','R')
    )
    where num=3;
    return ret;
    exception when no_data_found then return '';
  end;

  procedure get_place(inum_order in number, mask_ip in varchar2, ret_ip_addr out varchar2, ostatus out varchar2)
  is
    v_ip_addr varchar2(16);
    v_id_center pls_integer;
    cnt_place pls_integer default 0;
    r_order pdd.orders%rowtype;
    r_random_place pdd.random_place%rowtype;
  begin
    begin
      select * into r_random_place from random_place rp where rp.num_order=inum_order;
      ret_ip_addr:=r_random_place.ip_addr;
      return;
    exception when no_data_found then null;
    end;
    -- Check ID Center with help mask_ip and num_order
    select c.id_center into v_id_center
    from cop.list_workstation lw, cop.centers c
    where substr(lw.ip_addr, 1, length(mask_ip)) = mask_ip and rownum=1
    and   lw.code_center=c.code_center;

    begin
      select * into r_order from pdd.orders o where o.num_order=inum_order;
      if r_order.status!='New' then
        ret_ip_addr:='';
        ostatus:='ORDER_USED';
        return;
      end if;
      if r_order.ip_addr is not null then
        ret_ip_addr:=r_order.ip_addr;
        return;
      end if;
    exception when no_data_found then
      begin
        ret_ip_addr:='';
        ostatus:='ORDER_ABSENT';
        return;
      end;
    end;
    
    -- Now compare ID CENTER
    if v_id_center!=r_order.id_center then
       log('E', 'GET_PLACE',inum_order, 'MASK IP and INUM_ORDER is in different Centers');
        ret_ip_addr:='';
        ostatus:='MISTAKE_ID_CENTER';
       return;
    end if;

    v_ip_addr := get_free_addr(r_order.id_center);
    if v_ip_addr is null then
--        raise_application_error(-20000, '1. GET PLACE. RET: '||ret);
        select count(ip_addr) into cnt_place from pdd.random_place rp where rp.id_center=r_order.id_center;
        log('I', 'GET PLACE', inum_order, 'COUNT free IP_ADDR: '||CNT_PLACE);
        -- May be need create addr pool in table random_place
        if cnt_place=0 then
            init_place(r_order.id_center);
            v_ip_addr := get_free_addr(r_order.id_center);
        end if;
        if cnt_place>0 then
          ret_ip_addr:='';
          ostatus:='ALL_PLACE_BUSY';
          return;
        end if;
    end if;
    if v_ip_addr is not null then
      update orders o set o.ip_addr=v_ip_addr where o.num_order=inum_order;
      update pdd.random_place rp set rp.num_order=inum_order, rp.date_assign=sysdate, LCK='R' where rp.ip_addr=v_ip_addr;
      ret_ip_addr:=v_ip_addr;
      commit;
    end if;
    log('I', 'GET PLACE', inum_order, 'return IP_ADDR: '||v_ip_addr);
  end;

begin
  -- Initialization
  null;
end assign_place;
/
