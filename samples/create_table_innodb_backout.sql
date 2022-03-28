-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Backout script for VersionOne backlog B-39173.
--	Backout: Orders DB schema change - create new table "blar".
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	12/13/2010 - Dimitriy Alekseyev
--	Script created.
--	06/06/2012 - Dimitriy Alekseyev
--	Added more samples.
-- -----------------------------------------------------------------------------

USE orders;

SELECT NOW();


SHOW TABLES;
DESCRIBE blar;
SHOW CREATE TABLE blar\G;
SHOW INDEXES IN blar;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_blar_bins', 'trg_blar_bupd');

DROP TRIGGER trg_blar_bins;
DROP TRIGGER trg_blar_bupd;
DROP TABLE blar;

SHOW TABLES;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_blar_bins', 'trg_blar_bupd');


SELECT NOW();


-- -----------------------------------------------------------------------------


USE apex;

SELECT NOW();


DESCRIBE ac_customer_context;
SHOW CREATE TABLE ac_customer_context\G;
SHOW INDEXES IN ac_customer_context;

ALTER TABLE ac_customer_context
DROP FOREIGN KEY fk3_p_cc,
DROP COLUMN product_id,
DROP COLUMN default_ind,
COMMENT '';

DESCRIBE ac_customer_context;
SHOW CREATE TABLE ac_customer_context\G;
SHOW INDEXES IN ac_customer_context;


SELECT NOW();


SHOW TABLES;
DESCRIBE ac_product_app_context;
SHOW CREATE TABLE ac_product_app_context\G;
SHOW INDEXES IN ac_product_app_context;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_pac_bins', 'trg_pac_bupd');

DROP TRIGGER trg_pac_bins;
DROP TRIGGER trg_pac_bupd;
DROP TABLE ac_product_app_context;

SHOW TABLES;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_pac_bins', 'trg_pac_bupd');


SELECT NOW();


SHOW TABLES;
DESCRIBE ac_product;
SHOW CREATE TABLE ac_product\G;
SHOW INDEXES IN ac_product;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_p_bins', 'trg_p_bupd');

DROP TRIGGER trg_p_bins;
DROP TRIGGER trg_p_bupd;
DROP TABLE ac_product;

SHOW TABLES;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_p_bins', 'trg_p_bupd');


SELECT NOW();
