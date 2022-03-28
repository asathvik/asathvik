-- -----------------------------------------------------------------------------
-- Author:
--	Dimitriy Alekseyev
--
-- Purpose:
--	Script for VersionOne backlog B-12345.
--	Claimcheck DB schema change - add trigger.
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
DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER trg_svcreq_bdel BEFORE DELETE ON service_requests FOR EACH ROW
BEGIN
    IF(OLD.request_type = 'credcoHTMLPublish' OR OLD.request_type = 'credcoPDFPublish') THEN
        INSERT INTO service_requests_hist (
            request_id,
            request_uuid,
            request_type,
            platform_id,
            correlation_id,
            request_ts,
            request_data,
            request_metadata,
            request_state,
            failure_cnt,
            created_by,
            create_ts,
            updated_by,
            update_ts,
            delete_ts,
            action_type
        )
        VALUES (
            OLD.request_id,
            OLD.request_uuid,
            OLD.request_type,
            OLD.platform_id,
            OLD.correlation_id,
            OLD.request_ts,
            OLD.request_data,
            OLD.request_metadata,
            'success',
            OLD.failure_cnt,
            OLD.created_by,
            OLD.create_ts,
            OLD.updated_by,
            OLD.update_ts,
            NOW(),
            'D'
        );
    ELSE
        INSERT INTO service_requests_hist (
            request_id,
            request_uuid,
            request_type,
            platform_id,
            correlation_id,
            request_ts,
            request_data,
            request_metadata,
            request_state,
            failure_cnt,
            created_by,
            create_ts,
            updated_by,
            update_ts,
            delete_ts,
            action_type
        )
        VALUES (
            OLD.request_id,
            OLD.request_uuid,
            OLD.request_type,
            OLD.platform_id,
            OLD.correlation_id,
            OLD.request_ts,
            OLD.request_data,
            OLD.request_metadata,
            'success',
            OLD.failure_cnt,
            OLD.created_by,
            OLD.create_ts,
            OLD.updated_by,
            OLD.update_ts,
            NOW(),
            'D'
        );
    END IF;
END;;
DELIMITER ;

SELECT * FROM information_schema.triggers WHERE trigger_name = 'trg_svcreq_bdel'\G

SELECT NOW();

-- -----------------------------------------------------------------------------

USE db_tracking;

SELECT NOW();

SELECT * FROM information_schema.triggers WHERE trigger_name LIKE '%host%'\G

DROP TRIGGER IF EXISTS host_ai;
DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER trg_host_ains AFTER INSERT ON host FOR EACH ROW
INSERT INTO host_history
(
	host_id,
	host_name,
	host_data_center,
	host_ip,
	host_active_yn,
	host_os,
	host_os_detail,
	host_ram_total_allocated_mb,
	host_total_cores,
	host_core_type,
	host_core_speed,
	host_32bit_or_64bit_cores,
	host_swap_total_allocated_mb,
	host_disk_total_allocated_mb,
	host_purpose,
	host_nat_ip_in_satc,
	comment,
	network_env,
	network_tier,
	insert_ts,
	update_ts,
	trigger_event,
	update_datetime
)
VALUES
(
	new.host_id,
	new.host_name,
	new.host_data_center,
	new.host_ip,
	new.host_active_yn,
	new.host_os,
	new.host_os_detail,
	new.host_ram_total_allocated_mb,
	new.host_total_cores,
	new.host_core_type,
	new.host_core_speed,
	new.host_32bit_or_64bit_cores,
	new.host_swap_total_allocated_mb,
	new.host_disk_total_allocated_mb,
	new.host_purpose,
	new.host_nat_ip_in_satc,
	new.comment,
	new.network_env,
	new.network_tier,
	new.insert_ts,
	new.update_ts,
	'i',
	NOW()
);;
DELIMITER ;

DROP TRIGGER IF EXISTS host_au;
DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER trg_host_aupd AFTER UPDATE ON host FOR EACH ROW
INSERT INTO host_history
(
	host_id,
	host_name,
	host_data_center,
	host_ip,
	host_active_yn,
	host_os,
	host_os_detail,
	host_ram_total_allocated_mb,
	host_total_cores,
	host_core_type,
	host_core_speed,
	host_32bit_or_64bit_cores,
	host_swap_total_allocated_mb,
	host_disk_total_allocated_mb,
	host_purpose,
	host_nat_ip_in_satc,
	comment,
	network_env,
	network_tier,
	insert_ts,
	update_ts,
	trigger_event,
	update_datetime
)
VALUES
(
	new.host_id,
	new.host_name,
	new.host_data_center,
	new.host_ip,
	new.host_active_yn,
	new.host_os,
	new.host_os_detail,
	new.host_ram_total_allocated_mb,
	new.host_total_cores,
	new.host_core_type,
	new.host_core_speed,
	new.host_32bit_or_64bit_cores,
	new.host_swap_total_allocated_mb,
	new.host_disk_total_allocated_mb,
	new.host_purpose,
	new.host_nat_ip_in_satc,
	new.comment,
	new.network_env,
	new.network_tier,
	new.insert_ts,
	new.update_ts,
	'u',
	NOW()
);;
DELIMITER ;

DROP TRIGGER IF EXISTS host_ad;
DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER trg_host_adel AFTER DELETE ON host FOR EACH ROW
INSERT INTO host_history
(
	host_id,
	host_name,
	host_data_center,
	host_ip,
	host_active_yn,
	host_os,
	host_os_detail,
	host_ram_total_allocated_mb,
	host_total_cores,
	host_core_type,
	host_core_speed,
	host_32bit_or_64bit_cores,
	host_swap_total_allocated_mb,
	host_disk_total_allocated_mb,
	host_purpose,
	host_nat_ip_in_satc,
	comment,
	network_env,
	network_tier,
	insert_ts,
	update_ts,
	delete_ts,
	trigger_event,
	update_datetime
)
VALUES
(
	old.host_id,
	old.host_name,
	old.host_data_center,
	old.host_ip,
	old.host_active_yn,
	old.host_os,
	old.host_os_detail,
	old.host_ram_total_allocated_mb,
	old.host_total_cores,
	old.host_core_type,
	old.host_core_speed,
	old.host_32bit_or_64bit_cores,
	old.host_swap_total_allocated_mb,
	old.host_disk_total_allocated_mb,
	old.host_purpose,
	old.host_nat_ip_in_satc,
	old.comment,
	old.network_env,
	old.network_tier,
	old.insert_ts,
	old.update_ts,
	NOW(),
	'd',
	NOW()
);;
DELIMITER ;

DROP TRIGGER IF EXISTS trg_host_bins;
DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER trg_host_bins BEFORE INSERT ON host FOR EACH ROW
BEGIN
    SET new.update_ts = NOW();
END;;
DELIMITER ;

DROP TRIGGER IF EXISTS trg_host_bupd;
DELIMITER ;;
CREATE DEFINER = CURRENT_USER TRIGGER trg_host_bupd BEFORE UPDATE ON host FOR EACH ROW
BEGIN
    SET new.update_ts = NOW();
END;;
DELIMITER ;

SELECT * FROM information_schema.triggers WHERE trigger_name LIKE '%host%'\G

SELECT NOW();
