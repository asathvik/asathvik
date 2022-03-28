-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Validate count of database objects.
--
-- Usage:
--	m1c.sh < script_name.sql > script_name.log
--
-- Revisions:
--	05/17/2012 - Dimitriy Alekseyev
--	Script created.
--	05/18/2012 - Dimitriy Alekseyev
--	Revised by removing some of the output columns, so that there are less 
--	differences between two runs of this script when there were no schema 
--	changes.
--	05/18/2012 - Dimitriy Alekseyev
--	Removed auto_increment, data_length, index_length, and data_free fields 
--	from output and added a where clause to filter out information_schema 
--	for select from information_schema.tables.
--	06/06/2012 - Dimitriy Alekseyev
--	Revised column names in queries. Added filters to remove output about 
--	information_schema itself. Removed create_time column from query on 
--	information_schema.tables.
--	06/14/2012 - Dimitriy Alekseyev
--	Removed update_time column from query on information_schema.tables. 
--	Removed created and last_altered columns from query on 
--	information_schema.routines.
--	06/26/2012 - Dimitriy Alekseyev
--	Revised index count query so that it shows index count and indexed 
--	column count instead of just indexed column count.
--	09/07/2012 - Dimitriy Alekseyev
--	Split the script into two: validate_db_object_counts.sql and 
--	validate_db_object_counts_with_detail.sql. The regular validation of 
--	object counts did not need so much extra information.
-- -----------------------------------------------------------------------------

SELECT NOW();


SELECT 
	table_schema,
	table_type,
	engine,
	COUNT(*) AS 'table_and_view_count'
FROM
	information_schema.tables
WHERE
	table_schema <> 'information_schema'
GROUP BY table_schema, table_type, engine;

SELECT 
	table_schema,
	table_name,
	COUNT(*) AS 'column_count'
FROM
	information_schema.columns
WHERE
	table_schema <> 'information_schema'
GROUP BY table_schema, table_name;

SELECT
	table_schema,
	table_name,
	COUNT(DISTINCT index_name) AS 'index_count',
	COUNT(*) AS 'indexed_column_count'
FROM
	information_schema.statistics
GROUP BY table_schema, table_name;

SELECT 
	constraint_schema,
	table_name,
	COUNT(*) AS 'constraint_count'
FROM
	information_schema.table_constraints
GROUP BY constraint_schema, table_name;

SELECT 
	trigger_schema,
	event_object_schema,
	event_object_table,
	COUNT(*) AS 'trigger_count'
FROM
	information_schema.triggers
GROUP BY trigger_schema, event_object_schema, event_object_table;

SELECT 
	routine_schema,
	routine_type,
	COUNT(*) AS 'stored_procedure_and_function_count'
FROM
	information_schema.routines
GROUP BY routine_schema, routine_type;


SELECT
	table_catalog,
	table_schema,
	table_name,
	table_type,
	engine,
	version,
	row_format,
	max_data_length,
	check_time,
	table_collation,
	checksum,
	create_options,
	table_comment
FROM
	information_schema.tables
WHERE
	table_schema <> 'information_schema'
;

SELECT 
	*
FROM
	information_schema.columns
WHERE
	table_schema <> 'information_schema'
;

SELECT
	table_catalog,
	table_schema,
	table_name,
	non_unique,
	index_schema,
	index_name,
	seq_in_index,
	column_name,
	collation,
	sub_part,
	packed,
	nullable,
	index_type,
	comment
FROM
	information_schema.statistics
;

SELECT 
	*
FROM
	information_schema.table_constraints
;

SELECT 
	trigger_catalog,
	trigger_schema,
	trigger_name,
	event_manipulation,
	event_object_catalog,
	event_object_schema,
	event_object_table,
	action_order,
	action_condition,
	action_orientation,
	action_timing,
	action_reference_old_table,
	action_reference_new_table,
	action_reference_old_row,
	action_reference_new_row,
	created,
	sql_mode,
	definer
FROM
	information_schema.triggers
;

SELECT 
	specific_name,
	routine_catalog,
	routine_schema,
	routine_name,
	routine_type,
	dtd_identifier,
	routine_body,
	external_name,
	external_language,
	parameter_style,
	is_deterministic,
	sql_data_access,
	sql_path,
	security_type,
	sql_mode,
	routine_comment,
	definer
FROM
	information_schema.routines
;


SELECT NOW();
