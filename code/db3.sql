




-- Drop existing tables if they exist
DROP TABLE IF EXISTS loan_application CASCADE;
DROP TABLE IF EXISTS account CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS branch CASCADE;

-- Create branch table
CREATE TABLE branch (
    bid INT PRIMARY KEY,
    brname VARCHAR(30),
    brcity VARCHAR(30)
);

-- Create customer table
CREATE TABLE customer (
    cno INT PRIMARY KEY,
    cname VARCHAR(30),
    caddr VARCHAR(48),
    city VARCHAR(48),
    nationality VARCHAR(30),
    age INT CHECK (age > 0),
    bid INT,
    FOREIGN KEY (bid) REFERENCES branch(bid) ON UPDATE CASCADE
);

-- Create account table
CREATE TABLE account (
    acc_no INT PRIMARY KEY,
    acc_type VARCHAR(30),
    acc_balance INT,
    cno INT,
    bid INT,
    FOREIGN KEY (cno) REFERENCES customer(cno) ON UPDATE CASCADE,
    FOREIGN KEY (bid) REFERENCES branch(bid) ON UPDATE CASCADE
);

-- Create loan_application table
CREATE TABLE loan_application (
    Lno INT PRIMARY KEY,
    lamtrequired INT,
    lamtapproved INT,
    l_date DATE,
    cno INT,
    bid INT,
    FOREIGN KEY (cno) REFERENCES customer(cno) ON UPDATE CASCADE,
    FOREIGN KEY (bid) REFERENCES branch(bid) ON UPDATE CASCADE
);

-- Insert dummy data into branch table
INSERT INTO branch (bid, brname, brcity)
VALUES
    (1, 'Main Branch', 'Mumbai'),
    (2, 'Downtown Branch', 'Delhi'),
    (3, 'Uptown Branch', 'Bangalore'),
    (4, 'Westside Branch', 'Chennai'),
    (5, 'Eastside Branch', 'Kolkata');

-- Insert dummy data into customer table
INSERT INTO customer (cno, cname, caddr, city, nationality, age, bid)
VALUES
    (1, 'Rahul Sharma', '123 Main St', 'Mumbai', 'Indian', 35, 1),
    (2, 'Priya Patel', '456 Elm St', 'Delhi', 'Indian', 28, 2),
    (3, 'Amit Kumar', '789 Oak St', 'Bangalore', 'Indian', 40, 3),
    (4, 'Neha Gupta', '101 Pine St', 'Chennai', 'Indian', 65, 4),
    (5, 'Deepak Singh', '222 Maple St', 'Kolkata', 'Indian', 55, 5);

-- Insert dummy data into account table
INSERT INTO account (acc_no, acc_type, acc_balance, cno, bid)
VALUES
    (101, 'Savings', 5000, 1, 1),
    (102, 'Checking', 3000, 2, 2),
    (103, 'Savings', 7000, 3, 3),
    (104, 'Checking', 4500, 4, 4),
    (105, 'Savings', 6000, 5, 5);

-- Insert dummy data into loan_application table
INSERT INTO loan_application (Lno, lamtrequired, lamtapproved, l_date, cno, bid)
VALUES
    (201, 10000, 8000, '2024-04-10', 1, 1),
    (202, 15000, 12000, '2024-04-12', 2, 2),
    (203, 20000, 18000, '2024-04-15', 3, 3),
    (204, 12000, 10000, '2024-04-18', 4, 4),
    (205, 18000, 15000, '2024-04-20', 5, 5);

-- Queries

-- 1. List the names of customers who have received a loan which is exactly equal to their requirement
SELECT cname
FROM customer
WHERE cno IN (
    SELECT cno
    FROM loan_application
    WHERE lamtapproved = lamtrequired
);

-- 2. Find the details of all accounts of all senior citizens (more than 60 years of age)
SELECT *
FROM account
WHERE cno IN (
    SELECT cno
    FROM customer
    WHERE age > 60
);

-- 3. List the accounts of a specific branch and specific account type
SELECT *
FROM account
WHERE bid = (
    SELECT bid
    FROM branch
    WHERE brname = 'Main Branch'
)
AND acc_type = 'Savings';












--8


