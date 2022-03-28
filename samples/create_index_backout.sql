-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Backout script for VersionOne backlog B-xxxxx.
--	Backout: ars DB schema change - create new unique index.
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	06/29/2011 - Dimitriy Alekseyev
--	Script created.
-- -----------------------------------------------------------------------------

USE ars;

SELECT NOW();


SHOW INDEX IN service_requests;
SHOW CREATE TABLE service_requests\G;

ALTER TABLE service_requests
DROP INDEX ak1_srvc_reqs;

SHOW INDEX IN service_requests;
SHOW CREATE TABLE service_requests\G;


SELECT NOW();
