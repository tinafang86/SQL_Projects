USE world_offsets;

-- 匯入數字時發現匯入失敗原因
-- (1) funds_raised數字有$，int->varchar
-- (2)date_added目前年月日無法判別為datetime，和前面的date一起改為varchar
ALTER table layoffs
MODIFY COLUMN date_added varchar(50),
MODIFY COLUMN date varchar(50);

-- 檢視表格
SELECT * FROM layoffs;

-- EDA。避免更動原始表格，創造一個資料暫存區
-- 1.創造表格+插入資料
CREATE TABLE layoffs_staging 
LIKE layoffs;

INSERT layoffs_staging 
SELECT *
FROM layoffs;

-- 2.清除重複值 remove duplicates
-- 確保每一行都不重複->row_number()找出>1
-- 若有duplicate->delete from tables ...

WITH row_num_cte AS (
SELECT *,
row_number() OVER (PARTITION BY company, location, total_laid_off, `date`, 
                                 percentage_laid_off, industry, stage, funds_raised, country) AS row_num
FROM layoffs_staging)
SELECT * FROM row_num_cte
WHERE row_num >1; -- company:Beyond Meat, Cazoo

-- 檢查這兩家，確實有重複值
SELECT * FROM layoffs_staging
WHERE company IN ("Beyond Meat","Cazoo")
ORDER BY company asc;

-- 發現CTE不可以直接Delete
DELETE FROM layoffs_staging
WHERE row_num >1;

-- 開始刪除

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

-- 檢查company狀況:Beyond Meat, Cazoo
SELECT * FROM layoffs_staging
WHERE company IN ('Beyond Meat', 'Cazoo'); -- 確認已刪除

-- 3.標準化數據（拼字、格式等等檢查）
-- -3-1:移除頭尾空白
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
    
-- 3-2：檢視industry
-- Crypto, CryptoCurrency, Crypto Currency是一樣的，全改名為Crypto
SELECT DISTINCT industry
FROM layoffs_staging
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 3-3:檢視location
SELECT DISTINCT location
FROM layoffs_staging;

-- 3-4:檢視country
-- United States, United States.要合併為一個結果
SELECT DISTINCT country, trim(TRAILING '.' FROM country)
FROM layoffs_staging;

UPDATE layoffs_staging
SET country = trim(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 3-5:date轉換格式
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging;

UPDATE layoffs_staging
SET date = str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;

-- 4.Null/blanks檢視
-- 4.1:刪除total layoff和percentage layoff都是0的欄位
DELETE 
FROM layoffs_staging
WHERE total_laid_off IS NULL AND 
      percentage_laid_off IS NULL;


-- 4.2填補欄位。industry有空值、
SELECT *
FROM layoffs_staging
WHERE industry IS NULL OR
      industry = ''; -- Eyeo, Appsmith
      
DELETE FROM layoffs_staging
WHERE industry IS NULL OR
      industry = '';

-- 4.3 total_laid off和percentage laid off如果都為空，刪除
SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL AND 
      percentage_laid_off IS NULL; -- 沒有

-- 5.清除不必要欄位
ALTER TABLE layoffs_staging
DROP COLUMN source, 
DROP COLUMN date_added;

-- 6.修改percentage為小數點

UPDATE layoffs_staging
SET percentage_laid_off = percentage_laid_off/100
WHERE percentage_laid_off IS NOT NULL;
-- SELECT * FROM layoffs_staging;

-- EDA

-- 美國地區分析
SELECT *
FROM layoffs_staging
WHERE country = 'United States';

-- 美國全被裁員的公司，共有189間
WITH use_laidoff AS (
SELECT *
FROM layoffs_staging
WHERE country = 'United States' AND 
      percentage_laid_off = 1)
SELECT count(DISTINCT(company))
FROM use_laidoff;

-- 
SELECT *
FROM layoffs_staging
WHERE country = 'United States' AND 
      percentage_laid_off = 1
ORDER BY total_laid_off DESC; -- 被裁員最多的公司為Katerra，裁了2423人

-- 裁員日期從2020-03-11~2025-10-02
SELECT min(date), max(date)
FROM layoffs_staging
WHERE country = 'United States';

-- 我要分別計算2020,2021,2022,2023,2024, 2025，100% laid off（倒閉）公司數
-- 2023-2024擺脫疫情後為什麼倒閉數字提升？

-- 2020: 26
SELECT count(company)
FROM layoffs_staging
WHERE country = 'United States' AND 
      (date BETWEEN '2020-01-01' AND '2020-12-31') AND 
      (percentage_laid_off = 1);

-- 2021:6
SELECT count(company)
FROM layoffs_staging
WHERE country = 'United States' AND 
      date BETWEEN '2021-01-01' AND '2021-12-31' AND 
      (percentage_laid_off = 1);

-- 2022:33
SELECT count(company)
FROM layoffs_staging
WHERE country = 'United States' AND 
      date BETWEEN '2022-01-01' AND '2022-12-31' AND 
      (percentage_laid_off = 1);

-- 2023:58
SELECT count(company)
FROM layoffs_staging
WHERE country = 'United States' AND 
      date BETWEEN '2023-01-01' AND '2023-12-31' AND 
      (percentage_laid_off = 1);

-- 2024:54
SELECT count(company)
FROM layoffs_staging
WHERE country = 'United States' AND 
      date BETWEEN '2024-01-01' AND '2024-12-31' AND 
      (percentage_laid_off = 1);

-- 2025~10:14
SELECT count(company)
FROM layoffs_staging
WHERE country = 'United States' AND 
      date BETWEEN '2025-01-01' AND '2025-12-31' AND 
      (percentage_laid_off = 1);


-- 想知道倒閉的公司裡面，哪些產業最多
-- finance, healthcare, retail, food, transportation
SELECT DISTINCT(industry),
       count(company) AS company_count
FROM layoffs_staging
WHERE country = 'United States' AND 
      percentage_laid_off = 1
GROUP BY industry
ORDER BY count(company) DESC
LIMIT 5;

-- retail：倒閉公司前3名為Zulily, Deliv, Drizly
SELECT *
FROM layoffs_staging
WHERE country = 'United States' AND 
      percentage_laid_off = 1 AND 
      industry = 'Retail'
ORDER BY total_laid_off DESC;

-- food：倒閉公司前2名：Butler Hospitality, Fifth Season
SELECT *
FROM layoffs_staging
WHERE country = 'United States' AND 
      percentage_laid_off = 1 AND 
      industry = 'Food'
ORDER BY total_laid_off DESC;





