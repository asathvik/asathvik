-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Backout script for VersionOne backlog B-38138.
--	Backout: Orders DB schema change - add four columns to loan_detail table.
--
-- Revisions:
--	2010-11-11 - Dimitriy Alekseyev
--	Script created.
-- -----------------------------------------------------------------------------

USE orders;

SELECT NOW();

DESCRIBE loan_detail;
SHOW CREATE TABLE loan_detail\G;
SHOW INDEXES IN loan_detail;

-- Drop new columns.
ALTER TABLE loan_detail
DROP COLUMN loan_status_date,
DROP COLUMN cashout_ind,
DROP COLUMN cashout_amount,
DROP COLUMN user_lien_desc
;

DESCRIBE loan_detail;
SHOW CREATE TABLE loan_detail\G;
SHOW INDEXES IN loan_detail;

SELECT NOW();

ANALYZE TABLE loan_detail;
SHOW INDEXES IN loan_detail;

SELECT NOW();
