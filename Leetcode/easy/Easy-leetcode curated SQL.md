# Leetcode Practice - Easy

## 511. Game Play Analysis I

- 找出每個玩家第一次登入的id, first_login

| player_id | device_id | event_date | games_played |
|-----------|-----------|------------|--------------|
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-05-02 | 6            |
| 2         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-02 | 0            |
| 3         | 4         | 2018-07-03 | 5            |
Output: 

| player_id | first_login |
|-----------|-------------|
| 1         | 2016-03-01  |
| 2         | 2017-06-25  |
| 3         | 2016-03-02  |


#### 寫法一：直接用min去找

```sql
select player_id,
       min(event_date) as first_login
from Activity
group by player_id
order by player_id ASC;
```

#### 寫法二：window function

- 先針對有rank的結果寫一個CTE (common table expression)
- 接著操作CTE取出rank = 1的player_id
- RANK()：排序方式為 1,1,3,3,3,3,7

```sql
WITH CTE AS (
SELECT
    player_id,
    event_date AS first_login,
    RANK() OVER (PARTITION BY player_id ORDER BY event_date ASC) AS rank_of_day
FROM
    Activity)
 SELECT player_id,
        first_login
 FROM CTE
 WHERE rank_of_day = 1;
 ```

#### 寫法三：FIRST_VALUE

- 透過first_value找出第一個值，ASC排序下第一個值就是最小登入日期
- 因為window function 下player_id有重複值，因此補上distinct player_id

```sql
SELECT DISTINCT player_id,
       FIRST_VALUE(event_date) OVER (PARTITION BY player_id ORDER BY event_date) AS first_login
 FROM Activity;
```

## 586. Customer Placing the Largest Number of Orders

- 找出最大的order number次數，然後找出這位的customer_id
- 如果最大次數重複，則印出所有customer_id


#### 解法一：

- 思路：創建一個CTE，呈現customer_id, 對應的order count, max_order count
- 若order count = max_order count時，就可以回推customer_id
- 發現網路上一些order by 搭配limit的寫法，當customer_id有1個以上時會error，所以最佳做法應該是透過window_function rank或子查詢

```sql
WITH CTE AS (
SELECT customer_number,
       count(order_number) AS order_count,
       max(count(order_number)) over() AS max_order_count
FROM orders
GROUP BY customer_number)

SELECT customer_number 
FROM CTE
WHERE order_count = max_order_count;
```

#### 解法二：CTE

```sql
WITH CTE AS (
    SELECT customer_number,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM Orders
    GROUP BY customer_number
)
SELECT customer_number
FROM CTE
WHERE rnk = 1;

```

#### 解法三：CTE + subquery

```sql
WITH CTE AS (
	SELECT customer_number,
	       count(customer_number) AS count_of_order
	  FROM orders
	  GROUP BY customer_number
)
SELECT customer_number 
       FROM CTE
       WHERE count_of_order = (SELECT max(count_of_order) FROM CTE);
```

## 607. Sales Person

- 多張表格連接操作，選擇要用inner join, left/right join, cross join...。因為要查詢所有有訂單，且訂單公司名稱有Red，所以採用Inner Join
- 連接Salesperson, Company, Orders
- 找出和RED公司往來的salesperson name
- 和所有名字做差集，就會得到沒和RED互動的salesperson name

#### 解法一：EXCEPT
```sql
-- 和RED交易的業務員名字
/*
SELECT SalesPerson.name
   FROM Orders
   JOIN Company ON Orders.com_id = Company.com_id
   JOIN SalesPerson ON Orders.sales_id = SalesPerson.sales_id
   WHERE Company.name = "RED"; 
*/

-- 和所有業務員做差集，就可以得到沒有和RED交易的名字
SELECT name
FROM Salesperson
EXCEPT 
SELECT SalesPerson.name
   FROM Orders
   JOIN Company ON Orders.com_id = Company.com_id
   JOIN SalesPerson ON Orders.sales_id = SalesPerson.sales_id
   WHERE Company.name = "RED"; 
```

