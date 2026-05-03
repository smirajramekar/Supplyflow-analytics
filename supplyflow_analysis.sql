-- ============================================================
-- SupplyFlow Analytics — Supply Chain Data Analysis
-- Author: Smiraj
-- Database: supplyflow
-- Description: End-to-end SQL analysis of supply chain data
--              covering 300 suppliers, 15,000 orders across
--              5 cities and 6 product categories
-- ============================================================

USE supplyflow;

-- ============================================================
-- QUERY 1 — Order Status Distribution
-- Technique: GROUP BY, COUNT, Window Function in GROUP BY
-- Question: What percentage of orders are delivered vs pending?
-- ============================================================

SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(SUM(total_cost), 2) AS total_value
FROM purchase_orders
GROUP BY order_status
ORDER BY total_orders DESC;

/*
INSIGHT: Only 49.81% of purchase orders have been delivered.
The cancellation rate of 16.77% represents significant lost order value 
and warrants immediate investigation into supplier reliability and 
procurement processes.
*/


-- ============================================================
-- QUERY 2 — Average Delay by Transport Mode
-- Technique: JOIN, AVG, CASE WHEN inside SUM, WHERE filter
-- Question: Which transport mode is most reliable?
-- ============================================================

SELECT 
    s.transport_mode,
    COUNT(*) AS total_shipments,
    ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
    SUM(CASE WHEN s.delay_days = 0 THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS delayed,
    ROUND(SUM(CASE WHEN s.delay_days = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_rate_pct
FROM shipments s
WHERE s.shipment_status = 'Delivered'
GROUP BY s.transport_mode
ORDER BY avg_delay_days ASC;

/*
INSIGHT: Rail transport has the lowest average delay at 6.15 days,
marginally outperforming Air despite being significantly cheaper.
Road transport has the highest average delay (6.42 days) while handling 
the most shipments. Overall on-time rates are low across all modes,
suggesting systemic supplier-side delays rather than transport issues.
*/


-- ============================================================
-- QUERY 3 — Supplier Performance Ranking
-- Technique: JOIN, GROUP BY, delivery rate calculation
-- Question: Which suppliers are most reliable?
-- ============================================================

SELECT 
    s.supplier_id,
    s.supplier_name,
    s.city,
    s.rating,
    COUNT(po.order_id) AS total_orders,
    ROUND(SUM(po.total_cost), 2) AS total_order_value,
    SUM(CASE WHEN po.order_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN po.order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(SUM(CASE WHEN po.order_status = 'Delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(po.order_id), 2) AS delivery_rate_pct
FROM suppliers s
JOIN purchase_orders po ON s.supplier_id = po.supplier_id
GROUP BY s.supplier_id, s.supplier_name, s.city, s.rating
ORDER BY delivery_rate_pct DESC
LIMIT 15;

/*
INSIGHT: Bansal Trading leads with 69.05% delivery rate despite a 3.8 rating,
while Singhal Industries has the highest rating (4.9) but ranks 7th in delivery.
This disconnect suggests ratings are based on factors other than delivery 
reliability — a performance-based rating system should be implemented.
*/


-- ============================================================
-- QUERY 4 — On Time Delivery Rate by Carrier
-- Technique: JOIN, CASE WHEN, near on-time threshold
-- Question: Which carrier delivers fastest at lowest cost?
-- ============================================================

SELECT 
    s.carrier,
    COUNT(*) AS total_shipments,
    ROUND(AVG(s.shipment_cost), 2) AS avg_shipment_cost,
    ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
    SUM(CASE WHEN s.delay_days <= 2 THEN 1 ELSE 0 END) AS near_on_time,
    ROUND(SUM(CASE WHEN s.delay_days <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS near_on_time_pct
FROM shipments s
WHERE s.shipment_status = 'Delivered'
GROUP BY s.carrier
ORDER BY near_on_time_pct DESC;

/*
INSIGHT: DTDC leads with 35.92% near on-time rate and moderate cost —
making it the best value carrier. BlueDart, despite premium pricing,
delivers the worst on-time performance — a poor value proposition that 
should be renegotiated or replaced.
*/


-- ============================================================
-- QUERY 5 — Supplier Reliability Score
-- Technique: CTE, composite weighted scoring, CASE WHEN
-- Question: Who are our truly reliable suppliers across multiple factors?
-- ============================================================

WITH supplier_stats AS (
    SELECT 
        s.supplier_id,
        s.supplier_name,
        s.city,
        s.rating AS base_rating,
        COUNT(po.order_id) AS total_orders,
        SUM(CASE WHEN po.order_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
        SUM(CASE WHEN po.order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
        ROUND(AVG(sh.delay_days), 2) AS avg_delay,
        ROUND(SUM(po.total_cost), 2) AS total_value
    FROM suppliers s
    JOIN purchase_orders po ON s.supplier_id = po.supplier_id
    JOIN shipments sh ON po.order_id = sh.order_id
    GROUP BY s.supplier_id, s.supplier_name, s.city, s.rating
)
SELECT 
    supplier_id,
    supplier_name,
    city,
    base_rating,
    total_orders,
    delivered,
    cancelled,
    avg_delay,
    total_value,
    ROUND(
        (delivered * 100.0 / total_orders) * 0.5 +
        (base_rating / 5.0 * 100) * 0.3 +
        (CASE WHEN avg_delay <= 3 THEN 100
              WHEN avg_delay <= 6 THEN 70
              WHEN avg_delay <= 10 THEN 40
              ELSE 20 END) * 0.2, 2
    ) AS reliability_score,
    CASE
        WHEN ROUND(
            (delivered * 100.0 / total_orders) * 0.5 +
            (base_rating / 5.0 * 100) * 0.3 +
            (CASE WHEN avg_delay <= 3 THEN 100
                  WHEN avg_delay <= 6 THEN 70
                  WHEN avg_delay <= 10 THEN 40
                  ELSE 20 END) * 0.2, 2) >= 70 THEN 'Preferred Supplier'
        WHEN ROUND(
            (delivered * 100.0 / total_orders) * 0.5 +
            (base_rating / 5.0 * 100) * 0.3 +
            (CASE WHEN avg_delay <= 3 THEN 100
                  WHEN avg_delay <= 6 THEN 70
                  WHEN avg_delay <= 10 THEN 40
                  ELSE 20 END) * 0.2, 2) >= 50 THEN 'Acceptable Supplier'
        ELSE 'At Risk Supplier'
    END AS supplier_grade
FROM supplier_stats
ORDER BY reliability_score DESC
LIMIT 15;

/*
INSIGHT: Tandon Supply Co leads with reliability score of 76.32.
Bansal Trading scores 71.32 despite a low base rating of 3.8 — 
its strong delivery performance compensates for the poor rating.
Multi-factor scoring is more accurate than single-metric evaluation.
*/


-- ============================================================
-- QUERY 6 — Warehouse Utilization Analysis
-- Technique: LEFT JOIN, calculated fields, CASE WHEN
-- Question: Which warehouses are dangerously full?
-- ============================================================

SELECT 
    w.warehouse_id,
    w.warehouse_name,
    w.city,
    w.capacity_units,
    w.current_utilization_pct,
    ROUND(w.capacity_units * w.current_utilization_pct / 100) AS units_used,
    ROUND(w.capacity_units * (1 - w.current_utilization_pct / 100)) AS units_available,
    COUNT(i.inventory_id) AS products_stored,
    ROUND(SUM(i.stock_quantity * i.unit_value), 2) AS inventory_value,
    CASE
        WHEN w.current_utilization_pct >= 90 THEN 'Critical'
        WHEN w.current_utilization_pct >= 75 THEN 'High'
        WHEN w.current_utilization_pct >= 50 THEN 'Moderate'
        ELSE 'Low'
    END AS utilization_status
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name, w.city, 
         w.capacity_units, w.current_utilization_pct
ORDER BY w.current_utilization_pct DESC;

/*
INSIGHT: 3 warehouses are at Critical utilization above 90%.
Meanwhile 5 warehouses are underutilized below 50%, suggesting poor 
inventory distribution. Redistributing stock from critical to low 
utilization warehouses could resolve capacity issues without new investment.
*/


-- ============================================================
-- QUERY 7 — Top Suppliers by Product Category
-- Technique: CTE + RANK() Window Function + PARTITION BY
-- Question: Who are the top 3 suppliers in each product category?
-- ============================================================

WITH supplier_category AS (
    SELECT 
        s.supplier_id,
        s.supplier_name,
        p.category,
        COUNT(po.order_id) AS total_orders,
        ROUND(SUM(po.total_cost), 2) AS total_value,
        ROUND(AVG(sh.delay_days), 2) AS avg_delay
    FROM suppliers s
    JOIN purchase_orders po ON s.supplier_id = po.supplier_id
    JOIN products p ON po.product_id = p.product_id
    JOIN shipments sh ON po.order_id = sh.order_id
    GROUP BY s.supplier_id, s.supplier_name, p.category
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY category ORDER BY total_value DESC) AS category_rank
    FROM supplier_category
)
SELECT 
    category,
    supplier_id,
    supplier_name,
    total_orders,
    total_value,
    avg_delay,
    category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY category, category_rank;

/*
INSIGHT: Raw Materials has the highest order volumes with Walia Supply Co 
leading. Aggarwal Logistics (Raw Materials, avg delay 1.43 days) is the 
fastest supplier across all categories — ideal for urgent procurement needs.
*/


-- ============================================================
-- QUERY 8 — Monthly Order Value Trend Using LAG()
-- Technique: CTE + LAG() Window Function, DATE functions
-- Question: Is our procurement spend growing month over month?
-- ============================================================

WITH monthly_orders AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        DATE_FORMAT(order_date, '%Y-%m') AS yearmonth,
        COUNT(order_id) AS total_orders,
        ROUND(SUM(total_cost), 2) AS monthly_value
    FROM purchase_orders
    WHERE order_status != 'Cancelled'
    GROUP BY order_year, order_month, yearmonth
)
SELECT 
    yearmonth,
    total_orders,
    monthly_value,
    LAG(monthly_value) OVER (ORDER BY order_year, order_month) AS prev_month_value,
    ROUND(
        (monthly_value - LAG(monthly_value) OVER (ORDER BY order_year, order_month))
        * 100.0 / LAG(monthly_value) OVER (ORDER BY order_year, order_month), 2
    ) AS mom_growth_pct
FROM monthly_orders
ORDER BY order_year, order_month;

/*
INSIGHT: Monthly procurement value fluctuates between 3,808 Cr and 4,911 Cr
with no consistent growth trend. June 2023 saw the biggest spike at +27.20%.
The volatility suggests reactive rather than planned procurement — a structured 
annual procurement calendar would stabilize spending.
*/


-- ============================================================
-- QUERY 9 — Inventory Reorder Alerts
-- Technique: Multi-table JOIN, DATEDIFF, CURDATE, WHERE filter
-- Question: Which products need immediate restocking?
-- ============================================================

SELECT 
    w.city,
    w.warehouse_name,
    p.product_name,
    p.category,
    i.stock_quantity,
    i.reorder_level,
    i.last_restocked,
    DATEDIFF(CURDATE(), i.last_restocked) AS days_since_restock,
    ROUND(i.stock_quantity * i.unit_value, 2) AS current_stock_value,
    CASE
        WHEN i.stock_quantity = 0 THEN 'Out of Stock'
        WHEN i.stock_quantity <= i.reorder_level * 0.5 THEN 'Critical'
        WHEN i.stock_quantity <= i.reorder_level THEN 'Low Stock'
        ELSE 'Adequate'
    END AS stock_alert,
    ROUND(p.unit_cost * i.reorder_level, 2) AS estimated_reorder_cost
FROM inventory i
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
JOIN products p ON i.product_id = p.product_id
WHERE i.stock_quantity <= i.reorder_level
ORDER BY i.stock_quantity ASC
LIMIT 15;

/*
INSIGHT: All 15 flagged items are Critical with some not restocked in over 
1,000 days. Ceramic Tile Type-P in Delhi has only 3 units against reorder 
level of 145 — 98% depletion. Immediate procurement budget of approximately 
5-6 Cr needed to address critical stockouts across multiple warehouses.
*/


-- ============================================================
-- QUERY 10 — Shipment Cost Analysis View
-- Technique: SQL VIEW, cost per kg calculation
-- Question: Which transport mode and carrier offers best value?
-- ============================================================

CREATE VIEW shipment_cost_analysis AS
SELECT 
    s.transport_mode,
    s.carrier,
    COUNT(*) AS total_shipments,
    ROUND(AVG(s.shipment_cost), 2) AS avg_cost,
    ROUND(MIN(s.shipment_cost), 2) AS min_cost,
    ROUND(MAX(s.shipment_cost), 2) AS max_cost,
    ROUND(SUM(s.shipment_cost), 2) AS total_cost,
    ROUND(AVG(s.weight_kg), 2) AS avg_weight_kg,
    ROUND(AVG(s.shipment_cost) / AVG(s.weight_kg), 2) AS cost_per_kg,
    ROUND(AVG(s.delay_days), 2) AS avg_delay
FROM shipments s
WHERE s.shipment_status = 'Delivered'
GROUP BY s.transport_mode, s.carrier
ORDER BY cost_per_kg DESC;

-- Query the view
SELECT * FROM shipment_cost_analysis;

/*
INSIGHT: Air transport costs 45x more per kg than Sea yet has similar 
delay rates — making Sea the most cost-efficient option for non-urgent 
shipments. BlueDart charges the most for Road (8.05/kg) with the worst 
delays — poorest value road carrier. Rivigo offers cheapest Sea transport 
(2.97/kg) — ideal for bulk low-urgency shipments.
*/


-- ============================================================
-- END OF ANALYSIS
-- Next Step: Migrate to Snowflake for cloud-based querying
-- ============================================================
