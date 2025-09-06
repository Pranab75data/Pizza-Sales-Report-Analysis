
CREATE DATABASE PIZZA_SALES
USE PIZZA_SALES

SELECT * FROM order_details_FACT
SELECT * FROM orders_DIM
SELECT * FROM pizza_types_DIM
SELECT * FROM pizzas_DIM

--Retrieve the total number of orders placed
SELECT COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS FROM order_details_FACT

--Calculate the total revenue generated from pizza sales
SELECT ROUND(SUM(OD.QUANTITY * P.PRICE),2) AS TOTAL_REVENUE FROM order_details_FACT OD
JOIN pizzas_DIM P ON P.pizza_id = OD.pizza_id

--Identify the highest-priced pizza
SELECT TOP 1 P.PIZZA_TYPE_ID, PT.NAME, ROUND(P.PRICE,2) AS HIGHEST_PRICE_PIZZA FROM pizzas_DIM P
JOIN pizza_types_DIM PT ON P.pizza_type_id = PT.pizza_type_id
ORDER BY P.PRICE DESC

--Identify the most common pizza size ordered.
SELECT P.SIZE, COUNT(DISTINCT OD.order_details_id) AS TOTAL_ORDERS FROM pizzas_DIM P 
JOIN order_details_FACT OD ON P.pizza_id = OD.pizza_id
GROUP BY P.SIZE
ORDER BY TOTAL_ORDERS DESC

--List the top 5 most ordered pizza types along with their quantities.
SELECT TOP 5 PT.PIZZA_TYPE_ID, PT.NAME, SUM(OD.QUANTITY) AS TOTAL_ORDERS FROM pizza_types_DIM PT
JOIN pizzas_DIM P ON P.pizza_type_id = PT.pizza_type_id 
JOIN order_details_FACT OD ON OD.pizza_id = P.PIZZA_ID
GROUP BY PT.PIZZA_TYPE_ID, PT.NAME
ORDER BY TOTAL_ORDERS DESC

--Join the necessary tables to find the total quantity of each pizza category ordered
SELECT PT.CATEGORY, SUM(QUANTITY) TOTAL_QUANTITY FROM pizza_types_DIM PT
JOIN  pizzas_DIM P ON P.pizza_type_id = PT.pizza_type_id 
JOIN order_details_FACT OD ON OD.pizza_id = P.PIZZA_ID
GROUP BY PT.CATEGORY
ORDER BY TOTAL_QUANTITY DESC 

--Determine the distribution of orders by hour of the day. 
SELECT DATEPART(HOUR, TIME), COUNT(DISTINCT ORDER_ID) TOTAL_ORDERS FROM orders_DIM
GROUP BY DATEPART(HOUR, TIME)
ORDER BY TOTAL_ORDERS DESC

--Join relevant tables to find the category-wise distribution of pizzas
SELECT CATEGORY, COUNT(NAME) AS NAME FROM pizza_types_DIM
GROUP BY CATEGORY

--Group the orders by date and calculate the average number of pizzas ordered per day
SELECT AVG(QUANTITY) AVG_ORDER_PER_DAY FROM
(SELECT O.DATE, SUM(OD.QUANTITY) AS QUANTITY FROM orders_DIM O
JOIN order_details_FACT OD ON OD.order_id = O.order_id
GROUP BY O.DATE) AS  ORDER_QUANTITY

--Determine the top 3 most ordered pizza types based on revenue
SELECT TOP 5 PT.PIZZA_TYPE_ID, PT.NAME, SUM(OD.QUANTITY * P.PRICE) TOTAL_REVENUE FROM pizza_types_DIM PT
JOIN  pizzas_DIM P ON P.pizza_type_id = PT.pizza_type_id 
JOIN order_details_FACT OD ON OD.pizza_id = P.PIZZA_ID
GROUP BY PT.PIZZA_TYPE_ID, PT.NAME
ORDER BY TOTAL_REVENUE DESC

--Calculate the percentage contribution of each pizza type to total revenue.
WITH CTE_DEMO AS (
SELECT ROUND(SUM(OD.QUANTITY * P.PRICE),2) AS TOTAL_REVENUE FROM order_details_FACT OD
JOIN pizzas_DIM P ON P.pizza_id = OD.pizza_id 
)
SELECT PT.CATEGORY, SUM(OD.QUANTITY * P.PRICE) AS REVENUE ,(SUM(OD.QUANTITY * P.PRICE) / 
(SELECT TOTAL_REVENUE FROM CTE_DEMO)*100) AS PERCENTGE FROM pizza_types_DIM PT
JOIN pizzas_DIM P ON PT.pizza_type_id = P.pizza_type_id
JOIN order_details_FACT OD ON OD.pizza_id = P.pizza_id
GROUP BY PT.CATEGORY

--Analyze the cumulative revenue generated over time
WITH CTE_DEMO AS (
SELECT O.date,
	   SUM(OD.QUANTITY * P.PRICE) AS REVENUE FROM orders_DIM O
JOIN order_details_FACT OD ON OD.order_id = O.order_id
JOIN pizzas_DIM P ON OD.pizza_id = P.pizza_id
GROUP BY O.date
)
SELECT date,
		REVENUE,
		SUM(REVENUE) OVER (ORDER BY DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
		AS CUMULATIVE_REVENUE
		FROM CTE_DEMO 
		ORDER BY DATE

--Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH CTE_DEMO AS(
SELECT PT.NAME, PT.CATEGORY, ROUND(SUM(OD.QUANTITY * P.PRICE),2) AS TOTAL_REVENUE,
RANK() OVER (PARTITION BY CATEGORY ORDER BY ROUND(SUM(OD.QUANTITY * P.PRICE),2)DESC) AS NUMBER
FROM 
pizza_types_DIM PT
JOIN pizzas_DIM P ON P.pizza_type_id = PT.pizza_type_id 
JOIN order_details_FACT OD ON OD.pizza_id = P.PIZZA_ID
GROUP BY  PT.NAME, PT.CATEGORY

)
SELECT NAME,CATEGORY, TOTAL_REVENUE,NUMBER FROM CTE_DEMO
WHERE NUMBER <=3






