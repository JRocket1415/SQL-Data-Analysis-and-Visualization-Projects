/******** 1) GROUP BY  **********/
/*
	When we group by, we apply the function PER GROUP,	NOT on the ENTIRE DATA SET.
	Group by use Split, Apply, Combine strategry.
*/

/* How many employees worked in each department ? */
SELECT d.dept_name AS "Department Name" ,COUNT(e.emp_no) AS "Number Of Employee"
FROM employees e
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON d.dept_no = de.dept_no
GROUP BY d.dept_no
ORDER BY 1;

/*------------------------------------------------------------------------------------------------------------*/

/************ 2) HAVING Keyword *************/
/*
	"Having" applies filters to a group as a whole
	
	**** Order of Operations ****
		FROM
		WHERE
		GROUP BY
		HAVING
		SELECT
		ORDER
*/

/* How many employees worked in each department, but with employees more than 25000 ? */
SELECT d.dept_name AS "Department Name" ,COUNT(e.emp_no) AS "Number Of Employee"
FROM employees e
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON d.dept_no = de.dept_no
GROUP BY d.dept_name
HAVING COUNT(e.emp_no) > 25000
ORDER BY 1;

/* How many Female employees worked in each department, but with employees more than 25000 ? */
SELECT d.dept_name AS "Department Name" ,COUNT(e.emp_no) AS "Number Of Employee"
FROM employees e
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON d.dept_no = de.dept_no
WHERE e.gender='F'
GROUP BY d.dept_name
HAVING COUNT(e.emp_no) > 25000
ORDER BY 1;

/*------------------------------------------------------------------------------------------------------------*/

/********** 3) Ordering Group Data **********/
SELECT d.dept_name AS "Department Name" ,COUNT(e.emp_no) AS "Number Of Employee"
FROM employees e
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON d.dept_no = de.dept_no
GROUP BY d.dept_name
HAVING COUNT(e.emp_no) > 25000
ORDER BY 2 DESC;


/********* 4) GROUP BY Mental Model ***********/

/* What are the 8 employees who got the most salary bumps? */
-- SELECT e.emp_no, CONCAT(e.first_name, e.last_name) AS "Name", s.salary, s.from_date, s.to_date
SELECT emp_no, MAX(from_date)
FROM salaries
GROUP BY emp_no;


/*------------------------------------------------------------------------------------------------------------*/

/*********** 5) GROUPING SETS**********/

/******* UNION / UNION ALL *********/
/*
	SELECT col1, SUM(col2)
	FROM table
	GROUP BY col1
	
	UNION / UNION ALL
	
	SELECT SUM(col2)
	FROM table
	
	
 	UNION ALL doesn't remove DUPLICATE Records.
*/
SELECT NULL AS "prod_id", sum(ol.quantity)
FROM orderlines AS ol

UNION

SELECT prod_id AS "prod_id", sum(ol.quantity)
FROM orderlines AS ol
GROUP BY prod_id
ORDER BY prod_id DESC;

/*------------------------------------------------------------------------------------------------------------*/

/*********** GROUPING SETS ***********/
/* 
	A Subclause of GROUP BY that allows you to define multiple grouping
	It is very useful when we want to combine multiple grouping 
*/

-- same result as using above UNION code, but in same query
-- here we are combining Two Sets (one for getting Total, one for per each product)
SELECT prod_id, sum(ol.quantity)
FROM orderlines AS ol
GROUP BY
	GROUPING SETS(
		(),
		(prod_id)
	)
ORDER BY prod_id DESC;


/* we can add in multiple groups as we need */
SELECT prod_id, orderlineid, sum(ol.quantity)
FROM orderlines AS ol
GROUP BY
	GROUPING SETS(
		(),
		(prod_id),
		(orderlineid)
	)
ORDER BY prod_id DESC, orderlineid DESC;

/*------------------------------------------------------------------------------------------------------------*/

/************ GROUPING SETS for info from High Level to Details Level ***********/

SELECT
	EXTRACT(YEAR FROM orderdate) AS "YEAR",
	EXTRACT(MONTH FROM orderdate) AS "MONTH",
	EXTRACT(DAY FROM orderdate) AS "DAY",
	SUM(quantity)AS "TOTAL QUANTITY"
