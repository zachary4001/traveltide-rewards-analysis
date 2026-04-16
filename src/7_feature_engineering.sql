/* =========================================================================
    user_features: one row per user, aggregated from cohort_analytics
    'cohort_analytics' = (session-level source table)
    Dimensions: Website Usage, Spending/Discounts, Travel Patterns, User Profile
    version 7
========================================================================== */

-- 1. create table defining ALL cancelled trips
DROP TABLE IF EXISTS tt_project.cancelled_trips;

CREATE TABLE tt_project.cancelled_trips AS
    SELECT trip_id
    FROM tt_project.sessions
    WHERE trip_id IS NOT NULL
    GROUP BY trip_id
    HAVING COUNT(trip_id)>1
;

-- create new field in large cohort table to tag cancelled trips
ALTER TABLE tt_project.cohort_analytics 
ADD COLUMN trip_cancelled boolean;
-- populate all rows with trip_id as cancelled or not
UPDATE tt_project.cohort_analytics ca
SET trip_cancelled = TRUE
WHERE ca.trip_id IN (
    SELECT trip_id 
    FROM tt_project.cancelled_trips
);
UPDATE tt_project.cohort_analytics ca
SET trip_cancelled = FALSE
WHERE trip_id IS NOT NULL
AND trip_cancelled IS NULL
;
-- Verify
SELECT 
    trip_cancelled,
    session_type,
    COUNT(*)                        AS session_count,
    COUNT(DISTINCT trip_id)         AS unique_trips
FROM tt_project.cohort_analytics
GROUP BY trip_cancelled, session_type
ORDER BY trip_cancelled, session_type;

-- 2. Session level aggregations
DROP TABLE IF EXISTS tt_project.session_agg;

