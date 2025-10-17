-- Daily Usage and Activity View
CREATE OR REPLACE VIEW `atg_erp.usage_daily` AS
SELECT
  company_id,
  DATE(TIMESTAMP(event_timestamp)) AS event_date,
  COUNTIF(event_type = 'login') AS logins,
  COUNTIF(event_type = 'notification') AS notifications_sent,
  COUNT(*) AS total_events,
  DATE(TIMESTAMP(_ingest_ts)) AS ingest_date
FROM `atg_erp.raw_system_metrics`
GROUP BY company_id, event_date, ingest_date;