FROM orderlines
GROUP BY 
	GROUPING SETS(
		(EXTRACT(YEAR FROM orderdate)), 		-- yearly
		(EXTRACT(MONTH FROM orderdate)), 		-- monthly
		(EXTRACT(DAY FROM orderdate)),			-- daily
		(
			EXTRACT(YEAR FROM orderdate),		-- month and year
			EXTRACT(MONTH FROM orderdate)
		),
		(
			EXTRACT(MONTH FROM orderdate),		-- month and day
			EXTRACT(DAY FROM orderdate)
		),
		(
			EXTRACT(YEAR FROM orderdate),		-- year, month and day
			EXTRACT(MONTH FROM orderdate),
			EXTRACT(DAY FROM orderdate)
		),
		()										-- nothing in particular (TOTAL AMOUNT)
	)
ORDER BY 1,2,3;

/*------------------------------------------------------------------------------------------------------------*/

/************			6) ROLLUP			***************/

/* roll up can provide a very similar result as above using grouping sets, but with less code */
SELECT
	EXTRACT(YEAR FROM orderdate) AS "YEAR",
	EXTRACT(MONTH FROM orderdate) AS "MONTH",
	EXTRACT(DAY FROM orderdate) AS "DAY",
	SUM(quantity)AS "TOTAL QUANTITY"
FROM orderlines
GROUP BY 
	ROLLUP(
		EXTRACT(YEAR FROM orderdate),
		EXTRACT(MONTH FROM orderdate),
		EXTRACT(DAY FROM orderdate)
	)
ORDER BY 1,2,3;

/*------------------------------------------------------------------------------------------------------------*/

/******************** 8/9) WINDOW Functions ******************/
/*
	Window functions CREATE a NEW COLUMN based on functions performed on a SUBSET or "WINDOW" of the data.
	
	window_function(agr1, agr2) OVER(
		[PARTITION BY partition_expression]
		[ORDER BY sort_expression [ASC | DESC] [NULLS {FIRST | LAST}]]
	)
*/

-- Here we can see in the result that max salary is 158,220. Because query returns all data, then LIMIT say cut it off for 100 rows only. 
-- That's why OVER() is calculated on the window or subset of data (in this case the entire data were returned).
SELECT *,
	MAX(salary) OVER()
FROM salaries
LIMIT 100;

-- in this case, the maximum salary is 69,999. Because of WHERE conditions, the data were filtered out.
-- and OVER() is using on that subset or window of the returned data (in this case the results of WHERE filtered data).
SELECT 
	*,
	MAX(salary) OVER() 
FROM salaries
WHERE salary < 70000
ORDER BY salary DESC;


/******************** 10) PARTITON BY ******************/
/*
	Divide Rows into Groups to apply the function against (Optional)
*/

/* Employee salary compairing average salary of departments */
SELECT 
	s.emp_no, s.salary,d.dept_name,
	AVG(s.salary)
	OVER(
		PARTITION BY(d.dept_name)
	)
FROM salaries s
JOIN dept_emp de ON s.emp_no = de.emp_no
JOIN departments d ON d.dept_no = de.dept_no;


/******************** 11) ORDER BY ******************/
/*
	ORDER BY changes the FRAME of the window
	It tells SQL to take into account of everything before up until to this point (becoming Cumulative)
*/
-- against the window of entire data
SELECT emp_no,
	COUNT(salary) OVER()
FROM salaries;

-- using PARTION BY
-- Counting salary by each unique emp_no partion
SELECT emp_no,
	COUNT(salary) OVER(
		PARTITION BY(emp_no)
	)
FROM salaries;


-- using ORDER BY
-- Count number are becoming Cumulative
SELECT emp_no,
	COUNT(salary) OVER(
		ORDER BY emp_no
	)
FROM salaries;


/********************************* FRAME Clause *******************************************************/
/*
	When using Frame clause in a window function, we can create a SUB-RANGE or FRAME
	
	For example: when we use ORDER BY, we look at the PARTATIONED data in a different len (FRAME).
	
	NOTE: 
	Without ORDER BY, by default the framing is usually ALL PARTITION ROWs (Entire Window)
	With ORDER BY, by default the framing is usually everything before the CURRENT ROW AND the CURRENT ROW (Cumulatively)
	
	|----------------------------------------------------------------------------------------------------
	|			Keys						| 			Meaning 										|
	|---------------------------------------|-----------------------------------------------------------|
	|	ROWS or RANGE						|	Whether you want to use a RANGE or ROWS as a FRAME		|
	|	PRECEDING							|	Rows Before the CURRENT ONE								|
	|	FOLLOWING							|	Rows After the CURRENT ONE								|
	| 	UNBOUNDED PRECEDING or FOLLOWING	|	Returns All Before and After							|
	|	CURRENT ROW							|	Your Current Row										|
	-----------------------------------------------------------------------------------------------------
*/

