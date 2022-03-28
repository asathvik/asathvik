-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for Seapine ticket 16991.
--	Create empty wordpressblog database.
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	01/14/2011 - Dimitriy Alekseyev
--	Script created.
-- -----------------------------------------------------------------------------

SELECT NOW();

SHOW DATABASES;
CREATE DATABASE wordpressblog;
SHOW DATABASES;

SELECT NOW();
