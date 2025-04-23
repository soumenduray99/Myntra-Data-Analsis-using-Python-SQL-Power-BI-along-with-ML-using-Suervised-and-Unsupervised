import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import datetime as dt
import seaborn as sb
from sklearn.metrics import *
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import LabelEncoder
from itertools import product
from xgboost import XGBClassifier
import pickle
import streamlit as st
from imblearn.combine import SMOTETomek
import plotly.express as px
from sklearn.impute import KNNImputer
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
import pymysql as sql
import warnings
warnings.filterwarnings("ignore")


imp = KNNImputer(n_neighbors=7)

d=sql.connect(user='root',password='12345',host='localhost',database='Myntra_Ecommerce_Analysis')
cr=d.cursor()

# .\venv\Scripts\activate 
# python Model_design.py
# streamlit run Model_design.py

# EXTRACT tABLES FROM SQL
# Customer table
cst_i = "select * from customer"
cs1=cr.execute(cst_i)
c_i=[i for i in cr]
c_clm=[j[0] for j in cr.description]
c=pd.DataFrame(data=c_i,columns=c_clm)

# Product table
prd_i = "select * from product"
pr1=cr.execute(prd_i)
p_i=[i for i in cr]
p_clm=[j[0] for j in cr.description]
p=pd.DataFrame(data=p_i,columns=p_clm)

# Orders table
ord_i = "select * from orders"
or1=cr.execute(ord_i)
o_i=[i for i in cr]
o_clm=[j[0] for j in cr.description]
o=pd.DataFrame(data=o_i,columns=o_clm)
o['Order_Date']=pd.to_datetime(o['Order_Date'])

# Ratings table
rat_i = "select * from ratings"
rat1=cr.execute(rat_i)
rt_i=[i for i in cr]
rt_clm=[j[0] for j in cr.description]
rt=pd.DataFrame(data=rt_i,columns=rt_clm)

# Transaction table
tra_i = "select * from transactions"
tr1=cr.execute(tra_i)
tr_i=[i for i in cr]
tr_clm=[j[0] for j in cr.description]
tr=pd.DataFrame(data=tr_i,columns=tr_clm)

# Return Refund table
rtn_i = "select * from return_refund;"
rtn1=cr.execute(rtn_i)
rr_i=[i for i in cr]
rr_clm=[j[0] for j in cr.description]
rr=pd.DataFrame(data=rr_i,columns=rr_clm)

# Deliverytable
dev_i = "select * from delivery;"
dev1=cr.execute(dev_i)
dv_i=[i for i in cr]
dv_clm=[j[0] for j in cr.description]
dv=pd.DataFrame(data=dv_i,columns=dv_clm)


# SELECT NECESSARY FEATURE FROM EACH TABLE
# Customer
c_clm=['C_ID','Age','State','City']
c_fl=c[c_clm]

# Product
p_clm=['P_ID','P_Name','Price','Category','Company_Name','Gender']
p_fl=p[p_clm]

# Orders
o_clm=['Or_ID','C_ID','P_ID','DP_ID','Qty','Coupon','Discount','Order_Date','Order_Time']
o_fl=o[o_clm]
o_fl = o_fl.copy()  # Make an explicit copy to avoid SettingWithCopyWarning
o_fl.loc[:, 'Year'] = o_fl['Order_Date'].dt.year
o_fl.loc[:, 'Month'] = o_fl['Order_Date'].dt.month_name()
o_fl.loc[:, 'Day'] = o_fl['Order_Date'].dt.day_name()
o_fl.loc[:, 'Hour'] = o['Order_Time'].dt.components['hours']

# Delivery
dv_clm=['DP_ID','DP_name','Percent_Cut']
dv_fl=dv[dv_clm]

# Ratings
rt_clm=['Or_ID','Prod_Rating','Delivery_Service_Rating']
rt_fl=rt[rt_clm]

# Transaction
tr_clm=['Or_ID']
tr_fl=tr[tr_clm]

# Return_Refund
rr_clm=['RT_ID','Or_ID','Return_Refund']
rr_fl=rr[rr_clm]


#JOIN TABLES
po=pd.merge(o_fl,c_fl,on='C_ID',how='left')
pc=pd.merge(po,rt_fl,on='Or_ID',how='left')
ptd=pd.merge(pc,dv_fl,on='DP_ID',how='left')
prr=pd.merge(ptd,rr_fl,on='Or_ID',how='left')
pt=pd.merge(prr,tr_fl,on='Or_ID',how='left')

agg_ord=pt.groupby(['P_ID']).agg({
    'Or_ID':'count',
    'DP_name':lambda x: x.mode()[0],
    'RT_ID':'count',
    'Qty':'median',
    'Discount':'median',
    'Age':'median',
    'Year':lambda x: round(x.mode()[0]) ,
    'Month':lambda x: x.mode()[0],
    'Day':lambda x: x.mode()[0],
    'Hour':'median',
    'City':lambda x: x.mode()[0],
    'Prod_Rating':'median',
    'Delivery_Service_Rating':'median',
    'Percent_Cut':'mean'
}).reset_index()

fl_t=pd.merge(p_fl,agg_ord,on='P_ID',how='left')

df=pd.DataFrame(fl_t)

df.columns = ['P_ID', 'P_Name', 'Price', 'Category', 'Company Name', 'P_Gender',
              'Total_Customer','Delivery_Partner','Total_Return_Refund',
       'Qty', 'Discount',  'Age', 'Year', 'Month', 'Day', 'Hour',
       'City', 'Prod_Rating', 'Delivery/Service_Rating', 'Percent_Cut']

def null_val(df):
  n=df.isna().sum()
  nl=n[n>0].sort_values(ascending=False).reset_index()
  nl.columns=['Fet','Val']
  nl['Dtype']=[df[i].dtypes for i in nl['Fet']]
  nl['% Null']=round(nl['Val']/df.shape[0]*100,5)

  return nl
nvl=null_val(df)


nm_cl= nvl[nvl['Dtype']!='object']['Fet'].tolist()
for i in nm_cl:
  df[i]=imp.fit_transform(df[[i]])
  
df['Delivery_Partner']=df['Delivery_Partner'].fillna('Other Partners')
df['City']=df['City'].fillna('Other Cities')
ct_cl=['Month','Day' ]
for i in ct_cl:
  df[i] = df[i].fillna(df[i].mode()[0])
  
df['Hr_Prt']=np.where(df['Hour'].between(0,6),'Night',
                      np.where(df['Hour'].between(6,12),'Morning',
                      np.where(df['Hour'].between(12,17),'Afternoon','Evening')))

clm=['Total_Customer','Total_Return_Refund','Qty','Discount','Percent_Cut' ,'Age','Year','Hour' ]
for i in clm:
  df[i]=[ round(j) for j in df[i] ]
  
clm2=['Prod_Rating','Delivery/Service_Rating']
for i in clm2:
  df[i]=[ round(j,2) for j in df[i] ]
  
clm_f =  ['P_ID', 'P_Name',  'Category', 'Company Name', 'P_Gender', 'Total_Customer', 'Total_Return_Refund','Price', 
          'Qty', 'Discount', 'Age', 'Year', 'Month', 'Day', 'Hour','City', 'Prod_Rating', 'Delivery/Service_Rating', 
           'Percent_Cut','Hr_Prt','Delivery_Partner']

df_f=df[clm_f]
df_f2=df[clm_f]

# MODEL BUILDING
def model_gen(d_train,d_pred):
  cont=['Price', 'Total_Customer', 'Total_Return_Refund', 'Qty', 'Discount',
       'Age', 'Year', 'Hour',  'Prod_Rating',
       'Delivery/Service_Rating', 'Percent_Cut']
    
  for i in cont:
    q1=np.percentile(d_train[i],25)
    q3=np.percentile(d_train[i],75)
    iqr=q3-q1
    up=q3+1.5*iqr
    lw=q1-1.5*iqr
    d_train[i]=np.where(d_train[i]>up,up,d_train[i])
    d_train[i]=np.where(d_train[i]<lw,lw,d_train[i])
  
  for i in cont:
    q1=np.percentile(d_pred[i],25) 
    q3=np.percentile(d_pred[i],75) 
    iqr=q3-q1
    up=q3+1.5*iqr
    lw=q1-1.5*iqr
    d_pred[i]=np.where(d_pred[i]>up,up,d_pred[i])
    d_pred[i]=np.where(d_pred[i]<lw,lw,d_pred[i])
     
  d_train.drop(['P_ID','P_Name'],inplace=True,axis=1 )
  cl_le_tr=['Category','Company Name','Month','City','Delivery_Partner','P_Gender','Day','Hr_Prt']
  cl_le_pd=['Category','Company Name','Month','City','P_Gender','Day','Hr_Prt']
  le=LabelEncoder()
  for i in cl_le_tr:
    d_train[i]=le.fit_transform(d_train[i])
  for j in cl_le_pd:
    d_pred[j]=le.fit_transform(d_pred[j])
    
  df_dm=d_train.copy()
    
  x=df_dm.drop('Delivery_Partner',axis=1)
  y=df_dm['Delivery_Partner']
    
  ss=StandardScaler()
  xtrain_sm= pd.DataFrame(data=ss.fit_transform(x) , columns=x.columns)
  xtest_sm= pd.DataFrame(data=ss.transform(d_pred) , columns=d_pred.columns)
    
  smo=SMOTETomek(random_state=50)
  xtrain_s,ytrain_s=smo.fit_resample(xtrain_sm,y)
    
  xgb=XGBClassifier(eta=0.35,gamma=1.9,reg_alpha=0.6)
  xgb.fit(xtrain_s,ytrain_s)
    
  pred=xgb.predict(xtest_sm)
  return pred
  
  
