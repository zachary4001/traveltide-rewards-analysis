/* ================================================================
                    Business insights queries
    consolidated into a single sql file to allow for reproduction
    of insights going forward. This allows for monitoring and 
    comparison of changes in patterns and behaviors.
    version 1
=================================================================*/

-------------------------------------------------------------------
--  Demographic Level Insights
-------------------------------------------------------------------

-- D1 Home country of cohort users
SELECT 
    home_country,
    COUNT(home_country)
FROM tt_project.user_profile
GROUP BY home_country

-- D2 Home Country session actiivty

SELECT 
    home_country,
    COUNT(*) AS users
FROM tt_project.cohort_analytics
WHERE session_type = 'booking'
GROUP BY home_country
ORDER BY users DESC
LIMIT 20;

-- D3: Age Band + Gender + Family Status Summary
WITH demo_age AS (
SELECT
    user_id
    , CASE
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 18 AND 24 THEN '18-24'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 25 AND 34 THEN '25-34'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 35 AND 44 THEN '35-44'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 45 AND 54 THEN '45-54'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 55 AND 64 THEN '55-64'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) >= 65 THEN '65+'
    END AS age_band
)
SELECT
    user_id,
    p.age_band,
    gender,
    married,
    has_children,
    home_country,
    COUNT(*) AS users,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_cohort
FROM tt_project.user_profile
JOIN demo_age p USING(user_id)
GROUP BY p.age_band, gender, married, has_children, home_country
ORDER BY p.age_band, gender;



-- D4: Family Status 
SELECT
    married,
    has_children,
    COUNT(*) AS users
FROM tt_project.user_profile
GROUP BY married, has_children
ORDER BY married, has_children;

-- D5: Age Band Summary with Key Metrics
WITH demo_age AS (
SELECT
    user_id,
    DATE_PART('year', AGE('2024-08-19'::date, birthdate)) AS age,
    married,
    has_children
FROM tt_project.user_profile
)
SELECT
    CASE
        WHEN p.age BETWEEN 18 AND 24 THEN '18-24'
        WHEN p.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN p.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN p.age BETWEEN 45 AND 54 THEN '45-54'
        WHEN p.age BETWEEN 55 AND 64 THEN '55-64'
        WHEN p.age >= 65 THEN '65+'
    END AS age_band,
    COUNT(*) AS users,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_cohort,
    ROUND(AVG(u.completed_total_gross)::numeric, 2) AS avg_gross_spend,
    ROUND(AVG(u.trips_per_year)::numeric, 2) AS avg_trips_per_year,
    ROUND(AVG(u.life_total_trips)::numeric, 2) AS avg_life_trips,
    ROUND(COUNT(*) FILTER (WHERE p.married = true)::numeric
        / COUNT(*)::numeric * 100, 1) AS pct_married,
    ROUND(COUNT(*) FILTER (WHERE p.has_children = true)::numeric
        / COUNT(*)::numeric * 100, 1) AS pct_has_children
FROM demo_age p
JOIN tt_project.user_features u USING (user_id)
GROUP BY age_band
ORDER BY age_band;



-- D6: Session Behavior by Age Band
WITH demo_age AS (
SELECT
    user_id,
    DATE_PART('year', AGE('2024-08-19'::date, birthdate)) AS age
FROM tt_project.user_profile
)
SELECT
    CASE
        WHEN p.age BETWEEN 18 AND 24 THEN '18-24'
        WHEN p.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN p.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN p.age BETWEEN 45 AND 54 THEN '45-54'
        WHEN p.age BETWEEN 55 AND 64 THEN '55-64'
        WHEN p.age >= 65 THEN '65+'
    END AS age_band,
    COUNT(ca.session_id) AS total_sessions,
    COUNT(ca.session_id) FILTER (WHERE ca.session_type = 'booking') AS booking_sessions,
    COUNT(ca.session_id) FILTER (WHERE ca.session_type = 'browse') AS browse_sessions,
    COUNT(ca.session_id) FILTER (WHERE ca.session_type = 'cancel') AS cancel_sessions,
    ROUND(COUNT(ca.session_id) FILTER (WHERE ca.session_type = 'booking')::numeric
        / COUNT(ca.session_id)::numeric * 100, 1) AS booking_conversion_pct,
    ROUND(AVG(ca.session_duration_sec)
        FILTER (WHERE ca.session_type = 'booking')::numeric, 1) AS avg_booking_duration_sec,
    ROUND(AVG(ca.page_clicks)::numeric, 1) AS avg_page_clicks
