CREATE DATABASE mysql_final_test;
USE mysql_final_test;

#Student Performance Management System
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    course VARCHAR(50) NOT NULL,
    marks INT
);

INSERT INTO students
(student_id, student_name, course, marks)
VALUES
(1, 'Amruta', 'BCA', 85),
(2, 'Priya', 'BSc IT', 72),
(3, 'Rahul', 'BCA', 90),
(4, 'Sneha', 'BBA', 78),
(5, 'Amit', 'BSc IT', 65);
SELECT * FROM students;
SELECT student_name, marks
FROM students
WHERE marks > 75;

SELECT course, COUNT(*) AS total_students
FROM students
GROUP BY course;

SELECT student_name, marks
FROM students
WHERE marks = (
    SELECT MAX(marks)
    FROM students
);


#Employee Salary Analysis System
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2)
);


INSERT INTO employees
(employee_id, employee_name, department, salary)
VALUES
(1, 'Amit', 'IT', 50000),
(2, 'Priya', 'HR', 30000),
(3, 'Rahul', 'IT', 45000),
(4, 'Sneha', 'HR', 40000),
(5, 'Neha', 'Finance', 60000);
SELECT * FROM employees;
SELECT department,
       AVG(salary) AS average_salary
FROM employees
GROUP BY department;
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 1;

SELECT MAX(salary) AS second_highest_salary
FROM employees
WHERE salary < (
    SELECT MAX(salary)
    FROM employees
);


#Library Late Fee Calculation Using a Stored Function
CREATE TABLE borrow_records (
    borrow_id INT PRIMARY KEY,
    student_name VARCHAR(100),
    book_title VARCHAR(100),
    due_date DATE,
    return_date DATE
);
INSERT INTO borrow_records
(borrow_id, student_name, book_title, due_date, return_date)
VALUES
(1, 'Amruta', 'Java Programming',
 '2026-10-20', '2026-10-24');
 
 SELECT * FROM borrow_records;
 
 DELIMITER $$

CREATE FUNCTION calculate_fine(
    p_due_date DATE,
    p_return_date DATE
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN

    DECLARE late_days INT;
    DECLARE fine_amount DECIMAL(10,2);

    IF p_due_date IS NULL OR p_return_date IS NULL THEN
        RETURN NULL;

    ELSEIF p_return_date > p_due_date THEN

        SET late_days = DATEDIFF(
            p_return_date,
            p_due_date
        );

        SET fine_amount = late_days * 10;

    ELSE

        SET fine_amount = 0;

    END IF;

    RETURN fine_amount;

END $$

DELIMITER ;



SELECT
    '2026-10-20' AS due_date,
    '2026-10-24' AS return_date,
    DATEDIFF('2026-10-24', '2026-10-20')
        AS late_days,
    calculate_fine(
        '2026-10-20',
        '2026-10-24'
    ) AS fine_amount;
    
    SELECT calculate_fine(
    '2026-10-20',
    '2026-10-20'
) AS fine_amount;


#Banking System Using a Stored Procedure

CREATE TABLE bank_accounts (
    account_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    balance DECIMAL(10,2)
);

INSERT INTO bank_accounts
(account_id, customer_name, balance)
VALUES
(101, 'Amruta', 5000.00),
(102, 'Priya', 8000.00);

SELECT * FROM bank_accounts;


DELIMITER $$

CREATE PROCEDURE deposit_money(
    IN p_account_id INT,
    IN p_amount DECIMAL(10,2)
)
BEGIN

    DECLARE account_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO account_count
    FROM bank_accounts
    WHERE account_id = p_account_id;

    IF p_amount IS NULL OR p_amount <= 0 THEN

        SELECT 'Invalid deposit amount.' AS message;

    ELSEIF account_count = 0 THEN

        SELECT 'Account does not exist.' AS message;

    ELSE

        UPDATE bank_accounts
        SET balance = balance + p_amount
        WHERE account_id = p_account_id;

        SELECT 'Deposit successful.' AS message;

        SELECT balance AS updated_balance
        FROM bank_accounts
        WHERE account_id = p_account_id;

    END IF;

END $$

DELIMITER ;

CALL deposit_money(101, 2000);

CALL deposit_money(999, 1000);

SELECT * FROM bank_accounts;



#Automatic Stock Management Using Triggers
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    stock_quantity INT NOT NULL,
    CHECK (stock_quantity >= 0)
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity_sold INT NOT NULL,

    FOREIGN KEY (product_id)
    REFERENCES products(product_id),

    CHECK (quantity_sold > 0)
);


INSERT INTO products
(product_id, product_name, stock_quantity)
VALUES
(1, 'Laptop', 10),
(2, 'Mobile', 20);

SELECT * FROM products;


DELIMITER $$

CREATE TRIGGER before_sale_insert
BEFORE INSERT ON sales
FOR EACH ROW
BEGIN

    DECLARE available_stock INT DEFAULT 0;
    DECLARE product_count INT DEFAULT 0;

    SELECT COUNT(*), MAX(stock_quantity)
    INTO product_count, available_stock
    FROM products
    WHERE product_id = NEW.product_id;

    IF NEW.quantity_sold IS NULL
       OR NEW.quantity_sold <= 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid sale quantity';

    ELSEIF product_count = 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product does not exist';

    ELSEIF NEW.quantity_sold > available_stock THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock';

    END IF;

END $$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER after_sale_insert
AFTER INSERT ON sales
FOR EACH ROW
BEGIN

    UPDATE products
    SET stock_quantity =
        stock_quantity - NEW.quantity_sold
    WHERE product_id = NEW.product_id;

END $$

DELIMITER ;

INSERT INTO sales
(sale_id, product_id, quantity_sold)
VALUES
(1, 1, 3);

SELECT 'Sale recorded successfully.' AS message;
SELECT product_name, stock_quantity
FROM products
WHERE product_id = 1;

INSERT INTO sales
(sale_id, product_id, quantity_sold)
VALUES
(2, 1, 15);
SELECT * FROM products;