create or replace package admin is

  -- Author  : Shamil Gusseynov
  -- Created : 23.06.2021 17:37:04
  -- Purpose :

--  function add_question( iid_theme in number, iorder_num in number,
--        iurl_image in varchar2, iquestion in nvarchar2)
--        return varchar2;
  procedure get_user_info(iusername in varchar2, ofio out nvarchar2, oiin out varchar2);

  procedure role_delete(iid_role in pls_integer);
  procedure role_add(iname in nvarchar2, ifull_name in nvarchar2);
  procedure role_upd(iid_role in pls_integer, iname in nvarchar2, ifull_name in nvarchar2);

  procedure role_assign(iid_role in pls_integer, iid_user in pls_integer);
  procedure role_remove(iid_role in pls_integer, iid_user in pls_integer);

--  Regions, Centers, Workstations
  procedure region_add(iname_ru in nvarchar2, iname_kz in nvarchar2);
  procedure region_del(iid_region in pls_integer);
  procedure region_upd(iid_region in number, iname_ru in nvarchar2, iname_kz in nvarchar2);
  procedure region_name(iid_region in number, oname_ru out nvarchar2, oname_kz out nvarchar2);

  procedure center_add(iid_region in number, icode_center in varchar2,
            iname_short_ru in nvarchar2, iname_short_kz in nvarchar2,
            iname_ru in nvarchar2, iname_kz in nvarchar2);
  procedure center_del(iid_center in pls_integer);
  procedure center_upd(iid_center in number, icode_center in varchar2,
            iname_short_ru in nvarchar2, iname_short_kz in nvarchar2,
            iname_ru in nvarchar2, iname_kz in nvarchar2);
  procedure center_name(iid_center in pls_integer, 
            oregion_name out nvarchar2, ocode_center out varchar2, 
            oname_short_ru out nvarchar2, oname_short_kz out nvarchar2, 
            oname_ru out nvarchar2, oname_kz out nvarchar2);

  procedure workstation_stat(iid_pc in pls_integer);
  procedure workstation_del(iid_pc in pls_integer);
  procedure workstation_add(icode_center in varchar2,
            iip_addr in varchar2, imac in varchar2);
  procedure workstation_upd(iid_pc in pls_integer,
                iip_addr in varchar2, imac in varchar2);
  procedure clean_log;
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

  procedure get_user_info(iusername in varchar2, ofio out nvarchar2, oiin out varchar2)
  is
  begin
    select  u.lastname || ' ' || u.name || ' ' || u.middlename,
           u.iin
    into ofio, oiin
    from users u 
    where u.username=iusername;
    exception when no_data_found then null;
  end get_user_info;

    procedure role_delete(iid_role in pls_integer)
    is
    begin
        update cop.roles r
        set    r.active= case when r.active='Y' then 'N' else 'Y' end
        where  r.id_role=iid_role;
        commit;
    end role_delete;

    procedure role_add(iname in nvarchar2, ifull_name in nvarchar2)
    is
        v_id_role PLS_INTEGER default 0;
    begin
        select max(id_role) into v_id_role from roles;
        insert into roles (id_role, active, name, full_name)
                values(v_id_role+1, 'Y', iname, ifull_name);
        commit;
    end;

    procedure role_upd(iid_role in pls_integer, iname in nvarchar2, ifull_name in nvarchar2)
    is
    begin
        update roles r
        set r.name=coalesce(iname,r.name),
            r.full_name=coalesce(ifull_name, r.full_name)
        where r.id_role=iid_role;
        commit;
    end;

    procedure role_assign(iid_role in pls_integer, iid_user in pls_integer)
    is
    begin
        insert into users_roles(id_role, id_user) values(iid_role, iid_user);
        commit;
    exception when dup_val_on_index then null;
    end role_assign;

    procedure role_remove(iid_role in pls_integer, iid_user in pls_integer)
    is
    begin
        delete from users_roles r
        where id_role=iid_role
        and   id_user=iid_user;
        commit;
    exception when no_data_found then null;
    end role_remove;

  procedure region_add(iname_ru in nvarchar2, iname_kz in nvarchar2)
  is
    max_id_region pls_integer;
  begin
    select max(id_region) into max_id_region from regions t;
    insert into regions(id_region, active, date_op, region_name_ru, region_name_kz)
            values(coalesce(max_id_region,0)+1, 'Y', sysdate, iname_ru, iname_kz);
    commit;
  end;

  procedure region_del(iid_region in pls_integer)
  is
  begin
    update regions r
    set r.active= case when r.active='Y' then 'N' else 'Y' end,
        r.date_op=sysdate
    where r.id_region=iid_region;
    commit;
  end;

  procedure region_upd(iid_region in number, iname_ru in nvarchar2, iname_kz in nvarchar2)
  is
  begin
    update  regions r
    set     r.region_name_ru=iname_ru,
            r.region_name_kz=iname_kz,
            r.date_op=sysdate
    where r.id_region=iid_region;
    commit;
  end;

  procedure region_name(iid_region in number, oname_ru out nvarchar2, oname_kz out nvarchar2)
  is
  begin
    select region_name_ru name_ru, region_name_kz name_kz 
    into oname_ru, oname_kz
    from cop.regions t 
    where t.id_region = iid_region;
  end;

  procedure center_name(iid_center in pls_integer, 
            oregion_name out nvarchar2, ocode_center out varchar2, 
            oname_short_ru out nvarchar2, oname_short_kz out nvarchar2, 
            oname_ru out nvarchar2, oname_kz out nvarchar2
            )
  is
  begin
    select r.region_name_ru, code_center, name_short_ru, name_short_kz, name_ru, name_kz 
    into   oregion_name, ocode_center, oname_short_ru, oname_short_kz,
            oname_ru, oname_kz
    from cop.centers c, cop.regions r
    where c.id_center = iid_center
    and   r.id_region=c.id_region;
  end;
  
  procedure center_add(iid_region in number, icode_center in varchar2,
            iname_short_ru in nvarchar2, iname_short_kz in nvarchar2,
            iname_ru in nvarchar2, iname_kz in nvarchar2)
  is
    max_id_center pls_integer;
  begin
    select max(id_center) into max_id_center from centers t;
    insert into centers(id_center, id_region, active, date_op, code_center,
            name_short_ru, name_short_kz, name_ru, name_kz)
            values(coalesce(max_id_center, 0)+1, iid_region,
                'Y', sysdate, icode_center,
                iname_short_ru, iname_short_kz, iname_ru, iname_kz);
    commit;
  end;

  procedure center_del(iid_center in pls_integer)
  is
  begin
    update centers r
    set r.active= case when r.active='Y' then 'N' else 'Y' end,
        r.date_op=sysdate
    where r.id_center=iid_center;
    commit;
  end;

  procedure center_upd(iid_center in number, icode_center in varchar2,
            iname_short_ru in nvarchar2, iname_short_kz in nvarchar2,
            iname_ru in nvarchar2, iname_kz in nvarchar2)
  is
  begin
    update  centers r
    set     r.name_ru=nvl(iname_ru, r.name_ru),
            r.name_kz=nvl(iname_kz, r.name_kz),
            r.name_short_ru=nvl(iname_short_ru, r.name_short_ru),
            r.name_short_kz=nvl(iname_short_kz, r.name_short_kz),
            r.code_center=nvl(icode_center, r.code_center),
            r.date_op=sysdate
    where r.id_center=iid_center;
    commit;
  end;

  procedure workstation_del(iid_pc in pls_integer)
  is
  begin
    update list_workstation lw
    set     lw.active = case when lw.active='Y' then 'N' else 'Y' end,
            lw.date_op = sysdate
    where  lw.id_pc=iid_pc;
    commit;
  end;

  procedure workstation_stat(iid_pc in pls_integer)
  is
  begin
    update list_workstation lw
    set     lw.status = case when lw.status='T' then 'O' else 'T' end,
            lw.date_op = sysdate
    where  lw.id_pc=iid_pc;
    commit;
  end;

  procedure workstation_add(icode_center in varchar2,
                iip_addr in varchar2, imac in varchar2)
  is
    v_max_id_pc pls_integer default 0;
  begin
    select max(id_pc) into v_max_id_pc from list_workstation lw;
    insert into list_workstation(id_pc, code_center, active,
                    date_op, ip_addr, mac, status)
    values( (v_max_id_pc+1), icode_center, 'Y', sysdate, iip_addr, imac, 'T');
    commit;
    exception when dup_val_on_index then
      begin
        update list_workstation lw
        set lw.code_center=icode_center
        where lw.ip_addr=iip_addr;
        commit;
      end;
  end;

  procedure workstation_upd(iid_pc in pls_integer,
                iip_addr in varchar2, imac in varchar2)
  is
  begin
    update list_workstation lw
    set lw.ip_addr=nvl(iip_addr, lw.ip_addr),
        lw.mac=nvl(imac, lw.mac),
        lw.date_op=sysdate
    where lw.id_pc=iid_pc;
    commit;
  end;

  procedure clean_log
  is
  begin
    -- CLEAN COP.LOG
    delete from cop.log l where l.event_date<trunc(sysdate)-90;
    commit;
    log('I', 'COP.LOG', 0, '---> CLEAN LOG');
    -- CLEAN PDD.LOG
    delete from pdd.log l where trunc(l.event_date)<trunc(sysdate)-60;
    commit;
    log('I', 'PDD.LOG', 0, '---> CLEAN LOG');
    -- CLEAN PDD_TESTING.LOG
    delete from pdd_testing.log l where trunc(l.event_date)<trunc(sysdate)-90;
    commit;
    log('I', 'PDD_TESTING.LOG', 0, '---> CLEAN LOG');
  end; 
  
begin
  -- Initialization
  null;
end admin;
/