FROM demo_age p
JOIN tt_project.cohort_analytics ca USING (user_id)
GROUP BY age_band
ORDER BY age_band;


-- D7: Loyalty Metrics by Age Band
WITH demo_age AS (
SELECT
    user_id,
    DATE_PART('year', AGE('2024-08-19'::date, birthdate)) AS age
FROM tt_project.user_profile
)
SELECT
    CASE
        WHEN p.age BETWEEN 18 AND 24 THEN '18-24'
        WHEN p.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN p.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN p.age BETWEEN 45 AND 54 THEN '45-54'
        WHEN p.age BETWEEN 55 AND 64 THEN '55-64'
        WHEN p.age >= 65 THEN '65+'
    END AS age_band,
    COUNT(*) AS users,
    ROUND(AVG(u.life_total_trips)::numeric, 2) AS avg_life_trips,
    ROUND(AVG(u.trips_per_year)::numeric, 2) AS avg_trips_per_year,
    ROUND(AVG(u.total_cancellation_rate)::numeric, 3) AS avg_cancel_rate,
    ROUND(AVG(COALESCE(u.cancel_spend_ratio, 0))::numeric, 3) AS avg_cancel_spend_ratio,
    ROUND(AVG(u.flight_discount_rate)::numeric, 3) AS avg_flight_disc_rate,
    ROUND(AVG(u.hotel_discount_rate)::numeric, 3) AS avg_hotel_disc_rate,
    ROUND(AVG(u.avg_trip_nights)::numeric, 2) AS avg_trip_nights,
    ROUND(AVG(u.avg_checked_bags)::numeric, 3) AS avg_checked_bags,
    ROUND(AVG(u.pct_complete_flights_intl)::numeric, 3) AS avg_intl_rate,
    ROUND(AVG(u.completed_total_gross)::numeric, 2) AS avg_gross_spend,
    ROUND(AVG(u.avg_fare_per_seat)::numeric, 2) AS avg_fare_per_seat
FROM demo_age p
JOIN tt_project.user_features u USING (user_id)
GROUP BY age_band
ORDER BY age_band;

-- D8: Perk Assignment by Age Band
WITH demo_age AS (
SELECT
    user_id
    , DATE_PART('year', AGE('2024-08-19'::date, birthdate)) AS age
    , CASE
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 18 AND 24 THEN '18-24'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 25 AND 34 THEN '25-34'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 35 AND 44 THEN '35-44'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 45 AND 54 THEN '45-54'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) BETWEEN 55 AND 64 THEN '55-64'
        WHEN DATE_PART('year', AGE('2024-08-19'::date, birthdate)) >= 65 THEN '65+'
    END AS age_band
FROM tt_project.user_profile
)

SELECT
    p.age_band
    , pa.assigned_perk
    , COUNT(*) AS users
    , ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER
        (PARTITION BY p.age_band) * 100, 1) AS pct_within_age_band
    , ROUND(AVG(u.completed_total_gross)::numeric, 2) AS avg_gross_spend

FROM demo_age p
JOIN tt_project.user_features u USING (user_id)
JOIN tt_project.perk_assignments pa USING (user_id)
GROUP BY p.age_band, pa.assigned_perk 
ORDER BY p.age_band, users DESC;

-------------------------------------------------------------------
--  Session Level Insights
-------------------------------------------------------------------

-- INSIGHT S1: Session Type Distribution and Booking Conversion Rate
SELECT
    session_type,
    COUNT(*) AS sessions,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_total
FROM tt_project.cohort_analytics
GROUP BY session_type
ORDER BY sessions DESC;

-- INSIGHT S2: Booking Type Distribution
-- How do users book — flights only, hotels only, or packages?
-- How does spending compare between the types of bookings
SELECT
    booking_type,
    COUNT(*) AS sessions,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_bookings,
    ROUND(AVG(grand_total_gross)::numeric, 2) AS avg_session_gross,
    ROUND(AVG(grand_total_net)::numeric, 2) AS avg_session_net,
    ROUND(AVG(grand_total_gross)::numeric - 
          AVG(grand_total_net)::numeric, 2) AS avg_discount_value,
    ROUND(AVG(booking_lead_time_days)::numeric, 1) AS avg_lead_days
