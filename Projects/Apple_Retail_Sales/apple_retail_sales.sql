-- This dataset is not based on real Apple Inc. data.
-- It was created using Python and LLM-generated insights to simulate realistic sales patterns and business metrics.

USE apple_retail_sales;

-- 創建primary key
ALTER TABLE category
ADD CONSTRAINT PRIMARY KEY (category_id);

ALTER TABLE sales
ADD CONSTRAINT PRIMARY KEY (sale_id);

ALTER TABLE stores
ADD CONSTRAINT PRIMARY KEY (Store_id);

ALTER TABLE products
ADD CONSTRAINT PRIMARY KEY (Product_id);

-- 將所有資訊join，存入staging table

CREATE TABLE joins_record_staging AS 
SELECT 
       sales.sale_date,
       sales.store_id,
       sales.product_id,
       sales.quantity,
       stores.Store_Name,
       stores.City,
       stores.Country,
       products.Product_Name,
       products.Price,
       category.category_name
FROM sales
INNER JOIN stores
ON sales.store_id = stores.Store_id 
INNER JOIN products
ON sales.product_id = products.Product_ID
INNER JOIN category
ON products.Category_ID = category.category_id;

-- 台灣資料

CREATE TABLE joins_record_staging_tw AS 
SELECT 
       sales.sale_date,
       sales.store_id,
       sales.product_id,
       sales.quantity,
       stores.Store_Name,
       stores.City,
       stores.Country,
       products.Product_Name,
       products.Price,
       category.category_name
FROM sales
INNER JOIN stores
ON sales.store_id = stores.Store_id 
INNER JOIN products
ON sales.product_id = products.Product_ID
INNER JOIN category
ON products.Category_ID = category.category_id
WHERE Country = 'Taiwan';

-- 1.確認每一行不重複。row_num >1代表重複值
WITH row_num_cte AS (
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY sale_date, store_id,product_id, quantity, Store_Name, City, Country, Product_Name, Price, category_name) AS row_num
FROM joins_record_staging_tw)
SELECT * FROM row_num_cte
WHERE row_num > 1; -- 71筆資料


DELETE t1 FROM joins_record_staging_tw AS t1
INNER JOIN (
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY sale_date, store_id,product_id, quantity, Store_Name, City, Country, Product_Name, Price, category_name) AS row_num
FROM joins_record_staging_tw
) t2
ON
t1.sale_date = t2.sale_date AND 
t1.store_id = t2.store_id AND 
t1.product_id = t2.product_id AND 
t1.quantity = t2.quantity AND 
t1.Store_Name = t2.Store_Name AND 
t1.City = t2.City AND 
t1.Country = t2.Country AND 
t1.Product_Name = t2.Product_Name AND 
t1.Price = t2.Price AND 
t1.category_name = t2.category_name
WHERE row_num > 1;

-- 2.檢查名詞，沒有空格、遺漏值、大小寫問題
SELECT DISTINCT product_id, Product_Name
FROM joins_record_staging_tw
ORDER BY Product_Name; -- 確認正確

-- 3.轉換格式
-- a.日期轉換
-- b.其他格式正確
SELECT sale_date,
       str_to_date(sale_date, '%d-%m-%Y') 
FROM joins_record_staging_tw;

UPDATE joins_record_staging_tw
SET sale_date = str_to_date(sale_date, '%d-%m-%Y');

-- 4.檢查遺漏值
-- 5.清除欄位：drop store_id, product_id。
-- Store_Name, City, Country因為只有Apple Taiwan 101, Taipei Taiwan也先刪除

ALTER TABLE joins_record_staging_tw
DROP store_id, 
DROP product_id,
DROP Store_Name,
DROP City,
DROP Country;

-- 6.欄位名稱都改為小寫

ALTER TABLE joins_record_staging_tw
RENAME COLUMN Product_Name TO product_name,
RENAME COLUMN Price TO price;

-- 最後檢視表格
SELECT * FROM joins_record_staging_tw;

-- EDA

-- 數據範圍：2020/1/1-2024/11-12
SELECT min(sale_date),
       max(sale_date)
FROM joins_record_staging_tw;

-- 業績表現

-- 業績前五：Tablet, Accessories, Smartphone, Wearable, Audio
SELECT category_name,
       sum(quantity * price) AS total_sales
FROM joins_record_staging_tw
WHERE sale_date BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY category_name
ORDER BY total_sales DESC
LIMIT 5;

-- 業績前五：Tablet, Accessories, Laptop, Smartphone, Audio
SELECT category_name,
       sum(quantity * price) AS total_sales
FROM joins_record_staging_tw
WHERE sale_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY category_name
ORDER BY total_sales DESC
LIMIT 5;

-- 賣最好的品項為Tablet，找出是哪一隻Product Name

-- 2020年
SELECT product_name,
       sum(quantity * price) AS total_sales
FROM joins_record_staging_tw
WHERE sale_date BETWEEN '2020-01-01' AND '2020-12-31' AND 
      category_name = 'Tablet'
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 5;
-- ipad pro(m2), ipad air(5th generation), ipad(9th generation), ipad mini(5th generation), ipad(10th generation)

-- 2024年

SELECT product_name,
       sum(quantity * price) AS total_sales
FROM joins_record_staging_tw
WHERE sale_date BETWEEN '2024-01-01' AND '2024-12-31' AND 
      category_name = 'Tablet'
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 5;
-- ipad mini(5th Generation), ipad (10 generation), ipad pro(m2), ipad air(5th generation), ipad pro 11-inch

-- insight: 舊機型銷售量提升issue

       




      
