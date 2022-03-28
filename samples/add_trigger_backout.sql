-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Backout script for VersionOne backlog B-12345.
--	Backout: Claimcheck DB schema change - add trigger.
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	05/17/2012 - Dimitriy Alekseyev
--	Script created.
-- -----------------------------------------------------------------------------

USE claimcheck;

SELECT NOW();

SELECT * FROM information_schema.triggers WHERE trigger_name = 'trg_svcreq_bdel'\G

DROP TRIGGER IF EXISTS trg_svcreq_bdel;

SELECT * FROM information_schema.triggers WHERE trigger_name = 'trg_svcreq_bdel'\G

SELECT NOW();
