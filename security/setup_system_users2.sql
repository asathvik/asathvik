-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Delete all existing privileges and grant system user privileges. This 
--	script is to be used when setting up a brand new MySQL instance.
--
-- Usage:
--	m1c.sh < setup_system_users.sql > setup_system_users.log
--
-- Revisions:
--	05/07/2008 - Dimitriy Alekseyev
--	Script created.
--	04/27/2010 - Dimitriy Alekseyev
--	Modified script to delete all existing privileges. Previously all 
--	privileges from user and db table were deleted.
--	09/15/2010 - Dimitriy Alekseyev
--	Modified script to work with MySQL 5.1.
-- -----------------------------------------------------------------------------

DELETE FROM mysql.procs_priv;
DELETE FROM mysql.columns_priv;
DELETE FROM mysql.tables_priv;
DELETE FROM mysql.host;
DELETE FROM mysql.db;
DELETE FROM mysql.user;

FLUSH PRIVILEGES;

GRANT ALL ON *.* TO 'dbauser'@'%' IDENTIFIED BY 'surfb0ard' WITH GRANT OPTION;
SHOW GRANTS FOR 'dbauser';

GRANT SELECT ON *.* TO 'dbmon'@'%' IDENTIFIED BY 'w4tch0db';
SHOW GRANTS FOR 'dbmon';
