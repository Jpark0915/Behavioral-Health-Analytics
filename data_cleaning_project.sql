-- Data Cleaning 


SELECT * 
FROM layoffs;

-- 1. Remove Duplicates 
-- 2. Standardize the Data 
-- 3. Null Values or BLank Values 
-- 4. Remove Any Columns or Rows



CREATE TABLE layoffs_staging
LIKE layoffs; 


SELECT * 
FROM layoffs_staging;


INSERT layoffs_staging
SELECT * 
FROM layoffs; 


SELECT *,
ROW_NUMBER () OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num 
FROM layoffs_staging; 


WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage
, country, funds_raised_millions) AS row_num 
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte 
WHERE row_num > 1;


SELECT * 
FROM layoffs_staging
WHERE company = 'Casper';


WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage
, country, funds_raised_millions) AS row_num 
FROM layoffs_staging
)
DELETE 
FROM duplicate_cte 
WHERE row_num > 1;



CREATE TABLE `layoffs_staging2` (
  `company` varchar(50) DEFAULT NULL,
  `location` varchar(50) DEFAULT NULL,
  `industry` varchar(50) DEFAULT NULL,
  `total_laid_off` varchar(50) DEFAULT NULL,
  `percentage_laid_off` varchar(50) DEFAULT NULL,
  `date` varchar(50) DEFAULT NULL,
  `stage` varchar(50) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  `funds_raised_millions` varchar(50) DEFAULT NULL,
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT * 
FROM layoffs_staging2
WHERE row_num >1;


INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage
, country, funds_raised_millions) AS row_num 
FROM layoffs_staging;



DELETE
FROM layoffs_staging2
WHERE row_num >1;


SELECT *
FROM layoffs_staging2;




-- Standardizing Data 

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2 
SET company = TRIM(company);


SELECT DISTINCT industry 
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT `date`
FROM layoffs_staging2;


UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` IS NOT NULL
  AND `date` != ''
  AND `date` REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';


UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` IS NULL
   OR `date` = ''
   OR `date` NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';


ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT DISTINCT total_laid_off
FROM layoffs_staging2
ORDER BY total_laid_off;

SELECT * 
FROM layoffs_staging2
WHERE NOT total_laid_off REGEXP '^[0-9]+$';

UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE LOWER(TRIM(total_laid_off)) IN ('null', 'n/a', 'na', 'unknown', '');


UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE TRIM(LOWER(percentage_laid_off)) IN ('null', '', 'n/a', 'na', 'none', 'unknown');


SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';


SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';


SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;


UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


SELECT *
FROM layoffs_staging2;



SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;