CREATE TABLE tt_project.session_agg AS
-- create session level aggregation

    SELECT user_id,

        -- WEBSITE USAGE
        COUNT(session_id)                                              AS total_sessions,
        COUNT(DISTINCT trip_id)                                        AS total_bookings,
        COUNT(DISTINCT trip_id)::float
            / NULLIF(COUNT(session_id), 0)                             AS booking_conversion_rate,
        AVG(CASE WHEN session_duration_sec < 7200
            AND session_type != 'cancel'
            THEN session_duration_sec ELSE NULL END)                   AS avg_session_duration_sec,
        SUM(page_clicks)::float
            / NULLIF(COUNT(session_id), 0)                             AS avg_clicks_per_session,
        AVG(page_clicks::float
            / NULLIF(session_duration_sec, 0))                         AS clicks_per_second,

        -- LOYALTY METRICS
        COUNT(DISTINCT CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE THEN trip_id END)                    AS sess_total_trips,
        COUNT(CASE WHEN session_type = 'booking' 
            THEN 1 END)                                                 AS total_booking_sessions,
        COUNT(CASE WHEN session_type = 'browse' 
            THEN 1 END)                                                 AS total_browse_sessions,

        -- SPENDING - ATTEMPTED
        SUM(CASE WHEN session_type = 'booking'
        THEN flight_gross_amt END)                                      AS attempted_flight_gross,
        SUM(CASE WHEN session_type = 'booking'
        THEN hotel_gross_amt END)                                       AS attempted_hotel_gross,
        SUM(CASE WHEN session_type = 'booking'
        THEN grand_total_gross END)                                     AS attempted_total_gross,
        SUM(CASE WHEN session_type = 'booking'
        THEN flight_net_amt END)                                        AS attempted_flight_net,
        SUM(CASE WHEN session_type = 'booking'
        THEN hotel_net_amt END)                                         AS attempted_hotel_net,
        SUM(CASE WHEN session_type = 'booking'
        THEN grand_total_net END)                                       AS attempted_total_net,
        
        -- SPENDING - COMPLETED
        SUM(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE THEN flight_gross_amt END)           AS completed_flight_gross,
        SUM(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE THEN hotel_gross_amt END)            AS completed_hotel_gross,
        SUM(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE THEN grand_total_gross END)          AS completed_total_gross,
        SUM(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE THEN flight_net_amt END)             AS completed_flight_net,
        SUM(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE THEN hotel_net_amt END)              AS completed_hotel_net,
        SUM(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE THEN grand_total_net END)            AS completed_total_net,

        -- AVERAGES - COMPLETED TRIPS ONLY
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN flight_gross_per_seat END)                                 AS avg_fare_per_seat,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN hotel_gross_per_roomnight END)                             AS avg_hotel_per_room,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN hotel_gross_amt END)                                       AS avg_hotel_total_per_stay,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN flight_net_amt / NULLIF(seats, 0) END)                     AS net_avg_fare_per_seat,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN hotel_net_amt / NULLIF(calc_nights, 0)
            / NULLIF(rooms, 0) END)                                     AS net_avg_hotel_per_room,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN hotel_net_amt END)                                         AS net_avg_hotel_total_per_stay,

        -- DISCOUNT BEHAVIOR (booking sessions only)
        AVG(CASE WHEN session_type = 'booking'
        THEN flight_discount_amt END)                                   AS avg_flight_discount_amt,
        AVG(CASE WHEN session_type = 'booking'
        THEN hotel_discount_amt END)                                    AS avg_hotel_discount_amt,
        SUM(CASE WHEN session_type = 'booking'
        AND flight_discount = TRUE AND hotel_discount = TRUE
        THEN 1 ELSE 0 END)::float
        / NULLIF(COUNT(DISTINCT CASE WHEN session_type = 'booking'
        THEN trip_id END), 0)                                           AS discount_dependency,

        -- TRAVEL PATTERNS - COMPLETED TRIPS ONLY
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN checked_bags END)                                          AS avg_checked_bags,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN seats END)                                                 AS avg_seats,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN booking_lead_time_days END)                                AS avg_lead_time_days,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN calc_nights END)                                           AS avg_trip_nights,
        AVG(CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN return_flight_booked::int END)                             AS return_flight_rate,
        COUNT(DISTINCT CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN destination END)                                           AS destination_variety,
        COUNT(DISTINCT CASE WHEN session_type = 'booking'
        AND trip_cancelled = FALSE
        THEN trip_airline END)                                          AS airline_variety,

        -- DISTANCE - ATTEMPTED (all booking sessions incl. cancelled)
        SUM(CASE WHEN session_type = 'booking'
            AND flight_distance_km IS NOT NULL
            THEN flight_distance_km END)                                AS attempted_total_flight_distance_km,
        AVG(CASE WHEN session_type = 'booking'
            AND flight_distance_km IS NOT NULL
            THEN flight_distance_km END)                                AS attempted_avg_flight_distance_km,
        MAX(CASE WHEN session_type = 'booking'
            AND flight_distance_km IS NOT NULL
            THEN flight_distance_km END)                                AS attempted_max_flight_distance_km,
        COUNT(CASE WHEN passport_required = TRUE THEN 1 END)            AS attempted_intl_flights,
        COUNT(CASE WHEN passport_required = FALSE THEN 1 END)           AS attempted_domestic_flights


    FROM tt_project.cohort_analytics
    WHERE session_type IN ('browse', 'booking')  -- excluding cancellation sessions
        GROUP BY user_id
;
CREATE INDEX idx_session_agg_user_id 
    ON tt_project.session_agg(user_id);
-- 2. User Profile - cohort limited
DROP TABLE IF EXISTS tt_project.user_profile;

CREATE TABLE tt_project.user_profile AS
-- create user profile static fields (one row per user)

    SELECT DISTINCT ON (user_id)
        user_id,
        sign_up_date,
        birthdate,
        gender,
        married,
        has_children,
        home_country,
        home_city,
        home_airport,
        MIN(DATE(session_start)) OVER (PARTITION BY user_id)                AS first_session_date,
        MAX(DATE(session_start)) OVER (PARTITION BY user_id)                AS last_session_date
    FROM tt_project.cohort_analytics
    ORDER BY user_id, session_start
;
CREATE INDEX idx_user_profile_user_id 
    ON tt_project.user_profile(user_id);

-- 3. Trip metrics - User level aggregation 
DROP TABLE IF EXISTS tt_project.trip_agg;
--- CREATE 2 trip agg tables - 1 for completed trips, 1 for cancelled
CREATE TABLE tt_project.trip_agg AS