## 610. Triangle Judgement

Input: 
Triangle table:
| x  | y  | z  |
|----|----|---|
| 13 | 15 | 30 |
| 10 | 20 | 15 |
Output: 

| x  | y  | z  | triangle |
|----|----|----|----------|
| 13 | 15 | 30 | No       |
| 10 | 20 | 15 | Yes      |


- case when 創造triangle這個欄位的判斷。case when A and B and C then condition1

```
select x,
       y,
       z,
       case when (x + y > z) AND (x + z > y) AND (z + y > x) THEN 'Yes'
       ELSE 'No'
       END AS 'triangle'
 FROM Triangle;
```

## 1050. Actors and Directors Who Cooperated At Least Three Times

Input: 
ActorDirector table:
| actor_id    | director_id | timestamp   |
|-------------|-------------|-------------|
| 1           | 1           | 0           |
| 1           | 1           | 1           |
| 1           | 1           | 2           |
| 1           | 2           | 3           |
| 1           | 2           | 4           |
| 2           | 1           | 5           |
| 2           | 1           | 6           |

Output: 
|-------------|-------------|
| actor_id    | director_id |
|-------------|-------------|
| 1           | 1           |

- 找出合作過至少三次的actor_id and director_id
- concat actor_id和director_id as 新欄位 (11,12,21...)。去count新欄位，挑出次數>3的
- CTE裡面是concat和計算concat的大表格，之後再透過select篩選count數目

#### 解法一：CTE製作查詢大表格，再去篩選

```sql

WITH CTE AS (
SELECT 
    actor_id,
    director_id,
    concat(actor_id, director_id) AS id_concat,
    count(concat(actor_id, director_id)) AS count_id
FROM ActorDirector
GROUP BY actor_id, director_id
)

SELECT actor_id, director_id
FROM CTE
WHERE count_id >= 3;

```

#### 解法二：count(*)搭配聚合後HAVING篩選

- group by之後每一組 actor_id, director_id會被不重複分組
- 分組後再去計算分組的次數，也就是count(*)針對所有結果分組

```
SELECT actor_id, 
       director_id 
FROM ActorDirector
GROUP BY actor_id, director_id
HAVING count(*) >= 3;
```

## 1068. Product Sales Analysis I

Input: 
Sales table:
| sale_id | product_id | year | quantity | price |
|---------|------------|------|----------|-------|
| 1       | 100        | 2008 | 10       | 5000  |
| 2       | 100        | 2009 | 12       | 5000  |
| 7       | 200        | 2011 | 15       | 9000  |

Product table:

| product_id | product_name |
|------------|--------------|
| 100        | Nokia        |
| 200        | Apple        |
| 300        | Samsung      |

Output: 

| product_name | year  | price |
|--------------|-------|-------|
| Nokia        | 2008  | 5000  |
| Nokia        | 2009  | 5000  |
| Apple        | 2011  | 9000  |

- 寫出每一個sales id對應的product_name, year, price
- 這題滿基本的，就是一般的join應用
```sql
SELECT 
     Product.product_name,
     Sales.YEAR,
     Sales.price
FROM Sales
JOIN Product ON Sales.product_id = Product.product_id
ORDER BY Sales.YEAR ASC;
```

## 1075. Project Employees I

Input: 
Project table:

| project_id  | employee_id |
|-------------|-------------|
| 1           | 1           |
| 1           | 2           |
| 1           | 3           |
| 2           | 1           |
| 2           | 4           |

Employee table:

| employee_id | name   | experience_years |
|-------------|--------|------------------|
| 1           | Khaled | 3                |
| 2           | Ali    | 2                |
| 3           | John   | 1                |
| 4           | Doe    | 2                |

Output: 

| project_id  | average_years |
|-------------|---------------|
| 1           | 2.00          |
| 2           | 2.50          |

- round的用法：round(condition, 小數點幾位數)

