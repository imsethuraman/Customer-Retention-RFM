-- =========================================================
USE shopify_sales;
-- =========================================================
-- TABLE STRUCTURE CHECK
-- =========================================================
DESCRIBE sales;

-- Total number of records
SELECT COUNT(*) AS total_rows 
FROM sales;

-- Preview sample data
SELECT * 
FROM sales 
LIMIT 5;

-- =========================================================
-- CHECK DATE RANGE (DATA UNDERSTANDING)
-- =========================================================
SELECT 
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date
FROM sales;


-- =========================================================
-- COHORT ANALYSIS (CUSTOMER RETENTION)
-- =========================================================

-- Step 1: Identify each customer's first purchase date
WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(STR_TO_DATE(order_date, '%Y-%m-%d')) AS first_order_date
    FROM sales
    GROUP BY customer_id
),

-- Step 2: Assign cohort month and order month
cohort_data AS (
    SELECT 
        s.customer_id,
        STR_TO_DATE(s.order_date, '%Y-%m-%d') AS order_date,
        DATE_FORMAT(f.first_order_date, '%Y-%m') AS cohort_month,
        DATE_FORMAT(STR_TO_DATE(s.order_date, '%Y-%m-%d'), '%Y-%m') AS order_month
    FROM sales s
    JOIN first_purchase f 
        ON s.customer_id = f.customer_id
),

-- Step 3: Calculate months since first purchase
cohort_index AS (
    SELECT 
        customer_id,
        cohort_month,
        order_month,
        PERIOD_DIFF(
            DATE_FORMAT(order_month, '%Y%m'),
            DATE_FORMAT(cohort_month, '%Y%m')
        ) AS month_index
    FROM cohort_data
)

-- Step 4: Build retention table
SELECT 
    cohort_month,
    month_index,
    COUNT(DISTINCT customer_id) AS customers
FROM cohort_index
GROUP BY cohort_month, month_index
ORDER BY cohort_month, month_index;


-- =========================================================
-- RFM ANALYSIS (RECENCY, FREQUENCY, MONETARY)
-- =========================================================

-- Step 1: Calculate base RFM metrics
SELECT 
    customer_id,

    -- Customer lifetime (days between first & last purchase)
    DATEDIFF(
        MAX(STR_TO_DATE(order_date, '%Y-%m-%d')),
        MIN(STR_TO_DATE(order_date, '%Y-%m-%d'))
    ) AS customer_lifetime_days,

    -- Recency (days since last purchase)
    DATEDIFF(
        CURDATE(),
        MAX(STR_TO_DATE(order_date, '%Y-%m-%d'))
    ) AS recency,

    -- Frequency (total unique orders)
    COUNT(DISTINCT order_id) AS frequency,

    -- Monetary value (total revenue)
    SUM(revenue) AS monetary

FROM sales
GROUP BY customer_id
ORDER BY monetary DESC;


-- =========================================================
-- RFM SCORING USING NTILE
-- =========================================================

WITH rfm_base AS (
    SELECT 
        customer_id,

        -- Recency calculation
        DATEDIFF(
            CURDATE(),
            MAX(STR_TO_DATE(order_date, '%Y-%m-%d'))
        ) AS recency,

        -- Frequency calculation
        COUNT(DISTINCT order_id) AS frequency,

        -- Monetary calculation
        SUM(revenue) AS monetary

    FROM sales
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT *,
        -- Recency: lower is better → DESC
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,

        -- Frequency: higher is better
        NTILE(5) OVER (ORDER BY frequency) AS f_score,

        -- Monetary: higher is better
        NTILE(5) OVER (ORDER BY monetary) AS m_score

    FROM rfm_base
)

-- Step 2: Combine RFM score
SELECT *,
       CONCAT(r_score, f_score, m_score) AS rfm_score
FROM rfm_scores;


-- =========================================================
-- CUSTOMER SEGMENTATION BASED ON RFM
-- =========================================================
-- =========================================================
DROP TABLE IF EXISTS rfm_scores;

-- =========================================================
-- CREATE RFM SCORES TABLE
-- =========================================================
CREATE TABLE rfm_scores AS

WITH rfm_base AS (
    SELECT 
        customer_id,

        -- Recency (days since last purchase)
        DATEDIFF(
            CURDATE(),
            MAX(STR_TO_DATE(order_date, '%Y-%m-%d'))
        ) AS recency,

        -- Frequency (number of unique orders)
        COUNT(DISTINCT order_id) AS frequency,

        -- Monetary (total revenue)
        SUM(revenue) AS monetary

    FROM sales
    GROUP BY customer_id
)

SELECT 
    customer_id,
    recency,
    frequency,
    monetary,

    -- RFM Scores (1–5 buckets)
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score,

    -- Combined RFM Score
    CONCAT(
        NTILE(5) OVER (ORDER BY recency DESC),
        NTILE(5) OVER (ORDER BY frequency),
        NTILE(5) OVER (ORDER BY monetary)
    ) AS rfm_score

FROM rfm_base;


-- =========================================================
-- ADD SEGMENT COLUMN
-- =========================================================
ALTER TABLE rfm_scores 
ADD COLUMN segment VARCHAR(50);

-- =========================================================
-- UPDATE SEGMENTS
-- =========================================================
UPDATE rfm_scores
SET segment = CASE 
    WHEN r_score = 5 AND f_score = 5 AND m_score = 5 THEN 'Champions'
    WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal Customers'
    WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
    WHEN r_score = 1 THEN 'Lost Customers'
    ELSE 'Others'
END;

-- =========================================================
-- FINAL OUTPUT
-- =========================================================
SELECT * 
FROM rfm_scores
ORDER BY monetary DESC;