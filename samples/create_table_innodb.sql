-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- RDBMS:
--	MySQL 5.0
--
-- Purpose:
--	Script for VersionOne backlog B-39173.
--	Orders DB schema change - create new table "blar".
--
-- Revisions:
--	2010-12-13 - Dimitriy Alekseyev
--	Script created.
--	2012-06-06 - Dimitriy Alekseyev
--	Added more samples.
-- -----------------------------------------------------------------------------

USE orders;

SELECT NOW();

SHOW TABLES;


CREATE TABLE blar (
blar_id			INT		NOT NULL	AUTO_INCREMENT			COMMENT 'Auto incremented unique identifier for the table. Populated by the database.',
submission_key		CHAR(22)	NOT NULL					COMMENT '',
orig_submission_key	CHAR(22)	NULL						COMMENT '',
net_new_ind		CHAR(1)		NULL						COMMENT '',
mers_success_ind	CHAR(1)		NULL						COMMENT '',
mers_lockout_ind	CHAR(1)		NULL						COMMENT '',
insert_ts		TIMESTAMP	NOT NULL	DEFAULT NOW()			COMMENT 'Timestamp of when the row was inserted. Populated by the database.',
update_ts		TIMESTAMP	NOT NULL	DEFAULT '1970-01-02 00:00:00'	COMMENT 'Timestamp of when the row was updated. Populated by the database.',
PRIMARY KEY		(blar_id)
) ENGINE = InnoDB;

ALTER TABLE blar
ADD UNIQUE INDEX ak1_blar (submission_key);

DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER `trg_blar_bins` BEFORE INSERT ON `blar` FOR EACH ROW
BEGIN
	SET NEW.update_ts = NOW();
END;;
CREATE DEFINER = CURRENT_USER TRIGGER `trg_blar_bupd` BEFORE UPDATE ON `blar` FOR EACH ROW
BEGIN
	SET NEW.update_ts = NOW();
END;;
DELIMITER ;

SHOW TABLES;
DESCRIBE blar;
SHOW CREATE TABLE blar\G;
SHOW INDEXES IN blar;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_blar_bins', 'trg_blar_bupd');


SELECT NOW();


-- -----------------------------------------------------------------------------


USE apex;

SELECT NOW();

SHOW TABLES;


CREATE TABLE ac_product (
product_id		INT		NOT NULL	AUTO_INCREMENT			COMMENT 'Auto incremented unique identifier for the table. Populated by the database.',
product_name		VARCHAR(50)	NOT NULL					COMMENT 'The product name, ie "LSAM", required field.',
insert_ts		TIMESTAMP	NOT NULL	DEFAULT NOW()			COMMENT 'Timestamp of when the row was inserted. Populated by the database.',
update_ts		TIMESTAMP	NOT NULL	DEFAULT '1970-01-02 00:00:00'	COMMENT 'Timestamp of when the row was updated. Populated by the database.',
PRIMARY KEY		(product_id),
UNIQUE INDEX		ak1_p (product_name)
) ENGINE = InnoDB COMMENT 'Track Products used in Apex.';

DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER `trg_p_bins` BEFORE INSERT ON `ac_product` FOR EACH ROW
BEGIN
	SET NEW.update_ts = NOW();
END;;
CREATE DEFINER = CURRENT_USER TRIGGER `trg_p_bupd` BEFORE UPDATE ON `ac_product` FOR EACH ROW
BEGIN
	SET NEW.update_ts = NOW();
END;;
DELIMITER ;

DESCRIBE ac_product;
SHOW CREATE TABLE ac_product\G;
SHOW INDEXES IN ac_product;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_p_bins', 'trg_p_bupd');


SELECT NOW();


CREATE TABLE ac_product_app_context (
product_app_context_id	INT		NOT NULL	AUTO_INCREMENT			COMMENT 'Auto incremented unique identifier for the table. Populated by the database.',
app_id			INT		NOT NULL					COMMENT 'Foreign Key to ac_app_context table.',
product_id		INT		NOT NULL					COMMENT 'Foreign Key to ac_product table.',
profile_key_name	VARCHAR(50)	NULL						COMMENT 'The product\'s name for the product/application association, ie "LSAM_SERVICE_ID", not required.',
insert_ts		TIMESTAMP	NOT NULL	DEFAULT NOW()			COMMENT 'Timestamp of when the row was inserted. Populated by the database.',
update_ts		TIMESTAMP	NOT NULL	DEFAULT '1970-01-02 00:00:00'	COMMENT 'Timestamp of when the row was updated. Populated by the database.',
PRIMARY KEY		(product_app_context_id),
CONSTRAINT fk1_ac_pac FOREIGN KEY if1_pac (app_id) REFERENCES ac_app_context(app_id),
CONSTRAINT fk2_p_pac FOREIGN KEY if2_pac (product_id) REFERENCES ac_product(product_id)
) ENGINE = InnoDB COMMENT 'Join table, maintain association of Product to Application.';

DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER `trg_pac_bins` BEFORE INSERT ON `ac_product_app_context` FOR EACH ROW
BEGIN
	SET NEW.update_ts = NOW();
END;;
CREATE DEFINER = CURRENT_USER TRIGGER `trg_pac_bupd` BEFORE UPDATE ON `ac_product_app_context` FOR EACH ROW
BEGIN
	SET NEW.update_ts = NOW();
END;;
DELIMITER ;

DESCRIBE ac_product_app_context;
SHOW CREATE TABLE ac_product_app_context\G;
SHOW INDEXES IN ac_product_app_context;
SELECT * FROM information_schema.triggers WHERE trigger_name IN ('trg_pac_bins', 'trg_pac_bupd');


SELECT NOW();


DESCRIBE ac_customer_context;
SHOW CREATE TABLE ac_customer_context\G;
SHOW INDEXES IN ac_customer_context;

ALTER TABLE ac_customer_context
ADD	product_id		INT		NULL		COMMENT 'Foreign Key to ac_product table.'	AFTER app_id,
ADD	default_ind		CHAR(1)		NULL		COMMENT 'Y/N flag that indicates the customer context is used as a default profile for a product application.'	AFTER customer_id,
ADD	CONSTRAINT fk3_p_cc FOREIGN KEY if3_cc (product_id) REFERENCES ac_product(product_id),
COMMENT 'Join table, maintain association of Customer to Application.';

DESCRIBE ac_customer_context;
SHOW CREATE TABLE ac_customer_context\G;
SHOW INDEXES IN ac_customer_context;


SHOW TABLES;

SELECT NOW();
