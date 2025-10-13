# Data Analyst Project: Restaurant Order Analysis in SQL 


## Know the menu_items data
```sql
-- 1.View the menu_items table
SELECT * FROM menu_items;

-- 2.Find the number of items on the menu.
SELECT count(*) FROM menu_items;

-- 3.What are the least and most expensive items on the menu?

-- least expensive items
SELECT item_name,
       price
FROM menu_items
WHERE price = (SELECT min(price) FROM menu_items); -- Edamame, $5.00

-- Most expensive items
SELECT item_name,
       price
FROM menu_items
WHERE price = (SELECT max(price) FROM menu_items); -- Shrimp Scampi, $19.95

-- 4.How many Italian dished are on the menu?
SELECT count(item_name)
FROM menu_items
WHERE category = 'Italian'; -- 9

-- 5.What are the least and most expensive Italian dishes on the menu?
SELECT 
      item_name,
      price
FROM menu_items
WHERE category = 'Italian'
ORDER BY price DESC;

-- Max price = Shrimp Scampi
-- Min pruce = Fettuccine Alfredo

-- 6.How many dishes are in each category?
SELECT category,
       count(item_name)
 FROM menu_items
 GROUP BY category;

-- 7.What is the average dish price within each category?
SELECT category,
       round(avg(price),2) AS 'avg_price'
FROM menu_items
 GROUP BY category;
```

## Know the order_details data

```sql
-- 1.View the order details table
SELECT * FROM order_details;

-- 2. What is the date range of the data?
SELECT min(order_date),
       max(order_date)
 FROM order_details; -- 2023-01-01~2023-03-31
 
-- 3.How many orders were made within this date range?
SELECT count(DISTINCT(order_id))
 FROM order_details; -- 5370筆
-- 4.How many items were ordered within this date range?
SELECT count(DISTINCT(item_id))
 FROM order_details; -- 32種item
 
-- 5.Which orders has the most number of items?哪一筆交易買最多item?
WITH CTE AS (
 SELECT order_id,
       count(item_id) AS 'count_item_id'
FROM order_details
GROUP BY order_id
ORDER BY count(item_id) DESC)
SELECT ORDER_id
FROM CTE
WHERE count_item_id = 14;

-- 6.How many orders had more than 12 items?
WITH CTE AS (
SELECT order_id,
       count(item_id) AS count_item_id
 FROM order_details
GROUP BY order_id
HAVING count_item_id >12)
SELECT count(order_id)
FROM CTE;  -- 20筆orders一次購買超過12件商品
```

## Analyze Customer Behavior
```sql
-- 1.Combine tables - Inner Joins
SELECT o.order_id,
       o.order_date,
       o.order_time,
       o.item_id,
       m.item_name,
       m.category,
       m.price
FROM order_details AS o
JOIN menu_items AS m ON o.item_id = m.menu_item_id;

-- 2.What were the least and most ordered items? What categories were they in?

WITH CTE AS (SELECT o.order_id,
       o.order_date,
       o.order_time,
       o.item_id,
       m.item_name,
       m.category,
       m.price
FROM order_details AS o
JOIN menu_items AS m ON o.item_id = m.menu_item_id)
SELECT item_name,
       category,
       count(item_name) AS 'count_item_name'
FROM CTE
GROUP BY item_name, category
ORDER BY count(item_name) DESC
LIMIT 1; --  the most purchase item is Hamburger in the American category

WITH CTE AS (SELECT o.order_id,
       o.order_date,
       o.order_time,
       o.item_id,
       m.item_name,
       m.category,
       m.price
FROM order_details AS o
JOIN menu_items AS m ON o.item_id = m.menu_item_id)
SELECT item_name,
       category,
       count(item_name) AS 'count_item_name'
FROM CTE
GROUP BY item_name, category
ORDER BY count(item_name) ASC
LIMIT 1; -- the least purchase item is Chicken Taco in the Mexican category

-- 3.What are the top 5 orders that spent the most money?
WITH CTE AS (SELECT o.order_id,
       o.order_date,
       o.order_time,
       o.item_id,
       m.item_name,
       m.category,
       m.price
FROM order_details AS o
JOIN menu_items AS m ON o.item_id = m.menu_item_id)
SELECT item_name,
       sum(price) AS sum_of_item_spend
FROM CTE
GROUP BY item_name 
ORDER BY sum(price) DESC
LIMIT 5; 

-- Korean Beef Bowl, Spaghetti & Meatballs, Tofu Pad Thai, Cheeseburger, Hamburger
```