```sql
SELECT Project.project_id,
       round(avg(Employee.experience_years),2) AS average_years
FROM Project
JOIN Employee ON Project.employee_id = Employee.employee_id
GROUP BY Project.project_id;
```

## 1084. Sales Analysis III

Input: 

Product table:

| product_id | product_name | unit_price |
|------------|--------------|------------|
| 1          | S8           | 1000       |
| 2          | G4           | 800        |
| 3          | iPhone       | 1400       |

Sales table:

| seller_id | product_id | buyer_id | sale_date  | quantity | price |
|-----------|------------|----------|------------|----------|-------|
| 1         | 1          | 1        | 2019-01-21 | 2        | 2000  |
| 1         | 2          | 2        | 2019-02-17 | 1        | 800   |
| 2         | 2          | 3        | 2019-06-02 | 1        | 800   |
| 3         | 3          | 4        | 2019-05-13 | 2        | 2800  |
Output: 

| product_id  | product_name |
|-------------|--------------|
| 1           | S8           |

- Write a solution to report the products that were only sold in the first quarter of 2019. That is, between 2019-01-01 and 2019-03-31 inclusive.
- 這個產品要在Q1售出。如果在除Q1時個也有售出也不能包含
- 這題寫滿久的，尤其在下面group by和having的寫法

#### 解法一：使用except

- 包含在2019/1/1-3/31之間售出的產品 - 沒有在2019/1/1-3/31之間售出的產品差集，就會是我們要的答案

```sql
-- 在 2019/1/1-3/31之間售出
SELECT
  Product.product_id,
  Product.product_name
FROM
  Product
JOIN
  Sales ON Product.product_id = Sales.product_id
WHERE Sales.sale_date BETWEEN '2019-01-01' AND '2019-03-31'
EXCEPT 
-- 不在2019/1/1-3/31之間售出
SELECT
  Product.product_id,
  Product.product_name
FROM
  Product
JOIN
  Sales ON Product.product_id = Sales.product_id
WHERE Sales.sale_date NOT BETWEEN '2019-01-01' AND '2019-03-31';
```

## 1141. User Activity for the Past 30 Days I

Write a solution to find the daily active user count for a period of 30 days ending 2019-07-27 inclusively. A user was active on someday if they made at least one activity on that day.

Input: 

Activity table:

| user_id | session_id | activity_date | activity_type |
|---------|------------|---------------|---------------|
| 1       | 1          | 2019-07-20    | open_session  |
| 1       | 1          | 2019-07-20    | scroll_down   |
| 1       | 1          | 2019-07-20    | end_session   |
| 2       | 4          | 2019-07-20    | open_session  |
| 2       | 4          | 2019-07-21    | send_message  |
| 2       | 4          | 2019-07-21    | end_session   |
| 3       | 2          | 2019-07-21    | open_session  |
| 3       | 2          | 2019-07-21    | send_message  |
| 3       | 2          | 2019-07-21    | end_session   |
| 4       | 3          | 2019-06-25    | open_session  |
| 4       | 3          | 2019-06-25    | end_session   |

Output: 

| day        | active_users |
|------------|--------------| 
| 2019-07-20 | 2            |
| 2019-07-21 | 2            |

- 難
- 只要有任一個動作，都算是active users
- 日期從7/27往回推30天，也就是6/28-7/27。可以用between或是datediff去找
- datediff：datediff(day_a, day_b)->day a和day b的日期差距
    - where先刪除6/25這天的值
    - group by date根據日期分組，計算每個不重複日期有幾個獨立的user id


```sql
SELECT activity_date as day, 
       COUNT(DISTINCT user_id) as active_users
FROM Activity
WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-27'
GROUP BY activity_date;
```

## 1148. Article Views I

Write a solution to find all the authors that viewed at least one of their own articles.

Return the result table sorted by id in ascending order.

- author_id = viewer_id

Input: 

Views table:

| article_id | author_id | viewer_id | view_date  |
|------------|-----------|-----------|------------|
| 1          | 3         | 5         | 2019-08-01 |
| 1          | 3         | 6         | 2019-08-02 |
| 2          | 7         | 7         | 2019-08-01 |
| 2          | 7         | 6         | 2019-08-02 |
| 4          | 7         | 1         | 2019-07-22 |
| 3          | 4         | 4         | 2019-07-21 |
| 3          | 4         | 4         | 2019-07-21 |

Output: 

| id   |
|------|
| 4    |
| 7    |

```sql
SELECT  
       DISTINCT author_id AS id
FROM Views
WHERE author_id = viewer_id
ORDER BY id ASC;

```

## 1251. Average Selling Price

Write a solution to find the average selling price for each product. average_price should be rounded to 2 decimal places. If a product does not have any sold units, its average selling price is assumed to be 0.

- 每個產品的avg price, round (avg_price, 2)
- 沒有sold unit則avg price = 0

Input: 

Prices table:

| product_id | start_date | end_date   | price  |
|------------|------------|------------|--------|
| 1          | 2019-02-17 | 2019-02-28 | 5      |
| 1          | 2019-03-01 | 2019-03-22 | 20     |
| 2          | 2019-02-01 | 2019-02-20 | 15     |
| 2          | 2019-02-21 | 2019-03-31 | 30     |

UnitsSold table:


| product_id | purchase_date | units |
|------------|---------------|-------|
| 1          | 2019-02-25    | 100   |
| 1          | 2019-03-01    | 15    |
| 2          | 2019-02-10    | 200   |
| 2          | 2019-03-22    | 30    |

Output: 


| product_id | average_price |
|------------|---------------|
| 1          | 6.96          |
| 2          | 16.96         |

- 這題很難，JOIN之後發現purchase_date和後面的start_date, end_date對不起來

```sql
SELECT *
FROM UnitsSold AS un
JOIN Prices AS p ON un.product_id = p.product_id;
```

<img src="pictures_leetcode/01.png" width="50%">

- 因此，透過where讓目前的purchase_date和後面的start_date, end_date, price可以配對起來
```sql
SELECT *
FROM UnitsSold AS un
JOIN Prices AS p ON un.product_id = p.product_id
WHERE un.purchase_date BETWEEN p.start_date AND p.end_date;
```

- 因為隱藏測資中有銷量為0的資料，使用right join保留所有資料
- where部分用 or 保留0的資料
- ifnull將null轉會為0

```sql
WITH CTE AS (
SELECT un.product_id,
       un.units,
       p.price
FROM UnitsSold AS un
right JOIN Prices AS p ON un.product_id = p.product_id
WHERE (un.purchase_date BETWEEN p.start_date AND p.end_date) or
      un.units is null)
SELECT product_id,
       ifnull(round(sum(units * price) / sum(units),2),0) AS average_price
FROM CTE
GROUP BY product_id;
```

## 1280. Students and Examinations

Write a solution to find the number of times each student attended each exam.

Return the result table ordered by student_id and subject_name.

Input: 

Students table:

| student_id | student_name |
|------------|-------------|
| 1          | Alice        |
| 2          | Bob          |
| 13         | John         |
| 6          | Alex         |

Subjects table:

| subject_name |
|--------------|
| Math         |
| Physics      |
| Programming  |

Examinations table:

| student_id | subject_name |
|------------|--------------|
| 1          | Math         |
| 1          | Physics      |
| 1          | Programming  |
| 2          | Programming  |
| 1          | Physics      |
| 1          | Math         |
| 13         | Math         |
| 13         | Programming  |
| 13         | Physics      |
| 2          | Math         |
| 1          | Math         |

Output: 

| student_id | student_name | subject_name | attended_exams |
|------------  |--------------|--------------|----------------|
| 1          | Alice        | Math         | 3              |
| 1          | Alice        | Physics      | 2              |
| 1          | Alice        | Programming  | 1              |
| 2          | Bob          | Math         | 1              |
| 2          | Bob          | Physics      | 0              |
| 2          | Bob          | Programming  | 1              |
| 6          | Alex         | Math         | 0              |
| 6          | Alex         | Physics      | 0              |
| 6          | Alex         | Programming  | 0              |
| 13         | John         | Math         | 1              |
| 13         | John         | Physics      | 1              |
| 13         | John         | Programming  | 1              |

