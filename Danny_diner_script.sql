-- Make Tables
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
);
INSERT INTO sales VALUES ('A', '2021-01-01', '1');
INSERT INTO sales VALUES ('A', '2021-01-01', '2');
INSERT INTO sales VALUES ('A', '2021-01-07', '2');
INSERT INTO sales VALUES ('A', '2021-01-10', '3');
INSERT INTO sales VALUES ('A', '2021-01-11', '3');
INSERT INTO sales VALUES ('A', '2021-01-11', '3');
INSERT INTO sales VALUES ('B', '2021-01-01', '2');
INSERT INTO sales VALUES ('B', '2021-01-02', '2');
INSERT INTO sales VALUES ('B', '2021-01-04', '1');
INSERT INTO sales VALUES ('B', '2021-01-11', '1');
INSERT INTO sales VALUES ('B', '2021-01-16', '3');
INSERT INTO sales VALUES ('B', '2021-02-01', '3');
INSERT INTO sales VALUES ('C', '2021-01-01', '3');
INSERT INTO sales VALUES ('C', '2021-01-01', '3');
INSERT INTO sales VALUES ('C', '2021-01-07', '3');
CREATE TABLE menu (
  product_id INT,
  product_name VARCHAR(5),
  price INT
);
INSERT INTO menu VALUES ('1', 'sushi', '10');
INSERT INTO menu VALUES ('2', 'curry', '15');
INSERT INTO menu VALUES ('3', 'ramen', '12');
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);
INSERT INTO members VALUES ('A', '2021-01-07');
INSERT INTO members VALUES ('B', '2021-01-09');
--
 
-- QUESTION 
-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- ANSWER

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id, 
	SUM(m.price) AS Total_amount
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT
	s.customer_id,
	COUNT(DISTINCT order_date) AS Many_days
FROM sales s 
GROUP BY s.customer_id

-- 3. What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name,
    DENSE_RANK() OVER(
      PARTITION BY s.customer_id 
      ORDER BY s.order_date) AS sales_rank
  FROM sales s 
  JOIN menu m
    ON s.product_id = m.product_id
)
SELECT
	customer_id,
	product_name
FROM ordered_sales
WHERE sales_rank = 1
GROUP BY customer_id

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	m.product_name,
	COUNT(s.product_id) AS most_purchased_item
FROM sales s 
LEFT JOIN menu m 
	ON s.product_id = m.product_id 
GROUP BY m.product_name
ORDER BY most_purchased_item DESC
LIMIT 1

-- 5. Which item was the most popular for each customer?
WITH most_popular as(
	SELECT 
		s.customer_id,
		m.product_name,
		COUNT(m.product_id) AS order_count,
		DENSE_RANK() OVER(
			PARTITION BY s.customer_id
			ORDER BY COUNT(s.customer_id) DESC) AS count_rank
	FROM menu m
	JOIN sales s 
		ON m.product_id = s.product_id 
	GROUP BY s.customer_id, m.product_name 
)
SELECT
	customer_id,
	product_name,
	order_count
FROM most_popular
WHERE count_rank = 1

-- 6. Which item was purchased first by the customer after they became a member?
Rumus: jika dia mencari date setelah dia member, maka pastikan tanggal pembelian > dia join member pada ON CLAUSE di JOIN
WITH join_member AS (
	SELECT
		members.customer_id,
		s.product_id, 
		ROW_NUMBER() OVER(
		PARTITION BY members.customer_id
		ORDER BY s.order_date) AS row_num
	FROM members
	JOIN sales s 
		ON members.customer_id = s.customer_id 
		AND s.order_date > members.join_date
)
SELECT 
	customer_id,
	product_name
FROM join_member
JOIN menu m	
	ON join_member.product_id = m.product_id 
WHERE row_num = 1
ORDER BY customer_id ASC;

-- 7. Which item was purchased just before the customer became a member?
WITH buy_product AS (
	SELECT 
		members.customer_id,
		s.product_id,
		s.order_date,
		ROW_NUMBER() OVER(
		PARTITION BY members.customer_id
		ORDER BY s.order_date DESC) AS row_num
	FROM members
	JOIN sales s 
		ON members.customer_id = s.customer_id
		AND s.order_date < members.join_date 
)
SELECT
	customer_id,
	product_name,
	order_date
FROM buy_product
JOIN menu m 
	ON buy_product.product_id = m.product_id
WHERE row_num = 1
GROUP BY customer_id

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
	members.customer_id,
	m.product_name,
	m.price,
	COUNT(s.product_id) AS Total_items,
	SUM(m.price) AS amount_spent,
	s.order_date
FROM members
JOIN sales s 
	ON members.customer_id = s.customer_id
	AND s.order_date < members.join_date 
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY members.customer_id
ORDER BY s.order_date DESC

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH get_point AS(
	SELECT 
		m.product_id,
		CASE
			WHEN m.product_id = 1 THEN m.price * 20
			ELSE m.price * 10
		END AS points
	FROM menu m	
)
SELECT
	s.customer_id,
	SUM(get_point.points) AS Total_points
FROM sales s
JOIN get_point
	ON s.product_id = get_point.product_id 
GROUP BY s.customer_id 