-- create trip-level counts (all intermediate values preserved)
With trip_counts AS (
    SELECT
        user_id,
    COUNT(DISTINCT trip_id)                                             AS count_total_trips,
    COUNT(DISTINCT CASE WHEN booking_type = 'both'
        THEN trip_id END)                                               AS count_package_trips,
    COUNT(DISTINCT CASE WHEN booking_type = 'flight'
        THEN trip_id END)                                               AS count_flight_only_trips,
    COUNT(DISTINCT CASE WHEN booking_type = 'hotel'
        THEN trip_id END)                                               AS count_hotel_only_trips,
        COUNT(DISTINCT CASE WHEN flight_gross_amt IS NOT NULL 
        THEN trip_id END)                                               AS total_flight_trips,
        COUNT(DISTINCT CASE WHEN hotel_gross_amt IS NOT NULL 
            THEN trip_id END)                                           AS total_hotel_trips,
        COUNT(DISTINCT CASE WHEN flight_discount = TRUE 
            AND flight_gross_amt IS NOT NULL 
            THEN trip_id END)                                           AS discounted_flight_trips,
        COUNT(DISTINCT CASE WHEN hotel_discount = TRUE 
            AND hotel_gross_amt IS NOT NULL 
            THEN trip_id END)                                           AS discounted_hotel_trips,
        COUNT(DISTINCT CASE WHEN flight_discount = TRUE 
            AND hotel_discount = TRUE 
            THEN trip_id END)                                           AS both_discounted_trips,
        SUM(flight_gross_amt)                                           AS total_flight_gross,
        SUM(flight_net_amt)                                             AS total_flight_net,
        SUM(flight_discount_amt)                                        AS total_flight_disc,
        SUM(hotel_gross_amt)                                            AS total_hotel_gross,
        SUM(hotel_net_amt)                                              AS total_hotel_net,
        SUM(hotel_discount_amt)                                         AS total_hotel_disc,
        SUM(grand_total_gross)                                          AS total_gross_spend,
        SUM(grand_total_net)                                            AS total_net_spend,
        SUM(flight_discount_amt + 
            COALESCE(hotel_discount_amt,0))                             AS total_discounts_usd,
        SUM(flight_distance_km)                                         AS total_distance_km,
        MAX(CASE WHEN flight_distance_km IS NOT NULL
            THEN flight_distance_km END)                                AS max_flight_distance_km,
        COUNT(CASE WHEN passport_required = TRUE THEN 1 END)            AS total_intl_flights,
        COUNT(CASE WHEN passport_required = FALSE THEN 1 END)           AS total_domestic_flights

    FROM tt_project.cohort_analytics
    WHERE session_type = 'booking'
    AND trip_cancelled = FALSE   --- only completed trips
    GROUP BY user_id
)

-- leverage trip_counts to create calculated rates 

    SELECT
        user_id,
        count_total_trips,
        count_package_trips,
        count_flight_only_trips,
        count_hotel_only_trips,
        total_flight_trips,
        total_hotel_trips,
        discounted_flight_trips,
        discounted_hotel_trips,
        both_discounted_trips,
        total_flight_gross,
        total_flight_net,
        total_flight_disc,
        total_hotel_gross,
        total_hotel_net,
        total_hotel_disc,
        total_gross_spend,
        total_net_spend,
        total_discounts_usd,
        total_distance_km,
        max_flight_distance_km,
        total_intl_flights,
        total_domestic_flights,
        -- Calculated rates
        discounted_flight_trips::float / 
            NULLIF(total_flight_trips, 0)      AS flight_discount_rate,
        discounted_hotel_trips::float / 
            NULLIF(total_hotel_trips, 0)       AS hotel_discount_rate,
        both_discounted_trips::float / 
            NULLIF(count_total_trips, 0)       AS both_discount_rate,
        total_flight_disc / 
            NULLIF(total_flight_gross, 0)      AS avg_flight_discount_pct,
        total_hotel_disc / 
            NULLIF(total_hotel_gross, 0)       AS avg_hotel_discount_pct,
        total_discounts_usd / 
            NULLIF(total_gross_spend, 0)       AS overall_discount_pct,
        total_distance_km /
            NULLIF(total_flight_trips, 0)       AS avg_flight_distance_km,
        total_intl_flights::float / 
            NULLIF(total_flight_trips, 0)       AS pct_intl_flights,
        total_domestic_flights::float / 
            NULLIF(total_flight_trips, 0)       AS pct_domestic_flights

    FROM trip_counts
