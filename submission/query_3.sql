-- incremental query 
INSERT INTO
  mmarquez225.user_devices_cumulated
WITH
  yesterday AS ( -- collect yesterday's data from our target table
    SELECT
      *
    FROM
      mmarquez225.user_devices_cumulated
    WHERE
      DATE = DATE('2022-12-31')
  ),
  today AS ( --collect latest data from our base table 
    SELECT
      user_id,
      browser_type,  --browser_type from which the user logged in
      CAST(date_trunc('day', event_time) AS DATE) AS event_date, --extracting date from event_time column
      COUNT(1)
    FROM
      bootcamp.web_events we 
      left join bootcamp.devices d --left join devices to extract browser type
      on we.device_id = d.device_id
    WHERE
      date_trunc('day', event_time) = DATE('2023-01-01') --today's date
    GROUP BY
      user_id,
      browser_type,
      CAST(date_trunc('day', event_time) AS DATE)
  )
SELECT
  COALESCE(y.user_id, t.user_id) AS user_id,
  COALESCE(y.browser_type, t.browser_type) as browser_type,
  CASE
    WHEN y.dates_active IS NOT NULL THEN ARRAY[t.event_date] || y.dates_active --check if dates_active is not null the concat the new date to the existing list.
    ELSE ARRAY[t.event_date] -- if the dates_active list is null then create the list with new date
  END AS dates_active,
  DATE('2023-01-01') AS DATE
FROM
  yesterday y
  FULL OUTER JOIN today t ----join yesterday's data with today's data on user_id and browser_type
  ON y.user_id = t.user_id  
  and y.browser_type = t.browser_type