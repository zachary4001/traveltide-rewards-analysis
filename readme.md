# README.TXT

### TravelTide Rewards Program Analysis

**Author:** Jason Zachary Guest  
**Program:** Masterschool Data Science Foundations Mastery Project  
**Completed:** April 2026

---

### Project Description

TravelTide is a travel booking platform. This project analyzes the behavioral patterns of "cohort" users to assign each user exactly one of five personalized reward perks: Exclusive Discounts, No Change Fees, Free Checked Bags, Free Hotel Meals, and Premium Travel Benefits.

The analysis was commissioned by Elena Tarrant, Head of Marketing, to move beyond generic promotional emails and toward data-driven personalized reward offers.

---

#### Project Summary

##### Key Finding

Customer behavior on TravelTide follows a clear five-tier lifecycle, from never-booked users through to loyal high-frequency travelers. Each tier has a distinct behavioral fingerprint, revenue profile, and optimal perk assignment.

<table id="bkmrk-tier-users-avg-spend"><thead><tr><th>Tier</th><th>Users</th><th>Avg Spend</th><th>Assigned Perk Focus</th></tr></thead><tbody><tr><td>Tier 0 — Never Booked</td><td>522</td><td>$0</td><td>Exclusive Discounts (acquisition)</td></tr><tr><td>Tier 1 — Single Trip</td><td>939</td><td>$1,344</td><td>Exclusive Discounts / No Change Fees</td></tr><tr><td>Tier 2 — Two Trips</td><td>1,315</td><td>$2,595</td><td>Limited behavioral assignment</td></tr><tr><td>Tier 3 — Established (3–5 trips)</td><td>2,965</td><td>$4,235</td><td>Full behavioral evaluation</td></tr><tr><td>Tier 4 — Loyal (6–9 trips)</td><td>257</td><td>$6,410</td><td>Full behavioral evaluation</td></tr></tbody></table>

#### Perk Assignment Results

<table id="bkmrk-perk-users-%25-cohort-"><thead><tr><th>Perk</th><th>Users</th><th>% Cohort</th><th>Avg Spend</th></tr></thead><tbody><tr><td>Exclusive Discounts</td><td>2,546</td><td>42.4%</td><td>$2,332</td></tr><tr><td>No Change Fees</td><td>233</td><td>3.9%</td><td>$1,768</td></tr><tr><td>Free Checked Bags</td><td>715</td><td>11.9%</td><td>$3,692</td></tr><tr><td>Free Hotel Meals</td><td>221</td><td>3.7%</td><td>$3,987</td></tr><tr><td>Premium Travel Benefits</td><td>2,283</td><td>38.1%</td><td>$4,490</td></tr></tbody></table>

**Total cohort revenue: $18,829,588 | Users assigned: 5,998 | Users unassigned: 0**

#### Key Business Insights

- Top 20% of spenders generate 44% of total cohort revenue
- 73.7% of all bookings use no discount, discount dependency is a minority behavior
- Peak booking hour: 7PM–8PM daily, promotional email timing should align here
- International flights carry a 49% fare premium per seat vs domestic
- If 10% of users in each tier progress one tier up: projected +$1,049,937 revenue uplift

---

### Repository Structure

```
traveltide-rewards-analysis/
│
├── README.md                          # This file
├── .env                               # Placeholder — DB connection template (no credentials)
├── requirements.txt                   # Python dependencies
│
├── /src                               # All pipeline files in execution order
│   ├── 1_tt_project_data_import_1.sql # Source table mirroring from original DB
│   ├── 2_tt_project_data_import_2.sql # Cohort-scoped analytical table creation
│   ├── 3_DA_cohort_changes.sql        # Cohort definition and cohort_analytics build
│   ├── 4_data_assess.ipynb            # Initial data assessment, anomaly detection, V1 findings
│   ├── 5_db_changes.sql               # Session enrichment: session_type, booking_type,
│   │                                  #   passport_required, session_duration, lead_time
│   ├── 6_haversine_append.ipynb       # Haversine flight distance calculation → Postgres write
│   ├── 7_feature_engineering.sql      # 5-table intermediate architecture + user_features assembly
│   ├── 8_EDA.ipynb                    # EDA, outlier analysis, ML clustering (K-Means, PCA),
│   │                                  #   segment profiling, cluster label assignment
│   ├── 9_perk_rule_eval.ipynb         # V1 ML-based perk rule evaluation (threshold testing
│   │                                  #   against segment masks — documents analytical journey)
│   ├── 10_segmentation.ipynb          # Final lifecycle-gated perk assignment + perk_assignments
│   │                                  #   table write to Postgres
│   └── 11_insights_review.sql         # All business insight queries: demographic, session-level,
│                                      #   user-level, perk-level — reproducible insight generation
│
├── /data
│   └── perk_assignments.csv           # Final deliverable: 5,998 users × assigned_perk +
│                                      #   life_total_trips + assignment_reason
│
└── /docs
    ├── TravelTide_Executive_Summary.md      # One-page executive summary (business audience)
    ├── TravelTide_Executive_Summary.pdf     # Full color version suitable for printing.
    ├── TravelTide_Detailed_Report.pdf       # Full methodology + business insights (4 pages)
    ├── data-eda-feature-engineering-summary.md  # Field definitions, transform decisions,
    │                                            #   outlier caps, binning logic
    ├── presentation_video.md                # Recorded presentation — YouTube link + notes
    └── TravelTide_Rewards_Presentation.pdf  # PDF printable version of presentation slides

```