-- In this case, we can see that every salary is unique. Because we are using ORDER BY, each row is cumulativly
-- counted within the partition of each employee's window. As a result, it like like 1, (1+1 becomes 2), etc.
SELECT emp_no,
	salary,
	COUNT(salary) OVER(
		PARTITION BY emp_no
		ORDER BY salary
	)
FROM Salaries;


-- This one returns the same results as using PARTION BY only. The reason is we are looking at the data through the lends of Range.
-- For range using unbounded precedning and following, we are comparing against data with the entire data within that Partition.
SELECT emp_no,
	salary,
	COUNT(salary) OVER(
		PARTITION BY emp_no
		ORDER BY salary
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	)
FROM Salaries;

-- same reults as RANGE results
SELECT emp_no,
	salary,
	COUNT(salary) OVER(
		PARTITION BY emp_no
		ORDER BY salary
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	)
FROM Salaries;


-- same like ORDER BY
SELECT emp_no,
	salary,
	COUNT(salary) OVER(
		PARTITION BY emp_no
		ORDER BY salary
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	)
FROM Salaries;

/*------------------------------------------------------------------------------------------------------------*/

/************* 13) Solving for Current Salary ***********/
-- using GROUP BY isn't a good way to solve this problem because we need to pass in a lot of condition in GROUP BY clause.
SELECT emp_no, salary, to_date
FROM salaries
GROUP BY emp_no, salary, to_date
ORDER BY to_date DESC
LIMIT 10;

-- using window function for this problem
-- within frame, we compare the salary with salary of following and preceding one along the way.
-- LAST VALUE returns that very last value that won the salary comparing competition.
-- We order by from date Ascending order, so we knew ahead that the current salary should be the one on the most bottom.
SELECT 
	DISTINCT e.emp_no, e.first_name, d.dept_name,
	LAST_VALUE(s.salary) OVER(
		PARTITION BY e.emp_no
		ORDER BY s.from_date
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS "Current Salary"
FROM salaries s
JOIN employees e USING(emp_no)
JOIN dept_emp de USING (emp_no)
JOIN departments d USING (dept_no)
ORDER BY emp_no;

-- checking out the unique salary for each employees
SELECT emp_no, salary, from_date, to_date,
	COUNT(salary) OVER(
		PARTITION BY emp_no
		ORDER BY to_date
	)
FROM salaries;

/*-------------------------------------------------------------------------------------------------------------*/


/************************************	 WINDOW FUNCTIONS 	****************************************************/
/*
	---------------------------------------------------------------------------------------------------------------------
	|	Function				|		Purpose																			|
	----------------------------|---------------------------------------------------------------------------------------|
	|	SUM / MIN / MAX / AVG	|	Get the sum, min, .. of all the records in the partition							|
	|	FIRST_VALUE				|	Return the value evaluated against the first row within the partition.				|
	|	LAST_VALUE				|	Return the value evaluated against the last row within the partition.				|
	|	NTH_VALUE				| 	Return the value evaluated against the nth row in ordered partition.				|
	| 	PERCENT_RANK			|	Return the relative rank of the current row (rank-1) / (total rows - 1)				|
	|	RANK					|	Rank the current row within its partition with gaps.								|
	|	ROW_NUMBER				|	Number the current row within its partition starting from 1. (regardelss of framing)|
	|	LAG / LEAD				|	Access the values from the previous or next row.									|
	--------------------------------------------------------------------------------------------------------------------
*/

/************* 14) FIRST_VALUE ***********/

/* I want to know how my price compares to the item with the LOWEST price in the SAME category */
SELECT 
	prod_id, price, category,
	FIRST_VALUE(price) OVER(
		PARTITION BY category
		ORDER BY price
	) AS "Cheapest in the category"
FROM products
ORDER BY category, prod_id;

-- getting the same result using MIN which is easier, not needing ORDER BY too.
SELECT 
	prod_id, price, category,
	MIN(price) OVER(
		PARTITION BY category
	) AS "Cheapest in the category"
FROM products
ORDER BY category, prod_id;


/************* 15) LAST VALUE ****************/

/* I want to know how my price to the item with the HIGHEST PRICE in the SAME category */
SELECT 
	prod_id, price, category,
	LAST_VALUE(price) OVER(
		PARTITION BY category
		ORDER BY price
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS "Most Expensive Price in Category"
FROM products
ORDER BY category, prod_id;

-- using MAX
SELECT 
	prod_id, price, category,
	MAX(price) OVER(
		PARTITION BY category
	) AS "Highest Price in Category"
FROM products
ORDER BY category, prod_id;


/****************** 16) SUM ************************/

/* I want to see how much Cumulatively a customer has ordered at our store */
SELECT 
	customerid, orderid, orderdate, netamount,
	SUM(netamount) OVER(
		PARTITION BY customerid
		ORDER BY orderid
	) AS "Cumulative Spending"
FROM orders
ORDER BY customerid, orderid;


/**************** 17) ROW_NUMBER ****************/
-- ROW_NUMBER ignores the framing
-- no need to put parameters in ROW_NUMBER() function

/* I want to know where my product is positioned in the category by price */
SELECT 
	category, prod_id, price,
	ROW_NUMBER() OVER(
		PARTITION BY category
		ORDER BY price
	) AS "Position in category by price"
FROM products
ORDER BY category

/*------------------------------------------------------------------------------------------------------------*/

/********************* 19) Conditional Statements ***********************/

/********** CASE ************/
/*
	SELECT a,
		CASE
			WHEN a=1 THEN 'one'
			WHEN a=2 THEN 'two'
			ELSE 'other'
		END
	FROM test;
*/

-- 1) CASE statement can be used anywhere
SELECT 
	orderid, customerid,
	CASE
		WHEN customerid=1 THEN 'my first customer'
		ELSE 'not my first customer'
	END AS "customer status",
	netamount
FROM orders
ORDER BY customerid;

-- 2) using CASE in combination with WHERE
SELECT
	orderid, customerid, netamount