FROM tt_project.cohort_analytics
WHERE session_type = 'booking'
AND booking_type IS NOT NULL
GROUP BY booking_type
ORDER BY booking_type;

-- INSIGHT S3: International vs Domestic Flight Split
-- Share of flights that are international and average fare comparison
SELECT
    passport_required AS is_international,
    COUNT(*) AS flight_bookings,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_flights,
    ROUND(AVG(flight_gross_amt)::numeric, 2) AS avg_gross_fare,
    ROUND(AVG(flight_gross_per_seat)::numeric, 2) AS avg_fare_per_seat,
    ROUND(AVG(flight_distance_km)::numeric, 1) AS avg_distance_km,
    ROUND(AVG(booking_lead_time_days)::numeric, 1) AS avg_lead_days,
    ROUND(AVG(checked_bags)::numeric, 3) AS avg_checked_bags
FROM tt_project.cohort_analytics
WHERE session_type = 'booking'
AND flight_gross_amt IS NOT NULL
GROUP BY passport_required
ORDER BY is_international DESC;


-- INSIGHT S4: Session Engagement by Type
-- How long do users spend and how many pages do they click per session?
SELECT
    session_type,
    COUNT(*) AS sessions,
    ROUND(AVG(session_duration_sec)::numeric, 1) AS avg_duration_sec,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY session_duration_sec)::numeric, 1) AS median_duration_sec,
    ROUND(AVG(page_clicks)::numeric, 1) AS avg_page_clicks,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY page_clicks)::numeric, 1) AS median_page_clicks
FROM tt_project.cohort_analytics
GROUP BY session_type
ORDER BY session_type DESC;

-- INSIGHT S5: Booking Lead Time by Booking Type
-- How far in advance do users book and does it vary by booking type?
SELECT
    booking_type,
    ROUND(AVG(booking_lead_time_days)::numeric, 1) AS avg_lead_days,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP
        (ORDER BY booking_lead_time_days)::numeric, 1) AS p25_lead_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY booking_lead_time_days)::numeric, 1) AS median_lead_days,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP
        (ORDER BY booking_lead_time_days)::numeric, 1) AS p75_lead_days,
    COUNT(*) AS sessions
FROM tt_project.cohort_analytics
WHERE session_type = 'booking'
AND booking_lead_time_days IS NOT NULL
AND booking_type IS NOT NULL
GROUP BY booking_type
ORDER BY avg_lead_days DESC;

-- INSIGHT S6: Discount Usage Concentration
-- What share of bookings use discounts and what is the average discount value?
SELECT
    CASE 
        WHEN flight_discount = true AND hotel_discount = true 
            THEN 'both_discounts'
        WHEN flight_discount = true AND hotel_discount = false 
            THEN 'flight_discount_only'
        WHEN flight_discount = false AND hotel_discount = true 
            THEN 'hotel_discount_only'
        ELSE 'no_discount'
    END AS discount_pattern,
    COUNT(*) AS sessions,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_bookings,
    ROUND(AVG(grand_total_gross)::numeric, 2) AS avg_gross_spend,
    ROUND(AVG(grand_total_net)::numeric, 2) AS avg_net_spend,
    ROUND(AVG(grand_total_gross - grand_total_net)::numeric, 2) AS avg_discount_value
FROM tt_project.cohort_analytics
WHERE session_type = 'booking'
GROUP BY discount_pattern
ORDER BY sessions DESC;