- 難
- 所有學生配對的所有科目都應該呈現 （如果沒有該科目NULL需補上0)，因此需要排列組合列出所有可能->enumerate->cross join 笛卡爾乘機

## 1179. Reformat Department Table

Input: 
Department table:

| id   | revenue | month |
|------|---------|-------|
| 1    | 8000    | Jan   |
| 2    | 9000    | Jan   |
| 3    | 10000   | Feb   |
| 1    | 7000    | Feb   |
| 1    | 6000    | Mar   |

Output: 

| id   | Jan_Revenue | Feb_Revenue | Mar_Revenue | ... | Dec_Revenue |
|------|-------------|-------------|-------------|----|-------------|
| 1    | 8000        | 7000        | 6000        | ... | null        |
| 2    | 9000        | null        | null        | ... | null        |
| 3    | null        | 10000       | null        | ... | null        |

- Reformat the table such that there is a department id column and a revenue column for each month. Return the result table in any order.
reformat the table

#### 解法一

- SQL和PYTHON一樣有if語法，用法為：IF(條件),值,否則換成另個值 as xxx
- SQL本身在條件判斷是用case when，請見解法二

```sql
SELECT id,
       sum(IF (MONTH = 'Jan',revenue, NULL)) AS Jan_Revenue, -- if month = Jan then revenue, else print null
       sum(IF (MONTH = 'Feb',revenue, NULL)) AS Feb_Revenue,
       sum(IF (MONTH = 'Mar',revenue, NULL)) AS Mar_Revenue,
       sum(IF (MONTH = 'Apr',revenue, NULL)) AS Apr_Revenue,
       sum(IF (MONTH = 'May',revenue, NULL)) AS May_Revenue,
       sum(IF (MONTH = 'Jun',revenue, NULL)) AS Jun_Revenue,
       sum(IF (MONTH = 'Jul',revenue, NULL)) AS Jul_Revenue,
       sum(IF (MONTH = 'Aug',revenue, NULL)) AS Aug_Revenue,
       sum(IF (MONTH = 'Sep',revenue, NULL)) AS Sep_Revenue,
       sum(IF (MONTH = 'Oct',revenue, NULL)) AS Oct_Revenue,
       sum(IF (MONTH = 'Nov',revenue, NULL)) AS Nov_Revenue,
       sum(IF (MONTH = 'Dec',revenue, NULL)) AS Dec_Revenue
FROM Department
GROUP BY id;
```

#### 解法二

```sql
SELECT id,

    SUM(CASE WHEN MONTH = 'Jan' THEN revenue ELSE NULL END) AS Jan_Revenue,
    SUM(CASE WHEN MONTH = 'Feb' THEN revenue ELSE NULL END) AS Feb_Revenue,
    SUM(CASE WHEN MONTH = 'Mar' THEN revenue ELSE NULL END) AS Mar_Revenue,
    SUM(CASE WHEN MONTH = 'Apr' THEN revenue ELSE NULL END) AS Apr_Revenue,
    SUM(CASE WHEN MONTH = 'May' THEN revenue ELSE NULL END) AS May_Revenue,
    SUM(CASE WHEN MONTH = 'Jun' THEN revenue ELSE NULL END) AS Jun_Revenue,
    SUM(CASE WHEN MONTH = 'Jul' THEN revenue ELSE NULL END) AS Jul_Revenue,
    SUM(CASE WHEN MONTH = 'Aug' THEN revenue ELSE NULL END) AS Aug_Revenue,
    SUM(CASE WHEN MONTH = 'Sep' THEN revenue ELSE NULL END) AS Sep_Revenue,
    SUM(CASE WHEN MONTH = 'Oct' THEN revenue ELSE NULL END) AS Oct_Revenue,
    SUM(CASE WHEN MONTH = 'Nov' THEN revenue ELSE NULL END) AS Nov_Revenue,
    SUM(CASE WHEN MONTH = 'Dec' THEN revenue ELSE NULL END) AS Dec_Revenue

FROM Department
GROUP BY id;
```

