create database A3;
Exec sp_databases;


select * from teams


-- queries 


-- QUERY 1			we use the id of the 'specific manager' as names can be same/similar
-- All the players that have played under a specific manager.
DECLARE @Specific_Manager int = 41
select players.PLAYER_ID, players.FIRST_NAME, players.LAST_NAME, players.NATIONALITY, players.DOB, players.TEAM_ID, managers.ID as 'Managers ID'
from players
join managers on managers.TEAM_ID = players.TEAM_ID
where managers.ID = @Specific_Manager
order by players.PLAYER_ID



-- QUERY 2
-- All the matches that have been played in a specific country.
DECLARE @Specific_Country varchar(50) = 'Portugal'
select matches.MATCH_ID, matches.SEASON, matches.DATE_TIME, matches.STADIUM_ID, matches.HOME_TEAM_SCORE, matches.AWAY_TEAM_ID, matches.HOME_TEAM_SCORE, matches.AWAY_TEAM_SCORE, matches.ATTENDANCE
from matches
join stadiums on stadiums.ID = matches.STADIUM_ID
where stadiums.COUNTRY = @Specific_Country



-- QUERY 3
-- All the teams that have won more than 3 matches in their home stadium.
--(Assume a team wins only if they scored more goals then other team)
select matches.HOME_TEAM_ID as 'Team ID', teams.TEAM_NAME, teams.COUNTRY, teams.HOME_STADIUM_ID, count(*) as 'no.of Matches Won'
from teams
join matches on matches.STADIUM_ID = teams.HOME_STADIUM_ID			-- team playing in home stadium
				and matches.HOME_TEAM_ID = teams.ID
where matches.HOME_TEAM_SCORE > matches.AWAY_TEAM_SCORE				-- team won in their home stadium
group by matches.HOME_TEAM_ID, teams.TEAM_NAME, teams.COUNTRY, teams.HOME_STADIUM_ID
having count(*) > 3


-- EASY 
-- 4. All the teams with foreign managers.

     select teams.ID, teams.TEAM_NAME, managers.FIRST_NAME, teams.COUNTRY, teams.HOME_STADIUM_ID , managers.NATIONALITY from  teams
     join managers on teams.ID= managers.TEAM_ID
     where managers.NATIONALITY != teams.COUNTRY
     
-- 5. All the matches that were played in stadiums with seating capacity greater than 60,000.
     select matches.MATCH_ID, matches.SEASON , matches.AWAY_TEAM_ID,matches.HOME_TEAM_ID,matches.AWAY_TEAM_SCORE, matches.HOME_TEAM_SCORE, stadiums.ID as stadium_id, stadiums.NAME as stadium_name from matches 
     join stadiums on matches.STADIUM_ID= stadiums.ID
     where stadiums.CAPACITY> 60000

-- MEDIUM
-- 6. All Goals made without an assist in 2020 by players having height greater than 180 cm.
     select goals.GOAL_ID , goals.MATCH_ID, goals.PID , goals.ASSIST, goals.GOAL_DESC, player_id  FROM goals
     JOIN players ON goals.PID= players.PLAYER_ID
     JOIN matches on goals.MATCH_ID= matches.MATCH_ID
     where players.HEIGHT>180 and  (SELECT year((SELECT SUBSTRING(matches.DATE_TIME, 1, 9) AS myyear)))= 2020 
     and goals.ASSIST is NULL

