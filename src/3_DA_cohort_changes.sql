/* ----------------------------------------------- 
    -- Update cohort_analytics table with features
    and fields enabling better data understanding
    and verification abilities, using limited data
    set size. 
    -- version 3
------------------------------------------------- */

-- Insert 7 orphaned booking sessions from source tables
-- whose paired cancellation sessions exist within cohort 
-- the 2023-01-04 cohort cutoff, BUT
-- the original booking session predate the cutoff date. 
-- Included to maintain behavioral integrity of cancellation pairs.
-- Documented exception to cohort date filter.

INSERT INTO tt_project.cohort_analytics
SELECT 
    s.*,
    u.birthdate, u.gender, u.married, u.has_children,
    u.home_country, u.home_city, u.home_airport, 
    u.sign_up_date, u.home_airport_lat, u.home_airport_lon,
    f.origin_airport, f.destination, f.destination_airport, 
    f.seats, f.return_flight_booked,
    f.departure_time, f.return_time, f.checked_bags, 
    f.trip_airline, f.base_fare_usd, 
    f.destination_airport_lat, f.destination_airport_lon,
    h.hotel_name, h.nights, h.rooms, 
    h.check_in_time, h.check_out_time, h.hotel_per_room_usd
FROM tt_project.sessions s
JOIN tt_project.users u ON s.user_id = u.user_id
LEFT JOIN tt_project.flights f ON s.trip_id = f.trip_id
LEFT JOIN tt_project.hotels h ON s.trip_id = h.trip_id
WHERE s.session_id IN (
    '171470-ed6f11f424304b4d930b6c1f03813e82',
    '174997-8a2be403095348558385433f288d6440',
    '182191-18726bd41d9a4503aca1d936b4d79ee2',
    '204997-44a36a4443394a928199c68204e3a2c1',
    '468409-41f1f7e7613346c7aac2a8b8d212b42d',
    '498500-6d91f4dfdad44070b9ad63559317ce82',
    '508111-d649cabebb5a47fb9192d721ef1394eb'
);

-- Verify insertion
SELECT COUNT(*) AS total_rows
FROM tt_project.cohort_analytics;
-- Expected: 49211 + 7 = 49218

--- 1. Create Session type column 
ALTER TABLE tt_project.cohort_analytics 
ADD COLUMN session_type VARCHAR(25);

UPDATE tt_project.cohort_analytics
SET session_type = 'browse'
WHERE trip_id IS NULL;

UPDATE tt_project.cohort_analytics
SET session_type = 'cancel'
WHERE cancellation = 'true' AND trip_id IS NOT NULL;

UPDATE tt_project.cohort_analytics
SET session_type = 'booking'
WHERE cancellation = 'false' AND trip_id IS NOT NULL;

--- Verify field data 
SELECT COUNT(*) as null_count
FROM tt_project.cohort_analytics
WHERE session_type IS NULL;

SELECT 
COUNT(CASE WHEN session_type = 'browse' THEN 1 END) AS "browse_session_count",
COUNT(CASE WHEN session_type = 'booking' THEN 1 END) AS "booking_session_count",
COUNT(CASE WHEN session_type = 'cancel' THEN 1 END) AS "cancel_session_count"
FROM tt_project.cohort_analytics

--- 2. Create 3 fields from date/time stampe

ALTER TABLE tt_project.cohort_analytics 
ADD COLUMN session_duration_sec INT,
ADD COLUMN booking_lead_time_days INT,
ADD COLUMN trip_duration_days FLOAT;

--- populate session_duration_sec = time spent in session
UPDATE tt_project.cohort_analytics
SET 
    session_duration_sec = EXTRACT(EPOCH FROM (session_end - session_start));

--- populate booking_lead_time_days = # days trip booked in advance
UPDATE tt_project.cohort_analytics
SET 
    booking_lead_time_days = DATE_PART('day', 
    LEAST(departure_time, check_in_time) - session_start); 
-- using either flight departure or hotel checkin as 'trip start'
-- to avoid conflicts or nulls currupting values
    
--- populate trip_duration_days = # days from start to end of trip
UPDATE tt_project.cohort_analytics
SET 
    trip_duration_days = DATE_PART('day',(GREATEST(return_time, check_out_time)) - ((LEAST(departure_time, check_in_time))))
WHERE session_type = 'booking';
-- using earliest start and latest end times
-- convert to days - also helps to avoid conflicts with same day travel and hotel check-out time problems
-- 24 rows know to be one-way flights without hotel booked will be NULL

