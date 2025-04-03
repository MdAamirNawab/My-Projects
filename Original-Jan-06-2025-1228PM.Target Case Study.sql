create database aamir_db
use aamirkhandb

-- 1.Initial Exploration
--o	Get the time range between which the orders were placed.

select 
	min(order_purchase_timestamp) as min_date, 
	max(order_purchase_timestamp) as max_date,
	datediff(day , min(order_purchase_timestamp), max(order_purchase_timestamp)) as time_range_between_orders
from orders

--o	Count the cities & states of customers who ordered during the given period.

SELECT
	count(distinct customer_city) as City_count,
	count(distinct customer_state) as State_count 
	FROM
	customers as c JOIN orders as o
	ON c.customer_id = o.customer_id;

	-- 2.	In-depth Exploration
-- o	Identify trends in the number of orders placed over the years.
select 
	year(order_purchase_timestamp) as Years,
	month(order_purchase_timestamp) as Months,
	count(*) as number_orders
from 
	orders
group by 
	year(order_purchase_timestamp),month(order_purchase_timestamp)
order by
	year(order_purchase_timestamp),month(order_purchase_timestamp)

-- o	Detect any monthly seasonality in the number of orders.
select top 5
	month(order_purchase_timestamp) as Months,
	count(*) as number_orders
from 
	orders
group by 
	month(order_purchase_timestamp)
order by count(*) desc

-- o	Determine the time of day when Brazilian customers mostly place orders (Dawn, Morning, Afternoon, or Night).

select 
case when datepart(hour,order_purchase_timestamp) between 0 and 6 then 'Dawn'
when datepart(hour,order_purchase_timestamp) between 7 and 12 then 'Morning'
when datepart(hour,order_purchase_timestamp) between 13 and 18 then 'Afternoon'
else 'Night'
end as Duration,
count(*) as Total_count
from orders
group by 
case when datepart(hour,order_purchase_timestamp) between 0 and 6 then 'Dawn'
when datepart(hour,order_purchase_timestamp) between 7 and 12 then 'Morning'
when datepart(hour,order_purchase_timestamp) between 13 and 18 then 'Afternoon'
else 'Night'
end
order by count(*) desc

-- another solution can be

with cte as
(
select order_purchase_timestamp,
case
when datepart(hour,order_purchase_timestamp) > 0 and datepart(hour,order_purchase_timestamp)< 6 then 'Dawn'
when datepart(hour,order_purchase_timestamp) > 6 and datepart(hour,order_purchase_timestamp)< 12 then 'Morning'
when datepart(hour,order_purchase_timestamp) > 12 and datepart(hour,order_purchase_timestamp)< 18then 'Afternoon'
else 'Night'
end as Duration
from orders
)
select Duration,count(*) as counts from cte
group by Duration
order by count(*) desc

-- 3.	Evolution of E-commerce Orders in Brazil (10 points)
--o	Month-on-month number of orders placed in each state.
select 
	b.customer_state,
	datename(month,a.order_purchase_timestamp) as Months,
	count(a.order_purchase_timestamp) as counts
from 
	orders as a
join 
	customers as b
on 
	a.customer_id = b.customer_id
group by 
	b.customer_state,
	datename(month,a.order_purchase_timestamp)
	order by count(a.order_purchase_timestamp)

--o	Distribution of customers across all states.

select customer_state, count(customer_id) as number_of_customers
from customers
group by customer_state
order by count(customer_id) desc

-- 4.	Impact on Economy - Analyze money movement by looking at order prices, freight, and other factors.
-- o	Calculate the percentage increase in the cost of orders from 2017 to 2018 (Jan-Aug).
with cte1 as
(
select o.*,p.payment_value
from orders o
join payments p
on o.order_id = p.order_id
where year(o.order_purchase_timestamp) between 2017 and 2018 and 
month(o.order_purchase_timestamp)between 1 and 8
),
cte2 as
(
select year(order_purchase_timestamp) as Years,
sum(payment_value) as cost
from cte1
group by year(order_purchase_timestamp)
)

select Years, round(cost,2) as cost,
round(lead(cost)over(order by Years),2),
(((lead(cost)over(order by Years)-cost)/cost)*100) as Percent_increase
from cte2

-- o	Calculate the total & average value of order prices and freight for each state.

-- o	Calculate the total & average value of order prices for each state.

