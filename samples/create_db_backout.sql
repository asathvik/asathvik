-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Backout script for Seapine ticket 16991.
--	Backout: Create empty wordpressblog database.
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
DROP DATABASE wordpressblog;
SHOW DATABASES;

SELECT NOW();
