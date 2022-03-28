-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for VersionOne backlog B-38138.
--	Orders DB - analyze table.
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	11/11/2010 - Dimitriy Alekseyev
--	Script created.
-- -----------------------------------------------------------------------------

USE orders;

SELECT NOW();

SHOW INDEXES IN loan_detail;
ANALYZE TABLE loan_detail;
SHOW INDEXES IN loan_detail;

SELECT NOW();
