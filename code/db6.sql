





-- Drop existing tables if they exist
DROP TABLE IF EXISTS Student_Books;
DROP TABLE IF EXISTS Teacher_Books;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Teacher;
DROP TABLE IF EXISTS Librarian;

-- Create Student table
CREATE TABLE Student (
    Roll_No INT PRIMARY KEY,
    Student_Name VARCHAR(20),
    Class VARCHAR(5),
    Division VARCHAR(10) CHECK (Division IN ('A', 'B'))
);

-- Create Book table
CREATE TABLE Book (
    Book_id VARCHAR(10) PRIMARY KEY,
    Book_Name VARCHAR(20),
    Publisher VARCHAR(20),
    Author VARCHAR(20),
    No_of_copies INT
);

-- Create Teacher table
CREATE TABLE Teacher (
    Teacher_Name VARCHAR(20) PRIMARY KEY,
    Qualification VARCHAR(10),
    Post VARCHAR(20) CHECK (Post IN ('Assistant professor', 'Associate professor', 'Professor')),
    Join_Year INT
);

-- Create Librarian table
CREATE TABLE Librarian (
    Lib_Name VARCHAR(10) PRIMARY KEY,
    Address TEXT,
    Qualification VARCHAR(10)
);

-- Create Student_Books table for the many-to-many relationship between Student and Book
CREATE TABLE Student_Books (
    Roll_No INT,
    Book_id VARCHAR(10),
    FOREIGN KEY (Roll_No) REFERENCES Student(Roll_No) ON DELETE CASCADE,
    FOREIGN KEY (Book_id) REFERENCES Book(Book_id) ON DELETE CASCADE,
    PRIMARY KEY (Roll_No, Book_id)
);

-- Create Teacher_Books table for the many-to-many relationship between Teacher and Book
CREATE TABLE Teacher_Books (
    Teacher_Name VARCHAR(20),
    Book_id VARCHAR(10),
    FOREIGN KEY (Teacher_Name) REFERENCES Teacher(Teacher_Name) ON DELETE CASCADE,
    FOREIGN KEY (Book_id) REFERENCES Book(Book_id) ON DELETE CASCADE,
    PRIMARY KEY (Teacher_Name, Book_id)
);

-- Insert dummy data into Student table
INSERT INTO Student (Roll_No, Student_Name, Class, Division)
VALUES
    (1, 'Rahul Sharma', '10', 'A'),
    (2, 'Priya Patel', '11', 'B'),
    (3, 'Amit Kumar', '9', 'A'),
    (4, 'Neha Gupta', '12', 'B'),
    (5, 'Deepak Singh', '8', 'A');

-- Insert dummy data into Book table
INSERT INTO Book (Book_id, Book_Name, Publisher, Author, No_of_copies)
VALUES
    ('B001', 'Introduction to SQL', 'ABC Publications', 'Anita Mishra', 10),
    ('B002', 'Python Programming', 'XYZ Publishers', 'Arun Kumar', 8),
    ('B003', 'Data Structures and Algorithms', 'DEF Books', 'Sneha Singh', 12),
    ('B004', 'Introduction to Machine Learning', 'GHI Publishing', 'Rajesh Patel', 7),
    ('B005', 'English Grammar', 'JKL Press', 'Nisha Gupta', 15);

-- Insert dummy data into Teacher table
INSERT INTO Teacher (Teacher_Name, Qualification, Post, Join_Year)
VALUES
    ('Dr. Rohan Sharma', 'PhD', 'Professor', 2008),
    ('Prof. Sunita Patel', 'PhD', 'Associate professor', 2012),
    ('Mrs. Priya Singh', 'MSc', 'Assistant professor', 2015),
    ('Dr. Rahul Kumar', 'PhD', 'Professor', 2005),
    ('Mr. Sanjay Gupta', 'MSc', 'Associate professor', 2010);

-- Insert dummy data into Librarian table
INSERT INTO Librarian (Lib_Name, Address, Qualification)
VALUES
    ('Mr. Amit Kumar', '123 Library St, City', 'MLS'),
    ('Ms. Nisha Sharma', '456 Librarian Ave, Town', 'MLS'),
    ('Mrs. Renu Singh', '789 Book St, Village', 'MLIS'),
    ('Mr. Rajesh Patel', '101 Library Rd, Suburb', 'MLIS'),
    ('Ms. Sneha Gupta', '222 Reading St, County', 'MLS');

-- Queries

-- 1. List all students who issued a book having the minimum number of copies
SELECT *
FROM Student
WHERE Roll_No IN (
    SELECT Roll_No
    FROM Student_Books
    WHERE Book_id IN (
        SELECT Book_id
        FROM Book
        WHERE No_of_copies = (
            SELECT MIN(No_of_copies)
            FROM Book
        )
    )
);

-- 2. Find the list of all teachers who issued XYZ publisher's book
SELECT DISTINCT Teacher_Name
FROM Teacher_Books
WHERE Book_id IN (
    SELECT Book_id
    FROM Book
    WHERE Publisher = 'XYZ Publishers'
);

-- 3. Find the total number of students from division 'A' who are using 'Mr. X' author's book
SELECT COUNT(DISTINCT Roll_No) AS Total_Students
FROM Student_Books
WHERE Book_id IN (
    SELECT Book_id
    FROM Book
    WHERE Author = 'Mr. X'
)
AND Roll_No IN (
    SELECT Roll_No
    FROM Student
    WHERE Division = 'A'
);













