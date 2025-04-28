create Database Myntra_Ecommerce_Analysis;
use Myntra_Ecommerce_Analysis;
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS=0;

create table customer (
C_ID varchar(300) primary key, 
C_Name char (250),
 Gender char(50),
 Age int ,
 City char(200),
 State char(200),
 Street_Address varchar(400),
 Mobile bigint );
 
create table product(
 P_ID varchar(300) primary key, 
 P_Name varchar(200),
 Category char(200), 
 Company_Name char(200),
 Gender char(100), 
 Price float );
 
 create table orders(
 Or_ID varchar(300) primary key,
 C_ID varchar(300), 
 P_ID varchar(300), 
 Order_Date date , 
 Order_Time time, 
 Qty int, 
 Coupon varchar(150),
 DP_ID varchar(300), 
 Discount float );
 
 create table ratings (
 R_ID varchar(300) primary key, 
 Or_ID varchar(300), 
 Prod_Rating float, 
 Delivery_Service_Rating float );
 
 create table delivery(
 DP_ID varchar(300) primary key, 
 DP_name varchar(250), 
 DP_Ratings int,
 Percent_Cut float) ;
 
 create table return_refund (
 RT_ID varchar(300) primary key, 
 Or_ID varchar(300), 
 Reason varchar(250), 
 Return_Refund char(250), 
 Dates date );
 
 create table transactions (
 Tr_ID varchar(300) primary key, 
 Or_ID varchar(300), 
 Transaction_Mode varchar(200), 
 Reward char(200) );
 
show tables;

describe customer;
describe delivery;
describe  orders;
describe product;
describe ratings;
describe return_refund;
describe transactions;

select * from customer;
select * from  delivery;
select * from   orders;
select * from  product;
select * from  ratings;
select * from  return_refund;
select * from  transactions;


/* Add foreign key to connect the table */
alter table orders add foreign key (C_ID) references customer(C_ID), add foreign key (P_ID) references product(P_ID),
add foreign key (DP_ID) references delivery(DP_ID);
alter table ratings add foreign key (Or_ID) references orders(Or_ID);
alter table return_refund add foreign key (Or_ID) references orders(Or_ID);
alter table transactions add foreign key (Or_ID) references orders(Or_ID);



/* Analysis based on the following Dimensions */

#Customer Analytics
#1.	Find the total number of customers ordered in each state.
select c.State,count(c.C_Name) as Total_Customers from customer as c where 
c.C_ID in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) group by c.State order by count(c.C_Name) desc  ;

#2.	Get the count of male and female customers in each city.
select c.City,sum( case when c.gender='Male' then 1 else 0 end ) as Male_Count,
sum( case when c.gender='Female' then 1 else 0 end ) as Female_Count, count(c.c_name) as Total_Customer
 from customer as c group by c.City ;

#3.	Identify the top N states with the highest number of customers ordered.
delimiter //
create procedure Top_N_State_Customer(in N int)
begin
select c.State,count(c.C_Name) as Total_Customers from customer as c where 
c.C_ID in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) group by c.State order by count(c.C_Name) desc limit N  ;
end //
delimiter ;
call Top_N_State_Customer(10);

#4.	Find the average age of customers ordered by gender and age range.
select c.Gender, round(avg(c.Age)) as Avg_Age from customer as c where 
c.C_ID in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) group by c.Gender;

#5.	Determine the  Top N city with the highest number of customers aged between 20-40.
delimiter //
create procedure Top_N_City_Age_Cnt(in N int)
begin
select c.City , count(c.C_Name) as Total_Customer from customer as c where c.Age between 20 and 40 and 
c.C_ID in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) group by c.City order by count(c.C_Name) desc limit N;
end //
delimiter ;
call Top_N_City_Age_Cnt(10);

#6.	Get the count of customers grouped by age range (e.g., 18-25, 26-35, etc.).
select Age_grp, count(Age_grp) as Total_Customer from 
(select c.Age, 
case 
when c.Age between 18 and 25 then '18-25'
when c.Age between 26 and 35 then '26-35'
when c.Age between 35 and 50 then '35-45'
when c.Age between 45 and 60 then '45-60'
else '>60'
end as Age_grp
from customer as c where 
c.C_ID in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) ) as cst
group by Age_grp order by count(Age_grp) desc;

#7.	Find the top N state with the highest percentage of female and male customers.
delimiter // 
create procedure Top_N_State_Gender_Cnt(in N int)
begin
select State,round( Female/total_female*100,2) as `%_Female`,round(Male/total_male*100,2) as `%_Male` from
(select * , sum(Female) over () as total_female,sum(Male) over () as total_male from 
(select c.State, sum( case when c.Gender='Female' then 1 else 0 end) as Female,
sum( case when c.Gender='Male' then 1 else 0 end) as Male
 from customer as c where c.C_ID in (select o.C_ID from orders as o where o.C_ID=c.C_ID )
 group by c.State) as dk) as bsd order by `%_Female` desc,`%_Male` desc limit N;
end //
delimiter ;
call Top_N_State_Gender_Cnt(6);

#8.	Identify the top N cities where Myntra has the lowest customer base.
delimiter // 
create procedure Bottom_N_City_Cst_Cnt(in N int)
begin
select c.City, count(c.C_Name) as lowest_customer from customer as c where c.C_ID
in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) group by c.City order by count(c.C_Name) asc limit N;
end // 
delimiter ;
call Bottom_N_City_Cst_Cnt(10);

#9.	Find top N customers who have placed the most orders.
delimiter // 
create procedure Top_N_cust(in N int)
begin
select c.C_Name,count(o.Or_ID) as total_orders from customer as c left join orders as o
on o.C_ID=c.C_ID group by c.C_Name order by total_orders desc limit N;
end //
delimiter ;
call Top_N_cust(10);

#10. Calculate the percent proportion of customers in each city compared to the total customer base.
select City,customer/total_customer*100 as `%_customer` from
(select City,customer,sum(customer) over () as total_customer from 
(select c.City, count(c.C_Name) as customer from customer as c where c.C_ID
in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) group by c.City order by count(c.C_Name) asc )
as cnt) as ct order by `%_customer` desc;

#Product Analytics
#11.	Find the most expensive product in each category, along with  quantity 
select category,P_Name,Price,total_qty from 
(select *, row_number() over (partition by category order by Price desc ) as ranks from 
(select p.category,p.P_Name,p.Price, sum(o.Qty) as total_qty from product as p join orders as o 
on o.P_ID=p.P_ID group by p.category,p.P_Name,p.Price) as rnk) as rk where 
rk.ranks=1;

#12.	List the top N cheapest products across all categories.
delimiter // 
create procedure Top_N_prod_cat(in N int)
begin
select * from 
(select *, row_number() over (partition by category order by Price desc ) as ranks from 
(select p.category,p.P_Name,p.Price, sum(o.Qty) as total_qty from product as p join orders as o 
on o.P_ID=p.P_ID group by p.category,p.P_Name,p.Price) as rnk) as rk where rk.ranks between 1 and N;
end //
delimiter ;
call Top_N_prod_cat(4);

#13.	Identify the Companies that have products priced above ₹300.
with cte1 as 
(select p.Company_Name,avg(p.Price) as Price, sum(o.Qty) as total_qty, round(avg(r.Prod_Rating)) as prod_rating
 from product as p join orders as o on o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID 
where p.Price>300 group by p.Company_Name,p.Price  order by p.Company_Name asc)
select Company_Name,round(avg(Price),2) as Price , round(sum(total_qty)) as Qty , round(avg(prod_rating),1) as rating
from cte1 group by Company_Name order by Price desc , rating desc;

#14.	Find the number of products sold for each gender along with its quantity , price spent and rating.
select p.Gender,count(p.P_ID) as total_product ,sum(o.Qty) as quantity,
round(avg(p.Price)*avg(o.Qty)*(1- round(avg(o.Discount))/100),2) as Avg_Spend,
round(avg(r.Prod_Rating),2) as rating from product as p join orders as o on o.P_ID=p.P_ID
join ratings as r on r.Or_ID=o.Or_ID group by p.Gender;

#15.	Get the count of products for each company, along with price , price range, 
select p.Company_Name , count(p.P_ID) as Product_Count ,round(avg(p.Price),2) as Price,
concat(round(min(p.Price)) ," - ",round(max(p.Price)) ) as Price_Range,sum(Qty) as quantity,
round(avg(Prod_Rating),2) as Rating from product as p join orders as o on o.P_ID=p.P_ID join ratings as r
on r.Or_ID=o.Or_ID group by p.Company_Name;

#16.	Find the average price of products in each category along with its rating, price range,quantity 
select p.category , count(p.P_ID) as Product_Count ,round(avg(p.Price),2) as Price,
concat(round(min(p.Price)) ," - ",round(max(p.Price)) ) as Price_Range,sum(Qty) as quantity,
round(avg(Prod_Rating),2) as Rating from product as p join orders as o on o.P_ID=p.P_ID join ratings as r
on r.Or_ID=o.Or_ID group by p.category;

#17.	Get the top N most common product bought  in each company, along with quantity and rating .
delimiter //
create procedure Top_N_cat_prod(in N int)
begin
with cte2 as 
(with cte as 
(select p.Company_Name, p.P_Name,sum(o.Qty) as Quantity, round(avg(r.Prod_Rating),2) as Rating from product as p join orders as o on 
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID group by p.Company_Name, p.P_Name )  
select *, row_number() over (partition by Company_Name order by Quantity  desc) as  Ranks from cte)
select * from cte2 where Ranks between 1 and N;
end //
delimiter ;
call Top_N_cat_prod (4);

#18.	Identify the company with the least expensive product, along with quantity and rating.
with cte as 
(select *, rank() over (partition by Company_Name order by Price asc) as ranks from
(select p.Company_Name,p.P_Name,avg(p.Price) as Price,sum(o.Qty) as Orders,round(avg(r.Prod_Rating),2) as Rating from product as p join orders as o on
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID group by p.Company_Name,p.P_Name) as rn)
select Company_Name,P_Name,round(Price,2) as Price,Orders,Rating from cte where ranks=1;

#19.	List the top N least frequently bought product categories.
delimiter //
create procedure Bottom_N_least_prod_cat(in N int)
begin
with cte as 
(select *, rank() over (partition by category order by Price asc) as ranks from
(select p.category,p.P_Name,avg(p.Price) as Price,sum(o.Qty) as Orders,round(avg(r.Prod_Rating),2) as Rating from product as p join orders as o on
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID group by p.category,p.P_Name) as rn)
select category,P_Name,round(Price,2) as Price,Orders,Rating from cte where ranks between 1 and N;
end //
delimiter ;
call Bottom_N_least_prod_cat(2);

#Order Analysis
#21.	Find the total number of orders placed each day for the last N days (1-30 days) .
delimiter //
create procedure Days_N(in N int)
begin
select concat("Day-" ,day(o.Order_Date)) as Days,count(o.Or_ID) total_product,sum(o.Qty) as total_qty,
round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount from orders as o join product as p on p.P_ID=o.P_ID 
where Order_Date between 
(select  date_sub(max(Order_Date),interval N day ) from orders) and  
(select max(Order_Date) from orders)
group by concat("Day-" ,day(Order_Date)) order by concat("Day-" ,day(Order_Date)) desc ;
end //
delimiter ;
call Days_N(25);

#22.	Identify the peak hours part(morning,afternoon,evening, night) when most orders are placed.
with cte as 
(select * , case when hour(Order_Time) between 6 and 12 then "Morning" when hour(Order_Time) between 13 and 17 then "Afternoon"
when hour(Order_Time) between 18 and 22 then "Evening" else "Night" end as HR_Div from orders )
select HR_Div as Hours, count(*) as total_orders, sum(Qty) as Qty from cte group by HR_Div order by count(*) desc;

