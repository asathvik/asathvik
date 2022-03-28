-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for VersionOne backlog B-66024.
--	Make a copy of orders table in test environment, so that testing could be repeated.
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

CREATE TABLE "b66024_orders_tmp" (
  "SUBMISSION_KEY" char(22) NOT NULL default '',
  "ORDER_DATE" date default NULL,
  "search_date" date default NULL,
  "LOGON" char(32) NOT NULL default '',
  "BSC_CUSTNO" char(10) default NULL,
  "LOAN_NUMBER" char(20) default NULL,
  "PROP_ADDRESS" char(60) default NULL,
  "PROP_UNIT" char(10) default NULL,
  "PROP_CITY" char(30) default NULL,
  "PROP_STATE" char(2) default NULL,
  "PROP_ZIP5" int(11) default NULL,
  "PROP_ZIP4" int(11) default NULL,
  "cs_list_price" int(11) default NULL,
  "fips_code" char(5) default NULL,
  "CUST_ESTIMATE" int(11) default NULL,
  "BROKER_CODE" char(15) default NULL,
  "APPRAISER_CODE" char(15) default NULL,
  "CHANNEL_CODE" char(10) default NULL,
  "BRANCH_CODE" char(10) default NULL,
  "LOAN_OFFICER_CODE" char(15) default NULL,
  "UNDERWRITER_CODE" char(10) default NULL,
  "CORRESPONDENT_CODE" char(10) default NULL,
  "ORIGINATOR_CODE" char(10) default NULL,
  "LONGITUDE" bigint(20) default NULL,
  "LATITUDE" bigint(20) default NULL,
  "standardized_ind" char(1) default NULL,
  "DISABLE_FLAG" char(1) NOT NULL default '',
  "REFERENCE_NUM" char(20) default NULL,
  "BSC_RUN_TYPE" char(1) default NULL,
  "BSC_LOAN_STATUS" char(2) default NULL,
  "property_key" int(11) default NULL,
  "broker_nmls_id" int(11) default NULL COMMENT 'This is the result that we get from the Nationwide Mortgage Licensing System database search using the broker input provided.',
  "user1" varchar(100) default NULL,
  "user2" varchar(100) default NULL,
  "user3" varchar(100) default NULL,
  "user4" varchar(100) default NULL,
  "userdef1" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef2" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef3" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef4" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef5" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef6" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef7" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef8" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef9" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "userdef10" varchar(250) default NULL COMMENT 'This is a user defined field that can be used by the customers.',
  "mcap_user1" varchar(50) default NULL COMMENT 'This is for mapping the tags specific to MCAP rules.',
  "mcap_user2" varchar(50) default NULL COMMENT 'This is for mapping the tags specific to MCAP rules.',
  "mcap_user3" varchar(50) default NULL COMMENT 'This is for mapping the tags specific to MCAP rules.',
  "mcap_user4" varchar(255) default NULL COMMENT 'This is for mapping the tags specific to MCAP rules.',
  "STARTED" timestamp NULL default '0000-00-00 00:00:00',
  "SOURCE_RUN_TYPE" char(10) default NULL,
  "SOURCE_RUN_DATE" timestamp NOT NULL default '0000-00-00 00:00:00',
  "ript_id" varchar(50) default NULL,
  "realcore_property_id" bigint(20) default NULL,
  "run_tm_ms" int(11) default NULL,
  "insert_date" timestamp NOT NULL default CURRENT_TIMESTAMP,
  "last_update" timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  ("SUBMISSION_KEY"),
  KEY "ix1_orders" ("BSC_CUSTNO","LOAN_NUMBER"),
  KEY "ix2_orders" ("BSC_CUSTNO","BROKER_CODE"),
  KEY "ix3_orders" ("LOGON"),
  KEY "ix4_orders" ("ORDER_DATE")
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=1000000000 AVG_ROW_LENGTH=200 PACK_KEYS=1 CHECKSUM=1 ROW_FORMAT=DYNAMIC;

DESCRIBE b66024_orders_tmp;
SHOW CREATE TABLE b66024_orders_tmp\G;

SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM b66024_orders_tmp;

SELECT NOW();

INSERT INTO b66024_orders_tmp
SELECT *
FROM orders;

SHOW COUNT(*) ERRORS;
SHOW ERRORS;
SHOW COUNT(*) WARNINGS;
SHOW WARNINGS;

SELECT COUNT(*) FROM b66024_orders_tmp;
SELECT * FROM b66024_orders_tmp LIMIT 10;

SELECT NOW();