# DATA GENERATION  
def data_gen(n):
    category=['Jeans','Blazer','Hoodie','Shirt','Dress','Skirt','Shorts','T-Shirt','Jacket','Sweater']
    company=['Puma','Gap','Reebok',"Levi's",'H&M','Zara','Pantaloons','Nike','Adidas','Uniqlo']
    p_gender=['Unisex', 'Men', 'Women']
    Total_Customer=list(range(1,25))
    Total_Return_Refund=list(range(0,25))
    Price=np.arange(10,1000,0.01)
    Qty=list(range(1,12))
    Discount=list(range(0,51))
    Age=list(range(18,80))
    Year=[2023, 2024,2025,2026,2027]
    Month=['August','April','December','November','January','May','February','June','September','October','July','March']
    Day=['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Friday', 'Thursday', 'Saturday']
    Hour=list(range(0,24))
    City=['Delhi','Other Cities','Kanpur','Chennai','Ghaziabad','Visakhapatnam','Pune','Ahmedabad','Mumbai','Thane','Indore',
          'Kolkata','Hyderabad','Bengaluru','Surat','Nagpur','Patna','Jaipur','Vadodara','Lucknow','Bhopal']
    Prod_Rating=np.arange(1,5,0.01)
    Delivery_Rating=np.arange(1,5,0.01)
    Percent_Cut=list(range(15,26))
    Hr_Prt=['Morning', 'Afternoon', 'Night', 'Evening']
    
    
    df=pd.DataFrame(index=[dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S") for i in range(n) ] )
    df['Category']=np.random.choice(category,size=n)
    df['Company Name']=np.random.choice(company,size=n)
    df['P_Gender']=np.random.choice(p_gender,size=n)
    df['Total_Customer']=np.random.choice(Total_Customer,size=n)
    df['Total_Return_Refund']=np.random.choice(Total_Return_Refund,size=n)
    df['Price']=np.random.choice(Price,size=n)
    df['Qty']=np.random.choice(Qty,size=n)
    df['Discount']=np.random.choice(Discount,size=n)
    df['Age']=np.random.choice(Age,size=n)
    df['Year']=np.random.choice(Year,size=n)
    df['Month']=np.random.choice(Month,size=n)
    df['Day']=np.random.choice(Day,size=n)
    df['Hour']=np.random.choice(Hour,size=n)
    df['City']=np.random.choice(City,size=n)
    df['Prod_Rating']=np.random.choice(Prod_Rating,size=n)
    df['Delivery/Service_Rating']=np.random.choice(Delivery_Rating,size=n)
    df['Percent_Cut']=np.random.choice(Percent_Cut,size=n)
    df['Hr_Prt']=np.where(df['Hour'].between(0,6),'Night',
                      np.where(df['Hour'].between(6,12),'Morning',
                      np.where(df['Hour'].between(12,17),'Afternoon','Evening')))
    
    return df
  


# STREAMLIT FOR APP BUILDING
st.set_page_config(layout="wide", page_title="Myntra  Analysis ")
st.image("myntra.png")
st.title("Myntra Delivery Partner Prediction Analysis")

    
tab1,tab2,tab3,tab4,tab5,tab6,tab7,tab8,tab9,tab10,tab11=st.tabs(['Description','Model_Prediction_via_options',
                                                                 'Model_Prediction_via_table','Sales Dashboard',
                                                                 'Customer Dashboard','Product Dashboard',
                                                                 'Product Return Dashboard','Product Delivery Analysis Main Data',
                                                                  'Customer_Analysis_Prediction_via_table',
                                                                  'Customer Analysis Main Data',
                                                                  'Original Data'])


# Model Prediction 
with tab2:
  st.subheader('Prediction using select options')
  category=st.selectbox('Category',['Jeans','Blazer','Hoodie','Shirt','Dress','Skirt','Shorts','T-Shirt','Jacket','Sweater'])
  company=st.selectbox('Company Name',['Puma','Gap','Reebok',"Levi's",'H&M','Zara','Pantaloons','Nike','Adidas','Uniqlo'])
  p_gender=st.selectbox('Product Gender',['Unisex', 'Men', 'Women'])
  Total_Customer=st.number_input('Total Customer',min_value=1,max_value=30)
  Total_Return_Refund= st.number_input('Total Return',min_value=0,max_value=25)
  Price=st.number_input('Price',min_value=10.00,max_value=1000.00,step=0.01)
  Qty=st.number_input("Quantity",min_value=1,max_value=12)
  Discount=st.number_input("Discount",min_value=0.0,max_value=51.0,step=0.5)
  Age=st.number_input("Age",min_value=18,max_value=80)
  Year= st.selectbox( "Year",[2024,2025,2026,2027])
  Month= st.selectbox("Month",['August','April','December','November','January','May','February','June',
                          'September','October','July','March'])
  Day=st.selectbox("Day Name",['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Friday', 'Thursday', 'Saturday'])
  Hour=st.number_input('Hour',min_value=0,max_value=24)
  City=st.selectbox('City',['Delhi','Other Cities','Kanpur','Chennai','Ghaziabad','Visakhapatnam','Pune',
                            'Ahmedabad','Mumbai','Thane','Indore','Kolkata','Hyderabad','Bengaluru','Surat',
                            'Nagpur','Patna','Jaipur','Vadodara','Lucknow','Bhopal'])
  Prod_Rating=st.number_input("Product Rating",min_value=1.00,max_value=5.00,step=0.01)
  Delivery_Rating=st.number_input("Delivery Rating",min_value=1.00,max_value=5.00,step=0.01)
  Percent_Cut=st.number_input("Percent Cut",min_value=15,max_value=26)
  Hr_Prt= st.selectbox("Hour Parts",['Morning', 'Afternoon', 'Night', 'Evening'])
  
  if st.button('Predict'):
    input_df=pd.DataFrame([{'Category':category, 
                            'Company Name':company, 
                            'P_Gender':p_gender,
                            'Total_Customer':Total_Customer,
                            'Total_Return_Refund':Total_Return_Refund,
                            'Price':Price,
                            'Qty':Qty,
                            'Discount':Discount,  
                            'Age':Age, 
                            'Year':Year, 
                            'Month':Month, 
                            'Day':Day, 
                            'Hour':Hour,
                            'City':City, 
                            'Prod_Rating':Prod_Rating, 
                            'Delivery/Service_Rating':Delivery_Rating,
                            'Percent_Cut':Percent_Cut,
                            'Hr_Prt':Hr_Prt}])
    pred=model_gen(df_f,input_df)
    predict = np.where(pred == 0, "Blue Dart",
                 np.where(pred == 1, "Delhivery",
                 np.where(pred == 2, "Ecom Express",
                 np.where(pred == 3, "Other Partners",
                 np.where(pred == 4, "Shadowfax", "Xpressbees")))))
    st.success(f"Best Delivery Partner: {predict[0]}" )                            

with tab3:
  st.subheader("Prediction using Generated Data")
  num_row_pred=st.number_input("Enter number of rows ",min_value=100,max_value=7000,step=100 )
  dt_pd=data_gen(num_row_pred)
  st.dataframe(dt_pd, width=3000, height=500)
  dt_p=dt_pd.copy()
  num_row_fx=st.slider("Enter number of rows for graph display",min_value=10,max_value=100,step=1 )
  if st.button("Predict Data"):
    pred2=model_gen(df_f,dt_p)
    predict2 = np.where(pred2 == 0, "Blue Dart",
                 np.where(pred2 == 1, "Delhivery",
                 np.where(pred2 == 2, "Ecom Express",
                 np.where(pred2 == 3, "Other Partners",
                 np.where(pred2 == 4, "Shadowfax", "Xpressbees")))))
    dt_pd['Best Delivery Partner']=predict2
    dt_pred_fxy=dt_pd.head(num_row_fx)
    fig41 = px.line( x= list(range(dt_pred_fxy.shape[0])) , 
                    y=dt_pred_fxy['Best Delivery Partner']  , markers=True,
                    title="Delivery Partner Prediction Over Time",
                    color_discrete_sequence=["pink"])               
    fig41.update_layout( xaxis_title="Date", yaxis_title="Delivery Partner",hovermode="x unified")
    st.plotly_chart(fig41, use_container_width=True)
    st.success(" Prediction Successfully Done, to get the prediction click on 'Export File' button ")
    
    st.download_button(label='Export File',data= dt_pd.to_csv().encode('utf-8'),
                   file_name=f'Delivery_Partner_Prediction.csv',mime='text/csv')
    
  st.subheader('Prediction using Imported Data')
  uploaded_file = st.file_uploader("Choose a CSV file", type=["csv"])
  if uploaded_file is not None:
    dt_pd2 = pd.read_csv(uploaded_file)
    st.dataframe(dt_pd2, width=3000, height=500)
    dt_p2=dt_pd2.copy() 
    if st.button('Predict Data from File'):
      pred3=model_gen(df_f,dt_p2)
      predict3 = np.where(pred3 == 0, "Blue Dart",
                 np.where(pred3 == 1, "Delhivery",
                 np.where(pred3 == 2, "Ecom Express",
                 np.where(pred3 == 3, "Other Partners",
                 np.where(pred3 == 4, "Shadowfax", "Xpressbees")))))
      st.success(" Prediction Successfully Done, to get the prediction click on 'Export Uploaded File' button ")
      dt_pd2['Best Delivery Partner']=predict3
      st.download_button(label='Export Uploaded File',data= dt_pd2.to_csv().encode('utf-8'),
                   file_name=f'Delivery_Partner_Prediction_Uploaded_File.csv',mime='text/csv')

# Data Extraction
with tab11:
  cl1=st.container()
  with cl1:
    st.subheader("Customer Table")
    customer=st.number_input("Enter number of rows for Customer Table",min_value=20,max_value=100,step=1)
    st.dataframe(c.head(customer),width=3000, height=200)
    st.download_button(label='Export Customer File',data= c.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Customer.csv',mime='text/csv')
  
  cl2=st.container()
  with cl2:
    st.subheader("Product Table")
    prdto=st.number_input("Enter number of rows for Product Table",min_value=20,max_value=100,step=1)
    st.dataframe(p.head(prdto),width=3000, height=200)
    st.download_button(label='Export Product File',data= p.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Product.csv',mime='text/csv')
  
  cl3=st.container()
  with cl3:
    st.subheader("Orders Table")
    ordro=st.number_input("Enter number of rows Order Table",min_value=20,max_value=100,step=1)
    st.dataframe(o.head(ordro),width=3000, height=200)
    st.download_button(label='Export Orders File',data= o.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Orders.csv',mime='text/csv') 
  
  cl4=st.container()
  with cl4:
    st.subheader("Delivery Partner Table")
    st.dataframe(dv)
    st.download_button(label='Export Delivery Partner File',data= dv.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Delivery_Partner.csv',mime='text/csv')
  
  cl5=st.container()
  with cl5:
    st.subheader("Rating Table")
    rato=st.number_input("Enter number of rows Rating Table",min_value=20,max_value=100,step=1)
    st.dataframe(rt.head(rato),width=3000, height=200)
    st.download_button(label='Export Rating File',data= rt.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Rating.csv',mime='text/csv')
  
  cl6=st.container()
  with cl6:              
    st.subheader("Transaction Table")
    trao=st.number_input("Enter number of rows Transaction Table",min_value=20,max_value=100,step=1)
    st.dataframe(tr.head(trao),width=3000, height=200)
    st.download_button(label='Export Transaction File',data= tr.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Transaction.csv',mime='text/csv')
  
  cl7=st.container()
  with cl7:
    st.subheader("Return Refund Table")
    rrto=st.number_input("Enter number of rows Return Refund Table",min_value=20,max_value=100,step=1)
    st.dataframe(rr.head(rrto),width=3000, height=200)
    st.download_button(label='Export Return Refund File',data= rr.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Return_Refund.csv',mime='text/csv')
                    
 
with tab8:
  cl1=st.container()
  with cl1:
    st.subheader("Product Delivery Partner Main Table")
    final=st.number_input("Enter number of rows ",min_value=30,max_value=10000,step=1)
    st.dataframe(df_f.head(final),width=3000, height=600)
    st.download_button(label='Export  File',data= df_f.to_csv().encode('utf-8'),
                   file_name=f'Myntra_Product_Delivery_Partner.csv',mime='text/csv')
                       
 
# Dashboard
dt_d=df_f2.copy()
p_x=p[['P_ID','P_Name']]
state={"Delhi": "Delhi",  "Other Cities": "Other State","Kanpur": "Uttar Pradesh","Chennai": "Tamil Nadu","Ghaziabad": "Uttar Pradesh",
    "Visakhapatnam": "Andhra Pradesh", "Pune": "Maharashtra","Ahmedabad": "Gujarat","Mumbai": "Maharashtra", "Thane": "Maharashtra",
    "Indore": "Madhya Pradesh","Kolkata": "West Bengal","Hyderabad": "Telangana","Bengaluru": "Karnataka","Surat": "Gujarat",
    "Nagpur": "Maharashtra","Patna": "Bihar","Jaipur": "Rajasthan","Vadodara": "Gujarat","Lucknow": "Uttar Pradesh",
    "Bhopal": "Madhya Pradesh"}
Qtr={"January": "Qtr 1","February": "Qtr 1","March": "Qtr 1",
     "April": "Qtr 2","May": "Qtr 2","June": "Qtr 2",
     "July": "Qtr 3","August": "Qtr 3","September": "Qtr 3",
     "October": "Qtr 4","November": "Qtr 4","December": "Qtr 4"}
city_tiers = {"Delhi": "Tier 1","Other Cities": "Tier Not-Known", "Kanpur": "Tier 2","Chennai": "Tier 1","Ghaziabad": "Tier 2",
                "Visakhapatnam": "Tier 2","Pune": "Tier 1","Ahmedabad": "Tier 1", "Mumbai": "Tier 1","Thane": "Tier 2",
               "Indore": "Tier 2", "Kolkata": "Tier 1","Hyderabad": "Tier 1","Bengaluru": "Tier 1", "Surat": "Tier 2",
                "Nagpur": "Tier 2","Patna": "Tier 2","Jaipur": "Tier 2","Vadodara": "Tier 2", "Lucknow": "Tier 2","Bhopal": "Tier 2"}

dt_d['State']=dt_d['City'].replace(state)
dt_d['Tiers']=dt_d['City'].replace(city_tiers)
dt_d['Quarter']=dt_d['Month'].replace(Qtr)
dt_d['Amt_Before_Discount']=dt_d['Qty']*dt_d['Price']*dt_d['Total_Customer']
dt_d['Amt_After_Discount']=dt_d['Qty']*dt_d['Price']*(1-dt_d['Discount']/100 )*dt_d['Total_Customer']
dt_d['Revenue_Loss']=dt_d['Total_Return_Refund']*dt_d['Price']*dt_d['Total_Customer']*(1-dt_d['Discount']/100 )
o_x=o[['P_ID','Or_ID']]
dt_ds=pd.merge(dt_d,o_x,on='P_ID')
tr_x=tr[['Or_ID','Transaction_Mode']]
dt_ds_f=pd.merge(dt_ds,tr_x,on='Or_ID')
dt_ds_f['Transaction_Mode']=dt_ds_f['Transaction_Mode'].fillna('Other Payment Mode')
dt_ds_f.drop(['Or_ID'],axis=1,inplace=True)
dt_ds_f['Age_Grp']=np.where(dt_ds_f['Age'].between(18,25),'18-25',
                            np.where(dt_ds_f['Age'].between(26,35),'26-35',
                                     np.where(dt_ds_f['Age'].between(36,45),'36-45',
                                              np.where(dt_ds_f['Age'].between(46,60),'46-60','>60'))))
city_latitude = {'Delhi': 28.6139,'Kanpur': 26.4499,'Ghaziabad': 28.6692,'Visakhapatnam': 17.6868,'Pune': 18.5204,'Ahmedabad': 23.0225,
                 'Mumbai': 19.0760,'Indore': 22.7196,'Thane': 19.2183,'Kolkata': 22.5726,'Chennai': 13.0827,'Bengaluru': 12.9716,
                'Surat': 21.1702,'Nagpur': 21.1458,'Jaipur': 26.9124,'Vadodara': 22.3072,'Lucknow': 26.8467,'Patna': 25.5941,
                 'Bhopal': 23.2599,'Hyderabad': 17.3850 }

city_longitude = {'Delhi': 77.2090,'Kanpur': 80.3319,'Ghaziabad': 77.4538,'Visakhapatnam': 83.2185,'Pune': 73.8567,'Ahmedabad': 72.5714,
                   'Mumbai': 72.8777,'Indore': 75.8577,'Thane': 72.9781,'Kolkata': 88.3639,'Chennai': 80.2707,'Bengaluru': 77.5946,
                   'Surat': 72.8311,'Nagpur': 79.0882,'Jaipur': 75.7873,'Vadodara': 73.1812,'Lucknow': 80.9462,'Patna': 85.1376,
                   'Bhopal': 77.4126,'Hyderabad': 78.4867 }
dt_ds_f['Latitude']=dt_ds_f['City'].replace(city_latitude)
dt_ds_f['Longitude']=dt_ds_f['City'].replace(city_longitude)

with tab4:
  cl_a,cl_b=st.columns(2)
  with cl_a:
    years_x=st.selectbox('Year',['All',2023,2024])
  with cl_b:
    tiers_x=st.selectbox('Tiers',['All','Tier 1','Tier 2','Tier Not-Known'])
    
  df_app = dt_ds_f.copy()
  if years_x!='All':
    df_app=dt_ds_f[dt_ds_f['Year']==years_x]
  if tiers_x!='All':
    df_app=dt_ds_f[dt_ds_f['Tiers']==tiers_x]
    
  cl_1a,cl_1b,cl_1c,cl_1d,cl_1e=st.columns(5)
  with cl_1a:
    sm_add=round(float(df_app['Amt_After_Discount'].sum())/(10**6),2)
    st.metric('Total Sales',f"₹ {sm_add}M")
  with cl_1b:
    cs_add=float(round(df_app['Total_Customer'].sum()/(10**3) ,2))
    st.metric('Total Customer',f"{cs_add}K")
  with cl_1c:
    rv_add=round( df_app['Amt_After_Discount'].sum()/(max(df_app['Hour'])-min(df_app['Hour']))/(10**3),2)
    st.metric('Revenue per Hour',f"₹ {rv_add}K")
  with cl_1d:
    avo_add=round( df_app['Amt_After_Discount'].sum()/df_app['Total_Customer'].sum(),2)
    st.metric('Average Order Value',f"₹{avo_add}")
  with cl_1e:
    pct_add=round(df_app['Amt_After_Discount'].sum()/dt_ds_f['Amt_After_Discount'].sum()*100,2)
    st.metric('%_Sales',f"{pct_add}%")

  cl_2a,cl_2b=st.columns([2,1])
  with cl_2a:
    prds=st.number_input('Enter Top N Products',min_value=30,max_value=80,step=1)
    n_prod=df_app.groupby('P_Name')['Amt_After_Discount'].sum().reset_index()
    n_prod['Amt_After_Discount']=round(n_prod['Amt_After_Discount'],2)
    n_prod.sort_values(by='Amt_After_Discount',ascending=False,inplace=True)
    n_prod=n_prod.head(prds)
    fig_p=px.bar(n_prod,x='P_Name',y='Amt_After_Discount',title='Productwise Sales',
                 color_discrete_sequence=[px.colors.qualitative.Alphabet[22]],text_auto=True)
    fig_p.update_layout(width=25000, height=600)
    st.plotly_chart(fig_p, use_container_width=True)
    
  with cl_2b:
    days=df_app.groupby('Day')['Amt_After_Discount'].sum().reset_index()
    days['Amt_After_Discount']=round(days['Amt_After_Discount'],2)
    days.sort_values(by='Amt_After_Discount',ascending=False,inplace=True)
    fig_d=px.funnel(days,y='Day',x='Amt_After_Discount',title='Daywise Sales',
                    color_discrete_sequence=[px.colors.qualitative.Set1[7]])
    fig_d.update_layout(width=1000, height=600) 
    st.plotly_chart(fig_d, use_container_width=True)
    
  cl_3a,cl_3b,cl_3c=st.columns([4,5,3])
  with cl_3a:
    states=df_app.groupby('State')[['Amt_After_Discount','Latitude','Longitude']].agg({'Amt_After_Discount':'sum','Latitude':'mean','Longitude':'mean'  } ).reset_index()
    fig_ct = px.scatter_mapbox(states,lat='Latitude', lon='Longitude', text='State',size='Amt_After_Discount', color='State',
                            mapbox_style='open-street-map', 
                            title='Statewise Sales',
                            color_discrete_sequence=['#ff69b4', '#ffc0cb', '#ff1493', '#db7093', '#ff7f50'])
    fig_ct.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_ct, use_container_width=True)

  with  cl_3b:
    mnth=df_app.groupby('Month')[['Amt_Before_Discount','Amt_After_Discount']].sum().reset_index()
    mnth['Amt_Before_Discount']=round(mnth['Amt_Before_Discount'],2)
    mnth['Amt_After_Discount']=round(mnth['Amt_After_Discount'],2)
    month_order = ["January", "February", "March", "April", "May", "June", 
               "July", "August", "September", "October", "November", "December"]
    mnth['Month'] = pd.Categorical(mnth['Month'], categories=month_order, ordered=True)
    mnth = mnth.sort_values('Month').reset_index(drop=True)
    fig_mt = px.line(mnth,x='Month', y=['Amt_Before_Discount', 'Amt_After_Discount'],
                     color_discrete_sequence=['red', 'lightcoral'],markers=True,title="Monthwise Sales")
    fig_mt.update_layout(width=5000, height=600) 
    st.plotly_chart(fig_mt, use_container_width=True)
    
  with cl_3c:
    qs_s= df_app.groupby('Quarter')['Amt_After_Discount'].sum().reset_index()
    fig_qss=px.pie(qs_s,values='Amt_After_Discount',names='Quarter',hole=0.5,title='Sales by Quarter',
           color_discrete_sequence=['#ffc0cb', '#ff1493', '#db7093','#ff69b4'])
    fig_qss.update_layout(width=5000, height=600)
    st.plotly_chart(fig_qss, use_container_width=True)
    

with tab5:
  cl_a2,cl_b2=st.columns(2)
  with cl_a2:
    years_x2=st.selectbox('Year',['All',2023,2024], key='year_selectbox_1')
  with cl_b2:
    tiers_x2=st.selectbox('Tiers',['All','Tier 1','Tier 2','Tier Not-Known'],key='tier_selection_2')
    
  df_app2 = dt_ds_f.copy()
  if years_x2!='All':
    df_app2=dt_ds_f[dt_ds_f['Year']==years_x2]
  if tiers_x2!='All':
    df_app2=dt_ds_f[dt_ds_f['Tiers']==tiers_x2]
    
  cl_4a,cl_4b,cl_4c,cl_4d,cl_4e,cl_4f=st.columns(6)

  with cl_4a:
    tl_cs=round(float(df_app2['Total_Customer'].sum()/1000 ),2)
    st.metric('Total Customers',f"{tl_cs} K" )
  with cl_4b:
    av_sp=float(round(df_app2['Amt_After_Discount'].mean(),2))
    st.metric('Average Spending',f"₹{av_sp}")
  with cl_4c:
    av_ag=round(df_app2['Age'].mean())
    st.metric('Avg Age',f"{av_ag}")
  with cl_4d:
    av_ds=float(round(df_app2['Discount'].mean(),2))
    st.metric('Average Discount',f"{av_ds}%" )
  with cl_4e:
    av_hr=round(df_app2['Hour'].mean())
    st.metric('Average Hour',f"{av_hr}:00 Hr")
  with cl_4f:
    pc_cs= round(float(df_app2['Total_Customer'].sum()/dt_ds_f['Total_Customer'].sum()*100),2)
    st.metric('% Customer',f"{pc_cs}%")
    
  cl_5a,cl_5b,cl_5c,cl_5d=st.columns([2,2,2,2])
  with cl_5a:
    gn_cs=df_app2.groupby(['P_Gender'])['Total_Customer'].sum().reset_index()
    fig_gncs=px.pie(gn_cs,names='P_Gender',values='Total_Customer',title='Customer under Genderwise Section',
                    color_discrete_sequence=['#ffc0cb', '#ff1493', '#ff69b4'])
    fig_gncs.update_layout(width=600, height=500)
    st.plotly_chart(fig_gncs, use_container_width=True)
    
  with cl_5b:
    tr_cs=df_app2.groupby('Transaction_Mode')['Total_Customer'].sum().reset_index()
    tr_cs.sort_values(by='Total_Customer',ascending=False,inplace=True)
    fig_trcs=px.bar(tr_cs,'Transaction_Mode','Total_Customer',color_discrete_sequence=["#B22222"],
                    title="Transaction Mode",text_auto=True)
    fig_trcs.update_layout(width=4000, height=400)
    st.plotly_chart(fig_trcs, use_container_width=True)
    
  with cl_5c:
    cn_as=df_app2.groupby('Company Name')['Total_Customer'].sum().reset_index()
    cn_as.sort_values(by='Total_Customer',ascending=False,inplace=True)
    cn_as['Brand_Cat']=np.where(cn_as['Company Name'].isin(["Reebok","Puma","Adidas","Nike"]),"Premium",
                          np.where( cn_as['Company Name'].isin(["Levi's","Gap","Uniqlo"]),"Casual","Fast Fashion"))
    fig_br=px.treemap(cn_as,path=['Brand_Cat','Company Name'], values= 'Total_Customer',title="Brandwise Customer",
                     color= "Total_Customer" ,color_continuous_scale=['pink', 'lightcoral'] )
    fig_br.update_layout(width=4000, height=400,coloraxis_showscale=False)
    st.plotly_chart(fig_br, use_container_width=True)
    
  with cl_5d:
    cs_agp=df_app2.groupby(['Age_Grp','P_Gender'])['Total_Customer'].sum().reset_index()
    fig_agp=px.bar(cs_agp,x='Age_Grp',y='Total_Customer',color='P_Gender',barmode='stack',
                   text_auto=True,title="Gender vs Age",
                color_discrete_sequence=["#FF0000",'#ff69b4', '#ffc0cb'])
    fig_agp.update_layout(width=4000, height=400)
    st.plotly_chart(fig_agp, use_container_width=True)
    
  cl_6a,cl_6b,cl_6c=st.columns([1.25,1.25,2])
  with cl_6a:
    fos=df_app2.groupby('Age')['Total_Customer'].sum().reset_index()
    figx=px.histogram(fos,x='Age',y='Total_Customer',barmode='stack',nbins=25,text_auto=True,
                      color_discrete_sequence=["#FF0000"],title="Agewise Total Customer")
    figx.update_traces(marker=dict(line=dict(color='black', width=1)))
    figx.update_layout(width=4000, height=500)
    st.plotly_chart(figx, use_container_width=True)
  
  with cl_6b:
    fa_hr=df_app2.groupby('Hr_Prt')['Total_Customer'].sum().reset_index()
    fig_hr=px.pie(fa_hr,values='Total_Customer',names='Hr_Prt',title="Daily Purchase",
           color_discrete_sequence=px.colors.sequential.RdBu,hole=0.5)
    fig_hr.update_layout(width=4000, height=500)
    st.plotly_chart(fig_hr, use_container_width=True)
    
  with cl_6c:
    fa_ct=df_app2.groupby('City')['Total_Customer'].sum().reset_index()
    fa_ct.sort_values(by='Total_Customer',ascending=False,inplace=True)
    fig_ct=px.bar(fa_ct,x='City',y='Total_Customer',title="Citywise Customer",
                  color_discrete_sequence=["#DC143C"])
    fig_ct.update_layout(width=4000, height=500)
    st.plotly_chart(fig_ct, use_container_width=True)
    

with tab6:
  cl_a3,cl_b3=st.columns(2)
  with cl_a3:
    years_x3=st.selectbox('Year',['All',2023,2024], key='year_selectbox_3')
  with cl_b3:
    tiers_x3=st.selectbox('Tiers',['All','Tier 1','Tier 2','Tier Not-Known'],key='tier_selection_4')  
    
  df_app3 = dt_ds_f.copy()
  if years_x3!='All':
    df_app3=dt_ds_f[dt_ds_f['Year']==years_x3]
  if tiers_x2!='All':
    df_app3=dt_ds_f[dt_ds_f['Tiers']==tiers_x3] 
    
  cl_7a,cl_7b,cl_7c,cl_7d,cl_7e=st.columns(5)
  with cl_7a:
    p_un=df_app3['P_Name'].nunique()
    st.metric('Total Product Sold',f"{p_un}")
    
  with cl_7b:
    p_qt=  round(float(df_app3['Qty'].sum()/1000),2)
    st.metric('Total Quantity Sold',f"{p_qt}K")
    
  with cl_7c:
    p_prt= round(float(df_app3['Prod_Rating'].mean()),2)
    st.metric('Product Rating',f"{p_prt}")
  
  with cl_7d:
    p_dvrt= round(float(df_app3['Delivery/Service_Rating'].mean()),2)
    st.metric('Delivery_Service_Rating',f"{p_dvrt}")  
  
  with cl_7e:
    p_pqt=  round(float(df_app3['Qty'].sum()/dt_ds_f['Qty'].sum()*100),2)
    st.metric('% Quantity Sold',f"{p_pqt}%")
    
  cl_8a,cl_8b,cl_8c=st.columns([1.4,1.4,1])
  with cl_8a:
    prds=st.selectbox('Category',['All','Jeans', 'Blazer', 'Shirt', 'Dress', 'Hoodie', 'Shorts', 'T-Shirt',
                                  'Jacket', 'Sweater', 'Skirt'], key='year_selectbox_xy')
    df_xx=df_app3.copy()
    if prds!="All":
      df_xx=df_app3[df_app3['Category']==prds]
    n_prod=df_xx.groupby(['Company Name'])['Prod_Rating'].mean().reset_index()
    n_prod['Prod_Rating']=round(n_prod['Prod_Rating'],2)
    n_prod.sort_values(by='Prod_Rating',ascending=False,inplace=True)
    fig_prt=px.bar(n_prod,x='Company Name',y='Prod_Rating',title='CompanyWise Rating',
                 color_discrete_sequence=[px.colors.qualitative.Alphabet[22]],text_auto=True)
    fig_prt.update_layout(width=25000, height=600)
    st.plotly_chart(fig_prt, use_container_width=True)
  
  with cl_8b:
    prd_dv= df_app3.groupby('Delivery_Partner')['Delivery/Service_Rating'].mean().reset_index()
    prd_dv['Delivery/Service_Rating']=round(prd_dv['Delivery/Service_Rating'],2)
    prd_dv.sort_values(by='Delivery/Service_Rating',ascending=False,inplace=True)
    fig_dvx=px.bar(prd_dv,x='Delivery/Service_Rating',y='Delivery_Partner',title='Delivery Partner Rating',
                   color_discrete_sequence=["#DC143C"],text_auto=True)
    fig_dvx.update_layout(width=25000, height=600)
    st.plotly_chart(fig_dvx, use_container_width=True)
  
  with cl_8c:
    gn_cas=df_app3.groupby(['P_Gender'])['Qty'].sum().reset_index()
    fig_gncas=px.pie(gn_cas,names='P_Gender',values='Qty',title='Tota Quantity Sold',
                    color_discrete_sequence=['#ffc0cb', '#ff1493', '#ff69b4'],hole=0.5)
    fig_gncas.update_layout(width=600, height=500)
    st.plotly_chart(fig_gncas, use_container_width=True)
    
  cl_9a,cl_9b,cl_9c=st.columns([1.4,1,1])
  with cl_9a:
    cities=df_app.groupby('City')[['Qty','Latitude','Longitude']].agg({'Qty':'sum','Latitude':'mean','Longitude':'mean'  } ).reset_index()
    fig_ct = px.scatter_mapbox(cities,lat='Latitude', lon='Longitude', text='City',size='Qty', color='City',
                            mapbox_style='open-street-map', 
                            title='Citywise Total Quantity',
                            color_discrete_sequence=['#ff69b4', '#ffc0cb', '#ff1493', '#db7093', '#ff7f50'])
    fig_ct.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_ct, use_container_width=True)
    
  with cl_9b:
    prd_m= df_app3.groupby('Month')['Amt_After_Discount'].mean().reset_index()
    prd_m2= df_app3.groupby('Month')['Amt_After_Discount'].mean().reset_index()
    prd_m['Amt_After_Discount']=round(prd_m['Amt_After_Discount'],2)
    month_order = ["January", "February", "March", "April", "May", "June",
               "July", "August", "September", "October", "November", "December"]
    prd_m['Month'] = pd.Categorical(prd_m['Month'], categories=month_order, ordered=True)
    prd_m2['Month']= pd.Categorical(prd_m2['Month'], categories=month_order, ordered=True)
    prd_m=prd_m.sort_values('Month').reset_index(drop=True)
    prd_m= prd_m.set_index('Month').diff(1).reset_index()
    prd_m['Amt_After_Discount']=prd_m['Amt_After_Discount'].fillna(0)
    prd_m['Amt_After_Discount_Now']=prd_m2['Amt_After_Discount']
    prd_m['MOM']= round(prd_m['Amt_After_Discount']/prd_m['Amt_After_Discount_Now']*100,2)
    fig_mom= px.area(prd_m,x='Month',y='MOM',color_discrete_sequence=["#ff1493"],markers=True,title='MOM%')
    fig_mom.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_mom, use_container_width=True)
    
  with cl_9c:
    qtr_f= df_app3.groupby('Quarter')['Qty'].sum().reset_index()
    qtr_f.sort_values(by='Qty',ascending=False,inplace=True)
    fig_qtr=px.funnel(qtr_f,y='Quarter',x='Qty',color_discrete_sequence=["#DC143C"],title='Quarter Qty sold')
    fig_qtr.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_qtr, use_container_width=True)
    
with tab7:
  cl_a4,cl_b4=st.columns(2)
  with cl_a4:
    years_x4=st.selectbox('Year',['All',2023,2024], key='year_selectbox_5')
  with cl_b4:
    tiers_x4=st.selectbox('Tiers',['All','Tier 1','Tier 2','Tier Not-Known'],key='tier_selection_6')  
    
  df_app4 = dt_ds_f.copy()
  if years_x4!='All':
    df_app4=dt_ds_f[dt_ds_f['Year']==years_x4]
  if tiers_x4!='All':
    df_app4=dt_ds_f[dt_ds_f['Tiers']==tiers_x4] 
    
  cl_10a,cl_10b,cl_10c,cl_10d,cl_10e,cl_10f= st.columns(6)
  with cl_10a:
    pr_rtn= round(float(df_app4['Total_Return_Refund'].sum()/1000),2)
    st.metric('Total Return',f"{pr_rtn}K" )
    
  with cl_10b:
    rev_lss= round(float(df_app4['Revenue_Loss'].sum()/(10**6)),2)
    st.metric('Revenue Loss',f"₹ {rev_lss}M")
    
  with cl_10c:
    pct_rtn=round(float(df_app4['Total_Return_Refund'].sum()/df_app4['Qty'].sum()*100),2)
    st.metric('Return Rate', f"{pct_rtn}%")
    
  with cl_10d:
    pct_lss=round(float(df_app4['Revenue_Loss'].sum()/df_app4['Amt_After_Discount'].sum()*100),2)
    st.metric("% Revenue Loss",f"{pct_lss}%")
    
  with cl_10e:
    cs_rtn=round(float(df_app4[df_app4['Total_Return_Refund']>0]['Total_Customer'].sum()/1000),2)
    st.metric("Customers product return",f"{cs_rtn}K")
    
  with cl_10f:
    cs_rtn2= float(df_app4[df_app4['Total_Return_Refund']>0]['Total_Customer'].sum())
    prct_cs_rt=  round(  cs_rtn2/float(df_app4['Total_Customer'].sum())*100,2)
    st.metric('% Customer Returning Product',f"{prct_cs_rt}%")
    
  cl_11a,cl_11b,cl_11c,cl_11d=st.columns([2.3,2.6,2.3,2.2])
  with cl_11a:
    cs_rl =df_app4.groupby('Company Name')['Revenue_Loss'].sum().reset_index()
    cs_rl.sort_values(by='Revenue_Loss',ascending=False,inplace=True)
    cs_rl['Revenue_Loss']=round(cs_rl['Revenue_Loss'],2)
    fig_cs_rv=px.funnel(cs_rl,y='Company Name',x='Revenue_Loss',title="Company Revenue Loss",
                        color_discrete_sequence=["#FF69B4"])
    fig_cs_rv.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_cs_rv, use_container_width=True)
    
  with cl_11b:
    gn_tr= df_app4.groupby('P_Gender')['Total_Return_Refund'].sum().reset_index()
    fig_gntr=px.pie(data_frame=gn_tr,names='P_Gender',values='Total_Return_Refund',title='Gender Categroy Return',
                    color_discrete_sequence=['#ff69b4', '#ffc0cb'])
    fig_gntr.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_gntr, use_container_width=True)
    
  with cl_11c:
    cat_tr= df_app4.groupby('Category')['Total_Return_Refund'].sum().reset_index()
    cat_tr.sort_values(by='Total_Return_Refund',ascending=False,inplace=True)
    fig_cttr=px.bar(data_frame=cat_tr,x='Category',y='Total_Return_Refund',text_auto=True,
                     title="Categorywise Return",color_discrete_sequence=['#ffc0cb'])
    fig_cttr.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_cttr, use_container_width=True)
    
  with cl_11d:
    dp_tr= df_app4.groupby('Delivery_Partner')['Revenue_Loss'].sum().reset_index()
    dp_tr.sort_values(by='Revenue_Loss',ascending=False,inplace=True)
    fig_dptr=px.bar(data_frame=dp_tr,y='Delivery_Partner',x='Revenue_Loss',text_auto=True,
                     title="Revenue Loss for Delivery Partners" ,color_discrete_sequence=['#ff6666'])
    fig_dptr.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_dptr, use_container_width=True)
    
  cl_12a,cl_12b,cl_12c=st.columns([2.5,2,2])
  with cl_12a:
    map_trr= df_app4.groupby('City')[['Latitude','Longitude','Total_Return_Refund']].agg({'Total_Return_Refund':'sum',
                                                                                   'Latitude':'mean','Longitude':'mean' } ).reset_index()
    map_trr['Total_Return_Refund']=round(map_trr['Total_Return_Refund'],2)
    fig_mptr = px.scatter_mapbox(map_trr,lat='Latitude',lon='Longitude',text='City',size='Total_Return_Refund',
                                 color='City', mapbox_style='carto-positron',title='Citywise Total Return',
                                color_discrete_sequence=["#FFC0CB","#FF69B4","#FF1493", 
                                                         "#DB7093", "#C71585", "#FFB6C1",
                                                         "#E75480", "#DC143C", "#B22222", 
                                                         "#FF4500", "#D2042D", "#A52A2A" ] )
    fig_mptr.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_mptr, use_container_width=True)
    
  with cl_12b:
    mn_rl= df_app4.groupby('Month')['Revenue_Loss'].sum().reset_index()
    mn_rl.sort_values(by='Revenue_Loss',ascending=False,inplace=True)
    fig_mnrl=px.bar(data_frame=mn_rl,x='Month',y='Revenue_Loss',text_auto=True,
                      title='Monthwise Revenue Loss',color_discrete_sequence=["#C71585"])
    fig_mnrl.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_mnrl, use_container_width=True)
    
  with cl_12c:
    ct_rl =df_app4.groupby('State')['Revenue_Loss'].sum().reset_index()
    ct_rl.sort_values(by='Revenue_Loss',ascending=False,inplace=True)
    ct_rl['Revenue_Loss']=round(ct_rl['Revenue_Loss'],2)
    fig_ctrl=px.funnel(ct_rl,y='State',x='Revenue_Loss',title="Statewise Revenue Loss",
                       color_discrete_sequence=["#FF1493"])
    fig_ctrl.update_layout(width=3000, height=600) 
    st.plotly_chart(fig_ctrl, use_container_width=True)
  