select c.customer_state,
sum(p.payment_value) as total_price, 
AVG(p.payment_value) as average_price
from payments as p
join orders as o on p.order_id = o.order_id 
join customers as c on c.customer_id = o.customer_id
group by c.customer_state
order by c.customer_state


--5.Analysis on Sales, Freight, and Delivery Time 
--o	Calculate the delivery time and the difference between estimated and actual delivery dates.

select
	datediff(day,order_purchase_timestamp,order_estimated_delivery_date) as estimated_days,
	datediff(day,order_purchase_timestamp,order_delivered_customer_date) as actual_delivery_time,
	datediff(day,order_delivered_customer_date,order_estimated_delivery_date) as diff
from orders
where order_status = 'delivered'

--o	Identify the top 5 states with the highest & lowest average freight values.

select top 5 c.customer_state, avg(oi.freight_value) as AVG_top_5_freight_value
from order_items oi
join orders o
on oi.order_id = o.order_id
join customers c
on c.customer_id = o.customer_id 
group by c.customer_state
order by AVG_top_5_freight_value desc

-----------------------------------------------------------

select top 5 c.customer_state, avg(oi.freight_value) as AVG_lowest_5_freight_value
from order_items as oi join orders as o
on oi.order_id = o.order_id join customers as c on c.customer_id = o.customer_id
group by c.customer_state 
order by AVG_lowest_5_freight_value


--o	Identify the top 5 states with the highest & lowest average delivery times.

select top 5 c.customer_state, 
avg(datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) as AVG_highest_5_delivery_times
from orders as o
join customers as c
on o.customer_id = c.customer_id 
group by c.customer_state
order by AVG_highest_5_delivery_times desc

----------------------------------------------------------------

select top 5 c.customer_state, 
avg(datediff(day,o.order_purchase_timestamp,o.order_delivered_customer_date)) as AVG_lowest_5_delivery_times
from orders as o
join customers as c
on o.customer_id = c.customer_id 
group by c.customer_state
order by AVG_lowest_5_delivery_times 

----------------------------------------------------------------

--o	Identify the top 5 states where delivery is faster than the estimated date.

SELECT top 5
    c.customer_state,
    DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS faster_delivery_days
FROM orders AS o JOIN customers AS c 
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date < o.order_estimated_delivery_date  
-- Ensure delivery is faster
ORDER BY 
faster_delivery_days 
 -- Sort by the fastest deliveries (smallest negative values)
 =============================================================================

 --6.	Analysis Based on Payments

--o	Month-on-month number of orders placed using different payment types.

select payment_type,MONTH(order_purchase_timestamp) as months, year(order_purchase_timestamp) as years,

datename(month,order_purchase_timestamp) as month_name, count(payment_type) as number_of_orders
from orders as o
join payments as p on o.order_id = p.order_id
group by  year(order_purchase_timestamp), MONTH(order_purchase_timestamp),datename(month,order_purchase_timestamp),
payment_type

====================================

--o	Number of orders based on payment installments.


select payment_installments, count(payment_installments) as number_of_orders
from payments
where payment_installments > 1
group by payment_installments
order by count(payment_installments) desc

=======================================================

--- Ques - Find the number of total fast deliveries.

SELECT  
    c.customer_state,  
    COUNT(DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS total_faster_delivery_days  
FROM orders AS o  
JOIN customers AS c  
    ON o.customer_id = c.customer_id  
WHERE o.order_status = 'delivered'  
AND o.order_delivered_customer_date < o.order_estimated_delivery_date  
GROUP BY c.customer_state WITH ROLLUP  
ORDER BY total_faster_delivery_days ASC;

=======================================================

--Insights
--The data covers a time period of about 2 years.
--Between September 2016 and November 2017, the number of orders generally increased, showing overall growth. However, this growth slowed down in December 2017, then bounced back in January 2018, remained stable for a while, and then sharply declined again in September 2018.
--Orders tend to be higher in the middle months of the year (May, June, July, August), likely because of summer holiday shopping, suggesting these months are popular for shopping.
--September has the lowest order count in this dataset. It could be helpful to look into possible reasons for the sudden and large drop in orders during this month.
--The majority of orders were placed in the night, followed by the afternoon.
--The cost of orders increased by 136.98% from 2017 to 2018.
--Out of all orders, approx 87,000 were delivered before the estimated delivery date.
--The most commonly used payment method was credit card, followed by UPI.
