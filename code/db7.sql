






game player database
-- Drop existing tables if they exist
DROP TABLE IF EXISTS player_game;
DROP TABLE IF EXISTS game;
DROP TABLE IF EXISTS player;
DROP TABLE IF EXISTS team;
DROP TABLE IF EXISTS sports_club;

-- Create sports_club table
CREATE TABLE sports_club (
    club_id INT PRIMARY KEY, 
    club_name VARCHAR(38), 
    city VARCHAR(30), 
    year_establish CHAR(4)
);

-- Create team table
CREATE TABLE team (
    team_id INT PRIMARY KEY, 
    team_name VARCHAR(30),
    club_id INT REFERENCES sports_club(club_id) ON UPDATE CASCADE
);

-- Create player table
CREATE TABLE player (
    pid INT PRIMARY KEY, 
    player_name VARCHAR(30), 
    age INT CHECK (age > 0), 
    address VARCHAR(30),
    team_id INT REFERENCES team(team_id) ON UPDATE CASCADE
);

-- Create game table
CREATE TABLE game (
    game_id INT PRIMARY KEY, 
    game_name VARCHAR(30), 
    duration INT NOT NULL -- Duration in minutes
);

-- Create player_game table
CREATE TABLE player_game (
    pid INT REFERENCES player(pid) ON UPDATE CASCADE, 
    game_id INT REFERENCES game(game_id) ON UPDATE CASCADE, 
    PRIMARY KEY (pid, game_id)
);

-- Insert dummy data into sports_club table
INSERT INTO sports_club (club_id, club_name, city, year_establish)
VALUES
    (1, 'Mumbai Indians', 'Mumbai', '1995'),
    (2, 'Chennai Super Kings', 'Chennai', '2008'),
    (3, 'Royal Challengers Bangalore', 'Bangalore', '2008'),
    (4, 'Kolkata Knight Riders', 'Kolkata', '2008'),
    (5, 'Delhi Capitals', 'Delhi', '2008');

-- Insert dummy data into team table
INSERT INTO team (team_id, team_name, club_id)
VALUES
    (1, 'MI', 1),
    (2, 'CSK', 2),
    (3, 'RCB', 3),
    (4, 'KKR', 4),
    (5, 'DC', 5);

-- Insert dummy data into player table
INSERT INTO player (pid, player_name, age, address, team_id)
VALUES
    (1, 'Rahul Sharma', 25, 'Mumbai', 1),
    (2, 'Priya Patel', 28, 'Chennai', 2),
    (3, 'Amit Kumar', 30, 'Bangalore', 3),
    (4, 'Neha Gupta', 27, 'Kolkata', 4),
    (5, 'Deepak Singh', 26, 'Delhi', 5);

-- Insert dummy data into game table
INSERT INTO game (game_id, game_name, duration)
VALUES
    (1, 'Cricket', 400),
    (2, 'Football', 500),
    (3, 'Basketball', 450),
    (4, 'Tennis', 350),
    (5, 'Hockey', 480);

-- Insert dummy data into player_game table
INSERT INTO player_game (pid, game_id)
VALUES
    (1, 1),
    (2, 1),
    (3, 1),
    (4, 1),
    (5, 1);

-- Queries

-- 1. List the number of teams belonging to 'Royal Challengers Bangalore' sports club located in Bangalore city
SELECT COUNT(*)
FROM team, sports_club
WHERE team.club_id = sports_club.club_id
AND sports_club.club_name = 'Royal Challengers Bangalore'
AND sports_club.city = 'Bangalore';

-- 2. List names of players playing 'Cricket' game from 'IPL' team
SELECT p.player_name
FROM player p, player_game pg, game g, team t, sports_club sc
WHERE p.pid = pg.pid
AND pg.game_id = g.game_id
AND p.team_id = t.team_id
AND t.club_id = sc.club_id
AND g.game_name = 'Cricket'
AND sc.club_name = 'IPL';

-- 3. List the details of sports clubs played in Pune city
SELECT *
FROM sports_club
WHERE city = 'Pune';








--8

--

-- Function to find the count of players playing
DROP FUNCTION IF EXISTS count_players_playing;
CREATE OR REPLACE FUNCTION count_players_playing() RETURNS INTEGER AS
$$
DECLARE
    player_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO player_count
    FROM player;
    
    RETURN player_count;
END;
$$
LANGUAGE plpgsql;