# CUSTOMER CLASSIFICATION ANALYSIS

# Select the Necessary Column in the table
c_clm_c=['C_ID','C_Name','Age','Gender','State','City']
c_fl_c=c[c_clm_c]
p_clm_c=['P_ID','Price','Category','Company_Name','Gender']
p_fl_c=p[p_clm_c]
p_fl_c.columns=['P_ID','Price','Category','Company Name','P_Gender']
o_clm_c=['Or_ID','C_ID','P_ID','DP_ID','Qty','Coupon','Discount','Order_Date','Order_Time']
o_fl_c=o[o_clm_c]
o_fl_c['Year']=o_fl_c['Order_Date'].dt.year
o_fl_c['Month']=o_fl_c['Order_Date'].dt.month_name()
o_fl_c['Quarter']=o_fl_c['Order_Date'].dt.quarter
o_fl_c['Quarter']=[f"Qtr {i}" for i in o_fl_c['Quarter']]
o_fl_c['Day']=o_fl_c['Order_Date'].dt.day_name()
o_fl_c.loc[:, 'Hour'] = o['Order_Time'].dt.components['hours']
o_fl_c=o_fl_c.drop(['Order_Date','Order_Time'],axis=1)
dv_clm_c=['DP_ID','DP_name','Percent_Cut']
dv_fl_c=dv[dv_clm_c]
rt_clm_c=['Or_ID','Prod_Rating','Delivery_Service_Rating']
rt_fl_c=rt[rt_clm_c]
tr_clm_c=['Or_ID','Transaction_Mode','Reward']
tr_fl_c=tr[tr_clm_c]
rr_clm_c=['RT_ID','Or_ID','Return_Refund','Reason']
rr_fl_c=rr[rr_clm_c]

