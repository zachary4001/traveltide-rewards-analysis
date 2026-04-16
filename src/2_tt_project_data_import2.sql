/*------------------------------------------------
    2nd Step Cohort limited tables 
    --- CREATE 1 combined table --- 
    Data lake combining all columns from 4 source 
    tables: based on 'Cohort' limits specified by
    customer as customers with sessions starting 
    after 2023-01-04 and users with more than 7
    sessions during that same time frame.
    --- CREATE 2 subset tables ---
    limiting USERS 'cohort23' and 
    limiting SESSIONS 'cohort_sessions'
    to only rows matching cohort limitations to
    ensure data integrity and efficient analysis.
    --version 2 
--------------------------------------------------*/

--- 1. Create cohort users table ONLY with user_id 
--- for those meeting the criteria

DROP TABLE IF EXISTS tt_project.cohort23;

CREATE TABLE tt_project.cohort23 AS
WITH sessions_start AS (
    SELECT s.user_id,
    COUNT(DISTINCT(s.session_id)) as Dsession_count
    FROM tt_project.sessions s
    WHERE s.session_start > '2023-01-04'
    GROUP BY 1
)
SELECT s.user_id as cohort_user_id
FROM sessions_start s 
WHERE s.Dsession_count > 7; 

-- Add Primary Key to the cohort users list
ALTER TABLE tt_project.cohort23 ADD PRIMARY KEY (cohort_user_id);

--- Verify table size - last known = 5998
SELECT COUNT(*) FROM tt_project.cohort23;

--- 2. Create cohort sessions table limited to
--- sessions starting after 2023-01-04

DROP TABLE IF EXISTS tt_project.cohort_sessions;

CREATE TABLE tt_project.cohort_sessions AS
SELECT *
FROM tt_project.sessions
WHERE session_start > '2023-01-04';

-- Add Primary Key to the cohort session table
ALTER TABLE tt_project.cohort_sessions ADD PRIMARY KEY (session_id);

--- Verify table size - last known = 3,102,850
SELECT COUNT(*) FROM tt_project.cohort_sessions;

--- 3. Create data lake table with all data from all 
--- source tables that match the cohort users table
--- and related to sessions after 2023-01-04

DROP TABLE IF EXISTS tt_project.cohort_analytics;

CREATE TABLE tt_project.cohort_analytics AS
SELECT 
    s.*,
    u.birthdate, u.gender, u.married, u.has_children, 
    u.home_country, u.home_city, u.home_airport, u.sign_up_date, u.home_airport_lat, u.home_airport_lon,
    f.origin_airport, f.destination, f.destination_airport, f.seats, f.return_flight_booked,
    f.departure_time, f.return_time, f.checked_bags, f.trip_airline, f.base_fare_usd, f.destination_airport_lat, f.destination_airport_lon,
    h.hotel_name, h.nights, h.rooms, h.check_in_time, h.check_out_time, h.hotel_per_room_usd
FROM tt_project.cohort_sessions s
JOIN tt_project.cohort23 c ON s.user_id = c.cohort_user_id
JOIN tt_project.users u ON s.user_id = u.user_id
LEFT JOIN tt_project.flights f ON s.trip_id = f.trip_id
LEFT JOIN tt_project.hotels h ON s.trip_id = h.trip_id;

--- Optimize cohort tables for analysis 
--- Add Index to the analytics table for rapid user-level grouping
CREATE INDEX idx_cohort_analytics_user_id ON tt_project.cohort_analytics(user_id);

--- Verify table size - last known = 49211
SELECT COUNT(*) FROM tt_project.cohort_analytics;

-- Verify table details
SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT user_id)     AS unique_users,
    MIN(sign_up_date)           AS earliest_sign_up,
    MAX(sign_up_date)           AS latest_sign_up,
    MIN(session_start)          AS earliest_session,
    MAX(session_start)          AS latest_session,
    MIN(departure_time)         AS earliest_flight_depart,
    MAX(departure_time)         AS latest_flight_depart,
    MIN(return_time)            AS earliest_flight_return,
    MAX(return_time)            AS latest_flight_return,
    MIN(check_in_time)          AS earliest_hotel_checkin,
    MAX(check_in_time)          AS latest_hotel_checkin,
    MIN(check_out_time)         AS earliest_hotel_checkout,
    MAX(check_out_time)         AS latest_hotel_checkout

FROM tt_project.cohort_analytics;
/* ------------------ END -----------------------------------*/