-- INSIGHT S7: Peak Booking session times
-- What share of bookings occur during which ours?
WITH bookings AS (
    SELECT
        EXTRACT(HOUR FROM session_start) AS hour_of_day,
        COUNT(*) AS booking_count,
        booking_type
    FROM tt_project.cohort_analytics
    WHERE session_type = 'booking'
    AND booking_type IS NOT NULL
    GROUP BY hour_of_day, booking_type
    ORDER BY hour_of_day
),
cancels AS (
    SELECT
        EXTRACT(HOUR FROM session_start) AS hour_of_day,
        COUNT(*) AS cancel_count
    FROM tt_project.cohort_analytics
    WHERE session_type = 'cancel'
    GROUP BY hour_of_day
    ORDER BY hour_of_day
),
browser AS (
    SELECT
        EXTRACT(HOUR FROM session_start) AS hour_of_day,
        COUNT(*) AS browse_count
    FROM tt_project.cohort_analytics
    WHERE session_type = 'browse'
    GROUP BY hour_of_day
    ORDER BY hour_of_day
)
SELECT
    b.hour_of_day,
    SUM(b.booking_count) AS total_bookings,
    COALESCE(c.cancel_count, 0) AS cancels_same_hour,
    COALESCE(l.browse_count, 0) AS browse_same_hour,
    COUNT(*) FILTER (WHERE b.booking_type = 'both') AS package_bookings,
    COUNT(*) FILTER (WHERE b.booking_type = 'flight') AS flight_bookings,
    COUNT(*) FILTER (WHERE b.booking_type = 'hotel') AS hotel_bookings,
    ROUND(COUNT(*) FILTER (WHERE b.booking_type = 'both')::numeric
        / COUNT(*)::numeric * 100, 1) AS pct_package,
    ROUND(COUNT(*) FILTER (WHERE b.booking_type = 'flight')::numeric
        / COUNT(*)::numeric * 100, 1) AS pct_flight,
    ROUND(COUNT(*) FILTER (WHERE b.booking_type = 'hotel')::numeric
        / COUNT(*)::numeric * 100, 1) AS pct_hotel,
        ROUND(COALESCE(c.cancel_count, 0)::numeric
        / COUNT(*)::numeric * 100, 1) AS cancel_pct_of_bookings
FROM bookings b
LEFT JOIN cancels c USING (hour_of_day)
LEFT JOIN browser l USING (hour_of_day)
GROUP BY b.hour_of_day, c.cancel_count, l.browse_count
ORDER BY b.hour_of_day;


-- ANOMALY Q1: Cancel Session Duration — quantify timeout contamination
SELECT
    session_type,
    COUNT(*) AS sessions,
    MIN(session_duration_sec) AS min_duration_sec,
    MAX(session_duration_sec) AS max_duration_sec,
    ROUND(AVG(session_duration_sec)::numeric, 1) AS avg_duration_sec,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY session_duration_sec)::numeric, 1) AS median_duration_sec,
    COUNT(*) FILTER (WHERE session_duration_sec = 7200) AS at_timeout_ceiling,
    COUNT(*) FILTER (WHERE session_duration_sec >= 3600) AS above_one_hour,
    ROUND(COUNT(*) FILTER (WHERE session_duration_sec = 7200)::numeric 
        / COUNT(*)::numeric * 100, 1) AS pct_at_timeout
FROM tt_project.cohort_analytics
WHERE session_type = 'cancel'
GROUP BY session_type;

-- ANOMALY Q2: Cancel sessions by booking type context
-- Which booking types generate the most cancellations?
SELECT
    ca.booking_type AS original_booking_type,
    COUNT(cx.session_id) AS cancel_sessions,
    ROUND(AVG(cx.session_duration_sec)::numeric, 1) AS avg_cancel_duration,
    COUNT(*) FILTER (WHERE cx.session_duration_sec = 7200) AS at_timeout,
    MIN(cx.session_duration_sec) AS min_cancel_duration,
    MAX(cx.session_duration_sec) AS max_cancel_duration
FROM tt_project.cohort_analytics cx
JOIN tt_project.cohort_analytics ca
    ON cx.trip_id = ca.trip_id
    AND ca.session_type = 'booking'
WHERE cx.session_type = 'cancel'
GROUP BY ca.booking_type
ORDER BY cancel_sessions DESC;