#Join Tables 
po_c=pd.merge(o_fl_c,p_fl_c,on='P_ID',how='left')
pc_c=pd.merge(po_c,rt_fl_c,on='Or_ID',how='left')
ptd_c=pd.merge(pc_c,dv_fl_c,on='DP_ID',how='left')
prr_c=pd.merge(ptd_c,rr_fl_c,on='Or_ID',how='left')
pt_c=pd.merge(prr_c,tr_fl_c,on='Or_ID',how='left')

agg_ord_c=pt_c.groupby(['C_ID']).agg({
    'P_ID':'count',
    'DP_name':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'RT_ID':'count',
    'Qty':'sum',
    'Discount':'median',
    'Year':lambda x: round(x.mode()[0]) if not x.mode().empty else np.nan,
    'Month':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Quarter':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Day':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Hour':'median',
    'Price':'sum',
    'Category':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Company Name':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'P_Gender':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Prod_Rating':'median',
    'Delivery_Service_Rating':'median',
    'Percent_Cut':'mean',
    'Return_Refund':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Reason':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Transaction_Mode':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
    'Reward':lambda x: x.mode()[0] if not x.mode().empty else np.nan,
}).reset_index()

fl_t_c=pd.merge(c_fl_c,agg_ord_c,on='C_ID',how='inner')
cst_d=pd.DataFrame(fl_t_c)
cst_d.columns=['C_ID', 'Customer_Name', 'Age', 'Gender', 'State', 'City', 'Total Products', 'Delivery Partner',
               'Total Return','Qty', 'Discount', 'Year', 'Month', 'Quarter', 'Day', 'Hour','Price', 'Category',
               'Company Name','P_Gender', 'Prod_Rating','Delivery/Service_Rating', 'Percent_Cut', 'Return/Refund',
               'Reason','Transaction_Mode', 'Rewards']
    
