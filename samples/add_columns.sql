-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for VersionOne backlog B-38138.
--	Orders DB schema change - add four columns to loan_detail table.
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

-- Add new columns.
ALTER TABLE loan_detail
ADD	loan_status_date	DATE		NULL	COMMENT 'The date the loan status was provided.'						AFTER loan_status,
ADD	cashout_ind		CHAR(1)		NULL	COMMENT 'Indicates if cash was pulled out with the loan, values are Y/N.'			AFTER front_end_debt_ratio,
ADD	cashout_amount		INTEGER		NULL	COMMENT 'The amount of cash that was pulled out with the loan, if cashout indicator was Y.'	AFTER cashout_ind,
ADD	user_lien_desc		VARCHAR(30)	NULL	COMMENT 'Description of the lien code as given by the customer.'				AFTER user_lien_cd
;

DESCRIBE loan_detail;
SHOW CREATE TABLE loan_detail\G;
SHOW INDEXES IN loan_detail;

SELECT NOW();

ANALYZE TABLE loan_detail;
SHOW INDEXES IN loan_detail;

SELECT NOW();
