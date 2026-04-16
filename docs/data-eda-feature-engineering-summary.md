# Data / EDA / Feature Engineering Summary
**TRAVELTIDE - FEATURE ENGINEERING DECISION SUMMARY**  
*Updated: April 2026 - reflects V2 final pipeline state*

---

## SECTION 1 - Data Structure Confirmed

**cohort_analytics: `tt_project.cohort_analytics`**  
*One row per session. Primary analytical data lake. 49,218 rows.*

| Fact | Value |
|---|---|
| Total sessions (cohort window) | 49,218 |
| Total cohort users | 5,998 |
| Never-booked users | 522 (8.7%) |
| Cancelled-all users | 88 (1.5%) |
| Users with completed bookings | 5,388 (89.8%) |
| Browse-only sessions | 32,509 (66.1%) |
| Booking sessions | 16,099 (32.7%) |
| Cancel sessions | 610 (1.2%) |
| Flight only bookings | 1,786 (11.1%) |
| Hotel only bookings | 2,382 (14.8%) |
| Flight + Hotel (package) bookings | 11,931 (74.1%) |

**Note:** V1 counts differed due to pre-cutoff session leakage (1,336 sessions incorrectly included) and session type misclassification. V2 counts reflect corrected pipeline.

### Date Ranges

| Field | Earliest | Latest |
|---|---|---|
| Sign-up date | 2021-04-01 | 2023-07-20 |
| Session start | 2023-01-04 | 2023-07-28 |
| Flight departure | 2023-01-07 | 2024-07-16 |
| Flight return | 2023-01-08 | 2024-08-19 |
| Hotel check-in | 2023-01-07 | 2024-07-20 |
| Hotel check-out | 2023-01-08 | 2024-08-13 |

**Date anchor:** All relative calculations use `2024-08-19` (last recorded travel date). No current-date references used anywhere in the pipeline.

- Sessions & sign-up cutoff = `2023-07-28`
- Flight/Hotel travel cutoff = `2024-08-19`

---

## SECTION 2 - Columns Excluded from Clustering

| Column | Reason |
|---|---|
| `rooms` | r=0.94 with `seats` - redundant |
| `trip_duration_days` | r=0.98 with `calc_nights` - redundant |
| `user_id`, `session_id`, `trip_id` | Identity keys - not features |
| `home_airport_lat/lon`, `destination_airport_lat/lon` | Replaced by `flight_distance_km` haversine distance feature |
| Net spend versions where gross equivalent exists | Collinear - gross versions retained as more interpretable |
| Conditional zero-heavy fields (e.g. `cxl_*` for non-cancellers) | ~90% zeros create noise dimensions; evaluated per dimension |

---

## SECTION 3 - Field Renames (V2)

Four fields renamed in `3_DA_cohort_changes.sql` for clarity and reduced confusion:

| Original Name | New Name |
|---|---|
| `flight_discount_amount` | `flight_discount_pct` |
| `base_fare_usd` | `flight_gross_amt` |
| `hotel_discount_amount` | `hotel_discount_pct` |
| `hotel_per_room_usd` | `hotel_gross_per_roomnight` |

---

## SECTION 4 - Transformations (ML Input Only)

Applied to `user_features` before saving as `user_features_transformed`. Original values preserved in `user_features` for business insight queries.

| Column | Transform | Reason |
|---|---|---|
| `avg_fare_per_seat` and all gross/net spend fields | `log1p` | Right skew, extreme outliers |
| `avg_hotel_per_room` | `log1p` | Skew 2.35, long upper tail |
| `avg_session_duration_sec` | `log1p` | Right skewed, timeout noise at ceiling |
| `avg_clicks_per_session` | `log1p` | Heavy right tail |
| `avg_lead_time_days` | `log1p` | Two-population distribution |
| `cxl_gross_spend` and cancelled spend fields | `log1p` | Extreme right skew from high-value cancellations |

**Note:** `page_clicks` and `session_duration_sec` bins were evaluated then **dropped** - user-level aggregation of session-level bin distributions produced unimodal results with no meaningful cluster signal. Raw aggregated values retained instead.

---

