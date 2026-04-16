/* ------------------------------------------------------- 
-- with distance calculation fields  in place from step 4
-- in DataAssess notebook, now adding designation for 
-- booking type (hotel or flight only or both) and
-- passport rqrd (T/F) based on in or out of country travel
-- version 3
-----------------------------------------------------------*/

-- 1. update missing/outdated aiport codes
INSERT INTO tt_project.airport_lookup 
    (iata_code, airport_name, city, country_code, lat, lon, airport_type)
VALUES
    ('TXL', 'Berlin Tegel Airport', 'Berlin', 'DE', 52.5597, 13.2877, 'closed'),
    ('JRS', 'Jerusalem Airport', 'Jerusalem', 'IL', 31.8647, 35.2192, 'closed'),
    ('SXF', 'Berlin Schönefeld Airport', 'Berlin', 'DE', 52.3800, 13.5225, 'closed'),
    ('THF', 'Berlin Tempelhof Airport', 'Berlin', 'DE', 52.4728, 13.4011, 'closed');

-- 2. Add booking_type and passport_required       

-- Add columns
ALTER TABLE tt_project.cohort_analytics
    ADD COLUMN booking_type VARCHAR(10),
    ADD COLUMN passport_required BOOLEAN;

-- Populate booking_type on booking sessions only
UPDATE tt_project.cohort_analytics
SET booking_type = CASE
    WHEN flight_booked = TRUE  AND hotel_booked = TRUE  THEN 'both'
    WHEN flight_booked = TRUE  AND hotel_booked = FALSE THEN 'flight'
    WHEN flight_booked = FALSE AND hotel_booked = TRUE  THEN 'hotel'
END
WHERE session_type = 'booking';

-- Populate passport_required on flight booking sessions only
-- Joins airport_lookup twice: once for home, once for destination
UPDATE tt_project.cohort_analytics ca
SET passport_required = CASE
    WHEN al_dest.country_code != al_home.country_code THEN TRUE
    ELSE FALSE
END
FROM tt_project.airport_lookup al_home,
     tt_project.airport_lookup al_dest
WHERE al_home.iata_code = ca.home_airport
    AND al_dest.iata_code = ca.destination_airport
    AND ca.session_type = 'booking'
    AND ca.flight_booked = TRUE;

-- Verify
SELECT 
    session_type,
    booking_type,
    passport_required,
    COUNT(*) AS row_count
FROM tt_project.cohort_analytics
GROUP BY session_type, booking_type, passport_required
ORDER BY session_type, booking_type, passport_required;

/* -----------  END FILE  ------------- */