## 1667. Fix Names in a Table

- Write a solution to fix the names so that only the first character is uppercase and the rest are lowercase. Return the result table ordered by user_id.

Input: 

Users table:

| user_id | name  |
|---------|-------|
| 1       | aLice |
| 2       | bOB   |

Output: 

| user_id | name  |
|---------|-------|
| 1       | Alice |
| 2       | Bob   |

- 解法，全部改成小寫後，再將第一個字改為大寫
- 把字母拆兩半，字首以及字首後的字，以concat連接

#### 解法一
```sql
SELECT user_id, 
       CONCAT(UPPER(LEFT(LOWER(name), 1)), SUBSTRING(LOWER(name), 2)) AS name
FROM Users;
```

#### 解法二
- 先將全小寫的結果存入window function裡面，在針對字母拆分字首大寫、其他字小寫的處理
- 取字首：upper(Substr(name,1,1))
- 取其他字：substr(name,2) ->從第二個字開始

```sql
WITH CTE AS (
SELECT user_id,
       lower(name) AS name
FROM Users)

SELECT user_id,
       concat (upper(Substr(name,1,1)),substr(name,2))
 FROM CTE;

```

## 1407. Top Travellers

- Write a solution to report the distance traveled by each user. Return the result table ordered by travelled_distance in descending order, if two or more users traveled the same distance, order them by their name in ascending order.

Input: 

Users table:

| id   | name      |
|------|-----------|
| 1    | Alice     |
| 2    | Bob       |
| 3    | Alex      |
| 4    | Donald    |
| 7    | Lee       |
| 13   | Jonathan  |
| 19   | Elvis     |

Rides table:

| id   | user_id  | distance |
|------|----------|----------|
| 1    | 1        | 120      |
| 2    | 2        | 317      |
| 3    | 3        | 222      |
| 4    | 7        | 100      |
| 5    | 13       | 312      |
| 6    | 19       | 50       |
| 7    | 7        | 120      |
| 8    | 19       | 400      |
| 9    | 7        | 230      |

Output: 

| name     | travelled_distance |
|----------|--------------------|
| Elvis    | 450                |
| Lee      | 450                |
| Bob      | 317                |
| Jonathan | 312                |
| Alex     | 222                |
| Alice    | 120                |
| Donald   | 0                  |

```sql
SELECT u.name,
       ifnull(sum(r.distance),0) AS travelled_distance
FROM users AS u
LEFT JOIN Rides AS r ON u.id = r.user_id
GROUP BY u.id
ORDER BY sum(r.distance) DESC,
         u.name ASC;

```

## 1517. Find Users With Valid E-Mails

Write a solution to find the users who have valid emails.

A valid e-mail has a prefix name and a domain where:

The prefix name is a string that may contain letters (upper or lower case), digits, underscore '_', period '.', and/or dash '-'. The prefix name must start with a letter.
The domain is '@leetcode.com'.


Input: 

Users table:

| user_id | name      | mail                    |
|---------|-----------|-------------------------|
| 1       | Winston   | winston@leetcode.com    |
| 2       | Jonathan  | jonathanisgreat         |
| 3       | Annabelle | bella-@leetcode.com     |
| 4       | Sally     | sally.come@leetcode.com |
| 5       | Marwan    | quarz#2020@leetcode.com |
| 6       | David     | david69@gmail.com       |
| 7       | Shapiro   | .shapo@leetcode.com     |

Output: 

| user_id | name      | mail                    |
|---------|-----------|-------------------------|
| 1       | Winston   | winston@leetcode.com    |
| 3       | Annabelle | bella-@leetcode.com     |
| 4       | Sally     | sally.come@leetcode.com |