--- Verify field data
SELECT 
COUNT(CASE WHEN session_duration_sec IS NULL THEN 1 END) AS "null_sessionduration"
, COUNT(CASE WHEN booking_lead_time_days IS NULL THEN 1 END) AS "null_leadtimedays"
, COUNT(CASE WHEN trip_duration_days IS NULL THEN 1 END) AS "null_flighttripdays"
FROM tt_project.cohort_analytics
WHERE session_type = 'booking';

SELECT AVG(session_duration_sec) as "avg_session_duration_sec"
, MAX(session_duration_sec) as "max_session_duration_sec"
, MIN(session_duration_sec) as "min_session_duration_sec"
FROM tt_project.cohort_analytics
WHERE session_type IN ('browse', 'booking') ; 

SELECT AVG(booking_lead_time_days) as "avg_booking_lead_time_days"
, MAX(booking_lead_time_days) as "max_booking_lead_time_days"
, MIN(booking_lead_time_days) as "min_booking_lead_time_days"
FROM tt_project.cohort_analytics
WHERE session_type IN ('browse', 'booking') ; 

SELECT AVG(trip_duration_days) as "avg_trip_duration_days"
, MAX(trip_duration_days) as "max_trip_duration_days"
, MIN(trip_duration_days) as "min_trip_duration_days"
FROM tt_project.cohort_analytics
WHERE session_type IN ('browse', 'booking') ; 

--- 3. Create flight type column - one-way, round trip, none
ALTER TABLE tt_project.cohort_analytics 
ADD COLUMN flight_type VARCHAR(25);

UPDATE tt_project.cohort_analytics
SET flight_type = 
(CASE WHEN flight_booked = 'false' THEN 'none'
WHEN return_time IS NULL THEN 'one-way'
ELSE 'round-trip'
END)
WHERE session_type = 'booking';

--- Verify field data
SELECT COUNT(*)
FROM tt_project.cohort_analytics
WHERE session_type = 'booking' AND flight_type IS NULL;

SELECT 
COUNT(CASE WHEN flight_type = 'none' THEN 1 END) AS "no_flights"
, COUNT(CASE WHEN flight_type = 'one-way' THEN 1 END) AS "oneway_flights"
, COUNT(CASE WHEN flight_type = 'round-trip'  THEN 1 END) AS "roundtrip_flights"
FROM tt_project.cohort_analytics
WHERE session_type = 'booking';


--- 4. Correct NULL return_flight_booked for cleaner processing

UPDATE tt_project.cohort_analytics
SET return_flight_booked = False
WHERE return_flight_booked IS NULL;

--- Verify field data

SELECT count(*) 
FROM tt_project.cohort_analytics 
WHERE session_type = 'booking' 
AND return_flight_booked IS NULL;

--- 5. Add 'age' using DOB against the last known travel date

ALTER TABLE tt_project.cohort_analytics
ADD COLUMN user_age INT;

UPDATE tt_project.cohort_analytics
SET user_age = ROUND((EXTRACT(EPOCH FROM(AGE(
    DATE '2024-08-19', 
    DATE(birthdate))))/86400)/365)
;

--- Verify field data
SELECT COUNT(*)
FROM tt_project.cohort_analytics
WHERE user_age IS NULL; 

SELECT AVG(user_age) as "avg_age"
, MAX(user_age) as "max_age"
, MIN(user_age) as "min_age"
FROM tt_project.cohort_analytics; 


--- 6. Add reliable 'nights' column

--- Add the new column
ALTER TABLE tt_project.cohort_analytics 
ADD COLUMN calc_nights INT;

--- Populate with CEIL calculation for valid date ranges
UPDATE tt_project.cohort_analytics
SET calc_nights = CEIL(EXTRACT(EPOCH FROM (check_out_time - check_in_time)) / 86400)
WHERE session_type = 'booking' 
AND check_out_time > check_in_time;

--- check remaining nulls
SELECT COUNT(*)
FROM tt_project.cohort_analytics
WHERE calc_nights IS NULL
AND session_type = 'booking'
AND check_in_time > check_out_time ; 

--- Populate calc_nights value where check out < check-in time
-- using return flight as a proxy. */

UPDATE tt_project.cohort_analytics
SET calc_nights = CASE 
    WHEN CEIL(EXTRACT(EPOCH FROM (return_time - check_in_time)) / 86400) >= 3 THEN 3
    WHEN CEIL(EXTRACT(EPOCH FROM (return_time - check_in_time)) / 86400) >= 2 THEN 2
    ELSE 1 
END
WHERE session_type = 'booking' 
AND hotel_booked = 'true'
AND return_flight_booked = 'true'
AND check_in_time > check_out_time
;

--- check remaining nulls
SELECT COUNT(*)
FROM tt_project.cohort_analytics
WHERE calc_nights IS NULL
AND session_type = 'booking'
AND hotel_booked = 'true';
--- count = 8 ---

