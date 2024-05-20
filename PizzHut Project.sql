create database pizzahut;
use pizzahut;
-- IMPORT CSV FILES PIZZAS

-- IMPORT CSV FILES PIZZA_TYPES
-- CREATE A BLANK TABLE ORDERS THEN IMPORT THE ORDER CSV FILES IN IT
create table orders (
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id))


-- CREATE A BLANK TABLE ORDER_DETAILS THEN IMPORT THE ORDER_DETAILS CSV FILES IN IT
create table order_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key(order_details_id));


-- BASIC:
-- 1. Retrieve the total number of orders placed.
select count(*) as total_orders from orders;


-- 2. Calculate the total sales generated from pizza sales.
SELECT 
    ROUND(SUM(quantity * pizzas.price), 2) AS total_sales
FROM
    order_details
        JOIN
    pizzas ON pizzas.pizza_id = order_details.pizza_id;

    
-- 3. Identify the highest-priced pizza.
SELECT 
    pizza_types.name, pizzas.price
FROM
    pizzas
        JOIN
    pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY price DESC limit 1;


-- 4. Identify the most common pizza size ordered.
SELECT 
    pizzas.size, COUNT(*) AS order_count
FROM
    pizzas
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY size
ORDER BY order_count DESC
LIMIT 1;


-- 5. List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pizza_types.name, SUM(order_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5;


-- INTERMEDIATE:
-- 1. Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pizza_types.category,
    COUNT(order_details.quantity) AS category_count
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY category_count DESC;


-- 2. Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) AS hour,
    COUNT(HOUR(order_time)) AS order_count
FROM
    orders
GROUP BY HOUR(order_time)
ORDER BY order_count DESC;


-- 3. Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    category, COUNT(category) AS category_count
FROM
    pizza_types
GROUP BY category;


-- 4. Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    ROUND(AVG(quantity)) AS avg_per_day
FROM
    (SELECT 
        orders.order_date, SUM(order_details.quantity) AS quantity
    FROM
        orders
    JOIN order_details ON order_details.order_id = orders.order_id
    GROUP BY orders.order_date) AS order_quantity;

-- 5. Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pizza_types.name, SUM(quantity * price) AS price
FROM
    pizza_types
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY price DESC
LIMIT 3;	


-- ADVANCED:
-- 1. Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
  distinct(pizza_types.category), 
  round(
    SUM(quantity * price) over(), 
    0
  ) AS price, 
  round(
    SUM(quantity * price) over(
      partition by pizza_types.category
    ), 
    0
  ) AS price2, 
  round(
    (
      SUM(quantity * price) over(
        partition by pizza_types.category
      )/ SUM(quantity * price) over()
    )* 100, 
    0
  ) as per_contributation 
FROM 
  pizza_types 
  JOIN pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id 
  JOIN order_details ON order_details.pizza_id = pizzas.pizza_id;

-- OR YOU CAN FIND THIS SOLUATION WITHOUT WINDOWS FUNCTION
SELECT 
    pizza_types.category,
    ROUND((SUM(pizzas.price * order_details.quantity) / (SELECT 
                    SUM(order_details.quantity * pizzas.price) AS total_sale
                FROM
                    order_details
                        JOIN
                    pizzas ON pizzas.pizza_id = order_details.pizza_id)) * 100,
            0) AS revenue
FROM
    pizzas
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category;

    
-- 2. Analyze the cumulative revenue generated over time.
select order_date,
round(sum(revenue) over(order by order_date),0) as cum_revenue
from
(select orders.order_date,
sum(order_details.quantity * pizzas.price) as revenue
from order_details join pizzas
on order_details.pizza_id = pizzas.pizza_id
join orders
on orders.order_id = order_details.order_id
group by orders.order_date) as sales;


-- 3. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select category, name, revenue from 
(select category, name, revenue, rank() over(partition by category order by revenue desc ) as rn from
(select pizza_types.category, pizza_types.name, 
round(sum(order_details.quantity*pizzas.price),0) as revenue from pizza_types
join pizzas on pizzas.pizza_type_id = pizza_types.pizza_type_id
join order_details on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category, pizza_types.name) as a) as b
where rn<=3;