# Customer-Retention-RFM

# 📊 Customer Retention & Revenue Intelligence Dashboard

### 🔍 Customer Analytics using MySQL, Power BI & DAX

---

## 🚀 Project Overview

This project analyzes **customer behavior, retention patterns, and revenue performance** using an e-commerce dataset.

The goal is to:

* Identify high-value customers
* Understand repeat purchase behavior
* Analyze churn risk
* Track cohort-based retention

---

## 🧰 Tech Stack

* 🗄️ **MySQL** → Data extraction & cohort/RFM analysis
* 📊 **Power BI** → Dashboard & visualization
* ⚡ **DAX** → Measures & calculated metrics
* 📁 **CSV Dataset** → Raw data

---

## 📊 Dashboard Pages

### 1️⃣ Executive Overview

<img width="1755" height="1241" alt="Cohort-RFM-Analysis_page-0001" src="https://github.com/user-attachments/assets/2381fcaa-d545-4583-8e20-bba8f70cb4d4" />

* Revenue trend analysis
* Customer & order KPIs
* Product/category performance
* Return rate insights

---

### 2️⃣ RFM Analysis

<img width="1755" height="1241" alt="Cohort-RFM-Analysis_page-0002" src="https://github.com/user-attachments/assets/44a0711a-f4a7-4694-b30e-f58d55a9363c" />


* Customer segmentation (Champions, At Risk, etc.)
* Revenue contribution by segment
* Repeat behavior insights
* Customer value distribution (scatter plot)

---

### 3️⃣ Cohort Analysis

<img width="1755" height="1241" alt="Cohort-RFM-Analysis_page-0003" src="https://github.com/user-attachments/assets/a9421648-6d19-49a4-9fa0-4809abb4b00a" />


* Customer retention heatmap
* Cohort-based lifecycle tracking
* Retention trend over time

---

## 🧠 Key Insights

* 📉 Retention drops significantly after the first purchase
* 💰 Champions contribute the majority of revenue
* ⚠️ At-risk customers show high past value but low recent activity
* 🔁 Repeat rate indicates moderate customer loyalty

---

## 🗄️ MySQL Analysis

### 🔹 Cohort Analysis

```sql
WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(STR_TO_DATE(order_date, '%Y-%m-%d')) AS first_order_date
    FROM sales
    GROUP BY customer_id
),

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

SELECT 
    cohort_month,
    month_index,
    COUNT(DISTINCT customer_id) AS customers
FROM cohort_index
GROUP BY cohort_month, month_index
ORDER BY cohort_month, month_index;
```

---

### 🔹 RFM Analysis

```sql
SELECT 
    customer_id,
    DATEDIFF(CURDATE(), MAX(order_date)) AS recency,
    COUNT(DISTINCT order_id) AS frequency,
    SUM(revenue) AS monetary
FROM sales
GROUP BY customer_id;
```

---

## ⚡ Power BI DAX

### 🔹 Core Measures

```DAX
Total Revenue = SUM(sales[revenue])
Total Customers = DISTINCTCOUNT(sales[customer_id])
Total Orders = DISTINCTCOUNT(sales[order_id])
AOV = DIVIDE([Total Revenue], [Total Orders])
```

---

### 🔹 RFM Metrics

```DAX
Monetary = SUM(sales[revenue])

Recency = 
DATEDIFF(MAX(sales[order_date]), TODAY(), DAY)

Repeat Customers = 
CALCULATE(
    DISTINCTCOUNT(sales[customer_id]),
    FILTER(
        VALUES(sales[customer_id]),
        CALCULATE(DISTINCTCOUNT(sales[order_id])) > 1
    )
)
```

---

### 🔹 Cohort Metrics

```DAX
Retention % = 
VAR CohortSize =
    CALCULATE(
        DISTINCTCOUNT(sales[customer_id]),
        sales[Cohort Index] = 0
    )
RETURN
DIVIDE(
    DISTINCTCOUNT(sales[customer_id]),
    CohortSize
)
```
## 💼 Business Impact

* Improved understanding of **customer lifecycle & retention**
* Identified **high-value customer segments**
* Enabled **data-driven marketing strategies**
* Highlighted **churn risks and revenue opportunities**

---

## 🚀 Conclusion

This project demonstrates how combining **SQL + Power BI + DAX** can transform raw data into meaningful insights for business decision-making.

---

## ⭐ If you like this project

Give it a ⭐ on GitHub and feel free to connect!
