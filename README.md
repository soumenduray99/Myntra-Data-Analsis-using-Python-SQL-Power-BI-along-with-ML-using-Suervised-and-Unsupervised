# Myntra-Data-Analsis-using-Python-SQL-Power-BI-along-with-ML-using-Suervised-and-Unsupervised

🎯 Objective:
 To develop a data-driven system for Myntra that predicts optimal delivery partners, segments customers, and visualizes key sales and return metrics through an interactive Streamlit dashboard, enhancing operational efficiency and strategic decision-making.

❗ Problem Statement:
Myntra faces challenges in:
🚚 Optimally assigning delivery partners, leading to delays and customer dissatisfaction.
🧑‍🤝‍🧑 Understanding diverse customer behaviors, which hinders targeted marketing and personalized service.
🔄 High return rates in specific categories (especially fashion), impacting revenue.
📉 Lack of centralized insights across orders, returns, product performance, and customer trends for strategic decision-making.

✅ 1. Action
🛠️ Developed a complete Myntra Data Analysis & Delivery Partner Prediction System using Python, SQL, MySQL, Power BI, and Streamlit.
🗃️ Integrated data from 7 MySQL tables: Customer, Product, Orders, Ratings, Transactions, Return_Refund, Delivery.
🤖 Built two ML models:
Delivery Partner Prediction with XGBoost, KNN Imputation, Label Encoding, SMOTETomek, and Scaling.
Customer Segmentation with K-Means Clustering, PCA, and IQR for outlier removal.
📊 Designed interactive dashboards for sales, returns, product performance, and customer behavior analysis with real-time & batch ML predictions.

🌐 2. Streamlit Explanation
🧭 11 interactive tabs for end-to-end analytics and prediction:
🔍 Model_Prediction & Model_Prediction_via_tab – Manual & CSV-based delivery partner prediction.
👥 Customer Dashboard – Visualize sales, AOV, and trends across city tiers.
📦 Product Dashboard – Track ratings, sales volume, and delivery issues by brand/category.
🔁 Product Return Dashboard – Analyze returns, revenue loss, and demographic patterns.
🧬 Customer_Analysis_Prediction & Customer Analysis Main – Cluster visualization with PCA.
📂 Original Data Tab – Access raw SQL tables.
📈 Visuals via Plotly: Bar, Line, Pie, Funnel, Scatter, Geo maps.
🧰 Enhanced UX with CSV export, tooltips, and dynamic filters.

🎯 3. Outcome
🚚 Boosted delivery efficiency by recommending optimal delivery partners per order.
👤 Segmented customers to identify high-value, loyal, and high-risk groups.
📉 Revealed return trends – Fashion has high return rates, mainly due to size issues.
📦 Sales & Product Insights:
🔝 Peak order months and top-performing states/products identified.
👗 Fashion and 📱 Electronics lead in sales; Electronics has fewer returns.

🧑‍🤝‍🧑 Customer Insights:
🧑 Age group 25–35 is the core demographic.
⭐ Most users give 4–5 star ratings.
🏙️ Major demand from Tier-1 cities and metros.
