




-- Drop existing tables if they exist
DROP TABLE IF EXISTS expense;
DROP TABLE IF EXISTS trip;
DROP TABLE IF EXISTS salesman;
DROP TABLE IF EXISTS dept;

-- Create dept table
CREATE TABLE dept (
    deptno VARCHAR(10) PRIMARY KEY,
    dept_name VARCHAR(20)
);

-- Create salesman table
CREATE TABLE salesman (
    sne INT PRIMARY KEY,
    s_name VARCHAR(30),
    join_year INT,
    deptno VARCHAR(10) REFERENCES dept(deptno) ON UPDATE CASCADE,
    salary INT
);

-- Create trip table
CREATE TABLE trip (
    tne INT PRIMARY KEY,
    from_city VARCHAR(20),
    to_city VARCHAR(20),
    departure_date DATE,
    return_date DATE,
    salesman_id INT REFERENCES salesman(sne) ON UPDATE CASCADE
);

-- Create expense table
CREATE TABLE expense (
    eid INT PRIMARY KEY,
    amount INT,
    trip_id INT REFERENCES trip(tne) ON UPDATE CASCADE
);

-- Insert dummy data into dept table
INSERT INTO dept (deptno, dept_name)
VALUES
    ('D001', 'Sales'),
    ('D002', 'Marketing'),
    ('D003', 'Finance'),
    ('D004', 'Human Resources'),
    ('D005', 'Operations');

-- Insert dummy data into salesman table
INSERT INTO salesman (sne, s_name, join_year, deptno, salary)
VALUES
    (1, 'John Doe', 2018, 'D001', 50000),
    (2, 'Jane Smith', 2019, 'D002', 55000),
    (3, 'Michael Johnson', 2020, 'D001', 60000),
    (4, 'Emily Brown', 2017, 'D003', 48000),
    (5, 'David Lee', 2018, 'D002', 52000);

-- Insert dummy data into trip table
INSERT INTO trip (tne, from_city, to_city, departure_date, return_date, salesman_id)
VALUES
    (1, 'New York', 'Los Angeles', '2024-04-01', '2024-04-05', 1),
    (2, 'Chicago', 'San Francisco', '2024-04-10', '2024-04-15', 2),
    (3, 'Boston', 'Seattle', '2024-04-05', '2024-04-10', 3),
    (4, 'Houston', 'Miami', '2024-04-03', '2024-04-08', 4),
    (5, 'Denver', 'Las Vegas', '2024-04-12', '2024-04-17', 5);

-- Insert dummy data into expense table
INSERT INTO expense (eid, amount, trip_id)
VALUES
    (1, 1000, 1),
    (2, 1200, 2),
    (3, 800, 3),
    (4, 1500, 4),
    (5, 1100, 5);

-- Queries

-- 1. List the names of departments that have salesmen who have joined after a certain year
SELECT dept_name
FROM dept
WHERE deptno IN (
    SELECT deptno
    FROM salesman
    WHERE join_year > 2018 -- Example: Replace 2018 with the specific year you want to filter by
);

-- 2. Delete all the trip expenses having maximum expense and traveling to a specific city
DELETE FROM expense
WHERE trip_id IN (
    SELECT t.tne
    FROM trip t
    WHERE amount = (
        SELECT MAX(amount)
        FROM expense
    )
    AND to_city = 'Las Vegas' -- Example: Replace 'Las Vegas' with the specific city you want to filter by
);

-- 3. Find the department which is having the most junior salesman
SELECT dept_name
FROM (
    SELECT d.dept_name, s.join_year
    FROM dept d, salesman s
    WHERE d.deptno = s.deptno
    ORDER BY s.join_year ASC
)
WHERE ROWNUM = 1;












--8

-- Function to find salesman with minimum salary
DROP FUNCTION IF EXISTS min_sala();
CREATE OR REPLACE FUNCTION min_sala() RETURNS VARCHAR AS
'
DECLARE
    namet salesman.s_names%TYPE;
    namer salesman%ROWTYPE;
BEGIN
    SELECT INTO namer * FROM salesman WHERE salary = (SELECT MIN(salary) FROM salesman);
    SELECT INTO namet name FROM salesman WHERE salary = (SELECT MIN(salary) FROM salesman);
    RETURN namer; -- you can also return namet
END;
'
LANGUAGE plpgsql;

SELECT min_sala();

