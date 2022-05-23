create or replace package cop is

  -- Author  : Shamil Gusseynov
  -- Created : 21.06.2021 14:06:15
  -- Purpose :

  -- Public type declarations

  procedure login_admin(uname in nvarchar2, upass out nvarchar2, 
            iip_addr in varchar2, oid_user out number, oid_center out number);
  procedure login_center_admin(uname in nvarchar2, upass out nvarchar2, 
            iip_addr in varchar2, oid_user out number, oid_center out number);
  procedure new_user2(uname in nvarchar2, upass in nvarchar2, iid_creator in number, iiin in varchar2, 
                            iphone in nvarchar2,    
                            first_name in nvarchar2, last_name in nvarchar2, middle_name in nvarchar2, 
                            description in nvarchar2, imess out nvarchar2);
  procedure change_password(iusername in varchar2, ipassword in varchar2);
                            
  procedure get_roles(iid_user in pls_integer, cur out sys_refcursor);

  procedure all_roles(cur out sys_refcursor);
  procedure all_users(cur out sys_refcursor);
  procedure role_users(iid_role in pls_integer, cur out sys_refcursor);
  procedure list_users(cur out sys_refcursor);
  
  procedure get_role_name(iid_role in pls_integer, role_name out varchar2);
  procedure alter_user_role(iid_user in pls_integer, irole_name in varchar2);
  
  procedure set_user_info(iid_user in pls_integer, iusername in nvarchar2, ipassword in varchar2, iiin in varchar2, iphone in varchar2, 
                          ilast_name in nvarchar2, ifirst_name in nvarchar2, imiddle_name in nvarchar2, idescr in nvarchar2);
  procedure get_user_info(iid_user in pls_integer, ousername out nvarchar2, oiin out varchar2, ophone out varchar2, 
                          olast_name out nvarchar2, ofirst_name out nvarchar2, omiddle_name out nvarchar2, odescr out nvarchar2);
  
  procedure get_user_descr(iid_user in pls_integer, odescr out nvarchar2);

