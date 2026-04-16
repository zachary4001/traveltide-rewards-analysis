/* ================================================================
                    Step 1 Duplicate Source Tables
    Copies source tables from Neon cloud database into local 
    tt_project schema. Run once on initial setup.
    Requires active connection to both Neon source and local Postgres.
    Source: Neon TravelTide database (see .env NEON_DB_URL)
    Target: Local PostgreSQL tt_project schema
    ------------------------------------------------------------
    This file executes a series of queries to create a new dbase
    schema and duplicate the source tables from the Traveltide
    data source into your local postrgres dbase. Ensure you have
    permissions to create a new schema, as well as create, alter
    and drop tables within that schema.
    --version 1 pending table duplicate queries
====================================================================*/

/* --- First step - DUPLICATE source tables on LOCAL dbase --- */

CREATE SCHEMA IF NOT EXISTS tt_project;

-- Duplicate source tables into local schema

CREATE TABLE tt_project.users AS 
    SELECT * FROM users;

CREATE TABLE tt_project.sessions AS 
    SELECT * FROM sessions;

CREATE TABLE tt_project.flights AS 
    SELECT * FROM flights;

CREATE TABLE tt_project.hotels AS 
    SELECT * FROM hotels;

/* cleanup local dbase for EDA - re add indexes and relationships */

-- Primary Keys 
ALTER TABLE tt_project.users ADD PRIMARY KEY (user_id);
ALTER TABLE tt_project.sessions ADD PRIMARY KEY (session_id);
ALTER TABLE tt_project.flights ADD PRIMARY KEY (trip_id);
ALTER TABLE tt_project.hotels ADD PRIMARY KEY (trip_id);

-- Indexing
-- user_id most frequent 'join' and 'group by' key
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON tt_project.sessions(user_id);

-- trip_id links sessions to user_ids and purchases
CREATE INDEX IF NOT EXISTS idx_sessions_trip_id ON tt_project.sessions(trip_id);

-- 3. Maintenance (Update the Postgres 'Brain' on the new data distribution)
ANALYZE tt_project.users;
ANALYZE tt_project.sessions;
ANALYZE tt_project.flights;
ANALYZE tt_project.hotels;

/* --- Redacted - artifact from version 1 pipeline cycle 
    and replaced by later processes in the current version --- */

/* OBJECTIVE: Create a persistent 'Gold' table for our specific cohort.
   BENEFIT: Eliminates the need for repeated subqueries or complex joins. */

-- CREATE TABLE tt_project.cohort_users AS
-- SELECT 
--     u.*,
--     -- Pre-calculate some basic stats to save time later
--     COUNT(s.session_id) as total_sessions,
--     SUM(s.page_clicks) as total_clicks
-- FROM tt_project.users u
-- JOIN tt_project.sessions s ON u.user_id = s.user_id
-- WHERE s.session_start >= '2023-01-01'
-- GROUP BY u.user_id
-- HAVING COUNT(s.session_id) > 7;

-- -- Add a Primary Key to our new table for speed
-- ALTER TABLE tt_project.cohort_users ADD PRIMARY KEY (user_id);

-- /* OBJECTIVE: Enforce Referential Integrity on local NAS */

-- -- Link Sessions to Users
-- ALTER TABLE tt_project.sessions 
-- ADD CONSTRAINT fk_user_id 
-- FOREIGN KEY (user_id) REFERENCES tt_project.users(user_id);

-- -- Link Flights to Sessions (via trip_id)
-- ALTER TABLE tt_project.flights 
-- ADD CONSTRAINT fk_trip_id_flights 
-- FOREIGN KEY (trip_id) REFERENCES tt_project.sessions(trip_id);

-- -- Link Hotels to Sessions (via trip_id)
-- ALTER TABLE tt_project.hotels 
-- ADD CONSTRAINT fk_trip_id_hotels 
-- FOREIGN KEY (trip_id) REFERENCES tt_project.sessions(trip_id);