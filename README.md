# 🛍️ Myntra Data Analysis & Delivery Partner Prediction System

## 🎯 Objective
To develop a data-driven system for **Myntra** that:
- Predicts optimal delivery partners
- Segments customers for targeted marketing
- Visualizes key sales and return metrics through an interactive **Streamlit dashboard**

This system aims to enhance **operational efficiency** and **strategic decision-making**.

---

## ❗ Problem Statement

Myntra faces challenges in:

- 🚚 Inefficient delivery partner assignment, leading to delays and poor customer experience  
- 🧑‍🤝‍🧑 Limited understanding of diverse customer behaviors, impacting personalization and marketing  
- 🔄 High return rates, especially in the fashion category, affecting revenue  
- 📉 No centralized view of sales, returns, product, and customer data for decision-making  

---

## ✅ Action Taken

### 🛠️ System Development
- Built using **Python, SQL, MySQL, Power BI**, and **Streamlit**
- Integrated and processed data from **7 MySQL tables**:  
  `Customer`, `Product`, `Orders`, `Ratings`, `Transactions`, `Return_Refund`, `Delivery`

### 🤖 Machine Learning Models
1. **Delivery Partner Prediction**
   - Model: XGBoost  
   - Techniques: KNN Imputation, Label Encoding, SMOTETomek, MinMax Scaling  
2. **Customer Segmentation**
   - Model: K-Means Clustering with PCA  
   - Outlier removal using IQR  

### 📊 Dashboard & Visualization
- Developed interactive dashboards in **Power BI** and **Streamlit**
- Real-time and batch ML predictions
- Dashboards cover:
  - Sales performance
  - Product trends
  - Return patterns
  - Customer insights

---

## 🌐 Streamlit Application Overview

### 🔢 Interactive Tabs (11 total):
- **Model_Prediction** & **Model_Prediction_via_tab** – Delivery partner prediction (manual/CSV input)
- **Customer Dashboard** – Sales, AOV, trends by city/state
- **Product Dashboard** – Brand/category-wise ratings, sales, and delivery issues
- **Product Return Dashboard** – Return rates, revenue loss, patterns by gender/category
- **Customer_Analysis_Prediction** & **Customer Analysis Main** – Clustering results with PCA visuals
- **Original Data Tab** – Raw SQL data access

### 📈 Visualizations & UX:
- Built with **Plotly**: Bar, Line, Pie, Funnel, Scatter, Geo Maps  
- Enhanced UX with:
  - CSV Export
  - Tooltips
  - Dynamic filters  

---

## 🎯 Outcome

### 🚚 Delivery Optimization
- Recommended optimal delivery partners per order  
- Improved logistics efficiency and reduced delays  

### 👥 Customer Segmentation
- Identified high-value, loyal, and at-risk customer groups  
- Enabled targeted marketing and engagement  

### 🔁 Return Analysis
- Highlighted fashion as a high-return category  
- Main reasons: size issues, product mismatch  
- Suggested improvements in size guides and descriptions  

### 📦 Sales & Product Insights
- Identified peak order months and top-performing products/states  
- Electronics and Fashion lead sales  
- Electronics have lower return rates, indicating quality or necessity-driven purchases  

### 🧑‍🤝‍🧑 Customer Insights
- Core age group: **25–35 years**  
- Majority ratings: **4–5 stars**, indicating satisfaction  
- Strong demand from **Tier-1 cities and metros**  

---

## 📌 Tech Stack
- **Languages**: Python, SQL  
- **Tools**: MySQL, Power BI, Streamlit  
- **Libraries**: XGBoost, scikit-learn, Plotly, pandas, NumPy  



