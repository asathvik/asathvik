-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for VersionOne backlog B-66024.
--	Load loan mapping information into a staging table.
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	04/11/2012 - Dimitriy Alekseyev
--	Script created.
-- -----------------------------------------------------------------------------

USE orders_archive;

SELECT NOW();

SELECT COUNT(*) FROM b66024_loan_mapping_tmp;

LOAD DATA INFILE '/dba_share/dbs/orders_archive/mysql/db_maint/B-66024_citi_loan_number_cleanup/CitiLoanCleanup_2012-01-01_2012-03-31.txt'
INTO TABLE b66024_loan_mapping_tmp
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'
(decrypted_loan_nbr, encrypted_loan_nbr, submission_key);

SHOW COUNT(*) ERRORS;
SHOW ERRORS;
SHOW COUNT(*) WARNINGS;
SHOW WARNINGS;

SELECT NOW();

SELECT COUNT(*) FROM b66024_loan_mapping_tmp;

SELECT * FROM b66024_loan_mapping_tmp LIMIT 10;

SHOW INDEXES IN b66024_loan_mapping_tmp;
ANALYZE TABLE b66024_loan_mapping_tmp;
SHOW INDEXES IN b66024_loan_mapping_tmp;

SELECT NOW();
