# SQL Project - Data Cleaning

## 0. Data source

- Tech companies around the globe are fighting for economic shutdown and the turmoil in the whole society. The data shows the laid-off data and enables us to discover which industries have gone bankrupt and reached a 100% laid-off rate.

- This date range from 2020 to 2025, so we can take a close look at the changes within 5 years, including having insight about the post-pandemic economic performances.


- Columns including company name, location, total_laid_off, date, percentage_laid_off (100% means bankruptcy), industry, source, stage, fund_raised, country (we will mainly focus on the US market)

- Kaggle download URL：https://www.kaggle.com/datasets/swaptr/layoffs-2022

## 1. Raw & Data Cleaning
- Raw: layoffs
- New: layoffs_staging

Create a new staging table to avoid accidents during the ETL process.
```sql
CREATE TABLE layoffs_staging 
LIKE layoffs;

INSERT layoffs_staging 
SELECT *
FROM layoffs;
```

## 2. Remove Duplicates

- if all of the information are the same, delete from layoffs_staging. To find out those duplicate data, use row_number and delete the number > 1
- Company name: Beyond Meat, Cazoo are the duplicates. Delete them from the staging table.
- It is interesting that we cannot delete data from a CTE. So I use join table to fix the problem.

```sql
WITH row_num_cte AS (
SELECT *,
row_number() OVER (PARTITION BY company, location, total_laid_off, `date`, 
                                 percentage_laid_off, industry, stage, funds_raised, country) AS row_num
FROM layoffs_staging)
SELECT * FROM row_num_cte
WHERE row_num >1;

-- error message
DELETE FROM layoffs_staging
WHERE row_num >1;

-- delete by using join

DELETE t1 
FROM layoffs_staging t1
INNER JOIN (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, total_laid_off, `date`, 
                            percentage_laid_off, industry, stage, funds_raised, country
           ) AS row_num
    FROM layoffs_staging
) t2
ON t1.company = t2.company 
AND t1.location = t2.location 
AND t1.total_laid_off = t2.total_laid_off 
AND t1.`date` = t2.`date` 
AND t1.percentage_laid_off = t2.percentage_laid_off
AND t1.industry = t2.industry
AND t1.stage = t2.stage
AND t1.funds_raised = t2.funds_raised
AND t1.country = t2.country
WHERE t2.row_num > 1;
```
## 3. Standardize data

### 3-1: 移除頭尾空白
- trim() and update the data.

```sql
SELECT trim(company),
       trim(location),
       trim(industry),
       trim(stage),
       trim(LEADING '$' FROM funds_raised), -- fund_raised轉換為純數才可以改變為int
       trim(country)
FROM layoffs_staging;

UPDATE layoffs_staging
SET company = trim(company),
    location = trim(location),
    industry = trim(industry),
    stage = trim(stage),
    funds_raised = trim(LEADING '$' FROM funds_raised),
    country = trim(country);
```

### 3-2 ~ 3-4 分別檢查industry, locaiton, country欄位

### 3-5: date日期格式處理
- str -> date

```sql
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging;

UPDATE layoffs_staging
SET date = str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;
```

## 4. Null/ Blanks處理

- If total_laid_off & percentage_laid_offs are NULL and blank, the data have limited usage for insights.

```sql
DELETE 
FROM layoffs_staging
WHERE total_laid_off IS NULL AND 
      percentage_laid_off IS NULL; 
```

## 5. Delete Unnecessary columns: source, date_add
```sql
ALTER TABLE layoffs_staging
DROP COLUMN source, 
DROP COLUMN date_added;
```

## 6. EDA
- Focus on data in the US.
- Find how many companies that go bankrupt during the 5 years. We can see that 189 companies have shut down, and Katerra has fired the largest number of employees.
```sql
WITH use_laidoff AS (
SELECT *
FROM layoffs_staging
WHERE country = 'United States' AND 
      percentage_laid_off = 1)
SELECT count(DISTINCT(company))
FROM use_laidoff;

-- 189
```
- See the number of laid-off companies. Why is the number raise after the pandemic?
   - 2020: 26
   - 2021: 6
   - 2022: 33
   - 2023: 58
   - 2024: 54
   - 2025: 14

- Within these company, which industries are they belong to?
    - finance, healthcare, retail, food, transportation. I am interesting curious about the retail and food industry. So let's take a close look.
```sql
SELECT DISTINCT(industry),
       count(company) AS company_count
FROM layoffs_staging
WHERE country = 'United States' AND 
      percentage_laid_off = 1
GROUP BY industry
ORDER BY count(company) DESC
LIMIT 5;
```

- Retail: 倒閉公司前3名為Zulily, Deliv, Drizly
- Food: 倒閉公司前2名：Butler Hospitality, Fifth Season