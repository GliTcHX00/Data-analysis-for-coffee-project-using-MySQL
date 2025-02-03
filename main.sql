SELECT * from city
SELECT * from customers
SELECT * from products
SELECT * from sales


-- reports & data analysis

--* Coffee Consumers Count
--* How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name,
    ROUND(population * 0.25 / 1000000, 2) AS Coffee_Consumers_in_millions,
    city_rank
from city
ORDER BY 2 DESC


--* Total Revenue from Coffee Sales
--* What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT ci.city_name, SUM(s.total) total_revenue
FROM 
    sales as s
join customers as c
on 
    s.customer_id = c.customer_id
JOIN city as ci
on 
    ci.city_id = c.city_id
where 
    QUARTER(s.sale_date) = 4 and YEAR(s.sale_date) = 2023
GROUP BY 1
ORDER BY 2 DESC


--* Sales Count for Each Product
--* How many units of each coffee product have been sold?

SELECT d.product_name, COUNT(*) total_orders, SUM(s.total) total_sales
from sales s
join products d
on s.product_id = d.product_id
GROUP BY 1
ORDER BY 2 DESC


--* Average Sales Amount per City
--* What is the average sales amount per customer in each city?

SELECT ci.city_name, 
    SUM(s.total) total_revenue, 
    COUNT(DISTINCT s.customer_id) total_unique_cus,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cus
FROM 
    sales as s
join customers as c
on 
    s.customer_id = c.customer_id
JOIN city as ci
on 
    ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC


--* City Population and Coffee Consumers ( 25% )
--* Provide a list of cities along with their populations and estimated coffee consumers.

WITH city_table AS
(
    SELECT city_name, 
    ROUND((population * 0.25) / 1000000, 2) as coffee_Consumers_in_millions
    from city
),
customers_table
AS
(
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_Consumers
    from sales s
    join customers c
    on s.customer_id = c.customer_id
    join city ci
    on c.city_id = ci.city_id
    GROUP BY 1
    ORDER BY 2 DESC
)
SELECT 
    city_table.city_name,
    city_table.coffee_Consumers_in_millions,
    customers_table.unique_Consumers
from city_table
join customers_table
on city_table.city_name = customers_table.city_name
ORDER BY 2 DESC


--* Top Selling Products by City
--* What are the top 3 selling products in each city based on sales volume?

SELECT *
from 
(
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) as total_orders,
        DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) `rank`

    FROM sales as s
    JOIN products as p
    ON s.product_id = p.product_id
    JOIN customers as c
    ON c.customer_id = s.customer_id
    JOIN city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1, 2

) as t1
where `rank` <= 3


--* Customer Segmentation by City
--* How many unique customers are there in each city who have purchased coffee products?

SELECT ci.city_name, COUNT(DISTINCT c.customer_id) AS unique_customers
from city ci
join customers c
on ci.city_id = c.city_id
join sales s
on c.customer_id = s.customer_id
where s.product_id in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
-- where s.product_id <= 14
GROUP BY 1
ORDER BY 2 DESC


--* Average Sale vs Rent
--* Find each city and their average sale per customer and avg rent per customer

with city_table AS
(
    SELECT ci.city_name, 
        SUM(s.total) total_revenue, 
        COUNT(DISTINCT s.customer_id) total_unique_cus,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cus
    FROM 
        sales as s
    join customers as c
    on 
        s.customer_id = c.customer_id
    JOIN city as ci
    on 
        ci.city_id = c.city_id
    GROUP BY 1
    ORDER BY 2 DESC
), 
city_rent AS
(
    SELECT city_name, estimated_rent
    from city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_unique_cus,
    ct.avg_sale_per_cus,
    ROUND(cr.estimated_rent / ct.total_unique_cus, 2) as avg_rent_per_cus
from city_table as ct
JOIN city_rent as cr
on ct.city_name = cr.city_name
ORDER BY 4 DESC


--* Monthly Sales Growth
--* Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
--* by each city

with monthly_sales AS
(
    SELECT ci.city_name,
        YEAR(s.sale_date) year,
        MONTH(s.sale_date) month,
        SUM(s.total) cr_month_sales
    from sales s
    JOIN customers c
    on s.customer_id = c.customer_id
    JOIN city ci
    on c.city_id = ci.city_id
    GROUP BY 1, 2, 3
    order by 1, 2, 3
), 
growth_ratio AS
(
    SELECT city_name,
        year,
        month,
        cr_month_sales,
        LAG(cr_month_sales, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sales
    from monthly_sales
)
SELECT city_name,
    year,
    month,
    cr_month_sales,
    last_month_sales,
    ROUND((cr_month_sales - last_month_sales) / last_month_sales * 100, 2) AS GROWTH_RATIO
from growth_ratio
where last_month_sales is NOT NULL


--* Market Potential Analysis
--* Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with city_table AS
(
    SELECT ci.city_name, 
        SUM(s.total) total_revenue, 
        COUNT(DISTINCT s.customer_id) total_unique_cus,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cus
    FROM 
        sales as s
    join customers as c
    on 
        s.customer_id = c.customer_id
    JOIN city as ci
    on 
        ci.city_id = c.city_id
    GROUP BY 1
    ORDER BY 2 DESC
), 
city_rent AS
(
    SELECT city_name, estimated_rent, ROUND((population * 0.25) / 1000000, 3) as estimated_coffee_consumer_in_millions
    from city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    cr.estimated_coffee_consumer_in_millions,
    ct.total_unique_cus,
    ct.avg_sale_per_cus,
    ROUND(cr.estimated_rent / ct.total_unique_cus, 2) as avg_rent_per_cus
from city_table as ct
JOIN city_rent as cr
on ct.city_name = cr.city_name
ORDER BY 2 DESC


--*______________________________________________________________________________

--* -- Recomendation
--* City 1: Pune
--* 	1.Average rent per customer is very low.
--* 	2.Highest total revenue.
--* 	3.Average sales per customer is also high.

--* City 2: Delhi
--* 	1.Highest estimated coffee consumers at 7.7 million.
--* 	2.Highest total number of customers, which is 68.
--* 	3.Average rent per customer is 330 (still under 500).

--* City 3: Jaipur
--* 	1.Highest number of customers, which is 69.
--* 	2.Average rent per customer is very low at 156.
--* 	3.Average sales per customer is better at 11.6k.

--*______________________________________________________________________________