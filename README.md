# Supplyflow-analytics
End-to-end supply chain analytics pipeline analyzing rows of procurement and shipment data across suppliers using MySQL and Power BI

Project Overview
An end-to-end supply chain analytics pipeline simulating a real-world procurement and logistics intelligence system for SupplyFlow Analytics, a fictional supply chain company operating across 5 Indian cities. This project analyzes supplier performance, shipment reliability, warehouse utilization, and inventory health across 300 suppliers and 15,000 purchase orders.

Problem Statement
SupplyFlow Analytics needs to identify supply chain bottlenecks, evaluate supplier reliability, optimize transport costs, and flag critical inventory shortages across 20 warehouses. As the data analyst, the goal is to build a complete analytics pipeline delivering actionable operational insights.

Architecture
Excel (Data Generation & Cleaning)
        ↓
MySQL Workbench (Schema Design + SQL Analysis)
        ↓
Power BI (Interactive Dashboard)
        ↓
GitHub (Documentation + Deployment)

Dataset
Table                    Rows                       Description
suppliers                300                        Supplier type, city, rating, payment terms
warehouses               205                        cities, capacity, utilization %
products                 5005                       categories, unit cost, lead time, weight
purchase_orders          15,000                     Orders with status, priority, total cost
shipments                15,000                     Carrier, transport mode, delay days, cost
inventory                600                        Stock levels, reorder points, unit value
Total                    31,420

Tools Used

Excel — Data generation and cleaning
MySQL + MySQL Workbench — Relational database design and SQL analysis
Power BI + DAX — Interactive dashboard
GitHub — Version control and documentation

Key KPIs

Overall order delivery rate: 49.81%
Cancellation rate: 16.77% (₹3,259 Cr in lost order value)
Top supplier reliability score: 76.32 (Tandon Supply Co)
Best carrier on-time rate: 35.92% (DTDC)
Critical warehouse utilization: 3 warehouses above 90%
Air vs Sea cost difference: 15x (₹45/kg vs ₹3/kg)

SQL Techniques Used
Technique                                      Query                     
Window Function in GROUP BY              Order status distribution with %
JOIN, AVG, CASE WHEN                     Delay analysis by transport mode
Multi-table JOIN, delivery rate          Supplier performance ranking
CTE, composite weighted scoring          Supplier reliability score
LEFT JOIN, utilization calculation       Warehouse capacity analysis
CTE + RANK() + PARTITION BY              Top suppliers per product category
CTE + LAG() Window Function              Monthly procurement trend
DATEDIFF, CURDATE, subquery              Inventory reorder alerts
SQL VIEW                                 Shipment cost analysis


Key Findings

1. Only 49.81% of orders delivered — half of all procurement orders are pending, in transit or cancelled
2. Supplier rating doesn't predict delivery rate — composite scoring reveals more accurate supplier evaluation
3. DTDC is best value carrier — highest on-time rate (35.92%) at moderate cost
4. BlueDart is worst value — premium priced but lowest on-time performance
5. 3 warehouses at critical capacity (90%+) while 5 are below 50% utilization — redistribution opportunity
6. Sea transport is 15x cheaper than Air with comparable delay rates — cost optimization opportunity

Dashboard Pages

Executive Summary — Order status, monthly procurement value, transport delay analysis
Supplier Performance — Reliability scores, delivery rates by city, top suppliers by category
Shipment & Delivery Analysis — Carrier cost vs reliability, cost per kg, MoM procurement growth
Inventory & Warehouse Health — Warehouse utilization, stock alerts, reorder cost by category

Folder Structure
supplyflow-analytics/
├── data/
│   ├── raw/
│   │   ├── suppliers.csv
│   │   ├── warehouses.csv
│   │   ├── products.csv
│   │   ├── purchase_orders.csv
│   │   ├── shipments.csv
│   │   └── inventory.csv
│   └── cleaned/
│       ├── suppliers_cleaned.csv
│       ├── warehouses_cleaned.csv
│       ├── products_cleaned.csv
│       ├── purchase_orders_cleaned.csv
│       ├── shipments_cleaned.csv
│       ├── inventory_cleaned.csv
│       └── cleaning_log_supplyflow.xlsx
├── sql/
│   ├── schema/
│   │   ├── insert_suppliers.sql
│   │   ├── insert_warehouses.sql
│   │   ├── insert_products.sql
│   │   ├── insert_purchase_orders.sql
│   │   ├── insert_shipments.sql
│   │   └── insert_inventory.sql
│   └── analysis/
│       └── supplyflow_analysis.sql
├── dashboard/
│   └── SupplyFlow_Analytics.pbix
├── documentation/
│   └── SupplyFlow_Dashboard_Preview.pdf
└── README.md
How to Run

Clone this repository
Open MySQL Workbench and create database: CREATE DATABASE supplyflow;
Run SQL scripts in order: suppliers → warehouses → products → purchase_orders → shipments → inventory
Open supplyflow_analysis.sql to run all analysis queries
Open SupplyFlow_Analytics.pbix in Power BI Desktop

Author
Smiraj Ramekar
GitHub: https://github.com/smirajramekar
