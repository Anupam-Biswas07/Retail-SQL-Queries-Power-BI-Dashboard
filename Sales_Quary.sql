select * from sales;
select count(distinct Customer_ID) from sales;

-- Total Qnt Sold ---
create view Total_Quantity_Sold as
select 
	sum(Quantity_sold) As 'Total Quantity Sold'
from sales;

-- Total Revenue ---
create view Total_Revenue as
select 
	round(
	sum(Total_Sale_Amount), 2) as 'Total Revenue'
from sales;

-- Total Return --
create view Total_Return as
select
	sum(Quantity_sold) as 'Total Return'
from sales
	where Returned = 'Yes';
	
-- Total store --
create view Total_Store as
select 
	count(distinct Store_ID) as 'Total Store'
from sales;

-- Avg Qnty sold per store --
create view Avg_Qnty_sold_per_store as
select
	round(
	sum(Quantity_Sold)/ count(distinct Store_ID),0) as 'Avg Qty Sold Per Store' 
from sales;    

-- Avg Revenue per store --
create view Avg_Revenue_per_store as
select
	round(
	sum(Total_Sale_Amount)/ count(distinct Store_ID),2) as 'Avg Revenue Per Store' 
from sales;  

-- Avg Return per store --
create view Avg_Return_per_store as
SELECT 
    ROUND(
        SUM(CASE WHEN Returned = 'Yes' THEN Quantity_Sold ELSE 0 END) 
        / COUNT(DISTINCT Store_ID), 2
    ) AS 'Avg Return Per Store'
FROM sales;

-- 1. Which region has the highest total revenue?--
create view Region_wise_total_revenue as
select 
	Region,
    round(
    sum(Total_Sale_Amount), 2) as Revenue
from sales    
    group by Region
    order by Revenue Desc;
    
-- estra total revenue ---   
create view Category_wise_total_revenue as
select 
	Product_Category,
    round(
    sum(Total_Sale_Amount), 2) as Revenue
from sales    
    group by Product_Category
    order by Revenue Desc;    
 -- 2. Which product category generates the highest revenue on average per sale? --
create view Product_Category_wise_Revenue as 
 select
	Product_Category,
    round(
    avg(Total_Sale_Amount), 2) as Avg_Revenue_Per_Sale
from sales
		group by Product_Category
        order by Avg_Revenue_Per_Sale desc;

-- 3. What is the return rate per product category? --
create view return_rate_per_product_category as
with Returndata as (
	select
		product_category,
		SUM(CASE WHEN Returned = 'Yes' THEN Quantity_Sold ELSE 0 END) as Total_Return_Qty,
		sum(Quantity_Sold) as Total_Quantity    
	from sales
	group by  product_category
)  
select 
	product_category,
    Total_Return_Qty,
    Total_Quantity,  
    ROUND(100.0 * Total_Return_Qty / NULLIF(Total_Quantity, 0), 2) AS Return_Rate_Percent
FROM ReturnData
order by Return_Rate_Percent desc;

-- 4. Top 5 products with highest total sales by quantity --
create view top5_product_sales_qty as
SELECT 
	Product_ID,
	SUM(Quantity_Sold) AS Total_Sold
FROM sales
GROUP BY Product_ID
ORDER BY Total_Sold DESC
LIMIT 5;

-- 5. Which store has lowest revenue but highest number of sales?--
create view high_sales_low_revenue_1 as
SELECT 
Store_ID,
	COUNT(*) AS Number_of_Sales, 
	round(SUM(Total_Sale_Amount),2) AS Total_Revenue
FROM sales
GROUP BY Store_ID
ORDER BY Total_Revenue asc, Number_of_Sales DESC;


-- 5.1  Which store has the lowest average revenue per sale?"--
create view lowest_avg_revenue as
SELECT 
    Store_ID,
    COUNT(Sale_ID) AS Number_of_Sales,
    round(SUM(Total_Sale_Amount),2) AS Total_Revenue,
    ROUND(SUM(Total_Sale_Amount) / NULLIF(COUNT(Sale_ID), 0), 2) AS Avg_Revenue_Per_Sale
FROM sales
GROUP BY Store_ID
ORDER BY Avg_Revenue_Per_Sale ASC
limit 5;


-- 6. How do different payment methods impact total revenue?--
create view pmt_mthd_impact_total_rev as
select 
	Payment_Method,
    round(sum(Total_sale_amount),2) as total_revenue
from sales
group by Payment_Method
order by total_revenue desc;   

