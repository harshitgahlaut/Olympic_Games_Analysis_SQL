-- Advanced Queries

-- 1 Mention the total no of nations who participated in each olympics game?
WITH all_countries AS
					(SELECT games, olr.region
        			FROM olympics_history olh
        			JOIN olympics_regions olr ON olr.noc = olh.noc
        			GROUP BY games, olr.region)
SELECT games, COUNT(1) AS total_countries
FROM all_countries
GROUP BY games
ORDER BY games;

-- 2 Which year saw the highest and lowest no of countries participating in olympics.
WITH all_countries AS
				  (SELECT games, olr.region
				  FROM olympics_history olh
				  JOIN olympics_regions olr ON olr.noc=olh.noc
				  GROUP BY games, olr.region),
  	tot_countries AS
				  (SELECT games, COUNT(1) AS total_countries
				  FROM all_countries
				  GROUP BY games)
SELECT DISTINCT
		CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries),
			   '-',
			  FIRST_VALUE(total_countries) OVER(ORDER BY total_countries)) AS lowest_countries,
		CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries DESC),
			   '-', 
			   FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS highest_countries
FROM tot_countries
ORDER BY 1;

-- 3 Which nation has participated in all of the olympic games?
WITH tot_games AS
              (SELECT COUNT(DISTINCT games) AS total_games
              FROM olympics_history),
     countries AS
              (SELECT games, olr.region AS country
              FROM olympics_history olh
              JOIN olympics_regions olr ON olr.noc=olh.noc
              GROUP BY games, olr.region),
     countries_participated AS
              (SELECT country, COUNT(1) AS total_participated_games
              FROM countries
              GROUP BY country)
SELECT cp.*
FROM countries_participated cp
JOIN tot_games tg on tg.total_games = cp.total_participated_games
ORDER BY 1;

-- 4 Identify the sport which was played in all summer olympics.
WITH t1 AS
		(SELECT COUNT(DISTINCT(games)) AS total_summer_games
		FROM olympics_history
		WHERE season = 'Summer'), 
	t2 AS
		(SELECT sport, COUNT(DISTINCT(games)) AS no_of_games
		FROM olympics_history
		WHERE season ='Summer'
		GROUP BY sport)
SELECT * FROM t2
JOIN t1 ON t1.total_summer_games = t2.no_of_games;

-- 5 Which Sports were just played only once in the olympics?
WITH t1 AS
		(SELECT DISTINCT games, sport
		FROM olympics_history),
	  t2 AS
		(SELECT sport, COUNT(1) AS num_of_games
		FROM t1
		GROUP BY sport)
SELECT t2.*, t1.games
FROM t2
JOIN t1 ON t1.sport = t2.sport
WHERE t2.num_of_games = 1
ORDER BY t1.sport;
	  
-- 6 Fetch oldest athletes to win a gold medal.
WITH temp AS
		(SELECT name,sex,CAST(
								CASE 
									WHEN age = 'NA' THEN '0' 
									ELSE age 
								END AS int
								) AS age,
		 team,games,city,sport, event, medal
		FROM olympics_history),
	ranking AS
		(SELECT *, RANK() OVER(ORDER BY age DESC) AS rnk
		FROM temp
		WHERE medal='Gold')
SELECT *
FROM ranking
WHERE rnk = 1;

-- 7 Find the Ratio of male and female athletes participated in all olympic games.
WITH t1 AS
		(SELECT sex, COUNT(1) AS cnt
		FROM olympics_history
		GROUP BY sex),
	t2 AS
		(SELECT *, ROW_NUMBER() OVER(ORDER BY cnt) AS rn
		 FROM t1),
	min_cnt AS
		(SELECT cnt FROM t2	WHERE rn = 1),
	max_cnt AS
		(SELECT cnt FROM t2	WHERE rn = 2)
SELECT CONCAT('1 : ', ROUND(max_cnt.cnt::DECIMAL/min_cnt.cnt, 2)) AS ratio
FROM min_cnt, max_cnt;

