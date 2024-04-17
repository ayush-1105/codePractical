





-- Drop existing tables if they exist
DROP TABLE IF EXISTS m_a_p CASCADE;
DROP TABLE IF EXISTS producer CASCADE;
DROP TABLE IF EXISTS actor CASCADE;
DROP TABLE IF EXISTS movie CASCADE;

-- Create movie table
CREATE TABLE movie (
    movie_name VARCHAR(40) PRIMARY KEY,
    release_date DATE,
    movie_budget INT,
    producer_no INT,
    FOREIGN KEY (producer_no) REFERENCES producer(producer_no)
);

-- Create actor table
CREATE TABLE actor (
    actor_name VARCHAR(30) PRIMARY KEY,
    role VARCHAR(30),
    charges INT,
    address VARCHAR(40),
    contactno VARCHAR(15)
);

-- Create producer table
CREATE TABLE producer (
    producer_no INT PRIMARY KEY,
    name VARCHAR(30),
    address VARCHAR(40),
    age INT CHECK (age > 0)
);

-- Create m_a_p table (Many-to-Many relationship between movie, actor, and producer)
CREATE TABLE m_a_p (
    movie_name VARCHAR(40),
    actor_name VARCHAR(30),
    producer_no INT,
    FOREIGN KEY (movie_name) REFERENCES movie(movie_name),
    FOREIGN KEY (actor_name) REFERENCES actor(actor_name),
    FOREIGN KEY (producer_no) REFERENCES producer(producer_no),
    PRIMARY KEY (movie_name, actor_name, producer_no)
);

-- Insert dummy data into movie table
INSERT INTO movie (movie_name, release_date, movie_budget, producer_no)
VALUES
    ('Bahubali', '2015-07-10', 250000000, 1),
    ('3 Idiots', '2009-12-25', 55000000, 2),
    ('Dangal', '2016-12-23', 70000000, 3),
    ('Lagaan', '2001-06-15', 25000000, 4),
    ('Padmaavat', '2018-01-25', 190000000, 5);

-- Insert dummy data into actor table
INSERT INTO actor (actor_name, role, charges, address, contactno)
VALUES
    ('Amitabh Bachchan', 'Vijay Dinanath Chauhan', 5000000, 'Mumbai', '9876543210'),
    ('Shah Rukh Khan', 'Raj Malhotra', 4000000, 'Mumbai', '9876543211'),
    ('Aamir Khan', 'Rancho', 4500000, 'Mumbai', '9876543212'),
    ('Salman Khan', 'Sultan', 5500000, 'Mumbai', '9876543213'),
    ('Rajinikanth', 'Chitti', 6000000, 'Chennai', '9876543214');

-- Insert dummy data into producer table
INSERT INTO producer (producer_no, name, address, age)
VALUES
    (1, 'Karan Johar', 'Mumbai', 48),
    (2, 'Sajid Nadiadwala', 'Mumbai', 55),
    (3, 'Aditya Chopra', 'Mumbai', 49),
    (4, 'Sanjay Leela Bhansali', 'Mumbai', 57),
    (5, 'Rajkumar Hirani', 'Mumbai', 58);

-- Insert dummy data into m_a_p table
INSERT INTO m_a_p (movie_name, actor_name, producer_no)
VALUES
    ('Bahubali', 'Amitabh Bachchan', 1),
    ('3 Idiots', 'Aamir Khan', 2),
    ('Dangal', 'Aamir Khan', 3),
    ('Lagaan', 'Aamir Khan', 4),
    ('Padmaavat', 'Shah Rukh Khan', 5);

-- Solve the queries

-- 1. List the names of movies produced by ____ and whose actors take charges greater than _____
SELECT movie_name
FROM movie
WHERE producer_no = (SELECT producer_no FROM producer WHERE name = '____')
AND movie_name IN (
    SELECT movie_name
    FROM m_a_p
    WHERE actor_name IN (
        SELECT actor_name
        FROM actor
        WHERE charges > _____
    )
);

-- 2. Find the name(s) of actors with the highest charges.
SELECT actor_name
FROM actor
WHERE charges = (
    SELECT MAX(charges)
    FROM actor
);

-- 3. List the names of movies with minimum budget, release year along with all actors who all are acted in it.
SELECT m.movie_name, m.release_date, a.actor_name
FROM movie m, m_a_p map, actor a
WHERE m.movie_budget = (
    SELECT MIN(movie_budget)
    FROM movie
)
AND m.movie_name = map.movie_name
AND map.actor_name = a.actor_name;










--8


-- Function to find total number of movies produced by a specific producer
DROP FUNCTION IF EXISTS no_movie;
CREATE OR REPLACE FUNCTION no_movie(producer_name VARCHAR) RETURNS INTEGER AS
'
DECLARE
    total_movies_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_movies_count
    FROM movie
    WHERE producer_no = (SELECT producer_no FROM producer WHERE name = $1);
    
    RETURN total_movies_count;