-- Function to find the number of games with duration greater than 60 minutes
DROP FUNCTION IF EXISTS count_games_duration_greater_than_60;
CREATE OR REPLACE FUNCTION count_games_duration_greater_than_60() RETURNS INTEGER AS
$$
DECLARE
    game_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO game_count
    FROM game
    WHERE duration > 60;
    
    RETURN game_count;
END;
$$
LANGUAGE plpgsql;






--exception

--1

CREATE OR REPLACE FUNCTION find_year_of_establishment(sports_club_name VARCHAR) RETURNS INTEGER AS '
DECLARE
    establishment_year INTEGER;
BEGIN
    SELECT year_establish
    INTO establishment_year
    FROM sports_club
    WHERE club_name = sports_club_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION ''Sports club not found: %'', sports_club_name;
    ELSE
        RETURN establishment_year;
    END IF;
END;
' LANGUAGE plpgsql;

--2

CREATE OR REPLACE FUNCTION print_game_duration(game_name VARCHAR) RETURNS VOID AS '
DECLARE
    duration_minutes INTEGER;
BEGIN
    SELECT duration
    INTO duration_minutes
    FROM game
    WHERE game_name = game_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION ''Game not found: %'', game_name;
    ELSE
        RAISE NOTICE ''Game Duration of %: % minutes'', game_name, duration_minutes;
    END IF;
END;
' LANGUAGE plpgsql;

--view


--1

CREATE VIEW players_over_25_playing_cricket AS
SELECT *
FROM player
WHERE age > 25
AND pid IN (
    SELECT pid
    FROM player_game
    WHERE game_id = (
        SELECT game_id
        FROM game
        WHERE game_name = 'Cricket'
    )
);

--2

CREATE VIEW sports_clubs_from_city AS
SELECT *
FROM sports_club
WHERE city = 'City_Name';

--cursor
--1


CREATE OR REPLACE FUNCTION print_gold_sports_club_details() RETURNS VOID AS
DECLARE
    team_details team%ROWTYPE;
    player_details player%ROWTYPE;
    team_cursor CURSOR FOR
        SELECT *
        FROM team t, sports_club sc
        WHERE t.club_id = sc.club_id
        AND sc.club_name = 'Gold Sports Club';
BEGIN
    OPEN team_cursor;
    LOOP
        FETCH team_cursor INTO team_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Team Name: %, Club Name: %', team_details.team_name, team_details.club_name;

        -- Print players of the team
        FOR player_details IN SELECT *
                             FROM player
                             WHERE team_id = team_details.team_id
        LOOP
            RAISE NOTICE 'Player Name: %, Age: %', player_details.player_name, player_details.age;
        END LOOP;
    END LOOP;
    CLOSE team_cursor;
END;
LANGUAGE plpgsql;



--2
CREATE OR REPLACE FUNCTION print_players_playing_cricket_in_ipl() RETURNS VOID AS
DECLARE
    player_details player%ROWTYPE;
    player_cursor CURSOR FOR
        SELECT *
        FROM player p, player_game pg, game g, team t, sports_club sc
        WHERE p.pid = pg.pid
        AND pg.game_id = g.game_id
        AND p.team_id = t.team_id
        AND t.club_id = sc.club_id
        AND g.game_name = 'Cricket'
        AND sc.club_name = 'IPL';
BEGIN
    OPEN player_cursor;
    LOOP
        FETCH player_cursor INTO player_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Player Name: %, Team: %', player_details.player_name, player_details.team_name;
    END LOOP;
    CLOSE player_cursor;
END;
LANGUAGE plpgsql;



--12 trigger
-- 1 Trigger to check the year of establishment of a sports club before insertion:

CREATE OR REPLACE FUNCTION validate_sports_club_establishment_year() RETURNS TRIGGER AS
BEGIN
    IF NEW.year_establish > '2015' THEN
        RAISE EXCEPTION 'Year of establishment cannot be after 2015';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER sports_club_establishment_year_check
BEFORE INSERT ON sports_club
FOR EACH ROW
EXECUTE PROCEDURE validate_sports_club_establishment_year();


--2 Trigger to check the age of a player before insertion:

CREATE OR REPLACE FUNCTION validate_player_age() RETURNS TRIGGER AS
BEGIN
    IF NEW.age < 18 THEN
        RAISE EXCEPTION 'Age of player cannot be less than 18';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER player_age_check
BEFORE INSERT ON Player
FOR EACH ROW
EXECUTE PROCEDURE validate_player_age();