-- 8 Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
WITH t1 AS
		(SELECT name, team, COUNT(medal) AS no_total_medals
		FROM olympics_history
		WHERE medal IN ('Gold', 'Silver', 'Bronze')
		GROUP BY name, team
		ORDER BY no_total_medals DESC),
	t2 AS
		(SELECT *, DENSE_RANK() OVER(ORDER BY no_total_medals DESC )AS rnk
		 FROM t1)
SELECT name, team,no_total_medals,rnk
FROM t2
WHERE rnk<=5;

-- 9 Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
WITH t1 AS
		(SELECT region, count(medal) AS num_total_medals
		FROM olympics_history olh
		JOIN olympics_regions olr ON olh.noc = olr.noc
		WHERE medal IN ('Gold', 'Silver', 'Bronze')
		GROUP BY region
		ORDER BY num_total_medals DESC),
	t2 AS
		(SELECT *, DENSE_RANK() OVER(ORDER BY num_total_medals DESC )AS rnk
		 FROM t1
		)
SELECT region,num_total_medals, rnk
FROM t2
WHERE rnk<=5;

-- 10 List down total gold, silver and bronze medals won by each country.
SELECT country,
COALESCE (gold,0) AS gold,
COALESCE (silver,0) AS silver,
COALESCE (bronze,0) AS bronze
FROM CROSSTAB(
				'SELECT olr.region AS country, olh.medal, count(1) AS total_medals
				FROM olympics_history olh
				JOIN olympics_regions olr on olh.noc = olr.noc
				WHERE medal <> ''NA''
				GROUP BY olr.region, olh.medal
				ORDER BY olr.region, olh.medal',
				'VALUES (''Bronze''), (''Gold''),(''Silver'')'
			)
			AS RESULT( country varchar, bronze bigint, gold bigint, silver bigint)
ORDER BY gold DESC, silver DESC, bronze DESC;

-- 11 List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
SELECT SUBSTRING(games, 1, POSITION('-' in games)-1) AS games,
		SUBSTRING(games, POSITION('-' in games)+1) AS country,
		COALESCE (gold,0) AS gold,
		COALESCE (silver,0) AS silver,
		COALESCE (bronze,0) AS bronze
FROM CROSSTAB(
				'SELECT CONCAT(games, ''-'', olr.region) AS games, olh.medal, count(1) AS total_medals
				FROM olympics_history olh
				JOIN olympics_regions olr on olh.noc = olr.noc
				WHERE medal <> ''NA''
				GROUP BY games, olh.medal, olr.region
				ORDER BY games, medal',
				'VALUES (''Bronze''), (''Gold''),(''Silver'')'
			)
			AS result( games text, bronze bigint, gold bigint, silver bigint);


-- 12 Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH temp AS 
			(SELECT SUBSTRING(games_country, 1, POSITION('-' IN games_country)-1 ) AS games,
			SUBSTRING(games_country, POSITION('-' IN games_country)+1 ) AS country,
			COALESCE (gold,0) AS gold,
			COALESCE (silver,0) AS silver,
			COALESCE (bronze,0) AS bronze
			FROM CROSSTAB(
							'SELECT CONCAT(games, ''-'', olr.region ) AS games_country, olh.medal, count(1) AS total_medals
							FROM olympics_history olh
							JOIN olympics_regions olr ON olh.noc = olr.noc
							WHERE medal <> ''NA''
							GROUP BY games, olr.region, olh.medal
							ORDER BY games, olr.region, olh.medal',
							'VALUES (''Bronze''), (''Gold''),(''Silver'')'
						)
						AS result( games_country varchar, bronze bigint, gold bigint, silver bigint)
			ORDER BY games_country)
SELECT DISTINCT(games),
		concat(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY gold DESC),
			  '-',
			  FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC)) AS max_gold,
		concat(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY silver DESC),
			  '-',
			  FIRST_VALUE(silver) OVER(PARTITION BY games ORDER BY silver DESC)) AS max_silver,
		concat(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY bronze DESC),
			  '-',
			  FIRST_VALUE(bronze) OVER(PARTITION BY games ORDER BY bronze DESC)) AS max_bronze
