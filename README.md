# E-commerce Growth & Conversion Analysis

**MySQL · Marketing Analytics · Conversion Analysis**

I used SQL to analyze acquisition channels, website conversion, product performance, and repeat visits for Maven Fuzzy Factory, a simulated online retailer. The project explores how traffic and customer behavior can inform marketing, website, and product decisions.

## Dataset

The database contains **472,871 website sessions, 1,188,124 pageviews, and 32,313 orders** across six related tables: sessions, pageviews, orders, order items, products, and refunds.

The source data spans March 2012–March 2015. The queries in this project use selected business scenarios and time windows within 2012–2014.

## Selected findings

### 1. Conversion differed substantially by device

**Question:** How did desktop and mobile traffic perform within the same paid search campaign?

Scope: `gsearch` nonbrand sessions before May 11, 2012.

| Device | Sessions | Orders | Session-to-order conversion |
| --- | ---: | ---: | ---: |
| Desktop | 3,911 | 146 | 3.73% |
| Mobile | 2,492 | 24 | 0.96% |

**Business takeaway:** The conversion gap supports reviewing device-level bids and investigating the mobile purchase experience. Acquisition costs and order value would also be needed to determine the most profitable allocation.

### 2. The second billing-page version had a higher completion rate

**Question:** How did order conversion compare between the two billing-page versions?

Scope: sessions created September 10–November 9, 2012 that reached either billing page.

| Billing page | Sessions | Orders | Billing-to-order conversion |
| --- | ---: | ---: | ---: |
| `/billing` | 657 | 300 | 45.66% |
| `/billing-2` | 654 | 410 | 62.69% |

**Business takeaway:** The second version showed a **17.03 percentage-point higher observed conversion rate**. This makes it a candidate for further validation before a broader rollout; this SQL comparison does not establish statistical significance.

### 3. Repeat visits showed stronger conversion and revenue per session

**Question:** How did repeat sessions compare with first-time visits?

Scope: January 1–November 7, 2014, grouped by the dataset's repeat-session flag.

| Visit type | Sessions | Conversion rate | Revenue per session |
| --- | ---: | ---: | ---: |
| New | 149,787 | 6.80% | $4.34 |
| Repeat | 33,577 | 8.11% | $5.17 |

**Business takeaway:** Repeat sessions generated more revenue per visit and converted at a higher rate, suggesting an opportunity to test retention and re-engagement initiatives.

## Additional analysis in the SQL file

| Area | Analysis covered |
| --- | --- |
| Acquisition channels | Paid search, organic search, direct traffic, campaign trends, and device segmentation |
| Website performance | Landing-page bounce rates, page-level conversion funnels, and billing-page comparisons |
| Product performance | Sales and margin trends, product launches, cross-selling, average order value, and refund queries |
| Visitor behavior | Repeat-session frequency, time between visits, and new-versus-repeat performance |

## SQL techniques

- **Joins** to connect visits, pageviews, orders, and product-level records.
- **CTEs and temporary tables** to break multi-step analyses into manageable stages.
- **Conditional aggregation with `CASE WHEN`** to segment channels, devices, and funnel stages.
- **Session-level aggregation, date functions, and window functions** to examine conversion paths, trends, and event timing.

## Explore the code

The analysis is contained in **[Data Analysis.sql](Data%20Analysis.sql)**, with comments identifying each business question. It uses the `mavenfuzzyfactory` database and MySQL 8.0+ syntax. 
