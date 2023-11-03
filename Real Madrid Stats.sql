DROP TABLE IF EXISTS #real_madrid
SELECT 
	keys.player_name,
	keys.position,
	CASE
		WHEN keys.position = 'Goalkeeper' THEN '1'
		WHEN keys.position = 'Defender' THEN '2'
		WHEN keys.position = 'Midfielder' THEN '3'
		WHEN keys.position = 'Forward' THEN '4'
	END AS id_position,
	keys.match_played,
	keys.minutes_played,
	keys.goals,
	keys.assists,
	ISNULL(goal.inside_area, 0) AS inside_area,
	ISNULL(goal.outside_areas, 0) AS outside_area,
	ISNULL(goal.headers, 0) AS headers,
	ISNULL(goal.left_foot, 0) AS left_foot,
	ISNULL(goal.right_foot, 0) AS right_foot,
	ISNULL(goal.others, 0) AS others,
	ISNULL(dist.pass_attempted, 0) AS pass_attempted,
	ISNULL(dist.pass_completed, 0) AS pass_completed,
	CASE
		WHEN dist.pass_attempted IS NULL OR dist.pass_attempted = 0 THEN 0
        ELSE CAST(ROUND((ISNULL(dist.pass_completed, 0) * 100.0 / dist.pass_attempted),2) AS DECIMAL (10,2))
    END AS pass_accuracy,
	ISNULL(disc.fouls_committed, 0) AS fouls_commited,
	ISNULL(disc.red, 0) AS yellow,
	ISNULL(disc.yellow, 0) AS red,
	ISNULL(def.balls_recoverd, 0) AS balls_recovered
INTO #real_madrid
FROM [UCL].[dbo].[key_stats] as keys
FULL OUTER JOIN [UCL].[dbo].[goals] as goal
	ON keys.player_name = goal.player_name
FULL OUTER JOIN [UCL].[dbo].[distributon] as dist
	ON keys.player_name = dist.player_name
FULL OUTER JOIN [UCL].[dbo].[defending] as def
	ON keys.player_name = def.player_name
FULL OUTER JOIN [UCL].[dbo].[disciplinary] as disc
	ON keys.player_name = disc.player_name
FULL OUTER JOIN [UCL].[dbo].[goalkeeping] as kiper
	ON keys.player_name = kiper.player_name
WHERE keys.club = 'Real Madrid'
ORDER BY id_position, player_name;

--SELECT all data
SELECT *
FROM #real_madrid

--Real Madrid Top Scorer and Goal Contributions
SELECT
	RANK() OVER (ORDER BY goals DESC, minutes_played) AS goal_ranking,
	player_name,
	goals,
	ROUND((CONVERT(FLOAT, goals) / match_played),2) AS goal_ratio,
	SUM(goals) OVER () AS team_goals,
	ROUND(((CONVERT(FLOAT, goals) / SUM(goals) OVER () )) * 100, 2) AS goal_contribution_percentage
FROM #real_madrid
WHERE goals !=  0
ORDER BY RANK() OVER (ORDER BY goals DESC, minutes_played);

--Real Madrid Top Assist
SELECT
	RANK() OVER (ORDER BY assists DESC, minutes_played) AS ranking,
	player_name,
	assists
FROM #real_madrid
WHERE assists !=  0
ORDER BY RANK() OVER (ORDER BY assists DESC, minutes_played);

--Real Madrid Goal + Assists
SELECT
	player_name,
	goals,
	assists,
	goals + assists AS ga
FROM #real_madrid
WHERE goals != 0 OR assists !=0
GROUP BY player_name, goals, assists
ORDER BY goals + assists DESC;

--Player with most match played and minutes played
SELECT
	player_name,
	match_played,
	minutes_played
FROM #real_madrid
ORDER BY minutes_played DESC;

--Player with most pass completed and his pass accuracy
SELECT
	player_name,
	pass_attempted,
	pass_completed,
	pass_accuracy
FROM #real_madrid
ORDER BY pass_completed DESC;

--Player with most yellow card
SELECT
	player_name,
	position,
	yellow,
	SUM(yellow) OVER () AS total_team_yellow_card
FROM #real_madrid
WHERE yellow != 0
ORDER BY yellow DESC;

--Player with most ball recovered
SELECT
	player_name,
	position,
	balls_recovered
FROM #real_madrid
WHERE balls_recovered != 0
ORDER BY balls_recovered DESC;

--Goalkeeper Stats
--For GK, the table is in the goalkeeping table
SELECT
	player_name,
	saved,
	conceded,
	ROUND((CONVERT(FLOAT, saved) / (saved + conceded)) *100, 2) AS saved_percentage,
	saved_penalties,
	cleansheets,
	match_played
FROM goalkeeping
WHERE club = 'Real Madrid'
GROUP BY player_name, saved, conceded, saved_penalties, cleansheets, match_played;