FROM orders
WHERE
	CASE
		WHEN customerid > 10 THEN netamount < 100
		ELSE netamount > 100
	END
ORDER BY customerid;


-- 3) using CASE statement with Aggregate function

/* doing gesture of good faith, refunding 100$ for that order where spending is less than 100$ */
SELECT
	SUM(
		CASE
			WHEN netamount < 100 THEN -100
			ELSE netamount
		END
	) AS "Returns",
	SUM(netamount) AS "Normal Total",
FROM orders;

/* ----------------------------------------------------------------------------------------------------------- */

/******************* 20) NULL IF *******************/
/*
	Use NULLIF to fill in empty spots with a NULL value to avoid divide by zero issues
	
	NULLIF(val1, val2)
	
	if value 1 is equal to value 2, return NULL
*/

SELECT NULLIF(0, 0); -- returns null

SELECT NULLIF('ABC', 'DEF'); -- returns ABC


/* ----------------------------------------------------------------------------------------------------------- */


/******************** 21) VIEWS *********************/
/*
	Views allow you to store the results and query of previously run queries.
	
	There are 2 types of views: 1) Materialized and 2) Non-Materialized Views.
	
	1) Materialzed View - stores the data PHYSICIALLY AND PERIODICALLY UPDATES it when tables change.
	2) Non-Materialized View - Query gets RE-RUN each time the view is called on.
	
*/

/*************** 	22) VIEW syntax **************/
/*
	+ views are OUTPUT of query we ran.
	+ views act like TABLES you can query them.
	+ (Non-Materialized View): views tak VERY LITTLE SPACE to store. We only store the definition of the view, NOT ALL the data that it returns.	
*/

-- Create a view
CREATE VIEW view_name 
AS query;

-- Update a view
CREATE OR REPLACE view_name
AS query;

-- Rename a view
ALTER VIEW exisitng_view_name RENAME TO new_view_name;

-- Delete a view
DROP VIEW IF EXISTS view_name;

/*************** 23) Using VIEWS ******************/

-- get the last salary change of each employee
CREATE VIEW last_salary_change AS
	SELECT e.emp_no,
		MAX(s.from_date)
	FROM salaries s
	JOIN employees e USING(emp_no)
	JOIN dept_emp de USING(emp_no)
	JOIN departments d USING(dept_no)
	GROUP BY e.emp_no
	ORDER BY e.emp_no;

-- query entire data from that view
SELECT * FROM last_salary_change;

-- combine with view to get the latest salary of each employee
SELECT 
	s.emp_no, d.dept_name, s.from_date, s.salary
FROM last_salary_change lsc
JOIN salaries s USING(emp_no)
JOIN dept_emp de USING(emp_no)
JOIN departments d USING(dept_no)
WHERE s.from_date = lsc.max
ORDER BY s.emp_no;