---

### Installation

#### Prerequisites

- PostgreSQL (local or remote instance)
- Python 3.9+
- Jupyter Notebook or JupyterLab

#### Setup

```bash
git clone https://github.com/zahcary4001/traveltide-rewards-analysis.git
cd traveltide-rewards-analysis
pip install -r requirements.txt

```

#### Database Configuration

Copy `.env` and fill in your connection details:

```bash
cp .env .env.local

```

Edit `.env.local` with your PostgreSQL credentials. The `.env` file in this repo contains only placeholders - never commit real credentials.

---

### Usage

Execute pipeline files in numbered order:

**Step 1–3 (SQL):** Run in your PostgreSQL client (pgAdmin, DBeaver, or psql)

```bash
psql -U your_user -d your_database -f src/1_tt_project_data_import_1.sql
psql -U your_user -d your_database -f src/2_tt_project_data_import_2.sql
psql -U your_user -d your_database -f src/3_DA_cohort_changes.sql

```

**Step 4+ (Notebooks):** Open in Jupyter and run cells sequentially

```bash
jupyter notebook src/4_data_assess.ipynb

```

**Step 5 (SQL):** Run in your PostgreSQL client (pgAdmin, DBeaver, or psql)

```bash
psql -U your_user -d your_database -f src/5_db_changes.sql 

```

**Step 6 (Notebook):** Open in Jupyter and run cells sequentially

```bash
jupyter notebook src/6_Haversine-append.ipynb

```

**Step 7 (SQL):** Run in your PostgreSQL client (pgAdmin, DBeaver, or psql)

```bash
psql -U your_user -d your_database -f src/7_feature_engineering.sql

```

**Step 8 (Notebooks):** Open in Jupyter and run cells sequentially

```bash
jupyter notebook src/8_EDA.ipynb
jupyter notebook src/9_perk_rule_eval.ipynb
jupyter notebook src/10_segmentation.ipynb
```

**Reproduce business insights:**

```bash
psql -U your_user -d your_database -f src/11_insights_review.sql

```

**Export perk assignments:**

```sql
COPY tt_project.perk_assignments TO '/path/to/perk_assignments.csv' 
WITH CSV HEADER;

```

---

### Pipeline Architecture

The project uses a hybrid SQL + Python pipeline with a deliberate separation of concerns:

- **SQL files** handle all database engineering steps — table creation, cohort filtering, field enrichment, and feature engineering via materialized intermediate tables
- **Jupyter notebooks** handle all data science steps — EDA, statistical analysis, ML clustering, and perk assignment logic

This separation mirrors real-world data team structures where database engineers and data scientists work in different tooling layers.

#### PostgreSQL Table Architecture

The V2 pipeline builds 10 analytical tables in the `tt_project` schema, all derived from untouched source tables:

```
cohort23 → cohort_analytics
                ↓
    ┌───────────┬──────────┬──────────┬─────────────┬──────────────┐
session_agg  user_profile  trip_agg  trip_cx_agg  user_loyalty
    └───────────┴──────────┴──────────┴─────────────┴──────────────┘
                ↓
          user_features (109 cols)
                ↓
    user_features_transformed (160 cols — ML checkpoint)
                ↓
          perk_assignments (final deliverable)

```

---

### Key Technical Decisions

**Why V2 was a full rebuild (not a patch):** Six data quality issues discovered in V1 EDA required architectural fixes rather than patches — including discount rates &gt;1.0 from session-level double-counting, 1,336 pre-cohort sessions incorrectly included, and session\_duration\_sec only populated for flight sessions.

**Why rule-based assignment instead of ML-only:** K-Means cluster segment names were assigned post-hoc and several were found to be misleading on audit. Rule-based logic built independently from raw `user_features` fields converged on the same user populations as ML clustering — validating both approaches simultaneously and producing a more transparent, auditable assignment system.

**Why lifecycle gating:** Users with fewer than 3 completed trips show high statistical noise in behavioral metrics (single-trip cancel rate = 0.61 vs 3-trip rate = 0.31). The "three is a trend" principle prevents single-event noise from driving long-term perk assignments.

---

### Dependencies

```
pandas>=1.5.0
numpy<2.0
scikit-learn>=1.2.0
sqlalchemy>=1.4.0
psycopg2-binary>=2.9.0
python-dotenv>=1.0.0
matplotlib>=3.6.0
seaborn>=0.12.0
jupyter>=1.0.0
torch>=2.0.0

```

---

### Notes

- All date calculations are anchored to **August 19, 2024** (last recorded travel date in dataset). No current-date references are used — ensures full reproducibility regardless of when the pipeline is run.
- `random_state=53` used for all KMeans models throughout.
- The `.env` file contains only placeholder values. Real PostgreSQL connection details must be supplied locally and must never be committed to version control.
- Video presentation available at: [TravelTide presentation](https://youtu.be/mC52mT-WfxE) \[https://youtu.be/mC52mT-WfxE](https://youtu.be/mC52mT-WfxE)
    - (see docs/presentation\_video.md)

---

*Masterschool Data Science Foundations Mastery Project | April 2026*