end cop;
/
create or replace package body cop is

  procedure log(itype in char, iproc in varchar2, 
    imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, msg) 
        values(systimestamp, itype, 'cop', iproc, imess);
    commit;
  end;

  procedure log(itype in char, iproc in varchar2, 
    inum_order in number, imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log(event_date, type, module, proc, num_order, msg) 
        values(systimestamp, itype, 'cop', iproc, coalesce(inum_order,0), imess);
    commit;
    exception when others then
        raise_application_error(-20000, 'LOG. inum_order: '||inum_order);
  end;

--/*
  function is_admin(iid_user in number) return pls_integer
  as
    v_admin pls_integer default 0;
  begin
    select count(*) into v_admin
    from users u, users_roles ur, roles r
    where u.id_user=iid_user
    and   ur.id_user=iid_user
    and   r.id_role=ur.id_role
    and   lower(r.name)='admin';
    return v_admin;
  end is_admin;

  function is_cop(iid_user in number) return pls_integer
  as
    v_cop pls_integer default 0;
  begin
    log('I', 'is_cop', 'id_user: '||iid_user);
    select count(*) into v_cop
    from users u, users_roles ur, roles r
    where u.id_user=iid_user
    and   ur.id_user=iid_user
    and   r.id_role=ur.id_role
    and   lower(r.name)='secure';
    return v_cop;
    exception when no_data_found then return 0;
  end is_cop;

  procedure new_user2(uname in nvarchar2, upass in nvarchar2, iid_creator in number, iiin in varchar2, 
                            iphone in nvarchar2,    
                            first_name in nvarchar2, last_name in nvarchar2, middle_name in nvarchar2, 
                            description in nvarchar2, imess out nvarchar2)
  is
    v_id_user    number(9);
    v_name_creator nvarchar2(64);
  begin
    imess:='';
    select u.name into v_name_creator from users u where u.id_user=iid_creator;
    select max(id_user) into v_id_user from users;
    insert into users(id_user, username, password, active, iin, phone, date_op, name, lastname, middlename, descr) 
           values(v_id_user+1, uname, upass, 'Y', iiin, iphone, sysdate, first_name, last_name, middle_name, description);
    log('I', 'new_user2', uname||', created by: '||v_name_creator);
    commit;
    exception
      when no_data_found then
        begin
          log('E', 'new_user2', 'Not found id_creator: '||iid_creator);
          imess:='Mistake '||iid_creator;
          commit;
        end;
      when dup_val_on_index then
      begin
        if is_admin(iid_creator)>0 or
           v_name_creator=uname
          then
            update users u
            set u.password=upass
            where u.name=uname;
            commit;
            log('I', 'new_user2', 'Update password for user name: '||uname||' by: '||v_name_creator);
            commit;
        else
          log('E', 'new_user2', 'Duplicate user name: '||uname);
          imess:='Duplicated user name';
          commit;
        end if;
      end;
  end;

  procedure login_admin(uname in nvarchar2, upass out nvarchar2, 
            iip_addr in varchar2, oid_user out number, oid_center out number)
  is
    i_cop pls_integer default 0;
  begin
    oid_center:=0;
      begin
        select u.id_user, u.password 
        into oid_user, upass
        from users u
        where u.username=uname
        and  u.active='Y';
      exception when no_data_found then
        log('E', 'login_admin', 'USER not found. username: '||uname||', password: '||upass||', ip_addr: '||iip_addr);
        oid_center:=-100;
        oid_user:=-100;
--        upass:='';
      end;
     
    i_cop := is_cop(oid_user);
    if i_cop=0 then
      begin
          select c.id_center
          into oid_center 
          from list_workstation lw, centers c
          where lw.code_center=c.code_center
          and   lw.active='Y'
          and   lw.status='O'
          and   lw.ip_addr=iip_addr;
      exception when no_data_found then
        log('E', 'login_admin', 'Registration from UNKNOWN IP address. uname: '||uname||', ip_addr: '||iip_addr);
          oid_center:=-200;
          oid_user:=-200;
      end;
      log('I', 'login_admin', 'Oper login for: '||uname||', ip_addr: '||iip_addr||', id_center: '||oid_center||', '||upass);
    else
      log('I', 'login_admin', 'Admin login for: '||uname||', ip_addr: '||iip_addr||', id_center: '||oid_center||', '||upass);
    end if;
  end;    

  procedure login_center_admin(uname in nvarchar2, upass out nvarchar2, 
            iip_addr in varchar2, oid_user out number, oid_center out number)
  is
    i_cop pls_integer default 0;
  begin
    oid_center:=0;
      begin
        select u.id_user, u.password 
        into oid_user, upass
        from users u
        where u.username=uname
        and  u.active='Y';
      exception when no_data_found then
        log('E', 'login_admin', 'Not found. username: '||uname||', password: '||upass||', ip_addr: '||iip_addr);
        oid_center:=-100;
        oid_user:=-100;
      end;
      
    i_cop := is_cop(oid_user);
    if i_cop=0 then
        begin
            select c.id_center
            into oid_center 
            from list_workstation lw, centers c
            where lw.code_center=c.code_center
            and   lw.active='Y'
            and   lw.ip_addr=iip_addr;
        exception when no_data_found then
          log('E', 'login_admin', 'PC not found. uname: '||uname||', ip_addr: '||iip_addr);
            oid_center:=-200;
            oid_user:=-200;
        end;
    end if;
    log('I', 'login_admin', 'Login for: '||uname||', '||upass||', ip_addr: '||iip_addr||', id_center: '||oid_center);
  end; 

  procedure get_roles(iid_user in pls_integer, cur out sys_refcursor)
  is
    cmd varchar2(256);
  begin
    cmd := 
    'select r.name ' ||
    'from roles r, users u, users_roles us ' ||
    'where u.id_user=us.id_user ' ||
    'and   r.id_role=us.id_role ' ||
    'and u.id_user=:iid_user';
    open cur for cmd using iid_user;
    log('I', 'get_roles', 'role for iid_user: '||iid_user||', cmd: '||cmd);    
  end get_roles;
  
  procedure all_roles(cur out sys_refcursor)
  is
    cmd varchar2(128);
  begin
    cmd := 'select id_role, active, name, full_name from cop.roles order by id_role';
    open cur for cmd;
  end all_roles;
  
  procedure all_users(cur out sys_refcursor)
  is
    cmd varchar2(148);
  begin
    cmd := 'select u.id_user, u.username, u.lastname||'' ''||u.name||'' ''||u.middlename||'' (''||u.iin||'')'' as fio, u.descr ' ||
           'from cop.users u ';
    open cur for cmd;
  end all_users;  

  procedure list_users(cur out sys_refcursor)
  is
    cmd varchar2(1024);
  begin
    cmd := 'select id_user, sum(oper), sum(oper_center), sum(admin), sum(secure),username, fio, descr '||
           'from( '||
                  'select u.id_user, '||
                          'case when r.name=''oper'' then 1 else 0 end as oper, '||
                          'case when r.name=''oper_center'' then 1 else 0 end as oper_center, '||
                          'case when r.name=''admin'' then 1 else 0 end as admin, '||
                          'case when r.name=''secure'' then 1 else 0 end as secure, '||
                          ' u.username, u.lastname||'' ''||u.name||'' ''||u.middlename||'' (''||u.iin||'')'' as fio, u.descr '||
                  'from cop.users u, cop.users_roles ur, cop.roles r '||
                  'where u.id_user=ur.id_user '||
                  'and   r.id_role=ur.id_role '||
                  'order by u.username '||
                ') '||
            'group by id_user, username, fio, descr '||
            'order by username'; 
    open cur for cmd;
  end list_users;  

  procedure alter_user_role(iid_user in pls_integer, irole_name in varchar2)
  is
  v_id_role pls_integer default 0;
  ex char(1);
  begin
    log('I', '1. ALTER USER ROLE', 'id_user: '||iid_user||', role_name: '||irole_name);
    select id_role into v_id_role
    from cop.roles r
    where r.name=irole_name;
    log('I', '2. ALTER USER ROLE', 'id_user: '||iid_user||', role_name: '||irole_name);

    begin
      select '1' into ex
      from users_roles ur
      where ur.id_role=v_id_role
      and   ur.id_user=iid_user;
      delete from users_roles ur where ur.id_user=iid_user and ur.id_role=v_id_role;
      log('I', 'ALTER USER ROLE.', 'id_user: '||iid_user||', DELETE role_name: '||irole_name);
      commit;
    exception when no_data_found then
      begin
        insert into users_roles(id_role, id_user) values(v_id_role, iid_user);
        log('I', 'ALTER USER ROLE.', 'id_user: '||iid_user||', ADD role_name: '||irole_name);
        commit;
      end;      
    end;
  end alter_user_role;
     
  procedure role_users(iid_role in pls_integer, cur out sys_refcursor)
  is
    cmd varchar2(256);
  begin
    cmd := 'select u.id_user, u.username, u.lastname||'' ''||u.name||'' ''||u.middlename||'' (''||u.iin||'')'' as fio, u.descr ' ||
          'from cop.roles r, cop.users_roles ur, cop.users u '||
          'where r.id_role=ur.id_role ' ||
          'and   ur.id_user = u.id_user ' ||
          'and   r.id_role = :id_role';
    open cur for cmd using iid_role;
  end role_users;  

  procedure get_role_name(iid_role in pls_integer, role_name out varchar2)
  is
  begin
    select full_name into role_name from roles r where r.id_role=iid_role;
  end get_role_name;  
  
  procedure change_password(iusername in varchar2, ipassword in varchar2)
  is
  begin
--    log('E', 'change_password', 'username: '||iusername||', password: '||ipassword);
    update users u
    set u.password=ipassword,
        u.date_op=sysdate
    where u.username=iusername;
    log('I', 'change_password', 'uname: '||iusername||', pass: '||ipassword);
    commit;
  end change_password;

--*/
  procedure set_user_info(iid_user in pls_integer, iusername in nvarchar2, ipassword in varchar2, iiin in varchar2, iphone in varchar2, 
                          ilast_name in nvarchar2, ifirst_name in nvarchar2, imiddle_name in nvarchar2, idescr in nvarchar2)
  is
  begin
    UPDATE cop.users u 
    set    u.username = coalesce(iusername, u.username),
           u.iin      = coalesce(iiin, u.iin),
           u.phone    = coalesce(iphone, u.phone),
           u.password = coalesce(ipassword, u.password),
           u.lastname = coalesce(ilast_name, u.lastname),
           u.name  = coalesce(ifirst_name, u.name),
           u.middlename = coalesce(imiddle_name, u.middlename),
           u.descr = coalesce(idescr, u.descr),
           date_op = sysdate
    where u.id_user=iid_user;
    commit;
  end;
--/*
  procedure get_user_info(iid_user in pls_integer, ousername out nvarchar2, oiin out varchar2, ophone out varchar2,
                          olast_name out nvarchar2, ofirst_name out nvarchar2, omiddle_name out nvarchar2, odescr out nvarchar2)
  is
  begin
    select u.username, u.iin, u.phone, u.lastname, u.name, u.middlename, u.descr
    into   ousername, oiin, ophone, olast_name, ofirst_name, omiddle_name, odescr
    from cop.users u 
    where u.id_user=iid_user;
  end get_user_info;
--/*
--/*
  procedure get_user_descr(iid_user in pls_integer, odescr out nvarchar2)
  is
  begin
    select u.descr
    into   odescr
    from cop.users u 
    where u.id_user=iid_user;
  end get_user_descr;
  
begin
  null;
end cop;
/