END;
'
LANGUAGE plpgsql;

SELECT no_movie('Falana'); -- Example usage: Find the total number of movies produced by 'Falana' producer

-- Function to find budget of a movie released in a specific year and produced by a specific producer
DROP FUNCTION IF EXISTS bud;
CREATE OR REPLACE FUNCTION bud(release_year DATE, producer_name VARCHAR) RETURNS INTEGER AS
'
DECLARE
    movie_budget_val INTEGER;
BEGIN
    SELECT movie_budget INTO movie_budget_val
    FROM movie
    WHERE EXTRACT(YEAR FROM release_date) = EXTRACT(YEAR FROM $1)
    AND producer_no = (SELECT producer_no FROM producer WHERE name = $2);
    
    RETURN movie_budget_val;
END;
'
LANGUAGE plpgsql;

SELECT bud('2826-05-02', 'rohan'); -- Example usage: Find the budget of a movie released in '2826' and produced by 'rohan'




--exception


--1


CREATE OR REPLACE FUNCTION total_movies_by_actor(actor_name VARCHAR) RETURNS INTEGER AS '
DECLARE
    movie_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO movie_count
    FROM m_a_p
    WHERE actor_name = actor_name;
    
    IF movie_count = 0 THEN
        RAISE EXCEPTION ''Invalid actor name: %'', actor_name;
    END IF;
    
    RETURN movie_count;
END;
' LANGUAGE plpgsql;

--2

CREATE OR REPLACE FUNCTION actors_by_charges(charges INT) RETURNS SETOF actor AS '
BEGIN
    IF charges < 0 THEN
        RAISE EXCEPTION ''Invalid charges: %'', charges;
    ELSE
        RETURN QUERY
        SELECT *
        FROM actor
        WHERE charges = charges;
    END IF;
    RETURN;
END;
' LANGUAGE plpgsql;

--view


CREATE VIEW non_comedian_actors
SELECT actor_name
FROM actor
WHERE actor_name NOT IN (
    SELECT DISTINCT actor_name
    FROM m_a_p
    WHERE actor_name IN (
        SELECT DISTINCT actor_name
        FROM m_a_p
        WHERE role = 'Comedian'
    )
);



CREATE VIEW movies_by_producer AS
SELECT m.movie_name, p.name AS producer_name
FROM movie m, producer p, m_a_p map
WHERE m.movie_name = map.movie_name
AND map.producer_no = p.producer_no
AND p.name = 'Producer_Name';



-- cursor

--1
CREATE OR REPLACE FUNCTION print_actors_with_charges_greater_than(charge_threshold INTEGER) RETURNS VOID AS
DECLARE
    actor_details actor%ROWTYPE;
    actor_cursor CURSOR FOR
        SELECT *
        FROM actor
        WHERE charge > charge_threshold;
BEGIN
    OPEN actor_cursor;
    LOOP
        FETCH actor_cursor INTO actor_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Actor Name: %, Charge: %', actor_details.actor_name, actor_details.charge;
    END LOOP;
    CLOSE actor_cursor;
END;
LANGUAGE plpgsql;




--2

CREATE OR REPLACE FUNCTION print_actors_in_1995_movies() RETURNS VOID AS
DECLARE
    actor_details actor%ROWTYPE;
    actor_cursor CURSOR FOR
        SELECT DISTINCT a.*
        FROM actor a, movie m, movie_cast mc
        WHERE a.actor_id = mc.actor_id AND m.movie_id = mc.movie_id AND m.release_year = 1995;
BEGIN
    OPEN actor_cursor;
    LOOP
        FETCH actor_cursor INTO actor_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Actor Name: %', actor_details.actor_name;
    END LOOP;
    CLOSE actor_cursor;
END;
LANGUAGE plpgsql;


-- trig
--1  

CREATE OR REPLACE FUNCTION validate_movie_release_year() RETURNS TRIGGER AS
BEGIN
    IF NEW.release_year < 1975 THEN
        RAISE EXCEPTION 'Release year should not be less than 1975';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER movie_release_year_check
BEFORE INSERT ON Movie
FOR EACH ROW
EXECUTE PROCEDURE validate_movie_release_year();



--2
CREATE OR REPLACE FUNCTION validate_actor_charges() RETURNS TRIGGER AS
BEGIN
    IF NEW.charges <= 0 THEN
        RAISE EXCEPTION 'Charges should not be zero or negative';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER actor_charges_check
BEFORE INSERT ON Actor
FOR EACH ROW
EXECUTE PROCEDURE validate_actor_charges();