-- ANOMALY Q3: Booking Lead Time — quantify mean skew by booking type
SELECT
    booking_type,
    COUNT(*) AS sessions,
    MIN(booking_lead_time_days) AS min_lead_days,
    MAX(booking_lead_time_days) AS max_lead_days,
    ROUND(AVG(booking_lead_time_days)::numeric, 1) AS avg_lead_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY booking_lead_time_days)::numeric, 1) AS median_lead_days,
    COUNT(*) FILTER (WHERE booking_lead_time_days >= 90) AS bookings_90plus_days,
    COUNT(*) FILTER (WHERE booking_lead_time_days >= 180) AS bookings_180plus_days,
    ROUND(COUNT(*) FILTER (WHERE booking_lead_time_days >= 90)::numeric
        / COUNT(*)::numeric * 100, 1) AS pct_90plus_days
FROM tt_project.cohort_analytics
WHERE session_type = 'booking'
AND booking_lead_time_days IS NOT NULL
AND booking_type IS NOT NULL
GROUP BY booking_type
ORDER BY avg_lead_days DESC;

-------------------------------------------------------------------
--  User Level Insights
-------------------------------------------------------------------

-- INSIGHT U1: Customer Lifecycle Distribution
-- How is the cohort distributed across experience tiers?
SELECT
    CASE
        WHEN life_total_trips = 0 THEN 'tier_0_never_booked'
        WHEN life_total_trips = 1 THEN 'tier_1_single_trip'
        WHEN life_total_trips = 2 THEN 'tier_2_two_trips'
        WHEN life_total_trips BETWEEN 3 AND 5 THEN 'tier_3_established'
        WHEN life_total_trips BETWEEN 6 AND 9 THEN 'tier_4_loyal'
        WHEN life_total_trips >= 10 THEN 'tier_5_power_user'
    END AS lifecycle_tier,
    COUNT(*) AS users,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_cohort,
    ROUND(AVG(completed_total_gross)::numeric, 2) AS avg_gross_spend,
    ROUND(AVG(trips_per_year)::numeric, 2) AS avg_trips_per_year
FROM tt_project.user_features
GROUP BY lifecycle_tier
ORDER BY MIN(life_total_trips);

-- INSIGHT U2: Perk Assignment Distribution with Revenue Profile
-- What is the revenue profile of each perk group?
SELECT
    p.assigned_perk,
    COUNT(*) AS users,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_cohort,
    ROUND(AVG(u.completed_total_gross)::numeric, 2) AS avg_gross_spend,
    ROUND(AVG(u.trips_per_year)::numeric, 2) AS avg_trips_per_year,
    ROUND(AVG(u.life_total_trips)::numeric, 2) AS avg_life_trips,
    ROUND(AVG(u.avg_fare_per_seat)::numeric, 2) AS avg_fare_per_seat,
    CASE WHEN assigned_perk = 'Exclusive Discounts' THEN 0
        WHEN assigned_perk = 'No Change Fees' THEN 1
        WHEN assigned_perk = 'Free Checked Bags' THEN 2
        WHEN assigned_perk = 'Free Hotel Meals' THEN 3
        WHEN assigned_perk = 'Premium Travel Benefits' THEN 4
        END AS perk_rank

FROM tt_project.user_features u
JOIN tt_project.perk_assignments p USING (user_id)
GROUP BY p.assigned_perk
ORDER BY perk_rank;

-- INSIGHT U3: Revenue Concentration
-- What share of total revenue comes from the top 20% of spenders?
WITH ranked AS (
    SELECT
        user_id,
        completed_total_gross,
        NTILE(5) OVER (ORDER BY completed_total_gross DESC) AS spend_quintile
    FROM tt_project.user_features
    WHERE completed_total_gross > 0
),
totals AS (
    SELECT SUM(completed_total_gross) AS cohort_total
    FROM tt_project.user_features
    WHERE completed_total_gross > 0
)
SELECT
    r.spend_quintile,
    COUNT(*) AS users,
    ROUND(SUM(r.completed_total_gross)::numeric, 2) AS total_gross,
    ROUND(SUM(r.completed_total_gross)::numeric
        / t.cohort_total::numeric * 100, 1) AS pct_of_total_revenue,
    ROUND(AVG(r.completed_total_gross)::numeric, 2) AS avg_gross_spend
FROM ranked r
CROSS JOIN totals t
GROUP BY r.spend_quintile, t.cohort_total
ORDER BY r.spend_quintile ASC;