FROM temp
ORDER BY games;

-- 13 Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH temp AS
			(SELECT SUBSTRING(games, 1, POSITION(' - ' IN games) - 1) AS games,
			 SUBSTRING(games, POSITION(' - ' IN games) + 3) AS country,
			 COALESCE(gold, 0) AS gold,
			 COALESCE(silver, 0) AS silver,
			 COALESCE(bronze, 0) AS bronze
			 FROM CROSSTAB(
							'SELECT CONCAT(games, '' - '', olr.region) AS games,medal,
				 					count(1) as total_medals
				 				FROM olympics_history olh
								JOIN olympics_regions olr ON olr.noc = olh.noc
								WHERE medal <> ''NA''
								GROUP BY games,olr.region,medal
								ORDER BY games,medal',
								'VALUES (''Bronze''), (''Gold''), (''Silver'')'
			 				)
						AS final_result(games text, bronze bigint, gold bigint, silver bigint)),
	tot_medals AS
				(SELECT games, olr.region AS country, count(1) AS total_medals
				FROM olympics_history olh
				JOIN olympics_regions olr ON olr.noc = olh.noc
				WHERE medal <> 'NA'
				GROUP BY games,olr.region ORDER BY 1, 2)
SELECT DISTINCT t.games,
	CONCAT(FIRST_VALUE(t.country) OVER(PARTITION BY t.games ORDER BY gold DESC),
		   '-',
		   FIRST_VALUE(t.gold) OVER(PARTITION BY t.games ORDER BY gold DESC)) AS Max_Gold,
 	CONCAT(FIRST_VALUE(t.country) OVER(PARTITION BY t.games ORDER BY silver DESC),
		   '-',
		   FIRST_VALUE(t.silver) OVER(PARTITION BY t.games ORDER BY silver DESC)) AS Max_Silver,
	CONCAT(FIRST_VALUE(t.country) OVER(PARTITION BY t.games ORDER BY bronze DESC),
		   '-',
		   FIRST_VALUE(t.bronze) OVER(PARTITION BY t.games ORDER BY bronze DESC)) AS Max_Bronze,
   	CONCAT(FIRST_VALUE(tm.country) OVER (PARTITION BY tm.games ORDER BY total_medals DESC NULLS LAST),
		   '-',
		   FIRST_VALUE(tm.total_medals) OVER(PARTITION BY tm.games ORDER BY total_medals DESC NULLS LAST)) AS Max_Medals
FROM temp t
JOIN tot_medals tm ON tm.games = t.games AND tm.country = t.country
ORDER BY games;

-- 14 Which countries have never won gold medal but have won silver/bronze medals?
SELECT * FROM (
			SELECT country,
			COALESCE (gold,0) AS gold,
			COALESCE (silver,0) AS silver,
			COALESCE (bronze,0) AS bronze
			FROM CROSSTAB(
							'SELECT olr.region AS country, olh.medal, count(1) AS total_medals
							FROM olympics_history olh
							JOIN olympics_regions olr ON olh.noc = olr.noc
							WHERE medal <> ''NA''
							GROUP BY olr.region, olh.medal
							ORDER BY olr.region, olh.medal',
							'VALUES (''Bronze''), (''Gold''),(''Silver'')'
						)
						AS result( country text, bronze bigint, gold bigint, silver bigint))x
WHERE gold = 0 AND (silver >0 or bronze >0)
ORDER BY gold DESC NULLS LAST, silver DESC NULLS LAST, bronze DESC NULLS LAST;

-- 15 Create a view that lists all medallists  and their details.
CREATE VIEW medalist AS
SELECT id, name, sex, age, team, noc, year, sport, event, medal
FROM olympics_history
WHERE medal <> 'NA';

SELECT * FROM medalist;

