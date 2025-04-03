CREATE TABLE Matches (
    MatchID INT PRIMARY KEY,
    MatchDate DATE,
    Location VARCHAR(100),
    Team1 VARCHAR(100),
    Team2 VARCHAR(100),
    Winner VARCHAR(100)
);
CREATE TABLE Performance (
    MatchID INT,
    PlayerID INT,
    RunsScored INT,
    WicketsTaken INT,
    Catches INT,
    Stumpings INT,
    NotOut BIT,
    RunOuts INT,
    FOREIGN KEY (MatchID) REFERENCES Matches(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES Players(PlayerID)
);
CREATE TABLE Teams (
    TeamName VARCHAR(100) PRIMARY KEY,
    Coach VARCHAR(100),
    Captain VARCHAR(100)
);

INSERT INTO Players VALUES
(1, 'Virat Kohli', 'India', 'Batsman', 2008),
(2, 'Steve Smith', 'Australia', 'Batsman', 2010),
(3, 'Mitchell Starc', 'Australia', 'Bowler', 2010),
(4, 'MS Dhoni', 'India', 'Wicket-Keeper', 2004),
(5, 'Ben Stokes', 'England', 'All-Rounder', 2011);

INSERT INTO Matches VALUES
(1, '2023-03-01', 'Mumbai', 'India', 'Australia', 'India'),
(2, '2023-03-05', 'Sydney', 'Australia', 'England', 'England');


INSERT INTO Performance VALUES
(1, 1, 82, 0, 1, 0, 0, 0),
(1, 4, 5, 0, 0, 1, 1, 0),
(2, 3, 15, 4, 0, 0, 0, 0);


INSERT INTO Teams VALUES
('India', 'Rahul Dravid', 'Rohit Sharma'),
('Australia', 'Andrew McDonald', 'Pat Cummins');

select * from Players
select * from Matches
select * from Performance
select * from Teams

--1. Identify the player with the best batting average 
--(total runs scored divided by the number of matches played) across all matches.

SELECT TOP 1 p.PlayerID,p.PlayerName, 
avg(RunsScored) AS Batting_Average
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.PlayerID, p.PlayerName
ORDER BY Batting_Average DESC;

-- 2. Find the team with the highest win percentage in matches played across all locations.

SELECT TOP 1 

-- 3. Identify the player who contributed the highest percentage of their
-- team's total runs in any single match.

with contribution as
(
select 
	b.MatchID,
	a.PlayerID,
	a.PlayerName,
	a.teamname,
	b.runsscored,
	--calculate percentage contribution using window function 
	round((cast(b.RunsScored as float)/sum(cast(b.RunsScored as float)) over(partition by b.MatchID,a.Teamname)),2)*100  as percentage_score
from 
	Players as a
Join 
	Performance as b
on 
	a.PlayerID = b.PlayerID
)
, contri as
(
select *,
rank()over(partition by matchid order by percentage_score desc) as ranking
from contribution)
select *
from contri
where ranking = 1

----------------------------------------------------

--4. Determine the most consistent player, defined as the one with the smallest standard deviation of runs scored 
-- across matches.

select 
	a.PlayerID,
	a.PlayerName,
	a.teamname,
	--SQL Server's STDEV() function requires at least two non-NULL values to compute the standard deviation.
	isnull(stdev(b.runsscored),0) as std_dev	
from 
	Players as a
Join 
	Performance as b
on 
	a.PlayerID = b.PlayerID

group by
	a.PlayerID,
	a.PlayerName,
	a.teamname
order by 
	stdev(b.runsscored)

-- 5. Find all matches where the combined total of runs scored, wickets taken, and catches exceeded 500.

SELECT 
    MatchID, 
    SUM(runsscored + wicketstaken + catches) AS Exceed_500
FROM Performance
GROUP BY MatchID
HAVING SUM(runsscored + wicketstaken + catches) > 500;

-- 6. Identify the player who has won the most "Player of the Match" awards 
-- (highest runs scored or wickets taken in a match).

with MoM as
(
	select playerid,
		   matchid,
		   runsscored,
		   wicketstaken,
		   rank() over(partition by matchid order by runsscored desc) as most_run,
		   rank() over(partition by matchid order by wicketstaken desc) as most_wicket
	from
		performance
)
select top 1
	a.playerid,
	a.MatchID,
	c.playername,
	--counting the rank one player
	count(*) as Most_mom
from 
	performance as a
join 
	mom as b
on
	a.playerid = b.playerid
join
	players as c
on 
	c.PlayerID = b.playerid
--filterout the
where
	most_run = 1 or most_wicket = 1
group by
	a.playerid,
	a.matchid,
	c.playername
order by 
	count(*) desc,
	c.PlayerName desc

-- 7. Determine the team that has the most diverse player roles in their squad.

	select top 1 teamname,
	count(distinct role) as count_of_diff_role
from 
	players
group by 
	teamname
order by 
	count(distinct role)desc , TeamName desc

-- 8. Identify matches where the runs scored by both teams were unequal and sort them by the smallest difference in 
-- total runs between the two teams

WITH TeamRuns AS (
    SELECT 
        m.MatchID,
        m.Team1,
        m.Team2,
        SUM(CASE WHEN p.TeamName = m.Team1 THEN perf.RunsScored ELSE 0 END) AS Team1Runs,
        SUM(CASE WHEN p.TeamName = m.Team2 THEN perf.RunsScored ELSE 0 END) AS Team2Runs
    FROM Matches m
    JOIN Performance perf ON m.MatchID = perf.MatchID
    JOIN Players p ON perf.PlayerID = p.PlayerID
    GROUP BY m.MatchID, m.Team1, m.Team2
)
SELECT 
    MatchID,
    Team1,
    Team2,
    Team1Runs,
    Team2Runs,
    ABS(Team1Runs - Team2Runs) AS RunDifference
FROM TeamRuns
WHERE Team1Runs <> Team2Runs  -- Exclude matches where both teams scored the same
ORDER BY RunDifference ASC;  -- Sort by smallest difference first




WITH TeamRuns AS (
    SELECT 
        m.MatchID,
        m.Team1,
        m.Team2,
        SUM(CASE WHEN p.TeamName = m.Team1 THEN perf.RunsScored ELSE 0 END) AS Team1Runs,
        SUM(CASE WHEN p.TeamName = m.Team2 THEN perf.RunsScored ELSE 0 END) AS Team2Runs
    FROM Matches m
    JOIN Performance perf ON m.MatchID = perf.MatchID
    JOIN Players p ON perf.PlayerID = p.PlayerID
    GROUP BY m.MatchID, m.Team1, m.Team2
)
SELECT 
    MatchID,
    Team1,
    Team2,
    Team1Runs,
    Team2Runs,
    ABS(Team1Runs - Team2Runs) AS RunDifference
FROM TeamRuns
WHERE Team1Runs <> Team2Runs  -- Exclude matches where both teams scored the same
ORDER BY RunDifference ASC;  -- Sort by smallest difference first

---9 Find players who contributed (batted, bowled, or fielded) in every match that their team participated in.

select perf.MatchID, p.PlayerName,
case when RunsScored >= 1 then perf.PlayerID else 0 end as batted,
case when WicketsTaken >= 1 then perf.PlayerID else 0 end as bowled,
case when Catches >= 1 then perf.PlayerID else 0 end as fielded,
case when Stumpings >= 1 then perf.PlayerID else 0 end as stumped
from Performance as perf
join Players as p 
on perf.PlayerID = p.PlayerID

---------------------------------------------------------------------------- another query can be
select m.MatchID,p.PlayerName,perf.PlayerID, RunsScored, WicketsTaken, Catches, Stumpings
from Performance as perf
join Players as p
on perf.PlayerID = p.PlayerID
join Matches as m on
m.MatchID = perf.MatchID
where RunsScored >= 1 or WicketsTaken >= 1 or Catches >= 1 or Stumpings >= 1

-- 10. Identify the match with the closest margin of victory, based on runs scored by both teams.

WITH TeamScores AS (
    -- Calculate total runs scored by each team in each match
SELECT m.MatchID, m.Team1, m.Team2,
SUM(CASE WHEN p.TeamName = m.Team1 THEN perf.RunsScored ELSE 0 END) AS Team1Runs,
SUM(CASE WHEN p.TeamName = m.Team2 THEN perf.RunsScored ELSE 0 END) AS Team2Runs
FROM Matches m
JOIN Performance perf ON m.MatchID = perf.MatchID
JOIN Players p ON perf.PlayerID = p.PlayerID
GROUP BY m.MatchID, m.Team1, m.Team2
)
-- Find the match with the smallest run difference
SELECT top 1 MatchID, Team1, Team2, Team1Runs, Team2Runs,
ABS(Team1Runs - Team2Runs) AS RunDifference
FROM TeamScores
ORDER BY RunDifference ASC
 -- Fetch the match with the smallest run difference

-- 11. Calculate the total runs scored by each team across all matches.

select p.TeamName, sum(RunsScored) as total_runs_per_team
from Performance as perf
join Players p
on perf.PlayerID = p.PlayerID
group by p.TeamName

-- 12. List matches where the total wickets taken by the winning team exceeded 2.

select Winner, sum(WicketsTaken)
from Matches as m
join Performance as perf
on m.MatchID = perf.MatchID
group by Winner
having sum(WicketsTaken) > 2
---------------------------------------------------------------------------- another query can be

WITH WinningTeamWickets AS (
    -- Calculate total wickets taken by the winning team in each match
SELECT m.MatchID, m.Winner, SUM(perf.WicketsTaken) AS TotalWickets
FROM Matches m
JOIN Performance perf ON m.MatchID = perf.MatchID
JOIN Players p ON perf.PlayerID = p.PlayerID
WHERE p.TeamName = m.Winner  -- Only count wickets taken by the winning team's players
GROUP BY m.MatchID, m.Winner
)
-- Retrieve matches where the winning team took more than 2 wickets
SELECT MatchID, Winner, TotalWickets
FROM WinningTeamWickets
WHERE TotalWickets >= 2

-- 13. Retrieve the top 5 matches with the highest individual scores by any player.

select top 5 m.MatchID, p.PlayerName, perf.RunsScored, perf.PlayerID
from Matches as m
join Performance as perf
on m.MatchID = perf.MatchID
join Players as p
on p.PlayerID = perf.PlayerID
order by perf.RunsScored desc

-- Identify all bowlers who have taken at least 5 wickets across all matches.

select top 5 m.MatchID, p.PlayerName, sum(perf.WicketsTaken)
from Matches as m
join Performance as perf
on m.MatchID = perf.MatchID
join Players as p
on p.PlayerID = perf.PlayerID
group by m.MatchID, p.PlayerName
having sum(perf.WicketsTaken) > 2 -- taken 2 because no players have taken 5 wickets across all matches.

-- 15. Find the total number of catches taken by players from the team that won each match.

SELECT m.MatchID, m.Winner, perf.PlayerID, p.PlayerName, SUM(perf.Catches) AS Total_Catches
FROM Matches m
JOIN Performance as perf ON m.MatchID = perf.MatchID
JOIN Players as p ON perf.PlayerID = p.PlayerID
WHERE p.TeamName = m.Winner  -- Only count catches taken by the winning team's players
GROUP BY m.MatchID, m.Winner, perf.PlayerID, p.PlayerName

-- 16. Identify the player with the highest combined impact score in all matches.
-- The impact score is calculated as:
-- Runs scored × 1.5 + Wickets taken × 25 + Catches × 10 + Stumpings × 15 + Run outs × 10.
-- Only include players who participated in at least 3 matches.

select top 1 perf.PlayerID, p.PlayerName, count(perf.MatchID) as matches_played,
sum(RunsScored * 1.5 + WicketsTaken * 25 + Catches * 10 + Stumpings * 15 + RunOuts * 10) as impact_score
from Performance as perf
join Players as p
on perf.PlayerID = p.PlayerID
group by perf.PlayerID, p.PlayerName
having count(perf.MatchID) >= 1

-- 17. Find the match where the winning team had the narrowest margin of victory based on total runs scored by both teams.
-- If multiple matches have the same margin, list all of them.

WITH TeamScores AS (
    -- Calculate total runs scored by each team in each match
SELECT m.MatchID, m.Team1, m.Team2,
SUM(CASE WHEN p.TeamName = m.Team1 THEN perf.RunsScored ELSE 0 END) AS Team1Runs,
SUM(CASE WHEN p.TeamName = m.Team2 THEN perf.RunsScored ELSE 0 END) AS Team2Runs
FROM Matches m
JOIN Performance perf ON m.MatchID = perf.MatchID
JOIN Players p ON perf.PlayerID = p.PlayerID
where m.Winner = p.TeamName
GROUP BY m.MatchID, m.Team1, m.Team2
)
-- Find the match with the smallest run difference
SELECT MatchID, Team1, Team2, Team1Runs, Team2Runs,
ABS(Team1Runs - Team2Runs) AS RunDifference
FROM TeamScores
ORDER BY RunDifference ASC  -- Fetch the match with the smallest run difference

-- 18.List all players who have outperformed their teammates in terms of total runs scored in more than half the matches they played.
-- This requires finding matches where a player scored the most runs among their teammates and calculating the percentage.

WITH MostRuns AS 
(
SELECT PlayerID, MatchID,      -- Identify the highest scorer in each match
SUM(RunsScored) AS TotalScore,
RANK() OVER (PARTITION BY MatchID ORDER BY SUM(RunsScored) DESC) AS Ranking
FROM Performance
GROUP BY PlayerID, MatchID
)
SELECT PlayerName 
FROM Players as p 
JOIN MostRuns AS mr ON mr.PlayerID = p.PlayerID
GROUP BY p.PlayerID, p.PlayerName
HAVING 
COUNT(CASE WHEN mr.Ranking = 1 THEN 1 END) > (COUNT(DISTINCT mr.MatchID) / 2);

--19.Rank players by their average impact per match, considering only those who played at least three matches.
-- The impact is calculated as:
--Runs scored × 1.5 + Wickets taken × 25 + Catches × 10 + Stumpings × 15 + Run outs × 10.
--Players with the same average impact should share the same rank.

WITH PlayerImpact AS (
SELECT 
perf.PlayerID, 
p.PlayerName, 
COUNT(perf.MatchID) AS MatchesPlayed,
SUM(RunsScored * 1.5 + WicketsTaken * 25 + Catches * 10 + Stumpings * 15 + RunOuts * 10) AS TotalImpact,
SUM(RunsScored * 1.5 + WicketsTaken * 25 + Catches * 10 + Stumpings * 15 + RunOuts * 10) / COUNT(perf.MatchID) AS AvgImpact
FROM Performance AS perf
JOIN Players AS p ON perf.PlayerID = p.PlayerID
GROUP BY perf.PlayerID, p.PlayerName
HAVING COUNT(perf.MatchID) >= 1  -- Only players who played at least 3 matches
)
SELECT 
PlayerID, 
PlayerName, 
MatchesPlayed, 
TotalImpact, 
AvgImpact,
RANK() OVER (ORDER BY AvgImpact DESC) AS ImpactRank
FROM PlayerImpact
ORDER BY ImpactRank;

-- 20. Identify the top 3 matches with the highest cumulative total runs scored by both teams.
-- Rank the matches based on total runs using window functions. If multiple matches have the same total runs, they should share the same rank.

select m.MatchID, sum(RunsScored) as cumulative_total,
rank() over (order by sum(RunsScored) desc) as rank
from Matches as m
join Performance as perf
on m.MatchID = perf.MatchID
group by m.MatchID

-- 21. For each player, calculate their running cumulative impact score across all matches they’ve played, ordered by match date.
-- Include only players who have played in at least 3 matches.

with ImpactScores AS (
-- Calculate impact score for each player per match
SELECT 
perf.PlayerID,
m.MatchDate, 
perf.MatchID,
COUNT(DISTINCT perf.MatchID) AS MatchesPlayed,
sum(RunsScored * 1.5 + WicketsTaken * 25 + Catches * 10 + Stumpings * 15 + RunOuts * 10) AS cumulative_ImpactScore
FROM Performance perf
JOIN Matches m ON perf.MatchID = m.MatchID
group by perf.PlayerID, m.MatchDate,perf.MatchID
)
-- Calculate the running cumulative impact score
select PlayerID, MatchDate, MatchID, MatchesPlayed, cumulative_ImpactScore,
sum(cumulative_ImpactScore) over (partition by PlayerID order by MatchDate) as rank
from ImpactScores
where MatchesPlayed >=1