;
CREATE INDEX idx_trip_agg_user_id 
    ON tt_project.trip_agg(user_id);

DROP TABLE IF EXISTS tt_project.trip_cx_agg;   
CREATE TABLE tt_project.trip_cx_agg AS
---- For cancelled trips ----
-- create trip-level counts (all intermediate values preserved)
With trip_counts AS (
    SELECT
        user_id,
        COUNT(DISTINCT trip_id)                                         AS count_total_trips,
        COUNT(DISTINCT CASE WHEN booking_type = 'both'
        THEN trip_id END)                                               AS count_package_trips,
        COUNT(DISTINCT CASE WHEN booking_type = 'flight'
        THEN trip_id END)                                               AS count_flight_only_trips,
        COUNT(DISTINCT CASE WHEN booking_type = 'hotel'
        THEN trip_id END)                                               AS count_hotel_only_trips,
        COUNT(DISTINCT CASE WHEN flight_gross_amt IS NOT NULL 
        THEN trip_id END)                                               AS total_flight_trips,
        COUNT(DISTINCT CASE WHEN hotel_gross_amt IS NOT NULL 
            THEN trip_id END)                                           AS total_hotel_trips,
        COUNT(DISTINCT CASE WHEN flight_discount = TRUE 
            AND flight_gross_amt IS NOT NULL 
            THEN trip_id END)                                           AS discounted_flight_trips,
        COUNT(DISTINCT CASE WHEN hotel_discount = TRUE 
            AND hotel_gross_amt IS NOT NULL 
            THEN trip_id END)                                           AS discounted_hotel_trips,
        COUNT(DISTINCT CASE WHEN flight_discount = TRUE 
            AND hotel_discount = TRUE 
            THEN trip_id END)                                           AS both_discounted_trips,
        SUM(flight_gross_amt)                                           AS total_flight_gross,
        SUM(flight_net_amt)                                             AS total_flight_net,
        SUM(flight_discount_amt)                                        AS total_flight_disc,
        SUM(hotel_gross_amt)                                            AS total_hotel_gross,
        SUM(hotel_net_amt)                                              AS total_hotel_net,
        SUM(hotel_discount_amt)                                         AS total_hotel_disc,
        SUM(grand_total_gross)                                          AS total_gross_spend,
        SUM(grand_total_net)                                            AS total_net_spend,
        SUM(flight_discount_amt + 
            COALESCE(hotel_discount_amt,0))                             AS total_discounts_usd,
        SUM(flight_distance_km)                                         AS total_distance_km,
        MAX(CASE WHEN flight_distance_km IS NOT NULL
            THEN flight_distance_km END)                                AS max_flight_distance_km,
        COUNT(CASE WHEN passport_required = TRUE THEN 1 END)            AS total_intl_flights,
        COUNT(CASE WHEN passport_required = FALSE THEN 1 END)           AS total_domestic_flights

    FROM tt_project.cohort_analytics
    WHERE session_type = 'booking'
    AND trip_cancelled = TRUE   --- only cancelled trips
    GROUP BY user_id
)

-- leverage trip_counts to create calculated rates 

    SELECT
        user_id,
        count_total_trips,
        count_package_trips,
        count_flight_only_trips,
        count_hotel_only_trips,
        total_flight_trips,
        total_hotel_trips,
        discounted_flight_trips,
        discounted_hotel_trips,
        both_discounted_trips,
        total_flight_gross,
        total_flight_net,
        total_flight_disc,
        total_hotel_gross,
        total_hotel_net,
        total_hotel_disc,
        total_gross_spend,
        total_net_spend,
        total_discounts_usd,
        total_distance_km,
        max_flight_distance_km,
        total_intl_flights,
        total_domestic_flights,
        -- Calculated rates
        discounted_flight_trips::float / 
            NULLIF(total_flight_trips, 0)      AS flight_discount_rate,
        discounted_hotel_trips::float / 
            NULLIF(total_hotel_trips, 0)       AS hotel_discount_rate,
        both_discounted_trips::float / 
            NULLIF(count_total_trips, 0)       AS both_discount_rate,
        total_flight_disc / 
            NULLIF(total_flight_gross, 0)      AS avg_flight_discount_pct,
        total_hotel_disc / 
            NULLIF(total_hotel_gross, 0)       AS avg_hotel_discount_pct,
        total_discounts_usd / 
            NULLIF(total_gross_spend, 0)       AS overall_discount_pct,
        total_distance_km /
            NULLIF(total_flight_trips, 0)       AS avg_flight_distance_km,
        total_intl_flights::float / 
            NULLIF(total_flight_trips, 0)       AS pct_intl_flights,
        total_domestic_flights::float / 
            NULLIF(total_flight_trips, 0)       AS pct_domestic_flights
    FROM trip_counts