-- INSIGHT U4: Cancellation Impact at User Level
-- What is the total gross value at risk from cancellation behavior?
SELECT
    ROUND(SUM(cxl_gross_spend)::numeric, 2) AS total_cancelled_gross,
    ROUND(AVG(cxl_gross_spend)::numeric, 2) AS avg_cancelled_per_user,
    ROUND(AVG(cancel_spend_ratio)::numeric, 3) AS avg_cancel_spend_ratio,
    COUNT(*) FILTER (WHERE cancel_spend_ratio >= 0.40) AS high_cancel_users,
    COUNT(*) FILTER (WHERE user_booking_status = 'cancelled_all') AS total_cancellers,
    COUNT(*) FILTER (WHERE cxl_gross_spend > 0) AS users_with_any_cancellation
FROM tt_project.user_features;

-- INSIGHT U5: International vs Domestic User Revenue Comparison
-- Do international travelers generate more lifetime value?
SELECT
    CASE
        WHEN pct_complete_flights_intl >= 0.90 THEN 'near_exclusive_intl'
        WHEN pct_complete_flights_intl >= 0.50 THEN 'majority_intl'
        WHEN pct_complete_flights_intl > 0.00 THEN 'mixed_domestic_intl'
        WHEN pct_complete_flights_intl = 0.00 THEN 'domestic_only'
        ELSE 'no_flights'
    END AS travel_profile,
    COUNT(*) AS users,
    ROUND(AVG(completed_total_gross)::numeric, 2) AS avg_gross_spend,
    ROUND(AVG(avg_fare_per_seat)::numeric, 2) AS avg_fare_per_seat,
    ROUND(AVG(trips_per_year)::numeric, 2) AS avg_trips_per_year,
    ROUND(AVG(life_total_trips)::numeric, 2) AS avg_life_trips
FROM tt_project.user_features
WHERE life_total_trips > 0
GROUP BY travel_profile
ORDER BY avg_gross_spend DESC;

-- INSIGHT U6: Discount Dependency at User Level
-- Is discount usage concentrated in a small user segment?
SELECT
    CASE
        WHEN flight_discount_rate >= 0.70 THEN 'high_flight_discount'
        WHEN flight_discount_rate >= 0.30 THEN 'moderate_flight_discount'
        WHEN flight_discount_rate > 0.00 THEN 'low_flight_discount'
        ELSE 'no_flight_discount'
    END AS flight_discount_profile,
    COUNT(*) AS users,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_cohort,
    ROUND(AVG(completed_total_gross)::numeric, 2) AS avg_gross_spend,
    ROUND(AVG(trips_per_year)::numeric, 2) AS avg_trips_per_year
FROM tt_project.user_features
GROUP BY flight_discount_profile
ORDER BY avg_gross_spend DESC;

-- INSIGHT U7: Perk Group Progression Potential
-- How many users in lower lifecycle tiers show signals of higher-value behavior?
SELECT
    p.assigned_perk,
    COUNT(*) FILTER (WHERE u.life_total_trips <= 2) AS early_stage_users,
    COUNT(*) FILTER (WHERE u.life_total_trips >= 3) AS established_users,
    ROUND(COUNT(*) FILTER (WHERE u.life_total_trips <= 2)::numeric
        / COUNT(*)::numeric * 100, 1) AS pct_early_stage,
    ROUND(AVG(u.trips_per_year)::numeric, 2) AS avg_trips_per_year,
    ROUND(AVG(u.completed_total_gross)::numeric, 2) AS avg_gross_spend,
    CASE WHEN assigned_perk = 'Exclusive Discounts' THEN 0
        WHEN assigned_perk = 'No Change Fees' THEN 1
        WHEN assigned_perk = 'Free Checked Bags' THEN 2
        WHEN assigned_perk = 'Free Hotel Meals' THEN 3
        WHEN assigned_perk = 'Premium Travel Benefits' THEN 4
        END AS perk_rank
FROM tt_project.user_features u
JOIN tt_project.perk_assignments p USING (user_id)
GROUP BY p.assigned_perk
ORDER BY perk_rank;