## SECTION 5 - Binning Decisions

Only `booking_lead_time_days` retained as a bin at user level. All other bin candidates dropped after distribution analysis confirmed unimodal behavior at user-level aggregation.

| Feature | Bins | Labels | Basis |
|---|---|---|---|
| `avg_lead_time_days` (user level) | 0d / 1–7d / 8–30d / 31–90d / 90d+ | same_day / last_minute / standard / planner / advanced | Histogram shows two distinct populations; 7-day median boundary confirmed |
| `booking_conversion_rate` | 0 / <0.25 / 0.25–0.50 / 0.50+ | never / low / moderate / high | Spiked distributions at fractions (0.25, 0.33, 0.50) confirm mathematical artifacts of small session counts |

**V1 bin decisions for `session_duration_sec` and `page_clicks` deprecated** - bins were designed at session level. At user-level aggregation (averages), the distributions are unimodal and binning removes rather than adds signal.

---

## SECTION 6 - Outlier Capping

Applied to ML input only (`user_features_transformed`). Three-chart diagnostic per field: histogram + boxplot + log1p histogram. Zero-inflated fields evaluated on non-zero populations only. Gross and net spend fields capped independently.

| Column | Cap At | Value |
|---|---|---|
| `avg_fare_per_seat` | 99th percentile | ~$1,200 |
| `net_avg_fare_per_seat` | 99th percentile | ~$1,100 |
| `avg_hotel_per_room` | 99th percentile | ~$621 |
| `avg_session_duration_sec` | 95th percentile | 718 sec |
| `avg_clicks_per_session` | 99th percentile | 116 clicks |
| `avg_trip_nights` | 99th percentile | ~18 nights |
| `avg_lead_time_days` | 99th percentile | ~180 days |
| `avg_cancelled_lead_time` | 99th percentile | ~180 days |
| `cxl_gross_spend` | 99th percentile | ~$8,000 |

**Final decision:** Caps applied before log transforms but after zero-fill. Caps on attempted/completed gross spend deferred - values are summed totals where outliers represent genuine high-spend users rather than data errors.

---

## SECTION 7 - New Fields Added (cohort_analytics enrichment)

Added in `3_DA_cohort_changes.sql` and `5_db_changes.sql`:

| Field | Type | Logic | Notes |
|---|---|---|---|
| `session_type` | VARCHAR | browse / booking / cancel | cancel = cancellation=TRUE AND trip_id IS NOT NULL |
| `session_duration_sec` | INT | `EXTRACT(EPOCH FROM session_end - session_start)` | Replaces V1 approach that only populated for flights |
| `booking_lead_time_days` | INT | `DATE_PART('day', LEAST(departure_time, check_in_time) - session_start)` | LEAST() ensures hotel-only bookings are included |
| `trip_duration_days` | FLOAT | `DATE_PART('day', GREATEST(return_time, check_out_time) - LEAST(departure_time, check_in_time))` | Booking sessions only |
| `flight_type` | VARCHAR | none / one-way / round-trip | Booking sessions only |
| `user_age` | INT | `ROUND((DATE '2024-08-19' - birthdate) / 365)` | Anchored to dataset end date |
| `calc_nights` | INT | `CEIL(EXTRACT(EPOCH FROM check_out_time - check_in_time) / 86400)` | Replaces corrupted `nights` column; proxy logic for edge cases |
| `flight_discount_amt` | FLOAT | `flight_gross_amt * COALESCE(flight_discount_pct, 0)` | Absolute discount value |
| `flight_gross_per_seat` | FLOAT | `flight_gross_amt / seats` | Per-seat fare |
| `flight_net_amt` | FLOAT | `flight_gross_amt * (1 - COALESCE(flight_discount_pct, 0))` | Post-discount fare |
| `hotel_gross_amt` | FLOAT | `hotel_gross_per_roomnight * rooms * calc_nights` | Total hotel gross |
| `hotel_discount_amt` | FLOAT | `hotel_gross_amt * COALESCE(hotel_discount_pct, 0)` | Absolute discount value |
| `hotel_net_amt` | FLOAT | `hotel_gross_amt * (1 - COALESCE(hotel_discount_pct, 0))` | Post-discount hotel |
| `grand_total_gross` | FLOAT | `COALESCE(flight_gross_amt, 0) + COALESCE(hotel_gross_amt, 0)` | Total pre-discount spend |
| `grand_total_net` | FLOAT | `COALESCE(flight_net_amt, 0) + COALESCE(hotel_net_amt, 0)` | Total post-discount spend |
| `booking_type` | VARCHAR | both / flight / hotel | Booking sessions only; added in step 5 |
| `passport_required` | BOOLEAN | home_airport country != destination_airport country | Via airport_lookup join; flight booking sessions only |
| `flight_distance_km` | FLOAT | Haversine formula (Python) | Calculated in `6_haversine_append.ipynb`; written back via SQLAlchemy parameterized UPDATE |
| `trip_cancelled` | BOOLEAN | trip_id exists in cancelled_trips lookup | Added in step 7 feature engineering |