-- 7. Which customers have made the most purchases in terms of total amount spent?--
create view Most_spending_Customer as
select
	Customer_ID,
    round(sum(Total_sale_amount),2) as Total_Spend
from sales
group by Customer_ID
order by Total_Spend desc
limit 5;  

-- 8. Which quarter sees the highest sales?--
create view HIghest_qut_sale as
SELECT 
  QUARTER(STR_TO_DATE(Sale_Date, '%d-%m-%y')) AS Quarter,
  round(SUM(Total_Sale_Amount),2) AS Total_Revenue
FROM sales
GROUP BY Quarter 
ORDER BY  Quarter asc;  

-- 9. What is the average unit price per product category?--
create view avg_unit_price_by_product_category as
select
	Product_Category,
    round(avg(unit_price),2) as Avg_Unit_Price
from sales
group by Product_Category; 

-- Quantity Sold Trend by Month ----

Create view Quantity_Sold_Trend_by_Month as
SELECT
  DATE_FORMAT(STR_TO_DATE(Sale_Date, '%d-%m-%y'), '%b %Y') AS Sale_Month,
   DATE_FORMAT(STR_TO_DATE(Sale_Date, '%d-%m-%y'),'%Y%m') AS Sort_Column,
  SUM(Quantity_Sold) AS Total_Quantity_Sold
FROM sales
WHERE Returned = 'No'
GROUP BY Sale_Month, Sort_Column
ORDER BY Sort_Column;
-- Revenue Trend by Month---
create view Revenue_Trend_by_Month as 
SELECT
  DATE_FORMAT(STR_TO_DATE(Sale_Date, '%d-%m-%y'), '%b %Y') AS Sale_Month,
  DATE_FORMAT(STR_TO_DATE(Sale_Date, '%d-%m-%y'),'%Y%m') AS Sort_Column,
  round(SUM(Total_Sale_Amount),2) AS Total_Revenue
FROM sales
WHERE Returned = 'No'
GROUP BY Sale_Month, Sort_Column
ORDER BY Sort_Column;



   
    
 -- RFM Secmentation-----
create view RFM_Segmentation as 
with cte1 as (
	select Sale_Id,Sale_Date, Customer_ID, Quantity_Sold, Unit_Price,Total_Sale_Amount from sales
	where Customer_ID is not null and Sale_Id is not null
	and Quantity_Sold > 0
),
cte2 as (
select 
	customer_id,
    max(str_to_date(Sale_Date, '%d-%m-%y')) as Latest_date,
    (select max(str_to_date(Sale_Date, '%d-%m-%y'))from sales) as Max_Date,
    round(sum(Total_Sale_Amount),2) as Monetary,
    count(distinct Sale_ID) as Frequency
 from cte1
 group by customer_ID
 ),
 cte3 as (
 select 
    Customer_ID,
    timestampdiff(day,Latest_Date,Max_Date) +1 AS Recency,
    Frequency,
    Monetary
from cte2
),
cte4 as (
select *,
	ntile(5) over(order by Recency desc) As R,
    ntile(5) over(order by Frequency asc) As F,
    ntile(5) over(order by Monetary asc) As M
 from cte3
 ),
 cte5 as (
 select *,
	concat(R,F,M) As RFM
 from cte4
 ),
 cte6 as (
	SELECT *,
	CASE
		WHEN R= 5 AND F = 5 AND M = 5 THEN 'Champion'
		WHEN R >= 4 AND F >= 4 THEN 'Loyal'
		WHEN R >= 3 AND M >= 3 THEN 'Potential Loyalist'
		WHEN R = 5 THEN 'Recent Customer'
		WHEN F = 5 THEN 'Frequent Buyer'
		WHEN M = 5 THEN 'Big Spender'
		WHEN R = 1 AND F = 1 AND M = 1 THEN 'Lost'
		ELSE 'Others'
	END AS RFM_Segment
 from cte5
 )
SELECT 
  RFM_Segment,
  round( count(*) / (select count(*) from cte6 ) * 100,0) as perct_count
from cte6 
GROUP BY RFM_Segment
ORDER BY perct_count DESC;
 

  


  SELECT 
    Store_ID,
    COUNT(Sale_ID) AS Number_of_Sales,
    round(SUM(Total_Sale_Amount),2) AS Total_Revenue,
    ROUND(SUM(Total_Sale_Amount) / NULLIF(COUNT(Sale_ID), 0), 2) AS Avg_Revenue_Per_Sale
FROM sales
GROUP BY Store_ID
ORDER BY Avg_Revenue_Per_Sale ASC
    
        


    
    