#23.	Find the top N customers who placed the highest number of orders in the last M month.
delimiter //
create procedure Month_Customer(in N int,in M int)
begin
with cte as (select * from orders where Order_Date between (select  date_sub(max(Order_Date),interval M month ) from orders)   and 
(select  max(Order_Date) from orders) )
select c.C_Name,count(o.Or_ID) as total_order, sum(o.Qty) as total_qty,
round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount from cte as o join customer as c
on c.C_Id=o.C_ID join product as p on p.P_ID=o.P_ID
 group by c.C_Name order by count(o.Or_ID) desc,sum(o.Qty) limit N;
end // 
delimiter ;
call Month_Customer(20,4);

#24.	Get the  trend of product ordered in the particular year and month.
delimiter //
create procedure Month_Year_Top(in N int,in Months char(100),in Years int)
begin
select p.P_Name,p.Category ,count(o.Or_ID) as Orders , sum(o.Qty) as Qty, round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount,
round(avg(r.prod_rating),2) as Rating from orders as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
where year(o.Order_Date)=Years and monthname(o.Order_Date)= Months
group by p.P_Name,p.Category order by count(o.Or_ID) desc limit N;
end //
delimiter ;
call Month_Year_Top(20,"March",2023);

#25.	Get the top N company that generate the highest revenue in particular year .
delimiter //
create procedure Comp_Year_Top(in N int,in Years int)
begin
select p.Company_Name,count(o.Or_ID) as Orders , sum(o.Qty) as Qty, round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount,
round(avg(r.prod_rating),2) as Rating from orders as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
where year(o.Order_Date)=Years group by p.Company_Name  order by count(o.Or_ID) desc limit N;
end //
delimiter ;
call Comp_Year_Top(6,2023); 

#26.	Find the impact of discounts (pre and post discount) on products .  
select p.P_Name,p.Category ,count(o.Or_ID) as Orders , sum(o.Qty) as Qty, 
round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Pre_Discount,round(sum(o.Qty)*avg(p.Price) ,2) as Post_Discount
from orders as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
group by p.P_Name,p.Category order by count(o.Or_ID) ;

#27.	Identify the top-selling brand for each state.
with cte as 
(select *, row_number() over (partition by Company_Name order by Amount desc) as Ranks from
(select p.Company_Name,c.state,count(o.Or_ID) as Orders , sum(o.Qty) as Qty, round(sum(o.Qty)*avg(p.Price) ,2) as Amount,
round(avg(r.prod_rating),2) as Rating from orders as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
join customer as c on c.C_ID=o.C_ID group by p.Company_Name,c.state order by p.Company_Name) as rk)
select Company_Name,state,Orders,Qty,Amount,Rating from cte where Ranks=1;

#28.	Find the total number of orders productwise where customers used a discount less than 10%..
select p.P_Name,p.Category ,count(o.Or_ID) as Orders , sum(o.Qty) as Qty, 
round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount
from orders as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
group by p.P_Name,p.Category having avg( o.Discount)<10 order by count(o.Or_ID) ;

#29.	Identify customers who placed orders using discount greater than avg discount.
select c.C_Name,p.P_Name,p.Company_Name ,count(o.Or_ID) as Orders , sum(o.Qty) as Qty, 
round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount
from orders as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID join customer as c on c.C_ID=o.C_ID
group by c.C_Name,p.P_Name,p.Company_Name having avg( o.Discount)> (select avg(o.Discount) from orders as o)  order by count(o.Or_ID) ;

#30.	Find the Top N product with the highest total order quantity ,along with average age between 2 year.
delimiter //
create procedure Year_bt_TopN(in N int,in Y1 int,in Y2 int)
begin
select p.P_Name,p.Category,p.Company_Name ,round(avg(c.Age)) as Age , sum(o.Qty) as Qty, 
round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount , round(avg(r.prod_rating),2) as Rating
from orders as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID join customer as c on c.C_ID=o.C_ID
where year(Order_Date) between Y1 and Y2 group by p.P_Name,p.Category,p.Company_Name  order by sum(o.Qty) desc limit N ;
end //
delimiter ; 
call Year_bt_TopN(20, 2021,2024 );

#Transaction Analysis
#31.	Find the total number of successful and Failure transactions.
with cte2 as 
(with cte as 
(select Transaction_Mode , sum(case when Reward='Yes' then 1 else 0 end) as Reward_Yes,
sum(case when Reward='No' then 1 else 0 end ) as Reward_No from transactions as t
where t.Or_ID in (select Or_ID from orders  ) group by Transaction_Mode )
select *,Reward_Yes+Reward_No as Total_Reward from cte)
select * , round(Reward_Yes/Total_Reward*100,2) as `%_Reward_Yes`,
round(Reward_No/Total_Reward*100,2) as `%_Reward_No` from cte2;

#32.	Find the number of reward provide and  reward not provide for each product along with its age .
delimiter //
create procedure reward_age_cnt(in N int)
begin
with cte as 
(select p.P_Name,p.Company_Name,sum(case when Reward='Yes' then 1 else 0 end) as Reward_Yes,
sum(case when Reward='No' then 1 else 0 end ) as Reward_No ,
round(avg(case when Reward='Yes' then c.Age else 0 end)) as Age_Reward_Yes,
round(avg(case when Reward='No' then c.Age else 0 end)) as Age_Reward_No from 
transactions as t join orders as o on o.Or_ID=t.Or_ID join customer as c
on c.C_ID=o.C_ID join product as p on p.P_ID=o.P_ID group by p.P_Name , p.Company_Name)
select * from cte order by Reward_Yes desc,Reward_No desc limit N;
end//
delimiter ;
call reward_age_cnt(10);

#33.	Get the most common transaction mode used by customers.
select t.Transaction_Mode, count(c.C_ID) as Customers , round(avg(c.Age)) as Age ,
sum(case when Reward='Yes' then 1 else 0 end) as Reward_Yes,
sum(case when Reward='No' then 1 else 0 end ) as Reward_No 
from customer as c join orders as o 
on o.C_ID=c.C_ID join transactions as t on t.Or_ID=o.Or_ID group by t.Transaction_Mode ;

#34.	Calculate the total revenue collected from online transactions.
select t.Transaction_Mode,round(avg(Age)) as Age,round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as Amount
from transactions as t join orders as o on o.Or_ID=t.Or_ID join customer as c on c.C_ID=o.C_ID join product as p
on p.P_ID=o.P_ID where t.Transaction_Mode in ('UPI','Net Banking' )group by t.Transaction_Mode ;

#35.	Identify the transaction mode that has the highest no reward.
select * from 
(select t.Transaction_Mode,sum(case when Reward='No' then 1 else 0 end) as Reward_No from 
transactions as t join orders as o on o.Or_ID=t.Or_ID group by t.Transaction_Mode) as tr
order by tr.Reward_No desc ;