### Special Field Handling

| Case | Handling |
|---|---|
| Never-booked users (522) | Included in `user_features` - NULL spend cols become 0, browse metrics preserved |
| Cancelled-all users (88) | Distinct from never-booked - assigned `user_booking_status = 'cancelled_all'`; No Change Fees perk |
| Hotel-only bookings | NULL flight features - excluded from flight averages, preserved for hotel metrics |
| Flight-only bookings | NULL hotel features - excluded from hotel averages, preserved for flight metrics |
| Cancel sessions | Excluded from all financial aggregations - cancel sessions retain trip_id reference but represent reversal events not purchases |
| Deprecated IATA codes | JRS, SXF, THF, TXL added to airport_lookup to resolve NULL passport_required on 6 pre-cohort exception rows |

---

## SECTION 8 - Feature Engineering Architecture (V2)

Five materialized intermediate tables feed the final `user_features` table:

| Table | Rows | Description |
|---|---|---|
| `session_agg` | 5,998 | Website usage, booking counts, attempted/completed spend, discount behavior, travel pattern averages, distance (attempted) |
| `user_profile` | 5,998 | Demographics, account metadata, first/last session dates |
| `trip_agg` | 5,998 | Completed trip financial and distance metrics, booking type counts, discount rates |
| `trip_cx_agg` | 5,998 | Cancelled trip metrics - identical structure to trip_agg filtered to cancelled trips |
| `user_loyalty` | 5,998 | Lifetime trip counts (pre-cohort + cohort), cancellation metrics, cancel_spend_ratio, days_since_signup |
| **`user_features`** | **5,998** | **109-column final table joining all five above** |
| `user_features_transformed` | 5,998 | user_features + dtype fixes + zero fills + outlier caps + log transforms + bins + cluster labels. 160-column ML checkpoint. |

**Key architectural decisions:**
- All LEFT JOINs wrapped in COALESCE to prevent NULL propagation
- All ratio denominators use NULLIF(..., 0) to prevent divide-by-zero
- Integer division resolved via `::float` casts throughout
- Completed vs attempted vs cancelled spending tracked independently

---

## SECTION 9 - Clustering Architecture

### Data Preparation Steps (applied to user_features before clustering)

1. **Step 1a - Dtype fixes & zero-fills:** Date columns to datetime; numeric fields with meaningful zeros filled with 0. 22 pre-cohort bookers corrected from 'never' to 'low' in conversion_bin.
2. **Step 1b - Outlier capping:** Three-chart diagnostic per field. Zero-inflated fields evaluated on non-zero populations.
3. **Step 1c - Log transforms:** 24 log_ prefixed columns via log1p. Originals retained.
4. **Step 1d - Behavioral bins:** Session duration and page click bins dropped (unimodal user-level distributions). Lead time and conversion rate bins retained.

### Two-Path Parallel Clustering

PCA run on full 64-feature clean set. Eight meaningful components identified explaining 67% of variance. Informed two parallel clustering paths:

**Path A - Business-logic dimensions:**