--- Populate remaining calc_nights where check out < check-in time
--- as if same day or next day check out and equal to 1 

UPDATE tt_project.cohort_analytics
SET calc_nights = 1, trip_duration_days = 1
WHERE session_type = 'booking' 
AND hotel_booked = 'true'
AND flight_booked = 'true'
AND calc_nights IS NULL;

--- Verify field data ---
SELECT COUNT(*)
FROM tt_project.cohort_analytics
WHERE session_type = 'booking' 
AND hotel_booked = 'true'
AND calc_nights IS NULL;

SELECT AVG(calc_nights) as "avg_calc_nights"
, MAX(calc_nights) as "max_calc_nights"
, MIN(calc_nights) as "min_calc_nights"
FROM tt_project.cohort_analytics
WHERE session_type = 'booking'
AND hotel_booked = 'True';


--- 7. Add pre-calculated financial fields to enable better
--- transaction level understanding and comparison AND
--- better enables EDA and user-level aggregation

--- Rename flight discount to pct
ALTER TABLE tt_project.cohort_analytics 
RENAME COLUMN flight_discount_amount TO flight_discount_pct;
--- Rename flight base fare usd to net amt
ALTER TABLE tt_project.cohort_analytics 
RENAME COLUMN base_fare_usd TO flight_gross_amt;
--- Rename hotel discount to pct
ALTER TABLE tt_project.cohort_analytics 
RENAME COLUMN hotel_discount_amount TO hotel_discount_pct;
--- Rename hotel per room usd to hotel net and room-night
ALTER TABLE tt_project.cohort_analytics 
RENAME COLUMN hotel_per_room_usd TO hotel_gross_per_roomnight;


ALTER TABLE tt_project.cohort_analytics
ADD COLUMN flight_discount_amt  FLOAT, --
ADD COLUMN flight_gross_per_seat FLOAT, --
ADD COLUMN flight_net_amt       FLOAT, --
ADD COLUMN hotel_discount_amt   FLOAT, --
ADD COLUMN hotel_net_amt        FLOAT, --
ADD COLUMN hotel_gross_amt        FLOAT, --
ADD COLUMN grand_total_gross    FLOAT,
ADD COLUMN grand_total_net      FLOAT;

--- Flight amounts (booking sessions with flights only)
UPDATE tt_project.cohort_analytics
SET
    flight_gross_per_seat = flight_gross_amt / seats,
    flight_discount_amt = flight_gross_amt * 
                          COALESCE(flight_discount_pct, 0),
    flight_net_amt      = flight_gross_amt * 
                          (1 - COALESCE(flight_discount_pct, 0))
WHERE session_type = 'booking'
AND flight_gross_amt IS NOT NULL;

--- Hotel amounts (booking sessions with hotels only)
UPDATE tt_project.cohort_analytics
SET
    hotel_gross_amt     = hotel_gross_per_roomnight * rooms * calc_nights,
    hotel_discount_amt  = hotel_gross_per_roomnight * rooms * calc_nights *
                          COALESCE(hotel_discount_pct, 0),
    hotel_net_amt       = hotel_gross_per_roomnight * rooms * calc_nights *
                          (1 - COALESCE(hotel_discount_pct, 0))
WHERE session_type = 'booking'
AND hotel_gross_per_roomnight IS NOT NULL
AND calc_nights IS NOT NULL;

--- Grand totals (booking sessions only)
UPDATE tt_project.cohort_analytics
SET
    grand_total_gross   = COALESCE(flight_gross_amt, 0) + 
                          COALESCE(hotel_gross_amt, 0),
    grand_total_net     = COALESCE(flight_net_amt, 0) + 
                          COALESCE(hotel_net_amt, 0)
WHERE session_type = 'booking';

--- Verify
SELECT
    COUNT(flight_gross_amt)                         AS flight_amt_count,
    ROUND(AVG(flight_gross_amt)::numeric, 2)        AS avg_flight_gross,
    ROUND(AVG(flight_net_amt)::numeric, 2)          AS avg_flight_net,
    COUNT(hotel_gross_amt)                          AS hotel_amt_count,
    ROUND(AVG(hotel_gross_amt)::numeric, 2)         AS avg_hotel_gross,
    ROUND(AVG(hotel_net_amt)::numeric, 2)           AS avg_hotel_net,
    ROUND(AVG(grand_total_gross)::numeric, 2)       AS avg_grand_gross,
    ROUND(AVG(grand_total_net)::numeric, 2)         AS avg_grand_net
FROM tt_project.cohort_analytics
WHERE session_type = 'booking';

/* --------- END FILE -------------- */