-- INSIGHT U8: Tier level behavior - customer acquistion
WITH demo_age AS (
    SELECT
        user_id,
        DATE_PART('year', AGE('2024-08-19'::date, birthdate)) AS age
    FROM tt_project.user_profile
),
lifecycle AS (
    SELECT
        u.user_id,
        u.life_total_trips,
        u.days_since_signup,
        u.first_purchase_date,
        up.first_session_date,
        u.completed_total_gross,
        u.total_cancellation_rate,
        u.cancel_spend_ratio,
        u.trips_per_year,
        u.total_hotel_only_bookings,
        u.total_package_bookings,
        -- flight only = total completed trips minus hotel only minus packages
        (u.life_total_trips 
            - COALESCE(u.total_hotel_only_bookings, 0) 
            - COALESCE(u.total_package_bookings, 0)) AS total_flight_only_bookings,
        -- days from signup to first completed trip
        (u.first_purchase_date - up.sign_up_date) AS days_signup_to_first_trip,
        CASE
            WHEN u.life_total_trips = 0 THEN 'tier_0_never_booked'
            WHEN u.life_total_trips = 1 THEN 'tier_1_single_trip'
            WHEN u.life_total_trips = 2 THEN 'tier_2_two_trips'
            WHEN u.life_total_trips BETWEEN 3 AND 5 THEN 'tier_3_established'
            WHEN u.life_total_trips BETWEEN 6 AND 9 THEN 'tier_4_loyal'
            WHEN u.life_total_trips >= 10 THEN 'tier_5_power_user'
        END AS lifecycle_tier
    FROM tt_project.user_features u
    JOIN tt_project.user_profile up USING (user_id)
)
SELECT
    lifecycle_tier,
    COUNT(*) AS users,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_cohort,
    -- signup to first trip
    ROUND(AVG(days_signup_to_first_trip)::numeric, 1) AS avg_days_signup_to_first_trip,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY days_signup_to_first_trip)::numeric, 1) AS median_days_to_first_trip,
    -- spend
    ROUND(AVG(completed_total_gross)::numeric, 2) AS avg_gross_spend,
    -- cancellation
    ROUND(AVG(total_cancellation_rate)::numeric, 3) AS avg_cancel_rate,
    ROUND(AVG(COALESCE(cancel_spend_ratio, 0))::numeric, 3) AS avg_cancel_spend_ratio,
    -- booking type distribution as % of total bookings per tier
    ROUND(SUM(total_hotel_only_bookings)::numeric 
        / NULLIF(SUM(life_total_trips), 0)::numeric * 100, 1) AS pct_hotel_only,
    ROUND(SUM(total_package_bookings)::numeric 
        / NULLIF(SUM(life_total_trips), 0)::numeric * 100, 1) AS pct_package,
    ROUND(SUM(total_flight_only_bookings)::numeric 
        / NULLIF(SUM(life_total_trips), 0)::numeric * 100, 1) AS pct_flight_only,
    -- frequency
    ROUND(AVG(trips_per_year)::numeric, 2) AS avg_trips_per_year,
    ROUND(AVG(days_since_signup)::numeric, 1) AS avg_days_since_signup
FROM lifecycle
GROUP BY lifecycle_tier
ORDER BY MIN(life_total_trips);

-- INSIGHT U9: Total lifetime spend per tier
SELECT
    CASE
        WHEN life_total_trips = 0 THEN 'tier_0_never_booked'
        WHEN life_total_trips = 1 THEN 'tier_1_single_trip'
        WHEN life_total_trips = 2 THEN 'tier_2_two_trips'
        WHEN life_total_trips BETWEEN 3 AND 5 THEN 'tier_3_established'
        WHEN life_total_trips BETWEEN 6 AND 9 THEN 'tier_4_loyal'
    END AS lifecycle_tier,
    ROUND(SUM(completed_total_gross)::numeric, 2) AS total_lifetime_spend,
    ROUND(AVG(completed_total_gross)::numeric, 2) AS avg_spend_per_user,
    COUNT(*) AS users
FROM tt_project.user_features
GROUP BY lifecycle_tier
ORDER BY MIN(life_total_trips);

-------------------------------------------------------------------
--  Perk Assignments Verification
-------------------------------------------------------------------

SELECT 
    user_id,
    assigned_perk,
    life_total_trips,
    assignment_reason
FROM tt_project.perk_assignments
GROUP BY 2,3,1,4
ORDER BY assigned_perk
;