| Dimension | Features | k | Silhouette |
|---|---|---|---|
| website | total_sessions, browse_rate, clicks, duration, conversion_rate | 2 | 0.38 |
| spending | fare, hotel rate, gross spend, discount dependency | 3 | 0.41 |
| travel | lead time, return rate, nights, bags, destination variety | 3 | 0.44 |
| cancellation | cancel rate, cancel spend ratio, cxl lead time, cxl by type | 5* | 0.31* |

**Path B - PCA-aligned dimensions:**

| Dimension | Features | k | Silhouette |
|---|---|---|---|
| spending_distance | gross spend, fare, hotel, distance | 3 | 0.42 |
| cancellation | same as Path A | 5* | 0.31* |
| hotel_behavior | hotel discount rate, hotel nights, hotel bookings | 3 | 0.39 |
| flight_discounts | flight discount rate, discount amounts, package bookings | 3 | 0.45 |
| intl_travel | pct_intl, intl flight counts, distance | 4 | 0.48 |

**\*Zero-inflation correction:** Cancellation dimension initially returned silhouette = 0.955 - artificially inflated by 90.1% zero-cancellation population. Resolved by clustering 595 actual cancellers only; non-cancellers assigned to 'non_cancellers' cluster separately. k=5 confirmed on cancellers-only population.

**All models:** `random_state=53`, `n_init=10`, `StandardScaler` normalization

### Segment Naming - Known Limitation

Cluster segment names were assigned post-hoc by profiling centroids. Several names were found inaccurate on audit:
- `flight_advanced_planner_cancellers` - avg lead time = 7.09 days, below cohort baseline. Name was incorrect.
- `highvolume_package_travelers` - mixed signal of flight_discount_rate AND package bookings.

This naming ambiguity was the primary reason the ML-based sequential perk assignment (V1 approach, documented in `9_perk_rule_eval.ipynb`) was replaced by the independent rule-based lifecycle-gated system. Both approaches converged on near-identical user populations, cross-validating each other.

---

## SECTION 10 - Perk Assignment - Final Approach

Lifecycle-gated rule-based SQL system applied directly to `user_features`. Four tiers:

| Tier | Condition | Users | Perk Logic |
|---|---|---|---|
| 0 | `life_total_trips = 0` | 522 | Exclusive Discounts - unconditional |
| 1 | `life_total_trips = 1` | 939 | cancel_spend_ratio ≥ 0.40 → No Change Fees; else Exclusive Discounts |
| 2 | `life_total_trips = 2` | 1,315 | cancel ≥ 0.40 → NCF; 100% intl → FCB; else Exclusive Discounts |
| 3+ | `life_total_trips ≥ 3` | 3,222 | Full 5-perk behavioral evaluation in priority order |

**Final distribution:**

| Perk | Users | % Cohort |
|---|---|---|
| Exclusive Discounts | 2,546 | 42.4% |
| Premium Travel Benefits | 2,283 | 38.1% |
| Free Checked Bags | 715 | 11.9% |
| No Change Fees | 233 | 3.9% |
| Free Hotel Meals | 221 | 3.7% |
| **Total** | **5,998** | **100%** |

Zero unassigned users. Results stored in `tt_project.perk_assignments`.

---

## SECTION 11 - V1 Issues Resolved in V2

| Issue | Root Cause | Resolution |
|---|---|---|
| Discount rates >1.0 | Session-level double-counting | Trip-level deduplication CTE |
| 1,336 pre-cohort sessions included | Missing date filter on cohort JOIN | Added cohort window date filter |
| session_duration_sec NULL for non-flight sessions | Only populated from flight source | Recalculated as session_end - session_start |
| booking_lead_time_days NULL for hotel-only | Used departure_time alone | Changed to LEAST(departure_time, check_in_time) |
| 7 orphaned cancellation sessions | No matching booking in cohort window | Pre-cutoff booking sessions inserted as documented exceptions |
| NULL passport_required on 6 rows | 4 deprecated IATA codes missing | Added JRS, SXF, THF, TXL to airport_lookup |
| Segment names not validated | Post-hoc naming without geometric verification | Replaced ML assignment with independent rule-based system |

---

*TravelTide Feature Engineering Summary | Updated April 2026 | V2 Final State*