-- 7. All Russian teams with win percentage less than 50% in home matches
------------ Functions -------------
     create function num ()
     returns float
     as 
     BEGIN
     return
	 (
           select count(matches.MATCH_ID) as num from matches 
           join teams on teams.ID= matches.HOME_TEAM_ID
           where (matches.HOME_TEAM_SCORE>matches.AWAY_TEAM_SCORE) and teams.COUNTRY ='Russia'
     )
     
     EnD
     
     create function den ()
     returns float
     as 
     BEGIN
     return
	 (
           select count(matches.MATCH_ID) as num from matches 
           join teams on teams.ID= matches.HOME_TEAM_ID
           where  teams.COUNTRY ='Russia'
     )
     
     EnD
     -- query 
     select distinct teams.TEAM_NAME, teams.ID, teams.COUNTRY, teams.HOME_STADIUM_ID from teams 
     join matches on teams.ID= matches.HOME_TEAM_ID
     where 
          teams.COUNTRY ='Russia' 
          and
     	 (SELECT dbo.num()/dbo.den()*100 as perc )< 50
     
     
	 

-- QUERY 8
-- All Stadiums that have hosted more than 6 matches with host team having a win percentage less than 50%.
select stadiums.ID as 'Stadium ID' , stadiums.NAME as 'Stadium Name', stadiums.COUNTRY, teams.ID as 'Team ID', count(matches.MATCH_ID) as 'Matches Hosted'		-- stadiums that hosted more than 6 matches
from matches	
join teams on teams.HOME_STADIUM_ID = matches.STADIUM_ID					-- host team plays match in home stadium
join stadiums on stadiums.ID = teams.HOME_STADIUM_ID
group by teams.HOME_STADIUM_ID, stadiums.NAME, teams.ID, stadiums.COUNTRY, stadiums.ID
having count(matches.MATCH_ID) > 6	AND
	teams.ID in (
		select T1.ID
		from (  select teams.ID, count(*) as wins							-- count of matches won by host team
				from matches												-- in host stadium
				join teams on teams.HOME_STADIUM_ID = matches.STADIUM_ID	-- host team plays match in home stadium
							  and matches.HOME_TEAM_ID = teams.ID
				where matches.HOME_TEAM_SCORE > matches.AWAY_TEAM_SCORE
				group by teams.HOME_STADIUM_ID, teams.ID) as T1

		join (  select teams.ID, count(*) as total_plays					-- count of total played matches by host team
				from matches												-- in home stadium
				join teams on teams.HOME_STADIUM_ID = matches.STADIUM_ID	-- host team plays match in home stadium
							  and matches.HOME_TEAM_ID = teams.ID
				group by teams.HOME_STADIUM_ID, teams.ID) as T2 on T1.ID  = T2.ID

		where (T1.wins/T2.total_plays) * 100 < 50	)



-- QUERY 9
-- The season with the greatest number of left-foot goals.
select top 1 matches.SEASON, count(*) as 'Left - footed goals'
from goals
join matches on matches.MATCH_ID = goals.MATCH_ID
where goals.GOAL_DESC LIKE 'left%'
group by matches.SEASON
order by  count(*) desc

/*****	OR	*****/

SELECT T.SEASON	, COUNT(*) AS num_left_footed_goals	-- season with max no.of left-footed goals
FROM ( SELECT matches.SEASON, goals.MATCH_ID		-- lists all matches and their seasons that had left-footed goals
	   FROM goals
	   JOIN matches ON goals.MATCH_ID = matches.MATCH_ID
       WHERE GOAL_DESC LIKE 'left%' ) as T
group by T.SEASON
having count(*) = ( select max(Temp.num_left_footed_goals)				-- max left-footed goals from all seasons
					from (	SELECT matches.SEASON, COUNT(*) AS num_left_footed_goals	-- count of left-footed 
							FROM goals													-- goals of each season
							JOIN matches ON matches.MATCH_ID = goals.MATCH_ID
							WHERE goals.GOAL_DESC LIKE 'left%'
							GROUP BY matches.SEASON ) as Temp )



	 --------------------------- HARD ---------------------------

	 

-- QUERY 10
-- The country with maximum number of players with at least one goal.
select top 1  T1.NATIONALITY, count(*) as players_each_country	 -- count players from each country
from  ( select players.PLAYER_ID, count(*) as No_of_Goals, players.NATIONALITY
		from players											 -- players with goals >= 1
		join goals on players.PLAYER_ID = goals.PID				 -- and their nationality
		group by players.PLAYER_ID, players.NATIONALITY ) as T1