;
CREATE INDEX idx_trip_cx_agg_user_id 
    ON tt_project.trip_cx_agg(user_id);


-- 4. Loyalty metrics - User level aggregation 
DROP TABLE IF EXISTS tt_project.user_loyalty;

CREATE TABLE tt_project.user_loyalty AS

-- capture overall user loyalty metrics
WITH loyalty_user AS (
    SELECT
    c.cohort_user_id                                                        AS user_id,
        -- total trips ever taken on platform 
    COUNT(DISTINCT s.trip_id)                                               AS life_total_trips,
        --days since signup using dataset anchor
    (DATE '2024-08-19' - DATE(MIN(u.sign_up_date)))::INT                    AS days_since_signup,
    MIN(DATE(s.session_start))                                              AS first_purchase_date
    FROM tt_project.cohort23 c
    JOIN tt_project.users u ON c.cohort_user_id = u.user_id
    LEFT JOIN tt_project.sessions s ON c.cohort_user_id = s.user_id
        AND s.trip_id IS NOT NULL 
        --AND s.cancellation = 'false'
        AND NOT EXISTS (
            SELECT 1 FROM tt_project.cancelled_trips cx
            WHERE cx.trip_id = s.trip_id
            )
    GROUP BY c.cohort_user_id
), 

-- create loyalty metrics:
loyalty_metrics AS (
    SELECT
        sa.user_id,
        -- trips per year normalized for tenure
        ROUND(sa.sess_total_trips::numeric / 
            NULLIF((up.last_session_date - up.sign_up_date)::numeric 
            / 365.25, 0), 2)                                                AS trips_per_year,
        --avg days between trips
        ROUND((up.last_session_date - up.first_session_date)::numeric / 
            NULLIF(sa.sess_total_trips, 0), 0)                              AS avg_days_between_trips
    FROM tt_project.session_agg sa
    JOIN tt_project.user_profile up ON sa.user_id = up.user_id
),

-- create cancellation related metrics
cancel_metrics AS (
    SELECT
        ca.user_id,
        COUNT(*)                                                            AS total_cancellations,
        AVG(ca.flight_gross_amt)                                            AS avg_cancelled_fare,
        -- cancel session / booking sessions
        COUNT(*)::float/NULLIF(
            (SELECT sa.total_bookings 
            FROM tt_project.session_agg sa
            WHERE ca.user_id = sa.user_id), 0)                              AS cancellation_rate,
        AVG(ca.booking_lead_time_days)                                      AS avg_cancelled_lead_time,
        -- How long were cancelled trips planned to be?
        AVG(ca.nights)                                                      AS avg_cancelled_nights,
        -- Ratio of cancelled spend to attempted spend
        COALESCE(SUM(ca.flight_gross_amt), 0) + 
            COALESCE(SUM(ca.hotel_gross_amt), 0)                            AS cancelled_gross_spend
       FROM tt_project.cohort_analytics ca
    WHERE ca.trip_id IS NOT NULL
    AND ca.session_type = 'booking' AND trip_cancelled = TRUE
    GROUP BY ca.user_id
)

-- Combine Loyalty metrics in table format
SELECT
    c.cohort_user_id                                                    AS user_id,
    lu.life_total_trips,
    lu.days_since_signup,
    lu.first_purchase_date,
    lm.trips_per_year,
    lm.avg_days_between_trips,
    cm.total_cancellations,
    cm.cancellation_rate,
    cm.avg_cancelled_fare,
    cm.avg_cancelled_lead_time,
    cm.avg_cancelled_nights,
    cm.cancelled_gross_spend,
    cm.cancelled_gross_spend / 
        NULLIF(sa.attempted_total_gross, 0)                             AS cancel_spend_ratio