--8
-- Function to find the count of books issued by a teacher
DROP FUNCTION IF EXISTS count_books_issued_by_teacher;
CREATE OR REPLACE FUNCTION count_books_issued_by_teacher(teacher_name VARCHAR) RETURNS INTEGER AS
'
DECLARE
    book_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO book_count
    FROM teacher_books
    WHERE teacher_name = $1;
    
    RETURN book_count;
END;
'
LANGUAGE plpgsql;

SELECT count_books_issued_by_teacher('John Doe'); -- Example usage: Get the count of books issued by teacher 'John Doe'

-- Function to find the number of books written by a specific author and published by a specific publisher
DROP FUNCTION IF EXISTS count_books_by_author_and_publisher;
CREATE OR REPLACE FUNCTION count_books_by_author_and_publisher(author_name VARCHAR, publisher_name VARCHAR) RETURNS INTEGER AS
'
DECLARE
    book_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO book_count
    FROM book
    WHERE author = $1 AND publisher = $2;
    
    RETURN book_count;
END;
'
LANGUAGE plpgsql;

SELECT count_books_by_author_and_publisher('Jane Smith', 'ABC Publications'); -- Example usage: Get the count of books written by author 'Jane Smith' and published by 'ABC Publications'







--exception


--1

CREATE OR REPLACE FUNCTION print_teacher_details(teacher_name VARCHAR) RETURNS VOID AS '
DECLARE
    teacher_record RECORD;
BEGIN
    SELECT *
    INTO teacher_record
    FROM teacher
    WHERE teacher_name = teacher_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION ''Teacher not found: %'', teacher_name;
    ELSE
        RAISE NOTICE ''Teacher Details:'';
        RAISE NOTICE ''Name: %'', teacher_record.teacher_name;
        RAISE NOTICE ''Qualification: %'', teacher_record.qualification;
        RAISE NOTICE ''Post: %'', teacher_record.post;
        RAISE NOTICE ''Join Year: %'', teacher_record.join_year;
    END IF;
END;
' LANGUAGE plpgsql;



--2
CREATE OR REPLACE FUNCTION print_books_issued_by_student(student_name VARCHAR) RETURNS VOID AS '
DECLARE
    total_books_issued INT;
BEGIN
    SELECT COUNT(*)
    INTO total_books_issued
    FROM student_books
    WHERE roll_no = (
        SELECT roll_no
        FROM student
        WHERE student_name = student_name
    );

    IF NOT FOUND THEN
        RAISE EXCEPTION ''Student not found: %'', student_name;
    ELSE
        RAISE NOTICE ''Total Books Issued by %: %'', student_name, total_books_issued;
    END IF;
END;
' LANGUAGE plpgsql;

--view

--1

CREATE VIEW teacher_books_by_author AS
SELECT DISTINCT t.Teacher_Name, b.Book_Name, b.Author
FROM Teacher t, Teacher_Books tb, Book b, Student_Books sb
WHERE t.Teacher_Name = tb.Teacher_Name
AND tb.Book_id = b.Book_id
AND b.Author = 'Author_Name';

--2

CREATE VIEW books_with_more_than_200_copies AS
SELECT *
FROM Book
WHERE No_of_copies > 200;

--cursor


--1

CREATE OR REPLACE FUNCTION print_teachers_using_abc_books() RETURNS VOID AS
DECLARE
    teacher_details teacher%ROWTYPE;
    teacher_cursor CURSOR FOR
        SELECT t.*
        FROM teacher t, teacher_books tb, book b
        WHERE t.Teacher_Name = tb.Teacher_Name
        AND tb.Book_id = b.Book_id
        AND b.Publisher = 'ABC Publications';
BEGIN
    OPEN teacher_cursor;
    LOOP
        FETCH teacher_cursor INTO teacher_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Teacher Name: %, Address: %', teacher_details.Teacher_Name, teacher_details.Address;
    END LOOP;
    CLOSE teacher_cursor;
END;
LANGUAGE plpgsql;




--2

CREATE OR REPLACE FUNCTION print_students_in_division_a() RETURNS VOID AS
DECLARE
    student_details student%ROWTYPE;
    student_cursor CURSOR FOR
        SELECT *
        FROM student
        WHERE Division = 'A';
BEGIN
    OPEN student_cursor;
    LOOP
        FETCH student_cursor INTO student_details;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Student Name: %, Class: %, Address: %', student_details.Student_Name, student_details.Class, student_details.Address;
    END LOOP;
    CLOSE student_cursor;
END;
LANGUAGE plpgsql;



--  trigger

--1  Trigger to check the number of copies of a book before insertion:

CREATE OR REPLACE FUNCTION validate_book_copies() RETURNS TRIGGER AS
BEGIN
    IF NEW.num_of_copies <= 0 THEN
        RAISE EXCEPTION 'Number of copies of the book should be greater than 0';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER book_copies_check
BEFORE INSERT ON Books
FOR EACH ROW
EXECUTE PROCEDURE validate_book_copies();


--2  Trigger to print a message before changing the post of a teacher:

CREATE OR REPLACE FUNCTION print_teacher_post_change() RETURNS TRIGGER AS
BEGIN
    IF NEW.post = 'Associate professor' AND OLD.post = 'Assistant professor' THEN
        RAISE NOTICE 'Post is changing from Assistant professor to Associate professor';
    END IF;
    RETURN NEW;
END;
LANGUAGE plpgsql;

CREATE TRIGGER teacher_post_change_notice
BEFORE UPDATE ON Teacher
FOR EACH ROW
EXECUTE PROCEDURE print_teacher_post_change();