group by T1.NATIONALITY
order by players_each_country desc

/*****	OR	*****/

select T.NATIONALITY, count(*) as 'Max no.of goaling Players'		-- country with max goaling players
from  ( select players.PLAYER_ID, count(*) as No_of_Goals, players.NATIONALITY
		from players									-- players with goals >= 1
		join goals on players.PLAYER_ID = goals.PID
		group by players.PLAYER_ID, players.NATIONALITY ) as T
group by T.NATIONALITY
having count(*) = 
				(select max(T2.players_each_country)							 -- max players from a country
				 from ( select count(*) as players_each_country, T1.NATIONALITY  -- count players from each country
						from  ( select players.PLAYER_ID, count(*) as No_of_Goals, players.NATIONALITY
								from players									 -- players with goals >= 1
								join goals on players.PLAYER_ID = goals.PID		 -- and their nationality
								group by players.PLAYER_ID, players.NATIONALITY ) as T1
						group by T1.NATIONALITY ) as T2)



-- QUERY 11
-- All the stadiums with greater number of left-footed shots than right-footed shots.
select stadiums.ID as 'Stadium ID', stadiums.NAME as 'Stadium Name', stadiums.COUNTRY, count(CASE WHEN goals.GOAL_DESC like 'left%' THEN 1 END) as left_goal,
		count(CASE WHEN goals.GOAL_DESC like 'right%' THEN 1 END) as right_goal
from goals
join matches on matches.MATCH_ID = goals.MATCH_ID
join stadiums on matches.STADIUM_ID = stadiums.ID
group by stadiums.ID, stadiums.NAME, stadiums.COUNTRY
having count(CASE WHEN goals.GOAL_DESC like 'left%' THEN 1 END) >
		count(CASE WHEN goals.GOAL_DESC like 'right%' THEN 1 END)
order by  stadiums.ID



-- QUERY 12
-- All matches that were played in country with maximum cumulative stadium seating capacity order by recent first.
select matches.MATCH_ID, matches.SEASON, matches.DATE_TIME, matches.STADIUM_ID, matches.HOME_TEAM_SCORE, matches.AWAY_TEAM_ID, matches.HOME_TEAM_SCORE, matches.AWAY_TEAM_SCORE, matches.ATTENDANCE, stadiums.COUNTRY 
from matches
join stadiums on stadiums.ID = matches.STADIUM_ID
where stadiums.COUNTRY = (
		select stadiums.COUNTRY --, sum(stadiums.CAPACITY) as max_cumulative_capacity
		from stadiums
		group by stadiums.COUNTRY
		having sum(stadiums.CAPACITY) = (select max(Temp.cumulative_capacity) as cumulative_capacity
										 from ( select stadiums.COUNTRY, sum(stadiums.CAPACITY) as cumulative_capacity
												from stadiums
												group by stadiums.COUNTRY ) as Temp)
							)
order by matches.DATE_TIME desc		-- earliest first




--	 13 . The player duo with the greatest number of goal-assist combination
--(i.e. pair of players that have assisted each other in more goals than any other duo).





WITH player_combinations AS (
    SELECT g1.PID AS player1_id, g2.PID AS player2_id, COUNT(*) AS combination_count
    FROM goals g1
    JOIN goals g2 ON g1.PID = g2.ASSIST AND g1.ASSIST = g2.PID
    GROUP BY g1.PID, g2.PID
	--ORDER BY combination_count DESC
)
SELECT top 1 player1_id, player2_id, combination_count
FROM player_combinations
ORDER BY combination_count DESC