#36.	Find the average transaction amount per state.
delimiter //
create procedure top_state_Trans(in N int )
begin 
with cte2 as 
(with cte as 
(select  c.State, round( sum(case when t.Transaction_Mode = 'Wallet' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Wallet,
round( sum(case when t.Transaction_Mode = 'UPI' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as UPI,
round( sum(case when t.Transaction_Mode = 'Debit Card' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Debit_Card,
round( sum(case when t.Transaction_Mode = 'Credit Card' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Credit_Card,
round( sum(case when t.Transaction_Mode = 'Net Banking' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Net_Banking
from transactions as t join orders as o on o.Or_ID = t.Or_ID join customer as c on c.C_ID = o.C_ID join product as p on p.P_ID = o.P_ID
group by c.State )
select * from cte order by Wallet desc, UPI desc, Debit_Card desc, Credit_Card desc, Net_Banking desc)
select * from cte2 limit N;
end //
delimiter ;
call top_state_Trans(4);

#37.	Get the monthly breakdown of total transactions.
delimiter //
create procedure top_month_Trans(in N int )
begin 
with cte2 as 
(with cte as 
(select  monthname(o.Order_Date) as Months, round( sum(case when t.Transaction_Mode = 'Wallet' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Wallet,
round( sum(case when t.Transaction_Mode = 'UPI' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as UPI,
round( sum(case when t.Transaction_Mode = 'Debit Card' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Debit_Card,
round( sum(case when t.Transaction_Mode = 'Credit Card' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Credit_Card,
round( sum(case when t.Transaction_Mode = 'Net Banking' then o.Qty * p.Price * (1 - o.Discount / 100)  else 0 end), 2) as Net_Banking
from transactions as t join orders as o on o.Or_ID = t.Or_ID join product as p on p.P_ID = o.P_ID
group by  monthname(o.Order_Date) )
select * from cte order by Wallet desc, UPI desc, Debit_Card desc, Credit_Card desc, Net_Banking desc)
select * from cte2 limit N;
end //
delimiter ;
call top_month_Trans(6);

#38.	Identify customers who faced  no reward more than twice.
delimiter //
create procedure cust_no_rew(in N int )
begin 
with cte as 
(select c.C_Name, sum(case when Reward='No' then 1 else 0 end ) as No_Reward from transactions as t join orders as o
on o.Or_ID=t.Or_ID join customer as c on c.C_ID=o.C_ID group by c.C_Name)
select * from cte where No_Reward>2 order by No_Reward desc limit N;
end//
delimiter ;
call cust_no_rew(6);

#39.	Identify the company with the highest no rewards transaction based .
delimiter //
create procedure cmp_no_rew_mode(in N int )
begin
with cte2 as 
(with cte as (select * from transactions where reward='No')
select p.Company_Name , sum(case when t.Transaction_Mode = 'Wallet' then 1  else 0 end)  as Wallet,
sum(case when t.Transaction_Mode = 'UPI' then 1  else 0 end) as UPI,
sum(case when t.Transaction_Mode = 'Debit Card' then  1 else 0 end) as Debit_Card,
sum(case when t.Transaction_Mode = 'Credit Card' then  1 else 0 end) as Credit_Card,
sum(case when t.Transaction_Mode = 'Net Banking' then 1  else 0 end) as Net_Banking
from cte as t join orders as o on o.Or_ID=t.Or_ID join product as p on p.P_ID=o.P_ID 
group by p.Company_Name)
select * from cte2 order by Wallet desc,UPI desc,Debit_Card desc,Credit_Card desc,Net_Banking desc limit N; 
end //
delimiter ;
call cmp_no_rew_mode(3);

#Ratings & Customer Feedback
#41.	Find the average product rating for each product category and mark top N.
delimiter //
create procedure cat_prd_rt(in N int )
begin
with cte as 
(select * , rank() over ( partition by Category order by Ratings desc) as Ranks from 
(select p.Category , p.P_Name, round(avg(r.Prod_Rating),2) as Ratings from product as p join orders as o on 
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID group by  p.Category , p.P_Name) as rt)
select * from cte where Ranks<=N;
end //
delimiter ;
call cat_prd_rt(4);

#42.	Identify the products that received the highest rating companywise.
delimiter //
create procedure comp_prd_rt(in N int )
begin
with cte as 
(select * , rank() over ( partition by Company_Name order by Ratings desc) as Ranks from 
(select p.Company_Name, p.P_Name, round(avg(r.Prod_Rating),2) as Ratings from product as p join orders as o on 
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID group by  p.Company_Name, p.P_Name) as rt)
select * from cte where Ranks<=N;
end //
delimiter ;
call comp_prd_rt(4);

#43.	Get the count of orders where delivery rating is less than 3, citywise.
select * from 
(select c.city,count(o.Or_ID) as orders,round(avg(r.Delivery_Service_Rating),2) as rating from customer as c
join orders as o on o.C_ID=c.C_ID join ratings as r on r.Or_ID=o.Or_ID group by c.City)
as rt where rt.rating<=3 order by rating desc  ;

#44.	Identify the delivery partner with the highest average rating companywise.
delimiter //
create procedure comp_dv_rt(in N int )
begin
select * from
(with cte as 
(select d.DP_Name,p.Company_Name,round(avg(r.Delivery_Service_Rating),2) as Rating from product as p join 
orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join ratings as r on
r.Or_ID=o.Or_ID group by d.DP_Name,p.Company_Name)
select * , row_number() over (partition by DP_Name order by Rating desc ) as Ranks from cte) 
as rk where rk.Ranks<=N;
end //
delimiter ;
call comp_dv_rt(5);

#45.	Find the customers who gave the lowest product ratings,Category
delimiter //
create procedure cust_cat_rt(in N int )
begin
with cte as 
(select * , row_number() over ( partition by Category order by Ratings asc) as Ranks from 
(select p.Category, c.C_Name, round(avg(r.Prod_Rating),2) as Ratings from product as p join orders as o on 
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID join customer as c on c.C_ID=o.C_ID group by p.Category, c.C_Name) as rt)
select Category,C_Name,Ratings from cte where Ranks<=N;
end //
delimiter ;
call cust_cat_rt(4);

#46.	Get the products that have an average  rating below 2, companywise.
delimiter //
create procedure comp_prod_lw_rt(in N int )
begin
with cte as 
(select * , row_number() over ( partition by Company_Name order by Ratings desc) as Ranks from 
(select p.Company_Name, p.P_Name, round(avg(r.Prod_Rating),2) as Ratings from product as p join orders as o on 
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID group by  p.Company_Name, p.P_Name) as rt where rt.Ratings<=2)
select * from cte where Ranks<=N;
end //
delimiter ;
call comp_prod_lw_rt(4);

#47.	Find customers who have consistently rated delivery partners more than 4  stars, genderwise.
delimiter //
create procedure gndr_cust_dev(in N int )
begin
with cte as 
(select *, row_number() over (partition by Gender order by Ratings desc ) as Ranks from  
(select p.Gender,c.C_Name, round(avg(r.Delivery_Service_Rating),2) as Ratings from customer as c join orders as o on 
c.C_ID=o.C_ID join ratings as r on r.Or_ID=o.Or_ID join product as p on p.P_ID=o.P_ID 
group by p.Gender,c.C_Name) as rt where rt.Ratings>4)
select * from cte where Ranks<=N;
end //
delimiter ;
call gndr_cust_dev(5);

#48.	Get the products where the product rating is significantly lower than the delivery rating.
delimiter //
create procedure prd_dv_rt(in N int )
begin
select * from 
(select p.P_Name,round(avg(r.Prod_Rating),2) as Prod_Rating , round(avg(r.Delivery_Service_Rating),2) as Delivery_Service_Rating
from product as p join orders as o on p.P_ID=o.P_ID
join ratings as r on r.Or_ID=o.Or_ID group by p.P_Name) as dff
where dff.Prod_Rating<dff.Delivery_Service_Rating order by dff.Prod_Rating desc, dff.Delivery_Service_Rating desc limit N;
end //
delimiter ;
call prd_dv_rt(8);

#49.	Identify the genderwise product rating for different companies .
select * from 
(select p.Company_Name, 
round(avg(case when c.Gender='Male' then r.Prod_Rating else 0 end),2) as Male,
round(avg(case when c.Gender='Female' then r.Prod_Rating else 0 end),2) as Female 
from customer as c join orders as o on o.C_ID=c.C_ID join product as p 
on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID group by p.Company_Name ) as cst 
order by Male desc, Female desc;

#Delivery Partner Analysis
#51.	Find the average delivery partner rating.
with cte as 
(select p.Company_Name ,
sum(case when d.DP_name='Delhivery' then 1 else 0 end ) as Delhivery,
sum(case when d.DP_name='Ecom Express' then 1 else 0 end ) as Ecom_Express,
sum(case when d.DP_name='Blue Dart' then 1 else 0 end ) as Blue_Dart,
sum(case when d.DP_name='Xpressbees' then 1 else 0 end ) as Xpressbees,
sum(case when d.DP_name='Shadowfax' then 1 else 0 end ) as Shadowfax
from product as p join orders as o on o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID join delivery as d
on d.DP_ID=o.DP_ID group by p.Company_Name) select * from cte order by 
Delhivery desc, Ecom_Express desc, Blue_Dart desc, Xpressbees desc,Shadowfax desc  ;

#52.	Identify the delivery partner with the lowest rating, product category wise .
with cte as 
(select p.Gender ,
round(avg(case when d.DP_name='Delhivery' then d.DP_Ratings else 0 end ),2) as Delhivery,
round(avg(case when d.DP_name='Ecom Express' then d.DP_Ratings else 0 end ),2) as Ecom_Express,
round(avg(case when d.DP_name='Blue Dart' then d.DP_Ratings else 0 end ),2) as Blue_Dart,
round(avg(case when d.DP_name='Xpressbees' then d.DP_Ratings else 0 end ),2) as Xpressbees,
round(avg(case when d.DP_name='Shadowfax' then d.DP_Ratings else 0 end ),2) as Shadowfax
from product as p join orders as o on o.P_ID=p.P_ID join  delivery as d
on d.DP_ID=o.DP_ID group by p.Gender) select * from cte order by 
Delhivery desc, Ecom_Express desc, Blue_Dart desc, Xpressbees desc,Shadowfax desc  ;

#53.	Get the count of orders handled by each delivery partner along with the rating , given by the customer.
with cte as 
(select d.DP_name,count(c.C_ID) as total_customer , round(avg(r.Delivery_Service_Rating),2) as Service_Rating
from customer as c join orders as o on o.C_ID=c.C_ID join ratings as r on r.Or_ID=o.Or_ID join
delivery as d on d.DP_ID=o.DP_ID group by d.DP_name) select * from cte order by total_customer desc,  Service_Rating desc;

#54.	Identify the delivery partner that handled the highest number of returns.
with cte as 
(select * from orders as o where o.Or_ID in (select rr.Or_ID from return_refund as rr where rr.Or_ID=o.Or_ID and rr.Return_Refund="Return" ))
select d.DP_name ,  count(o.Or_ID) as total_return,
round(sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100)*avg(d.Percent_Cut/100) ,2) as Amount 
from delivery as d join cte as o on o.DP_ID=d.DP_ID join product as p on p.P_ID=o.P_ID group by 
d.DP_name order by count(o.Or_ID) desc;

#55.	Find the percentage of deliveries handled by each delivery partner product_categorywise
with cte2 as 
(with cte as 
(select p.Category ,
sum(case when d.DP_name='Delhivery' then 1 else 0 end ) as Delhivery,
sum(case when d.DP_name='Ecom Express' then 1 else 0 end ) as Ecom_Express,
sum(case when d.DP_name='Blue Dart' then 1 else 0 end ) as Blue_Dart,
sum(case when d.DP_name='Xpressbees' then 1 else 0 end ) as Xpressbees,
sum(case when d.DP_name='Shadowfax' then 1 else 0 end ) as Shadowfax
from product as p join orders as o on o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID join delivery as d
on d.DP_ID=o.DP_ID group by p.Category) 
select * , (Delhivery + Ecom_Express + Blue_Dart+ Xpressbees+ Shadowfax ) as Total_Orders  from cte order by 
Delhivery desc, Ecom_Express desc, Blue_Dart desc, Xpressbees desc,Shadowfax desc)
select Delhivery/Total_Orders*100 as `% Delhivery Orders`, Ecom_Express/Total_Orders*100 as `% Ecom_Express Orders` ,
 Blue_Dart/Total_Orders*100 as `% Blue_Dart Orders` , Xpressbees/Total_Orders*100 as `% Xpressbees Orders` ,
 Xpressbees/Total_Orders*100 as `% Xpressbees Orders`, Total_Orders from cte2;	

#56.	Get the top N  products  delivered  by each partner.
delimiter //
create procedure prod_patnr_TopN(in N int )
begin
with cte as 
(select p.P_Name ,
sum(case when d.DP_name='Delhivery' then 1 else 0 end ) as Delhivery,
round(sum(case when d.DP_name='Delhivery' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Delhivery_Eval ,
sum(case when d.DP_name='Ecom Express' then 1 else 0 end ) as Ecom_Express,
round(sum(case when d.DP_name='Ecom Express' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Ecom_Expres_Eval ,
sum(case when d.DP_name='Blue Dart' then 1 else 0 end ) as Blue_Dart,
round(sum(case when d.DP_name='Blue Dart' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Blue_Dart_Eval ,
sum(case when d.DP_name='Xpressbees' then 1 else 0 end ) as Xpressbees,
round(sum(case when d.DP_name='Xpressbees' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Xpressbees_Eval ,
sum(case when d.DP_name='Shadowfax' then 1 else 0 end ) as Shadowfax,
round(sum(case when d.DP_name='Shadowfax' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Shadowfax_Eval 
from product as p join orders as o on o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID join delivery as d
on d.DP_ID=o.DP_ID group by p.P_Name) select * from cte order by  Delhivery desc, Delhivery_Eval  desc, Ecom_Express desc,
Ecom_Expres_Eval desc, Blue_Dart desc,  Blue_Dart_Eval desc, Xpressbees desc ,Xpressbees_Eval desc , Shadowfax desc , Shadowfax_Eval  desc limit N ;
end //
delimiter ;
call prod_patnr_TopN(5);

#57.	Find the partner with the highest rating along with average price, product Category wise
with cte2 as 
(with cte as 
(select p.Category ,
sum(case when d.DP_name='Delhivery' then 1  else 0 end ) as Delhivery,
round(avg(case when d.DP_name='Delhivery' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Delhivery_Eval ,
sum(case when d.DP_name='Ecom Express' then 1 else 0 end ) as Ecom_Express,
round(avg(case when d.DP_name='Ecom Express' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Ecom_Expres_Eval ,
sum(case when d.DP_name='Blue Dart' then 1 else 0 end ) as Blue_Dart,
round(avg(case when d.DP_name='Blue Dart' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Blue_Dart_Eval ,
sum(case when d.DP_name='Xpressbees' then 1 else 0 end ) as Xpressbees,
round(avg(case when d.DP_name='Xpressbees' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Xpressbees_Eval ,
sum(case when d.DP_name='Shadowfax' then 1 else 0 end ) as Shadowfax,
round(avg(case when d.DP_name='Shadowfax' then (o.Qty)*(p.Price)*(1-( o.Discount)/100)*(d.Percent_Cut/100) else 0 end ),2) as Shadowfax_Eval 
from product as p join orders as o on o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID join delivery as d
on d.DP_ID=o.DP_ID group by p.Category) 
select *,(Delhivery+Ecom_Express+Blue_Dart+Xpressbees+Shadowfax) as Total_Orders 
from cte order by  Delhivery desc, Delhivery_Eval  desc, Ecom_Express desc,
Ecom_Expres_Eval desc, Blue_Dart desc,  Blue_Dart_Eval desc, Xpressbees desc ,Xpressbees_Eval desc , Shadowfax desc , Shadowfax_Eval  desc )
select Category,Delhivery/Total_Orders *100 as `% Delhivery` ,Delhivery_Eval,Ecom_Express/Total_Orders *100 as `% Ecom_Express`,Ecom_Expres_Eval,
Blue_Dart/Total_Orders *100 as 	`% Blue_Dart` , Blue_Dart_Eval,Xpressbees/Total_Orders *100 as `% Xpressbees` ,Xpressbees_Eval,
Shadowfax/Total_Orders *100 as 	`% Shadowfax`, Shadowfax_Eval,Total_Orders from cte2;

#58.	Identify delivery partners who have delivered more than 2000 orders, along with total_earning and Rating
with cte as 
(select d.DP_name,count(o.Or_ID) as Total_Orders , round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100)*avg(d.Percent_Cut/100),2) 
as prct_cut, round(avg(r.Delivery_Service_Rating),2) as service_rating
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join ratings as r 
on r.Or_ID=o.Or_ID  group by d.DP_name)
select * from cte where Total_Orders > (select avg(Total_Orders) from cte ) order by Total_Orders desc;

#59.	Find the number of delivery partners who have an average rating below average.
with cte as 
(select d.DP_name, round(avg(r.Delivery_Service_Rating),2) as service_rating,
count(o.Or_ID) as Total_Orders , round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100)*avg(d.Percent_Cut/100),2) as prct_cut,
count(distinct p.Company_Name ) as Company_associated
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join ratings as r 
on r.Or_ID=o.Or_ID  group by d.DP_name)
select * from cte where service_rating < (select avg(service_rating) from cte ) order by service_rating desc;

#Returns & Refunds
#61.	Find the most common reason for returns. 
with cte as 
(select rr.Reason , 
sum(case when rr.Return_Refund="Approved" then 1 else 0 end) as Approved, 
sum(case when rr.Return_Refund="Rejected" then 1 else 0 end) as Rejected
from return_refund as rr join orders as o on  o.Or_ID=rr.Or_ID  group by rr.Reason)
select *, (Approved+Rejected) as Total_Orders from cte;

#62.	Identify the percentage of orders that were rejected and apporved for return , companywise.
with cte2 as
(with cte as 
(select p.Company_Name,
sum(case when rr.Return_Refund="Approved" then 1 else 0 end) as Approved, 
sum(case when rr.Return_Refund="Rejected" then 1 else 0 end) as Rejected
from return_refund as rr  join orders as o on  o.Or_ID=rr.Or_ID 
join product as p on p.P_ID=o.P_ID group by p.Company_Name ) 
select *,(Approved +Rejected) as Total_Return  from cte)
select Company_Name,Approved,Approved/Total_Return*100 as `% Return`, Rejected,
Rejected/Total_Return*100 as `% Rejected`,Total_Return from cte2
order by Approved desc,Rejected desc, Total_Return desc;

#63.	Get the count of customers who have returned more than 2 orders.
with a_rtn as ( select * from return_refund where Return_Refund="Approved")
select c.C_Name,count(o.Or_ID) as total_orders from customer as c join orders as o on
o.C_ID=c.C_ID join a_rtn as r on r.Or_ID=o.Or_ID group by c.C_Name having count(o.Or_ID)>2 order by count(o.Or_ID) desc;

#64.	Identify the top 5 products with the highest return  rates.
delimiter //
create procedure rr_TopN_Prod(in N int)
begin
with cte2 as
(with cte as 
(select p.P_Name,
sum(case when rr.Return_Refund="Approved" then 1 else 0 end) as Approved, 
sum(case when rr.Return_Refund="Rejected" then 1 else 0 end) as Rejected
from return_refund as rr  join orders as o on  o.Or_ID=rr.Or_ID 
join product as p on p.P_ID=o.P_ID group by p.P_Name) 
select *,(Approved +Rejected) as Total_Return  from cte)
select P_Name,Approved,Approved/Total_Return*100 as `% Return`, Rejected,
Rejected/Total_Return*100 as `% Rejected`,Total_Return from cte2
order by Approved desc,Rejected desc, Total_Return desc limit N;
end//
delimiter ;
call rr_TopN_Prod(6);

#65.	Find the approved return value, percentage for each payment mode.
with cte2 as
(with cte as 
(select t.Transaction_Mode,
sum(case when rr.Return_Refund="Approved" then 1 else 0 end) as Approved, 
sum(case when rr.Return_Refund="Rejected" then 1 else 0 end) as Rejected
from return_refund as rr  join orders as o on  o.Or_ID=rr.Or_ID 
join transactions as t on t.Or_ID=o.Or_ID group by t.Transaction_Mode) 
select *,(Approved +Rejected) as Total_Return  from  cte)
select Transaction_Mode,Approved,Approved/Total_Return*100 as `% Approved`,Total_Return from cte2
order by Approved desc ;

#66.	Get the total revenue lost due to refunds companywise .
with loss_prct as 
(with revenue_loss as 
(with cte as (select * from  return_refund where return_refund="approved")
select p.Company_Name, round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as revenue_loss
from product as p join orders as o on o.P_ID=p.P_ID join cte as c on c.Or_ID=o.Or_ID group by p.Company_Name  ),
revenue as 
(select p.Company_Name, round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100) ,2) as revenue
from product as p join orders as o on o.P_ID=p.P_ID group by p.Company_Name )
select r.Company_Name,r.revenue,rl.revenue_loss from revenue as r left join revenue_loss as rl on 
rl.Company_Name=r.Company_Name)
select * , round(revenue_loss/revenue*100,2) as `% Loss` from loss_prct order by `% Loss` desc;

#67.	Identify the customers who requested the highest number of refunds but rejected more than 2 times
with cte as (select * from  return_refund where return_refund="rejected")
select c.C_Name, count(o.Or_ID) as total_orders from customer as c join orders as o on o.C_ID=c.C_ID
join cte as r where o.Or_ID=r.Or_ID group by c.C_Name having count(o.Or_ID)>2 order by total_orders desc;

#68.	Get the number of returned orders handled by each delivery partner.
with cte2 as
(with cte as 
(select d.DP_name,
sum(case when rr.Return_Refund="Approved" then 1 else 0 end) as Approved, 
sum(case when rr.Return_Refund="Rejected" then 1 else 0 end) as Rejected
from return_refund as rr  join orders as o on  o.Or_ID=rr.Or_ID 
join delivery  as d on d.DP_ID=o.DP_ID group by d.DP_name) 
select *,(Approved +Rejected) as Total_Return  from cte)
select DP_name,Approved,Approved/Total_Return*100 as `% Return`, Rejected,
Rejected/Total_Return*100 as `% Rejected`,Total_Return from cte2
order by Approved desc,Rejected desc, Total_Return desc;

#69.	Identify the Top N category of products with the highest return rate.
delimiter //
create procedure Cat_rt_TopN(in N int)
begin
with cte2 as
(with cte as 
(select p.Category,
sum(case when rr.Return_Refund="Approved" then 1 else 0 end) as Approved, 
sum(case when rr.Return_Refund="Rejected" then 1 else 0 end) as Rejected
from return_refund as rr  join orders as o on  o.Or_ID=rr.Or_ID 
join product as p on p.P_ID=o.P_ID group by p.Category) 
select *,(Approved +Rejected) as Total_Return  from cte)
select Category,Approved,Approved/Total_Return*100 as `% Return` from cte2
order by Approved desc limit N;
end //
delimiter ;
call Cat_rt_TopN(3);

# Advanced Analysis
#1.	Find the top N most ordered product along with its total ordered, average rating, revenue, how many got returned , loss due to return
delimiter //
create procedure prod_topN_fet(in N int )
begin
with revenue as
(select p.P_Name,count(o.OR_ID) as total_ordered , round(avg(rr.Prod_Rating),2) as Ratings, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as revenue
from product as p join orders as o on o.P_ID=p.P_ID join ratings as rr on rr.Or_ID=o.Or_ID group by p.P_Name ), 
revenue_loss as 
(with r_ap as (select * from return_refund where return_refund="Approved" )  
 select p.P_Name, count(o.Or_ID) as total_returned ,
 round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as revenue_loss
 from product as p join orders as o on o.P_ID=p.P_ID join ratings  as r on r.Or_ID=o.Or_ID
 join r_ap as rr on rr.Or_ID=o.Or_ID group by p.P_Name)
 select r.P_Name,r.total_ordered,r.Ratings,r.revenue,rl.total_returned,rl.revenue_loss,round(rl.revenue_loss/r.revenue*100,2) as `% Revenue Loss` 
 from  revenue as r left join revenue_loss as rl on r.P_Name=rl.P_Name 
 order by r.total_ordered desc,r.Ratings desc,r.revenue desc,rl.total_returned desc,rl.revenue_loss desc limit N;
 end //
 delimiter ;
call prod_topN_fet(8);

#2.	Identify the company  with the  total ordered, average rating, revenue, how many got returned , loss due to return
with revenue as
(select p.Company_Name,count(o.OR_ID) as total_ordered , round(avg(rr.Prod_Rating),2) as Ratings, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as revenue
from product as p join orders as o on o.P_ID=p.P_ID join ratings as rr on rr.Or_ID=o.Or_ID group by p.Company_Name), 
revenue_loss as 
(with r_ap as (select * from return_refund where return_refund="Approved" )  
 select p.Company_Name, count(o.Or_ID) as total_returned ,
 round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as revenue_loss
 from product as p join orders as o on o.P_ID=p.P_ID join ratings  as r on r.Or_ID=o.Or_ID
 join r_ap as rr on rr.Or_ID=o.Or_ID group by p.Company_Name)
 select r.Company_Name,r.total_ordered,r.Ratings,r.revenue,rl.total_returned,rl.revenue_loss,round(rl.revenue_loss/r.revenue*100,2) as `% Revenue Loss` 
 from  revenue as r left join revenue_loss as rl on r.Company_Name=rl.Company_Name
 order by r.total_ordered desc,r.Ratings desc,r.revenue desc,rl.total_returned desc,rl.revenue_loss desc;

#3.	Find the delivery partner with  total ordered, average rating, revenue, how many got returned , loss due to return
with revenue as
(select d.DP_name,count(o.OR_ID) as total_ordered , round(avg(rr.Prod_Rating),2) as Ratings, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as revenue
from product as p join orders as o on o.P_ID=p.P_ID join ratings as rr on rr.Or_ID=o.Or_ID 
join delivery as d on d.DP_ID=o.DP_ID  group by d.DP_name), 
revenue_loss as 
(with r_ap as (select * from return_refund where return_refund="Approved" )  
 select d.DP_name, count(o.Or_ID) as total_returned ,
 round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as revenue_loss
 from product as p join orders as o on o.P_ID=p.P_ID join ratings  as r on r.Or_ID=o.Or_ID
 join r_ap as rr on rr.Or_ID=o.Or_ID
 join delivery as d on d.DP_ID=o.DP_ID group by d.DP_name)
 select r.DP_name,r.total_ordered,r.Ratings,r.revenue,rl.total_returned,rl.revenue_loss,round(rl.revenue_loss/r.revenue*100,2) as `% Revenue Loss` 
 from  revenue as r left join revenue_loss as rl on r.DP_name=rl.DP_name
 order by r.total_ordered desc,r.Ratings desc,r.revenue desc,rl.total_returned desc,rl.revenue_loss desc;

#4.	Get the Hourewise wise  company analysis, including order, quantity and revenue generated 
with order_hr as 
(select *, case
when hour(Order_Time) between 6 and 11 then 'Morning'
when hour(Order_Time) between 12 and 4 then 'Afternoon'
when hour(Order_Time) between 5 and 9 then 'Evening'
else 'Night'  end as Hr_Div from orders)
select p.Company_Name,
sum(case when Hr_Div = "Morning" then 1 else 0 end ) as Orders_Morning,
sum(case when Hr_Div = "Morning" then o.Qty else 0 end ) as Qty_Morning,
round(sum(case when Hr_Div = "Morning" then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_Morning,
sum(case when Hr_Div = "Evening" then 1 else 0 end ) as Orders_Evening,
sum(case when Hr_Div = "Evening" then o.Qty else 0 end ) as Qty_Evening,
round(sum(case when Hr_Div = "Evening" then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_Evening,
sum(case when Hr_Div = "Night" then 1 else 0 end ) as Orders_Night,
sum(case when Hr_Div = "Night" then o.Qty else 0 end ) as Qty_Night,
round(sum(case when Hr_Div = "Night" then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_Night
from order_hr as o join product as p on p.P_ID=o.P_ID group by p.Company_Name;

#5.	 Get the Yearwise wise  company analysis, including order, quantity and revenue generated 
with order_yr as 
(select *, case
when year(Order_Date)=2023 then  '2023'
when year(Order_Date)=2024 then '2024'
else '2025'  end as Yr_Div from orders)
select p.Company_Name,
sum(case when Yr_Div='2024' then 1 else 0 end ) as Orders_2024,
sum(case when Yr_Div='2024' then o.Qty else 0 end ) as Qty_2024,
round(sum(case when Yr_Div='2024' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2024,
round(avg(case when Yr_Div='2024' then  Prod_Rating else 0 end),2) as Rating_2024,
sum(case when Yr_Div='2023' then 1 else 0 end ) as Orders_2023,
sum(case when Yr_Div='2023' then o.Qty else 0 end ) as Qty_2023,
round(sum(case when Yr_Div='2023' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2023,
round(avg(case when Yr_Div='2023' then  Prod_Rating else 0 end),2) as Rating_2023
from order_yr as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
group by p.Company_Name;

#6.	Identify the delivery partner handling the highest number of high-value orders.
with order_yr as 
(select *, case
when year(Order_Date)=2023 then  '2023'
when year(Order_Date)=2024 then '2024'
else '2025'  end as Yr_Div from orders)
select d.DP_name,
sum(case when Yr_Div='2024' then 1 else 0 end ) as Orders_2024,
sum(case when Yr_Div='2024' then o.Qty else 0 end ) as Qty_2024,
round(sum(case when Yr_Div='2024' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2024,
round(avg(case when Yr_Div='2024' then  Delivery_Service_Rating else 0 end),2) as Rating_2024,
sum(case when Yr_Div='2023' then 1 else 0 end ) as Orders_2023,
sum(case when Yr_Div='2023' then o.Qty else 0 end ) as Qty_2023,
round(sum(case when Yr_Div='2023' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2023,
round(avg(case when Yr_Div='2023' then  Delivery_Service_Rating else 0 end),2) as Rating_2023
from order_yr as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
join delivery as d on d.DP_ID=o.DP_ID
group by d.DP_name;

#7.	Find the most common transaction mode used for high-value orders yearwise.
with order_yr as 
(select *, case
when year(Order_Date)=2023 then  '2023'
when year(Order_Date)=2024 then '2024'
else '2025'  end as Yr_Div from orders)
select t.Transaction_Mode,
sum(case when Yr_Div='2024' then 1 else 0 end ) as Orders_2024,
round(sum(case when Yr_Div='2024' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2024,
sum(case when Yr_Div='2023' then 1 else 0 end ) as Orders_2023,
round(sum(case when Yr_Div='2023' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2023
from order_yr as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID
join transactions as t on t.Or_ID=o.Or_ID
group by t.Transaction_Mode;

#8.	Get the total revenue lost due to returned products.
delimiter //
create procedure revenue_analysis(in N int)
begin
with cte as 
(with revenue as 
(with order_yr as 
(select *, case
when year(Order_Date)=2023 then  '2023'
when year(Order_Date)=2024 then '2024'
else '2025'  end as Yr_Div from orders)
select p.P_Name,
sum(case when Yr_Div='2024' then 1 else 0 end ) as Orders_2024,
sum(case when Yr_Div='2024' then o.Qty else 0 end ) as Qty_2024,
round(sum(case when Yr_Div='2024' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2024,
round(avg(case when Yr_Div='2024' then  Prod_Rating else 0 end),2) as Rating_2024,
sum(case when Yr_Div='2023' then 1 else 0 end ) as Orders_2023,
sum(case when Yr_Div='2023' then o.Qty else 0 end ) as Qty_2023,
round(sum(case when Yr_Div='2023' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2023,
round(avg(case when Yr_Div='2023' then  Prod_Rating else 0 end),2) as Rating_2023
from order_yr as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID group by p.P_Name),
revenue_loss as 
(with order_yr as 
(select *, case
when year(Order_Date)=2023 then  '2023'
when year(Order_Date)=2024 then '2024'
else '2025'  end as Yr_Div from orders),
rr_ap as (select * from return_refund where Return_Refund="Approved" )
select p.P_Name,
sum(case when Yr_Div='2024' then 1 else 0 end ) as Orders_Return_2024,
sum(case when Yr_Div='2024' then o.Qty else 0 end ) as Qty_Return_2024,
round(sum(case when Yr_Div='2024' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_Loss_2024,
sum(case when Yr_Div='2023' then 1 else 0 end ) as Orders_Return_2023,
sum(case when Yr_Div='2023' then o.Qty else 0 end ) as Qty_Return_2023,
round(sum(case when Yr_Div='2023' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_Loss_2023
from order_yr as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID join rr_ap as rr
on rr.Or_ID=o.Or_ID group by p.P_Name)
select r.P_Name,r.Orders_2024,r.Orders_2023,r.Qty_2024,r.Qty_2023,r.Revenue_2024,r.Revenue_2023,
r.Rating_2024,r.Rating_2023,rl.Orders_Return_2024,rl.Orders_Return_2023,rl.Qty_Return_2024,rl.Qty_Return_2023,
rl.Revenue_Loss_2024, rl.Revenue_Loss_2023 , round(rl.Revenue_Loss_2024/r.Revenue_2024*100,2) as `% Loss 2024`,
round(rl.Revenue_Loss_2023/r.Revenue_2023*100,2) as `% Loss 2023`
from revenue as r join revenue_loss as rl on r.P_name=rl.P_Name)
select * from cte order by Orders_2024 desc, Orders_2023 desc, Qty_2024 desc, Qty_2023 desc, Revenue_2024 desc, Revenue_2023 desc,
Rating_2024 desc,Rating_2023 desc, Orders_Return_2024 desc,Orders_Return_2023 desc, Qty_Return_2024 desc, Qty_Return_2023 desc,
Revenue_Loss_2024 desc, Revenue_Loss_2023 desc, `% Loss 2024` desc, `% Loss 2023` desc limit N;
end //
delimiter ;
call revenue_analysis(5);

#9.	Identify the top-selling category for each city.
delimiter //
create procedure Cat_City_TopN(in N int )
begin
with cte as 
(select c.City, 
sum(case when p.Category='Jeans' then 1 else 0 end) as Jeans_Order,
sum(case when p.Category='Jeans' then o.Qty else 0 end) as Jeans_Qty,
sum(case when p.Category='Blazer' then 1 else 0 end) as Blazer_Order,
sum(case when p.Category='Blazer' then o.Qty else 0 end) as Blazer_Qty,
sum(case when p.Category='Hoodie' then 1 else 0 end) as Hoodie_Order,
sum(case when p.Category='Hoodie' then o.Qty else 0 end) as Hoodie_Qty,
sum(case when p.Category='Shirt' then 1 else 0 end) as Shirt_Order,
sum(case when p.Category='Shirt' then o.Qty else 0 end) as Shirt_Qty,
sum(case when p.Category='Dress' then 1 else 0 end) as Dress_Order,
sum(case when p.Category='Dress' then o.Qty else 0 end) as Dress_Qty,
sum(case when p.Category='Skirt' then 1 else 0 end) as Skirt_Order,
sum(case when p.Category='Skirt' then o.Qty else 0 end) as Skirt_Qty,
sum(case when p.Category='Shorts' then 1 else 0 end) as Shorts_Order,
sum(case when p.Category='Shorts' then o.Qty else 0 end) as Shorts_Qty,
sum(case when p.Category='T-Shirt' then 1 else 0 end) as T_Shirt_Order,
sum(case when p.Category='T-Shirt' then o.Qty else 0 end) as T_Shirt_Qty,
sum(case when p.Category='Jacket' then 1 else 0 end) as Jacket_Order,
sum(case when p.Category='Jacket' then o.Qty else 0 end) as Jacket_Qty,
sum(case when p.Category='Sweater' then 1 else 0 end) as Sweater_Order,
sum(case when p.Category='Sweater' then o.Qty else 0 end) as Sweater_Qty from 
customer as c  join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID group by  c.City )
select * from cte order by  Jeans_Order desc ,Jeans_Qty desc, Blazer_Order desc, Blazer_Qty desc, 
Hoodie_Order desc, Hoodie_Qty desc, Shirt_Order desc, Shirt_Qty desc, Skirt_Order desc , Skirt_Qty desc,
 Shorts_Order desc,  Shorts_Qty desc, T_Shirt_Order desc,T_Shirt_Qty desc, Jacket_Order desc, Jacket_Qty desc, 
 Sweater_Order desc, Sweater_Qty desc limit N;
 end //
 delimiter ;
call Cat_City_TopN(5); 
 
#10.	Find the percentage of orders yearwise that resulted in a refund.
with cte as 
(with revenue as 
(with order_yr as 
(select *, case
when year(Order_Date)=2023 then  '2023'
when year(Order_Date)=2024 then '2024'
else '2025'  end as Yr_Div from orders)
select monthname(o.Order_Date) as Order_Month,
sum(case when Yr_Div='2024' then 1 else 0 end ) as Orders_2024,
sum(case when Yr_Div='2024' then o.Qty else 0 end ) as Qty_2024,
round(sum(case when Yr_Div='2024' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2024,
round(avg(case when Yr_Div='2024' then  Prod_Rating else 0 end),2) as Rating_2024,
sum(case when Yr_Div='2023' then 1 else 0 end ) as Orders_2023,
sum(case when Yr_Div='2023' then o.Qty else 0 end ) as Qty_2023,
round(sum(case when Yr_Div='2023' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_2023,
round(avg(case when Yr_Div='2023' then  Prod_Rating else 0 end),2) as Rating_2023
from order_yr as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID group by monthname(o.Order_Date)),
revenue_loss as 
(with order_yr as 
(select *, case
when year(Order_Date)=2023 then  '2023'
when year(Order_Date)=2024 then '2024'
else '2025'  end as Yr_Div from orders),
rr_ap as (select * from return_refund where Return_Refund="Approved" )
select monthname(o.Order_Date) as Order_Month,
sum(case when Yr_Div='2024' then 1 else 0 end ) as Orders_Return_2024,
sum(case when Yr_Div='2024' then o.Qty else 0 end ) as Qty_Return_2024,
round(sum(case when Yr_Div='2024' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_Loss_2024,
sum(case when Yr_Div='2023' then 1 else 0 end ) as Orders_Return_2023,
sum(case when Yr_Div='2023' then o.Qty else 0 end ) as Qty_Return_2023,
round(sum(case when Yr_Div='2023' then o.Qty*p.Price*(1- o.Discount/100) else 0 end ),2) as Revenue_Loss_2023
from order_yr as o join product as p on p.P_ID=o.P_ID join ratings as r on r.Or_ID=o.Or_ID join rr_ap as rr
on rr.Or_ID=o.Or_ID group by monthname(o.Order_Date))
select r.Order_Month,  round(Orders_Return_2024/r.Orders_2024*100,2) as `% Ordered Returend 2024` ,
round(Orders_Return_2023/r.Orders_2023*100,2) as `% Ordered Returend 2023` ,
round(Qty_Return_2024/r.Qty_2024*100,2) as `% Qty Returend 2024`,
round(Qty_Return_2023/r.Qty_2023*100,2) as `% Qty Returend 2023`,
 round(rl.Revenue_Loss_2024/r.Revenue_2024*100,2) as `% Revenue Loss 2024`,
round(rl.Revenue_Loss_2023/r.Revenue_2023*100,2) as `% Revenue Loss 2023`
from revenue as r join revenue_loss as rl on r.Order_Month=rl.Order_Month)
select * from cte order by `% Revenue Loss 2024` desc , `% Revenue Loss 2023` desc; 

#11.	Identify the most purchased product company in each state.
select state,Company_Name, total_orders,total_qty,total_revenue from 
(with cte as 
(select c.state,p.Company_Name ,count(o.Or_ID) as total_orders, sum(o.Qty) as total_qty,
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as total_revenue from customer as c
join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID group by c.state,p.Company_Name)
select state,Company_Name, total_orders,total_qty,total_revenue, row_number() over (partition by state order by  total_qty desc) as ranks
from cte ) as rk where rk.ranks=1 ; 

#12.	Find the MOM% orders,MOM% Qty, MOM% Sales, MOM% Return , MOM% Revenue Loss yearwise
delimiter //
create procedure MOM_Year(in N int )
begin
with revenue as
(with cte1 as 
(select month_name,total_orders, lag(total_orders,1,0) over (order by month_no ) as pre_month_order,
total_qty, lag(total_qty,1,0) over (order by month_no ) as pre_month_qty,
total_revenue, lag(total_revenue ,1,0) over (order by month_no  ) as pre_month_revenue from 
(select monthname(o.Order_Date) as month_name,month(o.Order_Date) as month_no , count(o.Or_ID) as total_orders, sum(o.Qty) as total_qty, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as total_revenue from orders as o join product as p
on p.P_ID=o.P_ID where year(o.Order_Date)=N group by  month_name,month_no order by month_no  ) as rks)
select month_name,ifnull(round((total_orders-pre_month_order)/pre_month_order*100,2),0) as MOM_Orders ,
ifnull( round((total_qty-pre_month_qty)/pre_month_qty*100,2),0) as MOM_Qty ,
ifnull( round((total_revenue-pre_month_revenue)/pre_month_revenue*100,2),0) as MOM_Revenure from cte1),
revenue_loss as
(with cte2 as 
(select month_name,total_orders, lag(total_orders,1,0) over (order by month_no ) as pre_month_order,
total_qty, lag(total_qty,1,0) over (order by month_no ) as pre_month_qty,
total_revenue, lag(total_revenue ,1,0) over (order by month_no  ) as pre_month_revenue from 
(select monthname(o.Order_Date) as month_name,month(o.Order_Date) as month_no , count(o.Or_ID) as total_orders, sum(o.Qty) as total_qty, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as total_revenue from orders as o join product as p
on p.P_ID=o.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID where  year(o.Order_Date)=N and  rr.Return_Refund="Approved"
 group by  month_name,month_no order by month_no  ) as rks)
select month_name,ifnull(round((total_orders-pre_month_order)/pre_month_order*100,2),0) as MOM_Orders_Loss ,
ifnull( round((total_qty-pre_month_qty)/pre_month_qty*100,2),0) as MOM_Qty_Loss ,
ifnull( round((total_revenue-pre_month_revenue)/pre_month_revenue*100,2),0) as MOM_Revenure_Loss from cte2)
select r.month_name,r.MOM_Orders,rl.MOM_Orders_Loss,r.MOM_Qty,rl.MOM_Qty_Loss ,r.MOM_Revenure, rl.MOM_Revenure_Loss
from revenue as r left join revenue_loss as rl on r.month_name=rl.month_name;
end //
delimiter ;
call MOM_Year(2024);

#13.	Find the QOQ% orders,QOQ% Qty, QOQ% Sales, QOQ% Return , QOQ% Revenue Loss yearwise.
delimiter //
create procedure QOQ_Year(in N int )
begin
with revenue as
(with cte1 as 
(select quarter_name,total_orders, lag(total_orders,1,0) over (order by quarter_no ) as pre_quarter_order,
total_qty, lag(total_qty,1,0) over (order by quarter_no ) as pre_quarter_qty,
total_revenue, lag(total_revenue ,1,0) over (order by quarter_no  ) as pre_quarter_revenue from 
(select concat('Qtr ',quarter(o.Order_Date)) as quarter_name,quarter(o.Order_Date) as quarter_no , count(o.Or_ID) as total_orders, sum(o.Qty) as total_qty, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as total_revenue from orders as o join product as p
on p.P_ID=o.P_ID where year(o.Order_Date)=N group by  quarter_name,quarter_no order by quarter_no  ) as rks)
select quarter_name,ifnull(round((total_orders-pre_quarter_order)/pre_quarter_order*100,2),0) as QOQ_Orders ,
ifnull( round((total_qty-pre_quarter_qty)/pre_quarter_qty*100,2),0) as QOQ_Qty ,
ifnull( round((total_revenue-pre_quarter_revenue)/pre_quarter_revenue*100,2),0) as QOQ_Revenure from cte1),
revenue_loss as
(with cte2 as 
(select quarter_name,total_orders, lag(total_orders,1,0) over (order by quarter_no ) as pre_quarter_order,
total_qty, lag(total_qty,1,0) over (order by quarter_no ) as pre_quarter_qty,
total_revenue, lag(total_revenue ,1,0) over (order by quarter_no  ) as pre_quarter_revenue from 
(select concat('Qtr ',quarter(o.Order_Date)) as quarter_name,quarter(o.Order_Date) as quarter_no, count(o.Or_ID) as total_orders, sum(o.Qty) as total_qty, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as total_revenue from orders as o join product as p
on p.P_ID=o.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID where  year(o.Order_Date)=N and  rr.Return_Refund="Approved"
 group by  quarter_name,quarter_no order by quarter_no  ) as rks)
select quarter_name,ifnull(round((total_orders-pre_quarter_order)/pre_quarter_order*100,2),0) as QOQ_Orders_Loss ,
ifnull( round((total_qty-pre_quarter_qty)/pre_quarter_qty*100,2),0) as QOQ_Qty_Loss ,
ifnull( round((total_revenue-pre_quarter_revenue)/pre_quarter_revenue*100,2),0) as QOQ_Revenure_Loss from cte2)
select r.quarter_name,r.QOQ_Orders,rl.QOQ_Orders_Loss,r.QOQ_Qty,rl.QOQ_Qty_Loss ,r.QOQ_Revenure, rl.QOQ_Revenure_Loss
from revenue as r left join revenue_loss as rl on r.quarter_name=rl.quarter_name;
end //
delimiter ;
call QOQ_Year(2023);

#14.	Find the most commonly returned product for each gender.

with cte as 
(select *, row_number() over (partition by Gender order by total_orders desc ) as ranks from 
(select c.Gender,p.P_Name,count(o.Or_ID) as total_orders, sum(o.Qty) as total_qty, 
round( sum(o.Qty)*avg(p.Price)*(1-avg( o.Discount)/100),2) as return_loss from 
customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
join return_refund as rr on rr.Or_ID=o.Or_ID where rr.Return_Refund="Approved" group by c.Gender,p.P_Name ) as rk)
select * from cte where ranks in ( (select min(ranks) from cte where Gender="Female") ,(select max(ranks) from cte where Gender="Male")) ;


select   Gender,P_Name,total_orders,total_qty,return_loss,
case when ranks=1 then 'Maximum Return' else 'Minimum Return' end as `Returns Status` from cte2 ; 

#15.	Get the list of orders where the product rating is less than 2.5 and returned.
with return_prod as 
(select p.P_Name, round(avg(r.Prod_Rating),2) as Rating from product as p join orders as o on
o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID join return_refund as rr
on rr.Or_ID=o.Or_ID where rr.Return_Refund="Approved"  group by p.P_Name)
select * from return_prod where Rating<2.5 order by Rating desc;

#16.	Find customers who have consistently returned products despite giving 5 stars
with cte as 
(select c.C_ID, c.C_Name,round(avg(r.Prod_Rating),2) as Ratings from customer as c join orders as o on c.C_ID=o.C_ID join
ratings as r on r.Or_ID=o.Or_ID group by c.C_ID,c.C_Name having avg(r.Prod_Rating)=5 order by Ratings desc)
select C_Name,Ratings from cte as c join  orders as o on o.C_ID=c.C_ID join return_refund as rr on 
o.Or_ID=rr.Or_ID ;

#17.	Find the state where delivery partners have the lowest ratings.
select State,DP_name,Rating from 
(select *, row_number() over (partition by State order by Rating asc ) as Ranks from
(select c.State,d.DP_name,round(avg(r.Delivery_Service_Rating),2) as Rating from customer as c
join orders as o on c.C_ID=o.C_ID join delivery as d on d.DP_ID=o.DP_ID join ratings as r on
r.Or_ID=o.Or_ID group by c.State,d.DP_name) as rnk) as rk where rk.Ranks=1 order by Rating;

#18.	Find customers who placed an order but did not return the product.
select c.C_Name from customer as c join orders as o on c.C_ID=o.C_ID where 
o.Or_ID not in (select rr.Or_ID from return_refund as rr );

#19.	Get the delivery partners who handled the most high-value orders ,along with its company name.
select DP_name,Company_Name,Orders,Amount from 
(select * , row_number() over (partition by DP_Name order by Amount desc) as Ranks from 
(select d.DP_name,p.Company_Name,count(o.Or_ID) as Orders,
round( avg(p.Price)*sum(o.Qty)*(1-avg(o.Discount)/100),2) as Amount from product as p 
join orders as o on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID group by  d.DP_name,p.Company_Name) as rnk)
as rk where rk.Ranks=1 order by Amount desc;

#20.	Find the top N month with the highest returns in the last 12 months.
select monthname(o.Order_Date) as Months,year(o.Order_Date) as Years, count(o.Or_ID) as Orders, sum(o.Qty) as Qty ,
round( avg(p.Price)*sum(o.Qty)*(1-avg(o.Discount)/100),2) as Amount , round(avg(Prod_Rating),2) as Ratings
from product as p join orders as o on o.P_ID=p.P_ID join ratings as r on r.Or_ID=o.Or_ID join
return_refund as rr on rr.Or_ID=o.Or_ID where o.Order_Date between date_sub(current_date(),interval 12 month) and current_date()
 group by Months,Years order by Orders desc;



/*  Power BI Dashboard using SQL */

# SALES DASHBOARD
create view t_sales as  select  round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2) as total_sales  
from orders as o join product as p on p.P_ID=o.P_ID; 

# using Year as slicer
delimiter //
create procedure sales_yr (in yr int )   # Year = 2024,2025 
begin

# Single KPIs
with orders_n1 as (select * , year(order_date) as years from orders ) 
select concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales , count(o.Or_ID) as total_orders,
 concat('₹ ',round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))/count(o.Or_ID) ,2)) as AOV , 
 concat('₹ ',round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))/count(distinct o.C_ID) ,2)) as Revenue_per_Customer ,
concat( round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))/(select * from t_sales)*100 ,2),' %') as `% Sales` from 
product as p join orders_n1 as o on o.P_ID=p.P_ID join customer as c on c.C_ID=o.C_ID where o.years=yr ;

# statewise sales  
with orders_n2 as (select * , year(order_date) as years from orders )
select c.state,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n2 as o on o.P_ID=p.P_ID join customer as c on c.C_ID=o.C_ID where o.years=yr group by c.state order by total_sales desc;

# citywise sales
with orders_n3 as (select * , year(order_date) as years from orders )
select c.city,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n3 as o on o.P_ID=p.P_ID join customer as c on c.C_ID=o.C_ID where o.years=yr group by c.city order by total_sales desc;

# company sales
with orders_n4 as (select * , year(order_date) as years from orders )
select p.company_name,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n4 as o on o.P_ID=p.P_ID join customer as c on c.C_ID=o.C_ID where o.years=yr group by p.company_name order by total_sales desc;

# Daywise sales 
with orders_n4 as (select * , year(order_date) as years ,dayname(order_date) as days from orders)
select o.days ,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n4 as o on o.P_ID=p.P_ID join customer as c on c.C_ID=o.C_ID where o.years=yr group by o.days order by total_sales desc;

# Monthwise Sales before and after discount
select Months,sales_before_discount,sales_after_discount from 
(with orders_n5 as (select * , year(order_date) as years  from orders)
select monthname(o.order_date) as Months, month(o.order_date) as m ,  concat('₹ ',round(sum(o.qty)*avg(p.price),2)) as sales_before_discount ,
concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as sales_after_discount from 
product as p join orders_n5 as o on o.P_ID=p.P_ID join customer as c on c.C_ID=o.C_ID where o.years=yr group by Months,m order by m ) as mth ;

end //
delimiter ;
call sales_yr(2024);
call sales_yr(2023);

# using city tier as slicer
create view cust_tier as select *,
case 
when city in ("Delhi", "Mumbai", "Chennai", "Kolkata", "Hyderabad", "Bengaluru", "Pune", "Ahmedabad") then "Tier 1"
when city in ("Kanpur", "Surat", "Jaipur", "Lucknow", "Nagpur", "Indore", "Patna", "Visakhapatnam") then "Tier 2"
when city in ("Ghaziabad", "Thane", "Vadodara", "Bhopal") then "Tier 3"
else "Tier Unknown"
end as Tier from customer;

# using tier as slicer
delimiter //
create procedure sales_tier(in tier char(50))
begin

# Single KPIs
with orders_n1 as (select * , year(order_date) as years from orders ) 
select concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales , count(o.Or_ID) as total_orders,
 concat('₹ ',round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))/count(o.Or_ID) ,2)) as AOV , 
 concat('₹ ',round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))/count(distinct o.C_ID) ,2)) as Revenue_per_Customer ,
concat( round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))/(select * from t_sales)*100 ,2),' %') as `% Sales` from 
product as p join orders_n1 as o on o.P_ID=p.P_ID join cust_tier as c on c.C_ID=o.C_ID where c.tier=tier;

# statewise sales  
with orders_n2 as (select * , year(order_date) as years from orders )
select c.state,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n2 as o on o.P_ID=p.P_ID join cust_tier as c on c.C_ID=o.C_ID where c.tier=tier group by c.state order by total_sales desc;

# citywise sales
with orders_n3 as (select * , year(order_date) as years from orders )
select c.city,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n3 as o on o.P_ID=p.P_ID join cust_tier as c on c.C_ID=o.C_ID where c.tier=tier group by c.city order by total_sales desc;

# company sales
with orders_n4 as (select * , year(order_date) as years from orders )
select p.company_name,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n4 as o on o.P_ID=p.P_ID join cust_tier as c on c.C_ID=o.C_ID where c.tier=tier group by p.company_name order by total_sales desc;

# Daywise sales 
with orders_n4 as (select * , year(order_date) as years ,dayname(order_date) as days from orders)
select o.days ,  concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as total_sales from 
product as p join orders_n4 as o on o.P_ID=p.P_ID join cust_tier as c on c.C_ID=o.C_ID where c.tier=tier group by o.days order by total_sales desc;

# Monthwise Sales before and after discount
select Months,sales_before_discount,sales_after_discount from 
(with orders_n5 as (select * , year(order_date) as years  from orders)
select monthname(o.order_date) as Months, month(o.order_date) as m ,  concat('₹ ',round(sum(o.qty)*avg(p.price),2)) as sales_before_discount ,
concat('₹ ',round(sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100),2)) as sales_after_discount from 
product as p join orders_n5 as o on o.P_ID=p.P_ID join cust_tier as c on c.C_ID=o.C_ID where c.tier=tier group by Months,m order by m ) as mth ;

end //
delimiter ;
call sales_tier('Tier 1');
call sales_tier('Tier 2');
call sales_tier('Tier 3');


# CUSTOMER DASHBOARD
# using Year as slicer
delimiter //
create procedure customer_year (in yr int) # year= 2024,2023
begin

# Single KPIs
with cst_s as 
(with cst as ( select c.C_ID,count(o.Or_ID) as total_order from customer as c join orders as o on o.C_ID=c.C_ID
where year(o.order_date) =yr   group by c.C_ID order by total_order desc)
select count(C_ID) as total_customer, sum(case when total_order>1 then 1 else 0 end) as repeated_customer from cst)
select * ,concat(round(1-total_customer/(select count(*) from customer),2 )*100 ,' %' )as `% customer not engaged`,
concat( round( repeated_customer/total_customer*100,2),' %') as customer_repeated_rate,
concat(round(( 1-repeated_customer/total_customer)*100,2) ,' %') as customer_churn_rate from cst_s;

# Gender
select c.gender,count(c.C_ID) as total_customer from customer as c join orders as o on o.C_ID=c.C_ID
where year(o.order_Date)=yr group by c.gender;

# Daily Purchase 
with cst_hr as (select * , case when hour(order_time) between 6 and 11 then 'Morning' when hour(order_time) between 12 and 17 then 'Afternoon'
when hour(order_time) between 18 and 22 then 'Evening' else 'Night' end as Hr_Prt  from orders where year(order_date)=yr ) 
select o.Hr_Prt,count(c.C_ID) as total_customer from customer as c join cst_hr as o on o.C_ID=c.C_ID group by o.Hr_Prt;

# Transaction Mode
select t.Transaction_Mode,count(c.C_ID) as total_customer from customer as c join orders as o on o.C_ID=c.C_ID join transactions as t  on t.Or_ID=o.Or_ID
where year(o.Order_Date)=yr group by t.Transaction_Mode;

# Citywise Total Customer
select c.city,count(c.C_ID) as total_customer from customer as c join orders as o on o.C_ID=c.C_ID 
where year(o.Order_Date)=yr group by  c.city order by  total_customer limit 10;

# Company Name
select p.company_name,count(c.C_ID) as total_customer from product as p join orders as o on o.P_ID=p.P_ID
join customer as c on c.C_ID=o.C_ID where year(o.Order_Date)=yr group by  p.company_name order by  total_customer ;

# Age vs Gender 
with orders as (select * from orders where year(order_date)=yr ),
customer as (select *, case when age between 18 and 25 then '18-25' when age between 26 and 35 then '26-35' when age between 36 and 45 then '36-45'
when age between 46 and 60 then '46-60' else '>60' end as Age_Prt from customer )
select c.Age_Prt , sum(case when c.gender='Male' then 1 else 0 end ) as Male,sum(case when c.gender='Female' then 1 else 0 end ) as Female
from orders as o join customer as c on c.C_ID=o.C_ID  group by c.Age_Prt;

end //
delimiter ;
call customer_year(2024);
call customer_year(2023);

# using city tier as slicer
create view cust_tier2 as select *,
case 
when city in ("Delhi", "Mumbai", "Chennai", "Kolkata", "Hyderabad", "Bengaluru", "Pune", "Ahmedabad") then "Tier 1"
when city in ("Kanpur", "Surat", "Jaipur", "Lucknow", "Nagpur", "Indore", "Patna", "Visakhapatnam") then "Tier 2"
when city in ("Ghaziabad", "Thane", "Vadodara", "Bhopal") then "Tier 3"
else "Tier Unknown"
end as Tier from customer;

delimiter //
create procedure customer_tier (in tr char(50)) 
begin

# Single KPIs
with cst_s as 
(with cst as ( select c.C_ID,count(o.Or_ID) as total_order from cust_tier2 as c join orders as o on o.C_ID=c.C_ID
where c.Tier=tr  group by c.C_ID order by total_order desc)
select count(C_ID) as total_customer, sum(case when total_order>1 then 1 else 0 end) as repeated_customer from cst)
select * ,concat(round(1-total_customer/(select count(*) from customer),2 )*100 ,' %' )as `% customer not engaged`,
concat( round( repeated_customer/total_customer*100,2),' %') as customer_repeated_rate,
concat(round(( 1-repeated_customer/total_customer)*100,2) ,' %') as customer_churn_rate from cst_s;

# Gender
select c.gender,count(c.C_ID) as total_customer from cust_tier2 as c join orders as o on o.C_ID=c.C_ID
where c.Tier=tr group by c.gender;

# Daily Purchase 
with cst_hr as (select * , case when hour(order_time) between 6 and 11 then 'Morning' when hour(order_time) between 12 and 17 then 'Afternoon'
when hour(order_time) between 18 and 22 then 'Evening' else 'Night' end as Hr_Prt  from orders ) 
select o.Hr_Prt,count(c.C_ID) as total_customer from cust_tier2 as c join cst_hr as o on o.C_ID=c.C_ID where c.Tier=tr  group by o.Hr_Prt;

# Transaction Mode
select t.Transaction_Mode,count(c.C_ID) as total_customer from cust_tier2 as c join orders as o on o.C_ID=c.C_ID join transactions as t  on t.Or_ID=o.Or_ID
where c.Tier=tr group by t.Transaction_Mode;

# Citywise Total Customer
select c.city,count(c.C_ID) as total_customer from cust_tier2 as c join orders as o on o.C_ID=c.C_ID 
where c.Tier=tr group by  c.city order by  total_customer limit 10;

# Company Name
select p.company_name,count(c.C_ID) as total_customer from product as p join orders as o on o.P_ID=p.P_ID
join cust_tier2  as c on c.C_ID=o.C_ID where c.Tier=tr group by  p.company_name order by  total_customer ;

# Age vs Gender 
with orders as (select * from orders  ),
customer as (select *, case when age between 18 and 25 then '18-25' when age between 26 and 35 then '26-35' when age between 36 and 45 then '36-45'
when age between 46 and 60 then '46-60' else '>60' end as Age_Prt from cust_tier2 where  Tier=tr  )
select c.Age_Prt , sum(case when c.gender='Male' then 1 else 0 end ) as Male,sum(case when c.gender='Female' then 1 else 0 end ) as Female
from orders as o join customer as c on c.C_ID=o.C_ID  group by c.Age_Prt;

end //
delimiter ;
call customer_tier('Tier 1');
call customer_tier('Tier 2');
call customer_tier('Tier 3');


# PRODUCT AND SALES DASHBOARD
# Using Year as Slicer
delimiter //
create procedure prod_sales_year (in yr int )
begin 

# Single KPIs 
select count(distinct o.P_ID) as product_sold,sum(o.qty) as total_quantity_sold,
sum(case when o.qty<2 then 1 else 0 end ) as slow_moving_Product,round(avg(r.Prod_Rating),2) as Prod_Rating ,
round(avg(r.Delivery_Service_Rating),2) as Delivery_Service_Rating, concat( round( count(distinct rr.Or_ID)/count(distinct o.Or_ID)*100,2),' %') as return_requested
from orders as o left join ratings as r on r.Or_ID=o.Or_ID
left join return_refund as rr on rr.Or_ID=r.Or_ID where year(o.order_date)=yr ;

# Brands vs states
select c.state,
round(sum(case when p.company_name='Puma' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Puma`,
round(sum(case when p.company_name='Gap' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Gap`,
round(sum(case when p.company_name='Reebok' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Reebok`,
round(sum(case when p.company_name="Levi's" then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Levi's`,
round(sum(case when p.company_name='H&M' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `H&M`,
round(sum(case when p.company_name='Zara' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Zara`,
round(sum(case when p.company_name='Pantaloons' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Pantaloons`,
round(sum(case when p.company_name='Nike' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Nike` 
from orders as o join product as p on p.P_ID=o.P_ID  join customer as c on c.C_ID=o.C_ID 
where year(o.order_date)=yr  group by c.state;

# Citywise Product Sold
select c.city,count(p.P_ID) as total_product_sold from product as p join orders as o on o.P_ID=p.P_ID join 
customer as c on c.C_ID=o.C_ID where year(o.order_date)=yr  group by c.city order by count(p.P_ID) desc;

# Delivery Partner
select d.DP_name,round( avg(r.Delivery_Service_Rating),2) as delivery_partner_rate from orders as o join ratings as r on 
r.Or_ID=o.Or_ID join delivery as d on d.DP_ID=o.DP_ID where year(o.order_date)=yr  group by d.DP_name order by delivery_partner_rate;

# MOM Sales
with mom_prct as
(with mom_sales as
(select monthname(o.order_date) as months,month(o.order_date) as m, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) ,2) as sales from
orders as o join product as p on o.P_ID=p.P_ID where year(o.order_date)=yr group by months,m order by m asc) 
select months,sales, lag(sales,1,0) over () as pre_sales  from mom_sales) 
select months ,  round( (sales-pre_sales)/pre_sales*100,2) as `MOM %` from mom_prct; 

# Quarter sales
select concat('Qtr', quarter(o.order_date)) as Quarters , round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) ,2) as sales from
orders as o join product as p on o.P_ID=p.P_ID where year(o.order_date)=yr group by Quarters;

# Product Gender 
select gender, concat( round(total_customer/(sum(total_customer) over ())*100 ,2),' %') as total_customer from
(select p.gender, count(c.C_ID) as total_customer from orders as o join customer as c on c.C_ID=o.C_ID join product as p 
on p.P_ID=o.P_ID where year(o.order_date)=yr group by  p.gender  ) as prct_order;

end //
delimiter ;
call prod_sales_year(2024);
call prod_sales_year(2023);

# Using Category as Slicer
delimiter //
create procedure prod_sales_category (in ct char(100) )
begin  

# Single KPIs 
select count(distinct o.P_ID) as product_sold,sum(o.qty) as total_quantity_sold,
sum(case when o.qty<2 then 1 else 0 end ) as slow_moving_Product,round(avg(r.Prod_Rating),2) as Prod_Rating ,
round(avg(r.Delivery_Service_Rating),2) as Delivery_Service_Rating, concat( round( count(distinct rr.Or_ID)/count(distinct o.Or_ID)*100,2),' %') as return_requested
from orders as o left join ratings as r on r.Or_ID=o.Or_ID join product as p on p.P_ID=o.P_ID
left join return_refund as rr on rr.Or_ID=r.Or_ID  where p.category=ct ;

# Brands vs states
select c.state,
round(sum(case when p.company_name='Puma' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Puma`,
round(sum(case when p.company_name='Gap' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Gap`,
round(sum(case when p.company_name='Reebok' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Reebok`,
round(sum(case when p.company_name="Levi's" then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Levi's`,
round(sum(case when p.company_name='H&M' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `H&M`,
round(sum(case when p.company_name='Zara' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Zara`,
round(sum(case when p.company_name='Pantaloons' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Pantaloons`,
round(sum(case when p.company_name='Nike' then o.qty*p.price*(1-o.discount/100) else 0 end),2) as `Nike` 
from orders as o join product as p on p.P_ID=o.P_ID  join customer as c on c.C_ID=o.C_ID 
where p.category=ct   group by c.state;

# Citywise Product Sold
select c.city,count(p.P_ID) as total_product_sold from product as p join orders as o on o.P_ID=p.P_ID join 
customer as c on c.C_ID=o.C_ID where p.category=ct  group by c.city order by count(p.P_ID) desc;

# Delivery Partner
select d.DP_name,round( avg(r.Delivery_Service_Rating),2) as delivery_partner_rate from product as p join  orders as o on o.P_ID=p.P_ID join ratings as r on 
r.Or_ID=o.Or_ID join delivery as d on d.DP_ID=o.DP_ID where  p.category=ct  group by d.DP_name order by delivery_partner_rate;

# MOM Sales
with mom_prct as
(with mom_sales as
(select monthname(o.order_date) as months,month(o.order_date) as m, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) ,2) as sales from
orders as o join product as p on o.P_ID=p.P_ID where  p.category=ct group by months,m order by m asc) 
select months,sales, lag(sales,1,0) over () as pre_sales  from mom_sales) 
select months ,  round( (sales-pre_sales)/pre_sales*100,2) as `MOM %` from mom_prct; 

# Quarter sales
select concat('Qtr', quarter(o.order_date)) as Quarters , round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) ,2) as sales from
orders as o join product as p on o.P_ID=p.P_ID where  p.category=ct group by Quarters;

# Product Gender 
select gender, concat( round(total_customer/(sum(total_customer) over ())*100 ,2),' %') as total_customer from
(select p.gender, count(c.C_ID) as total_customer from orders as o join customer as c on c.C_ID=o.C_ID join product as p 
on p.P_ID=o.P_ID where  p.category=ct group by  p.gender  ) as prct_order;

end //
delimiter ;
call prod_sales_category('Jeans');
call prod_sales_category('Blazer');
call prod_sales_category('Hoodie');
call prod_sales_category('Shirt');
call prod_sales_category('Dress');
call prod_sales_category('Skirt');
call prod_sales_category('Shorts');
call prod_sales_category('T-Shirt');
call prod_sales_category('Jacket');
call prod_sales_category('Sweater');


# RETURN DASHBOARD
# Using Year as Slicer
delimiter //
create procedure return_year(in yr int )
begin

# Single KPIs
with ret_order as 
(select count(distinct rr.Or_ID) as return_requested, sum(case when rr.Return_Refund='Approved' then 1 else 0 end ) as Total_product_returned,
round( sum(case when rr.Return_Refund='Approved' then o.qty*p.price*(1-o.discount/100 ) else 0 end ) ,2) as loss_due_to_return from 
return_refund as rr join orders as o on o.Or_ID=rr.Or_ID join product as p on p.P_ID=o.P_ID where  year(o.order_date)=yr ) 
select * , concat(round(Total_product_returned/(select count(Or_ID) from orders )*100 ,2),' %') as `% Product Return`,
concat(round(loss_due_to_return/(select sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) from orders as o join product as p on p.P_ID=o.P_ID )*100,3),' %') 
as `% Loss due to Product Return` from ret_order;

# Loss for Delivery Partner
select d.DP_name, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(Percent_Cut)/100) ,2) as delivery_loss from product as p 
join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID 
where year(o.order_date)=yr  group by d.DP_name;

# Loss by month
with ret_lss_m as 
(select monthname(o.order_date) as Months ,month(o.order_date) as m, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(Percent_Cut)/100) ,2) as delivery_loss 
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID 
where year(o.order_date)=yr  group by Months,m order by m asc ) select Months,delivery_loss from ret_lss_m ;

# Citiwise Return
select c.city,count(o.Or_ID) as total_return from customer as c join orders as o on o.C_ID=c.C_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where year(o.order_date)=yr  group by c.city order by total_return  desc;

# Company Loss
select p.company_name, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) ,2) as delivery_loss from product as p 
join orders as o on o.P_ID=p.P_ID  join return_refund as rr on rr.Or_ID=o.Or_ID where year(o.order_date)=yr  
group by  p.company_name order by delivery_loss desc;

# Top 10 Product Return
select p.p_name,count(o.Or_ID) as total_return from product as p join orders as o on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where year(o.order_date)=yr  group by p.p_name order by total_return  desc limit 10;

# Return Approval
select *, concat(round(prod_return/(sum(prod_return) over ()),2)*100,' %') as `% Return Approval` from
(select rr.Return_Refund,count(o.Or_ID) as prod_return from orders as o join return_refund as rr
where rr.Or_ID=o.Or_ID and year(o.Order_Date)=yr group by rr.Return_Refund) as prct_rt;

end //
delimiter ;
call return_year(2024);
call return_year(2023);

# Using Category as Slicer
delimiter //
create procedure return_category(in cat char(100) )
begin

# Single KPIs
with ret_order as 
(select count(distinct rr.Or_ID) as return_requested, sum(case when rr.Return_Refund='Approved' then 1 else 0 end ) as Total_product_returned,
round( sum(case when rr.Return_Refund='Approved' then o.qty*p.price*(1-o.discount/100 ) else 0 end ) ,2) as loss_due_to_return from 
return_refund as rr join orders as o on o.Or_ID=rr.Or_ID join product as p on p.P_ID=o.P_ID where  p.category=cat ) 
select * , concat(round(Total_product_returned/(select count(Or_ID) from orders )*100 ,2),' %') as `% Product Return`,
concat(round(loss_due_to_return/(select sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) from orders as o join product as p on p.P_ID=o.P_ID )*100,3),' %') 
as `% Loss due to Product Return` from ret_order;

# Loss for Delivery Partner
select d.DP_name, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(Percent_Cut)/100) ,2) as delivery_loss from product as p 
join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID 
where p.category=cat  group by d.DP_name;

# Loss by month
with ret_lss_m as 
(select monthname(o.order_date) as Months ,month(o.order_date) as m, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(Percent_Cut)/100) ,2) as delivery_loss 
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID 
where p.category=cat  group by Months,m order by m asc ) select Months,delivery_loss from ret_lss_m ;

# Citiwise Return
select c.city,count(o.Or_ID) as total_return from customer as c join orders as o on o.C_ID=c.C_ID join return_refund as rr on rr.Or_ID=o.Or_ID
join product as p on p.P_ID=o.P_ID  where p.category=cat group by c.city order by total_return  desc;

# Company Loss
select p.company_name, round( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) ,2) as delivery_loss from product as p 
join orders as o on o.P_ID=p.P_ID  join return_refund as rr on rr.Or_ID=o.Or_ID where p.category=cat  
group by  p.company_name order by delivery_loss desc;

# Top 10 Product Return
select p.p_name,count(o.Or_ID) as total_return from product as p join orders as o on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where p.category=cat  group by p.p_name order by total_return  desc limit 10;

# Return Approval
select *, concat(round(prod_return/(sum(prod_return) over ()),2)*100,' %') as `% Return Approval` from
(select rr.Return_Refund,count(o.Or_ID) as prod_return from orders as o join return_refund as rr
on rr.Or_ID=o.Or_ID join product as p on p.P_ID=o.P_ID where p.category=cat group by rr.Return_Refund) as prct_rt;

end //
delimiter ;
call return_category('Jeans');
call return_category('Blazer');
call return_category('Hoodie');
call return_category('Shirt');
call return_category('Dress');
call return_category('Skirt');
call return_category('Shorts');
call return_category('T-Shirt');
call return_category('Jacket');
call return_category('Sweater');







