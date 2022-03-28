-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for VersionOne backlog B-xxxxx.
--	ars DB schema change - create new unique index.
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
ADD UNIQUE INDEX ak1_srvc_reqs (uuid);

SHOW INDEX IN service_requests;
SHOW CREATE TABLE service_requests\G;


SELECT NOW();
