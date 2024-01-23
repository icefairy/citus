-- Public role has connect,temp,temporary privileges on database
-- To test these scenarios, we need to revoke these privileges from public role
-- since public role privileges are inherited by new roles/users
set citus.enable_create_database_propagation to on;
create database test_2pc_db;

show citus.main_db;

revoke connect,temp,temporary  on database test_2pc_db from public;



CREATE SCHEMA grant_on_database_propagation;
SET search_path TO grant_on_database_propagation;


-- test grant/revoke CREATE privilege propagation on database
create user myuser;


\c test_2pc_db - - :master_port
grant create on database test_2pc_db to myuser;

\c regression - - :master_port;
select check_database_privileges('myuser','test_2pc_db',ARRAY['CREATE']);

\c test_2pc_db - - :master_port
revoke create on database test_2pc_db from myuser;

\c regression - - :master_port;
select check_database_privileges('myuser','test_2pc_db',ARRAY['CREATE']);

drop user myuser;
-----------------------------------------------------------------------

-- test grant/revoke CONNECT privilege propagation on database
\c regression - - :master_port
create user myuser2;

\c test_2pc_db - - :master_port
grant CONNECT on database test_2pc_db to myuser2;

\c regression - - :master_port;
select check_database_privileges('myuser2','test_2pc_db',ARRAY['CONNECT']);

\c test_2pc_db - - :master_port
revoke connect on database test_2pc_db from myuser2;

\c regression - - :master_port
select check_database_privileges('myuser2','test_2pc_db',ARRAY['CONNECT']);

drop user myuser2;

-----------------------------------------------------------------------

-- test grant/revoke TEMP privilege propagation on database
\c regression - - :master_port
create user myuser3;

-- test grant/revoke temp on database
\c test_2pc_db - - :master_port
grant TEMP on database test_2pc_db to myuser3;

\c regression - - :master_port;
select check_database_privileges('myuser3','test_2pc_db',ARRAY['TEMP']);


\c test_2pc_db - - :worker_1_port
revoke TEMP on database test_2pc_db from myuser3;

\c regression - - :master_port;
select check_database_privileges('myuser3','test_2pc_db',ARRAY['TEMP']);

drop user myuser3;

-----------------------------------------------------------------------

\c regression - - :master_port
-- test temporary privilege on database
create user myuser4;

-- test grant/revoke temporary on database
\c test_2pc_db - - :worker_1_port
grant TEMPORARY on database test_2pc_db to myuser4;

\c regression - - :master_port
select check_database_privileges('myuser4','test_2pc_db',ARRAY['TEMPORARY']);

\c test_2pc_db - - :master_port
revoke TEMPORARY on database test_2pc_db from myuser4;

\c regression - - :master_port;
select check_database_privileges('myuser4','test_2pc_db',ARRAY['TEMPORARY']);

drop user myuser4;
-----------------------------------------------------------------------

-- test ALL privileges with ALL statement on database
create user myuser5;

grant ALL on database test_2pc_db to myuser5;

\c regression - - :master_port
select check_database_privileges('myuser5','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);


\c test_2pc_db - - :master_port
revoke ALL on database test_2pc_db from myuser5;

\c regression - - :master_port
select check_database_privileges('myuser5','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);

drop user myuser5;
-----------------------------------------------------------------------

-- test CREATE,CONNECT,TEMP,TEMPORARY privileges one by one on database
create user myuser6;

\c test_2pc_db - - :master_port
grant CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db to myuser6;

\c regression - - :master_port
select check_database_privileges('myuser6','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);

\c test_2pc_db - - :master_port
revoke CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db from myuser6;

\c regression - - :master_port
select check_database_privileges('myuser6','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);


drop user myuser6;
-----------------------------------------------------------------------

-- test CREATE,CONNECT,TEMP,TEMPORARY privileges one by one on database with grant option
create user myuser7;
create user myuser_1;

\c test_2pc_db - - :master_port
grant CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db to myuser7;

set role myuser7;
--here since myuser does not have grant option, it should fail
grant CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db to myuser_1;

\c regression - - :master_port
select check_database_privileges('myuser_1','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);

\c test_2pc_db - - :master_port

RESET ROLE;

grant CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db to myuser7 with grant option;
set role myuser7;

--here since myuser have grant option, it should succeed
grant CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db to myuser_1 granted by myuser7;

\c regression - - :master_port
select check_database_privileges('myuser_1','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);

\c test_2pc_db - - :master_port

RESET ROLE;

--below test should fail and should throw an error since myuser_1 still have the dependent privileges
revoke  CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db from myuser7 restrict;
--below test should fail and should throw an error since myuser_1 still have the dependent privileges
revoke grant option for CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db from myuser7 restrict ;

--below test should succeed and should not throw any error since myuser_1 privileges are revoked with cascade
revoke grant option for CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db from myuser7 cascade ;

--here we test if myuser still have the privileges after revoke grant option for

\c regression - - :master_port
select check_database_privileges('myuser7','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);


\c test_2pc_db - - :master_port

reset role;

revoke  CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db from myuser7;
revoke CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db from myuser_1;

\c regression - - :master_port
drop user myuser_1;
drop user myuser7;

-----------------------------------------------------------------------

-- test CREATE,CONNECT,TEMP,TEMPORARY privileges one by one on database multi database
-- and multi user
\c regression - - :master_port
create user myuser8;
create user myuser_2;

set citus.enable_create_database_propagation to on;
create database test_db;

revoke connect,temp,temporary  on database test_db from public;

\c test_2pc_db - - :master_port
grant CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db,test_db to myuser8,myuser_2;

\c regression - - :master_port
select check_database_privileges('myuser8','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);
select check_database_privileges('myuser8','test_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);
select check_database_privileges('myuser_2','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);
select check_database_privileges('myuser_2','test_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);


\c test_2pc_db - - :master_port

RESET ROLE;
--below test should fail and should throw an error
revoke  CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db,test_db from myuser8 ;

--below test should succeed and should not throw any error
revoke  CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db,test_db from myuser_2;

--below test should succeed and should not throw any error
revoke  CREATE,CONNECT,TEMP,TEMPORARY on database test_2pc_db,test_db from myuser8 cascade;

\c regression - - :master_port
select check_database_privileges('myuser8','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);
select check_database_privileges('myuser8','test_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);
select check_database_privileges('myuser_2','test_2pc_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);
select check_database_privileges('myuser_2','test_db',ARRAY['CREATE', 'CONNECT', 'TEMP', 'TEMPORARY']);


\c test_2pc_db - - :master_port

reset role;

\c regression - - :master_port
drop user myuser_2;
drop user myuser8;

set citus.enable_create_database_propagation to on;
drop database test_db;

---------------------------------------------------------------------------
-- rollbacks public role database privileges to original state
grant connect,temp,temporary  on database test_2pc_db to public;
drop database test_2pc_db;
set citus.enable_create_database_propagation to off;
DROP SCHEMA grant_on_database_propagation CASCADE;

---------------------------------------------------------------------------