cst_d['Reason']=cst_d['Reason'].fillna('No Return Reason')
cst_d['Return/Refund']=cst_d['Return/Refund'].fillna('No Return')
cst_d['Transaction_Mode']=cst_d['Transaction_Mode'].fillna('Other Transaction Medium')
cst_d['Rewards']=cst_d['Rewards'].fillna('Not Sure')
cst_d['Prod_Rating']=imp.fit_transform(cst_d[['Prod_Rating']])
cst_d['Delivery/Service_Rating']=imp.fit_transform(cst_d[['Delivery/Service_Rating']])

cst_dx=cst_d.copy()
cst_dx= cst_dx[['C_ID', 'Customer_Name', 'Age', 'Gender', 'City','State', 'Total Products', 'Delivery Partner',
               'Total Return','Qty', 'Discount', 'Year', 'Month', 'Quarter', 'Day', 'Hour','Price', 'Category',
               'Company Name','P_Gender', 'Prod_Rating','Delivery/Service_Rating', 'Percent_Cut', 'Return/Refund',
               'Reason','Transaction_Mode', 'Rewards']]

cst_dx.drop(['C_ID','Customer_Name'],axis=1,inplace=True)

def cust_data_gen(m):
  c_age=[i for i in range(18,71)]
  c_gender=['Male','Female']
  c_city=['Delhi','Bengaluru','Thane','Ghaziabad','Kanpur','Visakhapatnam','Kolkata','Mumbai','Jaipur','Patna',
           'Ahmedabad','Indore','Nagpur','Lucknow','Bhopal','Hyderabad','Surat','Pune','Chennai','Vadodara']
  city_to_state = {'Delhi': 'Delhi','Bengaluru': 'Karnataka','Thane': 'Maharashtra','Ghaziabad': 'Uttar Pradesh',
                   'Kanpur': 'Uttar Pradesh',
                  'Visakhapatnam': 'Andhra Pradesh','Kolkata': 'West Bengal','Mumbai': 'Maharashtra','Jaipur': 'Rajasthan',
                  'Patna': 'Bihar','Ahmedabad': 'Gujarat','Indore': 'Madhya Pradesh','Nagpur': 'Maharashtra',
                  'Lucknow': 'Uttar Pradesh','Bhopal': 'Madhya Pradesh','Hyderabad': 'Telangana','Surat': 'Gujarat',
                  'Pune': 'Maharashtra','Chennai': 'Tamil Nadu','Vadodara': 'Gujarat'}
  c_t_prdt=list(range(1,40))
  c_delivery_p=['Xpressbees', 'Blue Dart', 'Shadowfax', 'Ecom Express', 'Delhivery']
  c_return=list(range(0,30))
  c_qty=list(range(1,200))
  c_discount=list(range(0,51))
  c_year=[2024,2025,2026,2027]
  c_month=['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
  c_quarter=['Qtr 1', 'Qtr 2', 'Qtr 3', 'Qtr 4']
  c_day=['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
  c_hour=list(range(0,24))
  c_price=list(range(100,10000))
  c_Category=['Hoodie','Shorts','Skirt','Blazer','T-Shirt','Jeans','Jacket',
              'Shirt','Dress', 'Sweater']
  c_Company=['Zara','Reebok','H&M',"Levi's",'Adidas','Nike','Pantaloons',
              'Uniqlo','Gap','Puma']
  c_p_gender=['Men', 'Unisex', 'Women']
  c_Prod_Rating=np.arange(1,5,0.01)
  c_Delivery_Service_Rating=np.arange(1,5,0.01)
  c_Percent_Cut=list(range(0,50))
  c_Return_Refund=['No Return', 'Approved', 'Rejected']
  c_Resaon=['No Return Reason','Wrong Item Shipped','Defective Product',
             'Late Delivery']
  c_Transaction_Mode=['Other Transaction Medium','Net Banking','Credit Card',
                        'UPI','Wallet','Debit Card']
  c_Rewards=['Not Sure', 'Yes', 'No']

  df_c=pd.DataFrame()
  df_c['Age']=np.random.choice(c_age,size=m)
  df_c['Gender']=np.random.choice(c_gender,size=m)
  df_c['City']=np.random.choice(c_city,size=m)
  df_c['State']=df['City'].replace(city_to_state)
  df_c['Total Products']=np.random.choice(c_t_prdt,size=m)
  df_c['Delivery Partner']=np.random.choice(c_delivery_p,size=m)
  df_c['Total Return']=np.random.choice(c_return,size=m)
  df_c['Qty']=np.random.choice(c_qty,size=m)
  df_c['Discount']=np.random.choice(c_discount,size=m)
  df_c['Year']=np.random.choice(c_year,size=m)
  df_c['Month']=np.random.choice(c_month,size=m)
  df_c['Quarter']=np.random.choice(c_quarter,size=m)
  df_c['Day']=np.random.choice(c_day,size=m)
  df_c['Hour']=np.random.choice(c_hour,size=m)
  df_c['Price']=np.random.choice(c_price,size=m)
  df_c['Category']=np.random.choice(c_Category,size=m)
  df_c['Company Name']=np.random.choice(c_Company,size=m)
  df_c['P_Gender']=np.random.choice(c_p_gender,size=m)
  df_c['Prod_Rating']=np.random.choice(c_Prod_Rating,size=m)
  df_c['Delivery/Service_Rating']=np.random.choice(c_Delivery_Service_Rating,
                                                   size=m)
  df_c['Percent_Cut']=np.random.choice(c_Percent_Cut,size=m)
  df_c['Return/Refund']=np.random.choice(c_Return_Refund,size=m)
  df_c['Reason']=np.random.choice(c_Resaon,size=m)
  df_c['Transaction_Mode']=np.random.choice(c_Transaction_Mode,size=m)
  df_c['Rewards']=np.random.choice(c_Rewards,size=m)

  return df_c
  
def cluster_cust_classification(d_train_a,d_pred_a):
  d_train = d_train_a.copy()
  d_pred = d_pred_a.copy()
  
  c_cont=d_train.dtypes[d_train.dtypes!='object'].index
  for i in c_cont:
    q1=np.percentile(d_train[i],1)
    q3=np.percentile(d_train[i],99)
    cst_d[i]=np.where(d_train[i]>q3,q3,d_train[i])
    cst_d[i]=np.where(d_train[i]<q1,q1,d_train[i])
  
  for j in c_cont:
    q2=np.percentile(d_pred[j],1)
    q4=np.percentile(d_pred[j],99)
    d_pred[j]=np.where(d_pred[j]>q4,q4,d_pred[j])
    d_pred[j]=np.where(d_pred[j]<q2,q2,d_pred[j])

  cat_c= d_train.dtypes[d_train.dtypes=='object'].index
  le_dict={}
  for k in cat_c:
    le_c=LabelEncoder()
    d_train[k]=le_c.fit_transform(d_train[k])
    d_pred[k]=le_c.fit_transform(d_pred[k])
    le_dict[k]=le_c
  
  ss_c=StandardScaler()
  train_ss=pd.DataFrame(data= ss_c.fit_transform(d_train),columns=d_train.columns)
  pred_ss=pd.DataFrame(data= ss_c.transform(d_pred),columns=d_pred.columns)

  pca = PCA(n_components=2)
  pca.fit(train_ss)

  pca_components_train = pca.transform(train_ss)
  pca_s_train= pd.DataFrame({'PCA1':pca_components_train[:, 0],'PCA2': pca_components_train[:, 1] })

  pca_components_pred = pca.transform(pred_ss)
  pca_s_pred= pd.DataFrame({'PCA1':pca_components_pred[:, 0],'PCA2': pca_components_pred[:, 1] })

  
  km_c=KMeans(n_clusters=8,random_state=50)
  km_c.fit(pca_s_train)

  predict_train=km_c.predict(pca_s_train)
  train_result = d_train_a.copy()
  train_result['Predict'] = predict_train
  pca_s_train['Predict'] = predict_train
  
  predict_grp=km_c.predict(pca_s_pred)
  pred_result = d_pred_a.copy()
  pred_result['Predict'] = predict_grp
  pca_s_pred['Predict'] = predict_grp
  
  train_result['Predict']=[f"Group {i+1}" for i in  train_result['Predict'] ]
  pred_result['Predict']=[f"Group {i+1}" for i in  pred_result['Predict'] ]
  
  pca_s_train['Predict']=[f"Group {i+1}" for i in  pca_s_train['Predict'] ]
  pca_s_pred['Predict']=[f"Group {i+1}" for i in  pca_s_pred['Predict'] ]

  return train_result,pred_result,pca_s_train,pca_s_pred



with tab9:
  st.subheader("Prediction using Generated Data")
  cst_rows=st.number_input('Enter row number',min_value=3000,max_value=6000,step=1)
  cust_data_prd1=cust_data_gen(cst_rows)
  
  st.dataframe(cust_data_prd1, width=3000, height=500)
  
  if st.button('Predict Generated Data'):
    train_result1,pred_result1,pca_s_train1,pca_s_pred1 = cluster_cust_classification(cst_dx,cust_data_prd1)
    fig_sct1= px.scatter(pca_s_pred1, x='PCA1',  y='PCA2', color='Predict', title="Customer Clusters Visualized ",
                labels={'PCA1': "Principal Component 1: [Price, Qty, Total Products, Total Return ]",
                         'PCA2': "Principal Component 2: [Discount , Percent_Cut, Prod_Rating, Delivery/Service_Rating ]"} ,
                color_discrete_sequence=  ["#FFC0CB","#FF69B4","#FF1493","#DB7093", "#C71585",
                                           "#E30B5C","#DC143C", "#A52A2A","#8B0000","#660000"],opacity=0.8)
    fig_sct1.update_traces(marker=dict(size=11, line=dict(color='white', width=1)))
    fig_sct1.update_layout(width=1000,height=1000,xaxis=dict(showgrid=True),yaxis=dict(showgrid=True),
                           legend_title='Cluster',font=dict(color='black'),plot_bgcolor='white'  )
    st.plotly_chart(fig_sct1,use_container_width=True)
    cust_data_prd1['Predicted Grp']=pred_result1['Predict']
    
    st.download_button(label='Export Generated File',data= cust_data_prd1.to_csv().encode('utf-8'),
                   file_name=f'Customer_Grouping_Prediction.csv',mime='text/csv')
    
  st.subheader("Prediction using Imported Data")
  uploaded_file = st.file_uploader("Choose a CSV file", type=["csv"],key="file_uploader_4")
  if uploaded_file is not None:
    cust_data_gen_pred = pd.read_csv(uploaded_file)
    st.dataframe(cust_data_gen_pred, width=3000, height=500)
    gen_pred2=cust_data_gen_pred.copy()
    if st.button("Predict Exported Data"):
      train_result2,pred_result2,pca_s_train2,pca_s_pred2 = cluster_cust_classification(cst_dx,gen_pred2)
      fig_sct2= px.scatter(pca_s_pred2, x='PCA1',  y='PCA2', color='Predict', title="Customer Clusters Visualized ",
                labels={'PCA1': "Principal Component 1: [Price, Qty, Total Products, Total Return ]",
                         'PCA2': "Principal Component 2: [Discount , Percent_Cut, Prod_Rating, Delivery/Service_Rating ]"} ,
                color_discrete_sequence=  ["#FFC0CB","#FF69B4","#FF1493","#DB7093", "#C71585",
                                           "#E30B5C","#DC143C", "#A52A2A","#8B0000","#660000"],opacity=0.8)
      fig_sct2.update_traces(marker=dict(size=11, line=dict(color='white', width=1)))
      fig_sct2.update_layout(width=1000,height=1000,xaxis=dict(showgrid=True),yaxis=dict(showgrid=True),
                           legend_title='Cluster',font=dict(color='black'),plot_bgcolor='white'  )
      st.plotly_chart(fig_sct2,use_container_width=True)
      cust_data_gen_pred['Predicted Grp']=pred_result2['Predict'] 
      st.download_button(label='Export Imported File',data= cust_data_gen_pred.to_csv().encode('utf-8'),
                   file_name=f'Customer_Grouping_Prediction.csv',mime='text/csv')
    
      
with tab10:
  st.subheader("Customer Analysis Main Table") 
  st.dataframe(cst_d, width=3000, height=500) 
  st.download_button(label='Download Customer Main File',data= cst_d.to_csv().encode('utf-8'),
                   file_name=f'Customer_Main_Data.csv',mime='text/csv')
  if st.button("Predict Data",key="predict_button_f"):
    train_result,pred_result,pca_s_train,pca_s_pred = cluster_cust_classification(cst_dx,cst_dx)
    fig_sct_f= px.scatter(pca_s_pred, x='PCA1',  y='PCA2', color='Predict', title="Customer Clusters Visualized ",
                labels={'PCA1': "Principal Component 1: [Price, Qty, Total Products, Total Return ]",
                         'PCA2': "Principal Component 2: [Discount , Percent_Cut, Prod_Rating, Delivery/Service_Rating ]"} ,
                color_discrete_sequence=  ["#FFC0CB","#FF69B4","#FF1493","#DB7093", "#C71585",
                                           "#E30B5C","#DC143C", "#A52A2A","#8B0000","#660000"],opacity=0.8)
    fig_sct_f.update_traces(marker=dict(size=11, line=dict(color='white', width=1)))
    fig_sct_f.update_layout(width=1000,height=1000,xaxis=dict(showgrid=True),yaxis=dict(showgrid=True),
                           legend_title='Cluster',font=dict(color='black'),plot_bgcolor='white'  )
    st.plotly_chart(fig_sct_f,use_container_width=True)
    cst_d_y=cst_d.copy()
    cst_d_y['Predicted Grp']=pred_result['Predict'] 
    st.download_button(label='Export Predicted File',data= cst_d_y.to_csv().encode('utf-8'),
                   file_name=f'Customer_Prediction_Main.csv',mime='text/csv')
    
# Description 
  
def show_myntra_documentation():
    documentation = """
    # Myntra Data Analysis and Delivery Partner Prediction System , Along with Customer Segmentation Analysis

    ## 1. Project Overview

    This project is a full-fledged data analysis and machine learning solution designed for Myntra, a leading Indian e-commerce fashion retailer. It leverages Python, SQL, Power BI, and machine learning to derive insights and optimize delivery operations. The main goal is to analyze customer behavior, evaluate product and delivery performance, and predict the optimal delivery partner for each order.

    ### Key Features:
    - Data extraction from a MySQL database
    - Data preprocessing and feature engineering
    - Delivery partner prediction using machine learning
    - Customer segmentation using clustering techniques
    - Interactive Streamlit dashboard with analytical views
    - Rich data visualization capabilities

    ## 2. Project Objectives
    - **Delivery Partner Prediction**: Recommend the best delivery partner for orders based on historical data.
    - **Customer Segmentation**: Group customers by purchasing patterns and demographics.
    - **Business Intelligence**: Deliver actionable insights through:
      - Sales and revenue analysis
      - Customer behavior trends
      - Product performance metrics
      - Return and refund analysis
      - Geographic sales insights

    ## 3. Setup and Execution Instructions

    ### Prerequisites
    - Python 3.x
    - MySQL database containing Myntra data
    - Required Python packages (listed in requirements.txt)

    ### Installation Steps
    ```bash
    # Create and activate a virtual environment
    python -m venv venv
    
    # For Windows
    .venv\Scripts\activate
    
    # Install dependencies
    pip install -r requirements.txt
    ```

    ### Database Configuration
    Set up MySQL connection:
    ```python
    d = sql.connect(user='root', password='12345', host='localhost', database='Myntra_Ecommerce_Ana')
    ```

    ### Run Application
    ```bash
    streamlit run Model_design.py
    ```

    ## 4. Model and Tools Explanation

    ### Data Sources
    The system uses 7 MySQL tables:
    - Customer
    - Product
    - Orders
    - Ratings
    - Transactions
    - Return_Refund
    - Delivery

    ### Machine Learning Models

    #### Delivery Partner Prediction (Supervised Learning)
    - **Algorithm**: XGBoost Classifier
    - **Features**: Product category, company, price, quantity, discounts, ratings, etc.
    - **Preprocessing**: 
      - KNN imputation (missing values)
      - Label encoding (categorical data)
      - Standard scaling (numerical features)
      - SMOTETomek (class imbalance)

    #### Customer Segmentation (Unsupervised Learning)
    - **Algorithm**: K-Means Clustering with PCA
    - **Features**: Purchase history, demographics, ratings, return data
    - **Preprocessing**: 
      - IQR for outliers
      - Label encoding
      - Standard scaling
      - PCA for dimensionality reduction

    ### Tools and Libraries
    - **Python Libraries**: pandas, numpy, scikit-learn, xgboost, plotly, matplotlib, seaborn, streamlit, PyMySQL
    - **Database**: MySQL

    ## 5. Dashboard Tabs Overview
    The dashboard is structured into 11 interactive tabs:
    1. Description: Project overview and instructions  
    2. Model_Prediction: Delivery partner prediction interface  
    3. Model_Prediction_via_tab: Alternate prediction methods  
    4. Customer Dashboard: Sales and customer analytics  
    5. Product Dashboard: Product performance analysis  
    6. Product Return Dashboard: Return/refund insights  
    7. Customer_Analysis_Prediction: Customer clustering interface  
    8. Customer Analysis Main: Comprehensive clustering results  
    9. Original Data: Raw table access  

    ## 6. Detailed Tab Contents  

    ### Tab 1: Description  
    - Project intro  
    - Instructions  
    - Myntra branding  

    ### Tab 2: Model_Prediction  
    - Input fields for:  
      - Product details (category, company, gender)  
      - Order details (quantity, discount, price)  
      - Customer info (age, city)  
      - Temporal and rating features  
    - Outputs recommended delivery partner:  
      - Blue Dart, Delhivery, Ecom Express, ShadowFax, Xpressbees, Other Partners  

    ### Tab 3: Model_Prediction_via_tab  
    - Generated Data: Bulk synthetic predictions with visualizations
    - **File Upload**: Batch prediction via CSV upload

    ### Tab 4: Customer Dashboard
    - Filters: Year, City Tier
    - Metrics: Total Sales, Total Customers, Revenue per Hour, AOV
    - Charts: Top products, daily sales, state and monthly trends, etc.

    ### Tab 5: Product Dashboard
    - Filters: Year, City Tier
    - Metrics: Quantity sold, ratings, % sold
    - Charts: Company ratings, delivery performance, city-wise maps

    ### Tab 6: Product Return Dashboard
    - Metrics: Total Returns, Revenue Loss, Return Rate
    - Charts: Company loss, gender/category returns, monthly/state trends

    ### Tab 7: Customer_Analysis_Prediction
    - Clustering with PCA visualizations
    - Options for synthetic and file-uploaded data
    - Cluster characteristics view

    ### Tab 8: Customer Analysis Main
    - Raw customer data view
    - Full dataset clustering and visualization

    ### Tab 9: Original Data
    - Access to raw tables:
      - Customer, Product, Orders, Ratings, Transactions, Return_Refund, Delivery

    ## 7. Technical Implementation Details

    ### Data Pipeline
    - **Extraction:** SQL queries
    - **Joining**: Via primary keys  
    - **Feature Engineering**:  
      - Temporal and geographic features  
      - Revenue calculations  
      - Age grouping  
    - **Cleaning**:  
      - Missing value imputation (KNN, mode)  
      - IQR for outliers  

    ### Visualizations  
    - Plotly-powered charts:  
      - Bar, Line, Pie, Funnel, Scatter, Geo maps  
    - Responsive UI and tooltips  

    ### Deployment  
    - Streamlit frontend  
    - CSV export features  
    - Batch and interactive prediction modes  

    ## 8. Business Applications

    ### Operations  
    - Improve partner allocation and reduce failures  

    ### Marketing  
    - Target promotions by segment  
    - Identify high-value customers  

    ### Product Management
    - Track returns
    - Improve product mix

    ### Executives
    - Monitor metrics
    - Discover growth opportunities

    ## 9. Conclusion
    This platform delivers a robust blend of business intelligence and machine learning tailored for Myntra. It enhances operational decision-making and offers deep insights into customers, products, and logistics through an interactive, visual, and data-driven interface.
    """
    
    # Create a scrollable box with the documentation
    st.markdown("""
    <div style="
        height: 2000px;
        overflow-y: scroll;
        padding: 20px;
        background-color: #000000;
        border-radius: 10px;
        border: 1px solid #dee2e6;
    ">
    {}
    </div>
    """.format(documentation), unsafe_allow_html=True)

with tab1:
  st.subheader("Myntra Project Documentation")
  show_myntra_documentation()  

    
  
## For Activating the file :

# .\venv\Scripts\activate 
# python Model_design.py
# streamlit run Model_design.py       
      
      


  
  
  
  
  
  
  
    
    
  

    