FROM tt_project.cohort23 c
LEFT JOIN loyalty_user lu ON c.cohort_user_id = lu.user_id
LEFT JOIN loyalty_metrics lm ON c.cohort_user_id = lm.user_id
LEFT JOIN cancel_metrics cm ON c.cohort_user_id = cm.user_id    
LEFT JOIN tt_project.session_agg sa ON c.cohort_user_id = sa.user_id    
;
CREATE INDEX idx_user_loyalty_user_id 
    ON tt_project.user_loyalty(user_id);

-- 5. Create combined USER FEATURES table
-- holding User level aggregation of all section tables

DROP TABLE IF EXISTS tt_project.user_features;

CREATE TABLE tt_project.user_features AS
SELECT
    sa.user_id,

    -- WEBSITE USAGE
    sa.total_sessions,
    sa.total_bookings,
    COALESCE(ta.count_package_trips, 0) +
        COALESCE(tcx.count_package_trips, 0)            AS total_package_bookings,
    COALESCE(ta.count_flight_only_trips, 0) +
        COALESCE(tcx.count_flight_only_trips, 0)        AS total_flight_only_bookings,
    COALESCE(ta.count_hotel_only_trips, 0) +
        COALESCE(tcx.count_hotel_only_trips, 0)         AS total_hotel_only_bookings,
    sa.avg_session_duration_sec,
    sa.avg_clicks_per_session,
    sa.clicks_per_second,
    sa.total_booking_sessions,
    sa.total_browse_sessions,
    sa.booking_conversion_rate,

    -- SPENDING GROSS - COMPLETED TRIPS
    sa.avg_fare_per_seat,
    sa.avg_hotel_per_room,
    sa.avg_hotel_total_per_stay,
    sa.completed_flight_gross,
    sa.completed_hotel_gross,
    sa.completed_total_gross,

    -- SPENDING NET - COMPLETED TRIPS
    sa.net_avg_fare_per_seat,
    sa.net_avg_hotel_per_room,
    sa.net_avg_hotel_total_per_stay,
    sa.completed_flight_net,
    sa.completed_hotel_net,
    sa.completed_total_net,

    -- SPENDING - ATTEMPTED (all bookings)
    sa.attempted_flight_gross,
    sa.attempted_hotel_gross,
    sa.attempted_total_gross,
    sa.attempted_flight_net,
    sa.attempted_hotel_net,
    sa.attempted_total_net,

    -- DISCOUNT BEHAVIOR
    ta.flight_discount_rate,
    ta.hotel_discount_rate, 
    ta.both_discount_rate,
    sa.avg_flight_discount_amt,
    sa.avg_hotel_discount_amt,
    sa.discount_dependency,
    ta.total_flight_disc,
    ta.total_hotel_disc,
    ta.total_discounts_usd,
    ta.avg_flight_discount_pct,
    ta.avg_hotel_discount_pct,
    ta.overall_discount_pct,
    ta.total_flight_gross,
    ta.total_hotel_gross,
    ta.total_gross_spend,
    ta.total_net_spend,

    -- CANCELLATION BEHAVIOR
    tcx.count_total_trips                                       AS total_cancellations,
    tcx.count_package_trips                                     AS package_cancellations,
    tcx.count_flight_only_trips                                 AS flight_only_cancellations,
    tcx.count_hotel_only_trips                                  AS hotel_only_cancellations,
    (tcx.count_total_trips::float
        / NULLIF(sa.total_booking_sessions, 0))                 AS total_cancellation_rate,
    (tcx.count_hotel_only_trips::float 
        / NULLIF((ta.count_hotel_only_trips +
        tcx.count_hotel_only_trips), 0))                        AS hotel_only_cxl_rate,
    (tcx.count_flight_only_trips::float 
        / NULLIF((ta.count_flight_only_trips +
        tcx.count_flight_only_trips), 0))                       AS flight_only_cxl_rate,
    (tcx.count_package_trips::float 
        / NULLIF((ta.count_package_trips +
        tcx.count_package_trips), 0))                           AS package_cxl_rate,
    tcx.total_flight_gross                                      AS cxl_flight_gross,
    tcx.total_hotel_gross                                       AS cxl_hotel_gross,
    tcx.total_gross_spend                                       AS cxl_gross_spend,
    ul.cancel_spend_ratio,          --- cancel $ / attempted $
    tcx.flight_discount_rate                                    AS cxl_flight_discount_rate,
    tcx.hotel_discount_rate                                     AS cxl_hotel_discount_rate,
    tcx.both_discount_rate                                      AS cxl_both_discount_rate,
    (tcx.total_flight_net::float
            / NULLIF(tcx.count_total_trips, 0))                 AS avg_net_cancelled_flight,
    (tcx.total_hotel_net::float
            / NULLIF(tcx.count_total_trips, 0))                 AS avg_net_cancelled_hotel,
    ul.avg_cancelled_lead_time,
    ul.avg_cancelled_nights,

    -- TRAVEL PATTERNS
    sa.avg_checked_bags,
    sa.avg_seats,
    sa.avg_lead_time_days,
    sa.avg_trip_nights,
    sa.return_flight_rate,
    sa.destination_variety,
    sa.airline_variety,
    sa.sess_total_trips,
    
    -- DISTANCE BEHAVIOR 
    -- (attempted flights)
    sa.attempted_total_flight_distance_km           AS attempted_total_km,
    sa.attempted_avg_flight_distance_km             AS attempted_avg_km,
    sa.attempted_max_flight_distance_km             AS attempted_max_km,
    sa.attempted_intl_flights,
    sa.attempted_domestic_flights,
    -- (completed flights)
    ta.total_distance_km                            AS completed_total_km,
    ta.avg_flight_distance_km                       AS completed_avg_km,  
    ta.max_flight_distance_km                       AS completed_max_km,
    ta.total_intl_flights                           AS completed_intl_flights,
    ta.total_domestic_flights                       AS completed_domestic_flights,
    ta.pct_intl_flights                             AS pct_complete_flights_intl,
    ta.pct_domestic_flights                         AS pct_complete_flights_domestic,

    -- (cancelled flights)
    tcx.total_distance_km                           AS cxl_total_km,
    tcx.avg_flight_distance_km                      AS cxl_avg_km,
    tcx.max_flight_distance_km                      AS cxl_max_km,
    tcx.total_intl_flights                          AS total_cxl_intl_flights,
    tcx.total_domestic_flights                      AS total_cxl_domestic_flights,
    tcx.pct_intl_flights                            AS pct_cxl_flights_intl,
    tcx.pct_domestic_flights                        AS pct_cxl_flights_domestic,

    -- LOYALTY
    CASE
    WHEN ul.life_total_trips = 0 
        AND COALESCE(tcx.count_total_trips, 0) > 0  THEN 0
    WHEN ul.life_total_trips = 0 THEN 1 ELSE 0 END                          AS is_never_booked,
    CASE
    WHEN ul.life_total_trips = 0 
        AND COALESCE(tcx.count_total_trips, 0) > 0  THEN 'cancelled_all'
    WHEN ul.life_total_trips = 0 THEN 'never_booked' ELSE 'booked' END
                                                                            AS user_booking_status,
    ul.life_total_trips,
    ul.trips_per_year,
    ul.avg_days_between_trips,
    ul.days_since_signup,

    -- USER PROFILE
    up.sign_up_date,
    ROUND(
        (DATE '2024-08-19' - DATE(up.birthdate))::NUMERIC 
        / 365.0, 0)::INT                                                    AS user_age,
    up.gender,
    up.married,
    up.has_children,
    up.home_country,
    up.home_city,
    up.home_airport,
    up.first_session_date,
    up.last_session_date,
    up.last_session_date - up.first_session_date                            AS active_tenure_days,
    ul.first_purchase_date,
    ul.first_purchase_date - up.sign_up_date                                AS signup_to_first_purchase_days,
    sa.avg_seats
        / NULLIF((up.married::int
        + up.has_children::int + 1), 0)                                     AS family_seats_ratio

FROM tt_project.session_agg sa
LEFT JOIN tt_project.user_profile up  ON sa.user_id = up.user_id
LEFT JOIN tt_project.user_loyalty ul  ON sa.user_id = ul.user_id
LEFT JOIN tt_project.trip_agg ta      ON sa.user_id = ta.user_id
LEFT JOIN tt_project.trip_cx_agg tcx  ON sa.user_id = tcx.user_id
ORDER BY sa.user_id;

CREATE INDEX idx_user_features_user_id 
    ON tt_project.user_features(user_id);
/* ------------  END FILE ------------ */ 