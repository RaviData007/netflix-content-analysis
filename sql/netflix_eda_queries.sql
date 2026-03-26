CREATE DATABASE Netflix_1;

SELECT
*
FROM
netflix_clean;	

-- 1. Content type split
SELECT 
	type, 
	COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM netflix_clean
GROUP BY type;

--First see data
SELECT
*
FROM
	netflix_clean
WHERE
	type IN ('12/15/2018','William Wyler');

--Delete data
DELETE FROM
	netflix_clean
WHERE
	type IN ('12/15/2018','William Wyler');


-- 2. Yearly additions trend

SELECT 
	year_added, 
	type,
	COUNT(*) AS titles_added
FROM 
	netflix_clean
WHERE
	year_added IS NOT NULL
GROUP BY
	year_added, 
	type
ORDER BY
	year_added;

--Movies only

SELECT 
	year_added, 
	type,
	COUNT(*) AS titles_added
FROM 
	netflix_clean
WHERE
	year_added IS NOT NULL
GROUP BY
	year_added, 
	type
HAVING
	type='Movie'
ORDER BY
	year_added;

-- 3. Top 10 content-producing countries

SELECT TOP 10
	country ,
	COUNT(*) AS total
FROM
	[dbo].[netflix_countries]
WHERE
	country <> 'Unknown'
GROUP BY
	country
ORDER BY
	total DESC;


-- 4. Top 15 directors (Movies only)

SELECT TOP 15
	director,
	COUNT(*) AS movies
FROM
	netflix_clean
WHERE
	type = 'Movie' AND	director <> 'Unknown'
GROUP BY
	director
ORDER BY
	movies DESC;

-- 5. Rating distribution by type

SELECT 
	rating,
	type,
	COUNT(*) AS cnt
FROM
	netflix_clean
GROUP BY
	rating,
	type
ORDER BY 
	cnt DESC;

-- 6. Average movie duration by year

SELECT
	release_year,
	AVG(duration_int) AS avg_minutes,
	COUNT(*) AS movie_count
FROM
	netflix_clean
WHERE
	type = 'Movie' AND duration_int IS NOT NULL
GROUP BY
	release_year
ORDER BY
	release_year;

-- 7. Content added per month (seasonality)

SELECT
	month_added,
	month_name,
	COUNT(*) AS cnt
FROM
	netflix_clean
WHERE
	month_added IS NOT NULL
GROUP BY
	month_added,
	month_name
ORDER BY
	month_added ;


-- 8. Top genres 

SELECT TOP 10
	genre,
	type,
	COUNT(*) AS cnt
FROM
	netflix_genres
GROUP BY
	genre,
	type
ORDER BY
	cnt DESC

-- 9. YoY growth using LAG

WITH yearly AS (
    SELECT 
		year_added,
		COUNT(*) AS cnt
    FROM 
		netflix_clean
    WHERE 
		year_added IS NOT NULL
    GROUP BY 
		year_added
)
SELECT 
	year_added,
	cnt,
    LAG(cnt) OVER (ORDER BY year_added) AS prev_year,
	cnt - LAG(cnt) OVER (ORDER BY year_added) AS yoy_change,
    ROUND(100.0 * (cnt - LAG(cnt) OVER (ORDER BY year_added))
    / NULLIF(LAG(cnt) OVER (ORDER BY year_added), 0), 1) AS yoy_pct
FROM
	yearly;

-- YoY growth using LAG Movie vs TV Shows

WITH yearly_type AS (
    SELECT 
        year_added, 
        type, 
        COUNT(*) AS cnt
    FROM netflix_clean
    WHERE year_added IS NOT NULL
    GROUP BY year_added, type
)
SELECT 
    year_added,
    type,
    cnt,
    LAG(cnt) OVER (PARTITION BY type ORDER BY year_added) AS prev_year,
    cnt - LAG(cnt) OVER (PARTITION BY type ORDER BY year_added) AS yoy_change,
    ROUND(100.0 * (cnt - LAG(cnt) OVER (PARTITION BY type ORDER BY year_added))
    / NULLIF(LAG(cnt) OVER (PARTITION BY type ORDER BY year_added), 0), 1) AS yoy_pct
FROM
    yearly_type
ORDER BY
	year_added DESC,
	type;


-- 10. Director–genre heatmap (top directors × genre)

SELECT TOP 20
	director, 
	genre, 
	COUNT(*) AS cnt
FROM
	netflix_clean nc
JOIN netflix_genres ng 
ON nc.show_id = ng.show_id
WHERE 
	nc.director <> 'Unknown'
GROUP BY
	director, genre
ORDER BY cnt DESC;