-- 14. The team having players with more header goal percentage than any other team in 2020.

     SELECT top 1 teams.ID, teams.TEAM_NAME,teams.COUNTRY,teams.HOME_STADIUM_ID, 
            COUNT(*) AS total_goals,
            SUM(CASE WHEN goals.GOAL_DESC = 'header' THEN 1 ELSE 0 END) AS header_goals,
            (SUM(CASE WHEN goals.GOAL_DESC = 'header' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS percentage_header_goals
     FROM teams
     JOIN matches ON teams.ID = matches.AWAY_TEAM_ID
     JOIN goals ON matches.MATCH_ID = goals.MATCH_ID
     where (SELECT year((SELECT SUBSTRING(matches.DATE_TIME, 1, 9) AS myyear)))= 2020
     GROUP BY teams.ID, teams.TEAM_NAME,teams.COUNTRY,teams.HOME_STADIUM_ID
     ORDER BY percentage_header_goals DESC;


-- 15. The most successful manager of UCL (2016-2022).

	WITH my_table AS (
    SELECT total_matches_played, total_matches_won, t_id, team_name, firstname,lastname,dob,nationality, manager_id,
    CAST((total_matches_won * 1.0 / total_matches_played) * 100 AS FLOAT) AS percentage1
    FROM 
	(
        SELECT teams.id AS t_id, teams.TEAM_NAME AS team_name, managers.FIRST_NAME as firstname,managers.LAST_NAME as lastname, 
		managers.ID as manager_id,
		managers.DOB as dob,managers.NATIONALITY as nationality,
        COUNT(*) AS total_matches_played,
        SUM(CASE
            WHEN matches.HOME_TEAM_SCORE > matches.AWAY_TEAM_SCORE THEN 1
            ELSE 0
            END) AS total_matches_won
		
        FROM teams
		join managers on teams.ID= managers.TEAM_ID
        JOIN matches ON teams.ID = matches.AWAY_TEAM_ID OR teams.ID = matches.HOME_TEAM_ID
		
		--where matches.SEASON in('2016-2017', '2017-2018' , '2018-2019', '2019-2020' , '2022-2021', '2021-2022') 
        GROUP BY teams.id, teams.TEAM_NAME,managers.FIRST_NAME,managers.LAST_NAME,managers.ID,managers.DOB,managers.NATIONALITY
    ) AS my_cte
)
SELECT 'The most successfull manager is ' as cout, t_id, team_name, firstname,lastname,dob,nationality, manager_id,'with winning percentage of the team as'as cout2, team_name,  percentage1
FROM my_table
WHERE percentage1 = (SELECT MAX(percentage1) FROM my_table);



-- BONUS 16. The winner teams for each season of UCL (2016-2022).
     
	  ------------------------------------------------------
	  ------------------------------------------------------
	 

	WITH my_table AS (
    SELECT total_matches_played, total_matches_won, t_id, team_name, season,country,std_id,
           CAST((total_matches_won * 1.0 / total_matches_played) * 100 AS FLOAT) AS percentage1,
           ROW_NUMBER() OVER (PARTITION BY season ORDER BY (total_matches_won * 1.0 / total_matches_played) DESC) AS rn
    FROM 
	(
        SELECT teams.id AS t_id, teams.TEAM_NAME AS team_name,teams.COUNTRY as country,teams.HOME_STADIUM_ID as std_id, matches.season as season,
               COUNT(*) AS total_matches_played,
               SUM(CASE
                   WHEN HOME_TEAM_SCORE > AWAY_TEAM_SCORE THEN 1
                   ELSE 0
               END) AS total_matches_won
        FROM teams
        JOIN matches ON teams.ID = matches.AWAY_TEAM_ID OR teams.ID = matches.HOME_TEAM_ID
        WHERE matches.SEASON IN ('2016-2017', '2017-2018', '2018-2019', '2019-2020', '2022-2021', '2021-2022') 
        GROUP BY teams.id, teams.TEAM_NAME, matches.season, teams.COUNTRY,teams.HOME_STADIUM_ID
    ) AS my_cte
)
SELECT season, team_name, t_id,std_id,country, percentage1 AS percentage_matches_won
FROM my_table
WHERE rn = 1
ORDER BY season;

	                                        