-- Function to find count of business trips returning on a specific date
DROP FUNCTION IF EXISTS count_trip;
CREATE OR REPLACE FUNCTION count_trip(return_date DATE) RETURNS INTEGER AS
'
DECLARE
    t_c trip%TYPE;
    tic INTEGER;
BEGIN
    SELECT COUNT(tno) INTO tic FROM trip WHERE return_date = $1;
    RETURN tic;
END;
'
LANGUAGE plpgsql;

SELECT count_trip('2023-07-25');


--exception



--1

CREATE OR REPLACE FUNCTION total_trips_from_city(city_name VARCHAR) RETURNS INTEGER AS '
DECLARE
    trip_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO trip_count
    FROM trip
    WHERE from_city = city_name;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION ''No trips found for the city: %'', city_name;
    END IF;
    
    RETURN trip_count;
END;
' LANGUAGE plpgsql;

--2
CREATE OR REPLACE FUNCTION max_salary_salesman_in_department(department_name VARCHAR) RETURNS VOID AS '
DECLARE
    salesman_name VARCHAR;
    dept_id VARCHAR;
BEGIN
    SELECT deptno INTO dept_id
    FROM dept
    WHERE dept_name = department_name;
    
    IF dept_id IS NULL THEN
        RAISE NOTICE ''No department found: %'', department_name;
    ELSE
        SELECT s_name INTO salesman_name
        FROM salesman
        WHERE deptno = dept_id
        ORDER BY salary DESC
        LIMIT 1;
        
        IF NOT FOUND THEN
            RAISE NOTICE ''No salesman found in the department: %'', department_name;
        ELSE
            RAISE NOTICE ''Salesman with maximum salary in % department: %'', department_name, salesman_name;
        END IF;
    END IF;
END;
' LANGUAGE plpgsql;



--view


CREATE VIEW salesmen_joined_on_date AS
SELECT *
FROM salesman, trip
WHERE salesman.salesman_id = trip.salesman_id
AND trip.join_date = :specific_date;




CREATE VIEW trips_arranged_by_salesman AS
SELECT *
FROM trip
WHERE salesman_id IN (
    SELECT salesman_id
    FROM salesman
    WHERE s_name = salesman_name
);


--cursor
--1 

CREATE OR REPLACE FUNCTION print_salesmen_in_department(dept_name VARCHAR) RETURNS VOID AS
DECLARE
    salesman_rec Salesmen%ROWTYPE;
    salesman_cur CURSOR FOR
        SELECT *
        FROM Salesmen
        WHERE department = dept_name;
BEGIN
    OPEN salesman_cur;
    LOOP
        FETCH salesman_cur INTO salesman_rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Salesman ID: %, Name: %, Department: %, Salary: %',
            salesman_rec.sid, salesman_rec.s_name, 
            salesman_rec.department, salesman_rec.salary;
    END LOOP;
    CLOSE salesman_cur;
END;
LANGUAGE plpgsql;



--2

CREATE OR REPLACE FUNCTION print_trip_expenses_from_city(city_name VARCHAR) RETURNS VOID AS
DECLARE
    trip_rec Trip%ROWTYPE;
    trip_cur CURSOR FOR
        SELECT *
        FROM Trip
        WHERE from_city = city_name;
BEGIN
    OPEN trip_cur;
    LOOP
        FETCH trip_cur INTO trip_rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Trip ID: %, From City: %, To City: %, Expense: %',
            trip_rec.tid, trip_rec.from_city, 
            trip_rec.to_city, trip_rec.expense;
    END LOOP;
    CLOSE trip_cur;
END;
LANGUAGE plpgsql;



-- trigger

--1

CREATE OR REPLACE FUNCTION validate_trip_return_date() RETURNS TRIGGER AS
DECLARE
BEGIN
    IF NEW.return_date < NEW.start_date THEN
        RAISE EXCEPTION 'Return date cannot be less than start date';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER trip_return_date_check
BEFORE INSERT ON trip
FOR EACH ROW
EXECUTE PROCEDURE validate_trip_return_date();



-- 2

CREATE OR REPLACE FUNCTION validate_salesman_salary() RETURNS TRIGGER AS
DECLARE
BEGIN
    IF NEW.salary <= 0 THEN
        RAISE EXCEPTION 'Salary should not be zero or negative';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER validate_salesman_salary_trigger
BEFORE INSERT ON Salesman
FOR EACH ROW
EXECUTE PROCEDURE validate_salesman_salary();