-- Function to return the loan approved for a particular customer
DROP FUNCTION IF EXISTS loan_approved_for_customer;
CREATE OR REPLACE FUNCTION loan_approved_for_customer(customer_name VARCHAR) RETURNS INTEGER AS
'
DECLARE
    approved_loan_amount INTEGER;
BEGIN
    SELECT lamtapproved INTO approved_loan_amount
    FROM loan_application
    WHERE cno = (SELECT cno FROM customer WHERE cname = $1);
    
    RETURN approved_loan_amount;
END;
'
LANGUAGE plpgsql;

SELECT loan_approved_for_customer('John Doe'); -- Example usage: Get the loan approved for customer 'John Doe'

-- Function to find the average loan amount required
DROP FUNCTION IF EXISTS average_loan_amount_required;
CREATE OR REPLACE FUNCTION average_loan_amount_required() RETURNS INTEGER AS
'
DECLARE
    avg_loan_amount INTEGER;
BEGIN
    SELECT AVG(lamtrequired) INTO avg_loan_amount
    FROM loan_application;
    
    RETURN avg_loan_amount;
END;
'
LANGUAGE plpgsql;

SELECT average_loan_amount_required(); -- Example usage: Get the average loan amount required





--exception



--1


CREATE OR REPLACE FUNCTION validate_loan_amount(loan_amt_required INT) RETURNS VOID AS '
BEGIN
    IF loan_amt_required < 500000 THEN
        RAISE EXCEPTION ''Invalid loan amount: Loan amount must be at least 500,000'';
    END IF;
END;
' LANGUAGE plpgsql;

--2


CREATE OR REPLACE FUNCTION loan_amount_approved_for_customer(customer_name VARCHAR) RETURNS VOID AS '
DECLARE
    loan_amt INT;
BEGIN
    SELECT lamtapproved INTO loan_amt
    FROM loan_application
    WHERE cno = (
        SELECT cno
        FROM customer
        WHERE cname = customer_name
    );
    
    IF NOT FOUND THEN
        RAISE exception ''Customer not found: %'', customer_name;
    ELSE
        RAISE NOTICE ''Loan amount approved for %: %'', customer_name, loan_amt;
    END IF;
END;
' LANGUAGE plpgsql;

--cursor

--1

CREATE OR REPLACE FUNCTION print_customers_with_loan_details() RETURNS VOID AS
DECLARE
    customer_details customer%ROWTYPE;
    customer_cursor CURSOR FOR
        SELECT DISTINCT c.*
        FROM customer c, loan_application l
        WHERE c.cno = l.cno;
BEGIN
    OPEN customer_cursor;
    LOOP
        FETCH customer_cursor INTO customer_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Customer Name: %, Loan Required Amount: %', customer_details.cname, customer_details.lamtrequired;
    END LOOP;
    CLOSE customer_cursor;
END;
LANGUAGE plpgsql;



--2

CREATE OR REPLACE FUNCTION print_indian_customers() RETURNS VOID AS
DECLARE
    customer_details customer%ROWTYPE;
    customer_cursor CURSOR FOR
        SELECT *
        FROM customer
        WHERE nationality = 'Indian';
BEGIN
    OPEN customer_cursor;
    LOOP
        FETCH customer_cursor INTO customer_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Customer Name: %, Nationality: %', customer_details.cname, customer_details.nationality;
    END LOOP;
    CLOSE customer_cursor;
END;
LANGUAGE plpgsql;



-- trigger

--1   Trigger to validate loan approved amount:

CREATE OR REPLACE FUNCTION validate_loan_approved_amount() RETURNS TRIGGER AS
BEGIN
    IF NEW.loan_approved_amount < 500000 THEN
        RAISE EXCEPTION 'Loan approved amount should not be less than Rs. 500,000';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER loan_approved_amount_check
BEFORE INSERT ON loan
FOR EACH ROW
EXECUTE PROCEDURE validate_loan_approved_amount();
-- 2  Trigger to validate customer nationality:

CREATE OR REPLACE FUNCTION validate_customer_nationality() RETURNS TRIGGER AS
BEGIN
    IF NEW.nationality <> 'Indian' THEN
        RAISE EXCEPTION 'Customer should have nationality as Indian';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER customer_nationality_check
BEFORE INSERT OR UPDATE ON customer
FOR EACH ROW
EXECUTE PROCEDURE validate_customer_nationality();