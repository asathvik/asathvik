-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Backout script for VersionOne backlog B-39173.
--	Backout: Orders_archive DB schema change - create new table "blar".
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	12/13/2010 - Dimitriy Alekseyev
--	Script created.
-- -----------------------------------------------------------------------------

USE orders_archive;

SELECT NOW();

SHOW TABLES;
DESCRIBE blar;
SHOW CREATE TABLE blar\G;
SHOW INDEXES IN blar;

SELECT * FROM information_schema.triggers
WHERE trigger_name IN ('trg_blar_bins', 'trg_blar_bupd');


DROP TRIGGER trg_blar_bins;
DROP TRIGGER trg_blar_bupd;

DROP TABLE blar;


SHOW TABLES;

SELECT * FROM information_schema.triggers
WHERE trigger_name IN ('trg_blar_bins', 'trg_blar_bupd');

SELECT NOW();
