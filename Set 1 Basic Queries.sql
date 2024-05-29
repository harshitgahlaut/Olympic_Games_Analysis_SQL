-- Basic Queries

-- 1 How many olympic games have been held?
SELECT COUNT(DISTINCT(games)) AS total_olympic_games
FROM olympics_history;

-- 2 List down all Olympics games held so far.
SELECT DISTINCT year, season, city
FROM olympics_history
ORDER BY year;

-- 3 Retrieve all athlete names and their respective teams.
SELECT DISTINCT name, team
FROM olympics_history;

-- 4 Find all female athletes who won a gold medal.
SELECT DISTINCT name, sport, team
FROM olympics_history
WHERE sex = 'F' AND medal = 'Gold';

-- 5 List the first 10 athletes sorted by age.
SELECT DISTINCT name,age
FROM olympics_history
ORDER BY age
LIMIT 10;

-- 6 Count the number of unique sports in the dataset.
SELECT COUNT(DISTINCT sport) AS unique_sports
FROM olympics_history;

-- 7 Calculate the average height of male athletes.
SELECT ROUND(AVG(CAST(height AS DECIMAL)),2) AS avg_height
FROM olympics_history
WHERE sex = 'M' AND height <> 'NA';

-- 8 Find the average weight of athletes by sport.
SELECT sport, ROUND(AVG(CAST(weight AS DECIMAL)),2) AS avg_weight
FROM olympics_history
WHERE weight <> 'NA'
GROUP BY sport;

-- 9 Count the number of athletes per NOC.
SELECT noc, COUNT(*) AS num_of_athletes
FROM olympics_history
GROUP BY noc;

-- 10 List all countries and their corresponding codes
SELECT DISTINCT olr.region as country, olh.noc as country_code
FROM olympics_history olh
JOIN olympics_regions olr ON olh.noc = olr.noc
ORDER BY country;

-- 11 List all the unique events where medals were awarded.
SELECT DISTINCT event
FROM olympics_history
WHERE medal <> 'NA';

-- 12 Retrieve athletes' full names in uppercase and their respective teams
SELECT DISTINCT UPPER(Name) AS athlete_name, team
FROM olympics_history;

-- 13 Replace 'Summer' with 'SUM' and 'Winter' with 'WIN' in the Season column.
SELECT DISTINCT name,
				CASE
					WHEN season = 'Summer' THEN 'SUM'
					WHEN season = 'Winter' THEN 'WIN'
				END AS short_season
FROM olympics_history;

-- 14 Handle NULL values in the Medal column by replacing them with 'No Medal'.
SELECT DISTINCT name, REPLACE(medal, 'NA', 'No Medal') as medals
FROM olympics_history;

-- 15 List all host cities that have hosted the Olympics more than once.
SELECT city, count(distinct year) as host_count
FROM olympics_history
GROUP BY city
HAVING count(distinct year) > 1;