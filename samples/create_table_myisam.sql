-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for VersionOne backlog B-39173.
--	Orders_archive DB schema change - create new table "blar".
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


CREATE TABLE blar (
blar_id			INT		NOT NULL	AUTO_INCREMENT			COMMENT 'Auto incremented unique identifier for the table. Origin: database.',
submission_key		CHAR(22)	NOT NULL					COMMENT '',
orig_submission_key	CHAR(22)	NULL						COMMENT '',
net_new_ind		CHAR(1)		NULL						COMMENT '',
mers_success_ind	CHAR(1)		NULL						COMMENT '',
mers_lockout_ind	CHAR(1)		NULL						COMMENT '',
insert_date		TIMESTAMP	NOT NULL	DEFAULT CURRENT_TIMESTAMP	COMMENT 'The date and time that the row was inserted into this table. Origin: database.',
last_update		TIMESTAMP	NOT NULL	DEFAULT '1970-01-02 00:00:00'	COMMENT 'The date and time that the row was updated in this table. Origin: database.',
PRIMARY KEY		(blar_id)
)
ENGINE=MyISAM MAX_ROWS=1000000000 AVG_ROW_LENGTH=57 PACK_KEYS=1 CHECKSUM=1 ROW_FORMAT=DYNAMIC;

ALTER TABLE blar
ADD UNIQUE INDEX ak1_blar (submission_key);

DELIMITER ;;

CREATE DEFINER=`dbauser`@`%` TRIGGER `trg_blar_bins` BEFORE INSERT ON `blar` FOR EACH ROW
BEGIN
	SET NEW.last_update = NOW();
END;;

CREATE DEFINER=`dbauser`@`%` TRIGGER `trg_blar_bupd` BEFORE UPDATE ON `blar` FOR EACH ROW
BEGIN
	SET NEW.last_update = NOW();
END;;

DELIMITER ;


SHOW TABLES;
DESCRIBE blar;
SHOW CREATE TABLE blar\G;
SHOW INDEXES IN blar;

SELECT * FROM information_schema.triggers
WHERE trigger_name IN ('trg_blar_bins', 'trg_blar_bupd');

SELECT NOW();
