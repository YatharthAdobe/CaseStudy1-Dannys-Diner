/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as total_spent from sales s join menu m
on s.product_id = m.product_id
group by 1;


-- 2. How many days has each customer visited the restaurant?
select customer_id , count(distinct order_date) as unique_days from sales 
group by 1;

-- 3. What was the first item from the menu purchased by each customer?
with cte as (select s.customer_id , m.product_name ,dense_rank() over(partition by s.customer_id order by s.order_date) as rnk
from sales s join menu m 
on s.product_id = m.product_id)

select customer_id , product_name as first_order from cte
where rnk = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name as most_popular_item , count(*) as times_bought from sales s join menu m on s.product_id = m.product_id
group by 1
order by count(*) desc
limit 1;

-- 5. Which item was the most popular for each customer?
with cte as (select s.customer_id , m.product_name , count(*) as buy_count , dense_rank() over(partition by s.customer_id order by count(*) desc) as rnk
from sales s join menu m on s.product_id = m.product_id
group by 1,2)
select customer_id , product_name , buy_count as most_bought_item from cte
where rnk = 1;


-- 6. Which item was purchased first by the customer after they became a member?
with cte as (select s.customer_id ,s.product_id , m.join_date , s.order_date, dense_rank() over(partition by s.customer_id order by s.order_date) as rnk
from sales s join members m on s.customer_id = m.customer_id and s.order_date >= m.join_date)
select customer_id, product_id , join_date , order_date as first_purchase from cte
where rnk = 1;


-- 7. Which item was purchased just before the customer became a member?
with cte as (select s.customer_id ,s.product_id , m.join_date , s.order_date, dense_rank() over(partition by s.customer_id order by s.order_date desc) as rnk
from sales s join members m on s.customer_id = m.customer_id and s.order_date < m.join_date)
select customer_id, product_id , join_date , order_date as last_purchase from cte
where rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
with cte as (select s.customer_id ,sum(t.price) as total_amount_spent, count(distinct t.product_name) as total_items
from sales s join members m on s.customer_id = m.customer_id and s.order_date < m.join_date
join menu t on s.product_id = t.product_id
group by 1)
select * from cte;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id, sum(case when m.product_name = 'sushi' then m.price*20 
							when m.product_name = 'ramen' or m.product_name = 'curry' then m.price*10 end) as points
from sales s join menu m on s.product_id = m.product_id
group by 1;

-- 10. Total points that each customer has accrued after taking a membership

SELECT s.customer_id,
       SUM(CASE
               WHEN product_name = 'sushi' THEN price*20
               ELSE price*10
           END) AS customer_points
FROM menu AS m
INNER JOIN sales AS s ON m.product_id = s.product_id
INNER JOIN members AS mem ON mem.customer_id = s.customer_id
WHERE order_date >= join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 11. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH program_last_day_cte AS
  (SELECT join_date,
          DATE_ADD(join_date, INTERVAL 6 DAY) AS program_last_date,
          customer_id
   FROM members)
SELECT s.customer_id,
       SUM(CASE
               WHEN order_date BETWEEN join_date AND program_last_date THEN price*10*2
               WHEN order_date NOT BETWEEN join_date AND program_last_date
                    AND product_name = 'sushi' THEN price*10*2
               WHEN order_date NOT BETWEEN join_date AND program_last_date
                    AND product_name != 'sushi' THEN price*10
           END) AS customer_points
FROM menu AS m
INNER JOIN sales AS s ON m.product_id = s.product_id
INNER JOIN program_last_day_cte AS mem ON mem.customer_id = s.customer_id
AND order_date <='2021-01-31'
AND order_date >=join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

SELECT s.customer_id,
       SUM(IF(order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY), price*10*2, IF(product_name = 'sushi', price*10*2, price*10))) AS customer_points
FROM menu AS m
INNER JOIN sales AS s ON m.product_id = s.product_id
INNER JOIN members AS mem USING (customer_id)
WHERE order_date <='2021-01-31'
  AND order_date >=join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;


-- Bonus Questions - Rank all the things

WITH data_table AS
  (SELECT customer_id,
          order_date,
          product_name,
          price,
          IF(order_date >= join_date, 'Y', 'N') AS member
   FROM members
   RIGHT JOIN sales USING (customer_id)
   INNER JOIN menu USING (product_id)
   ORDER BY customer_id,
            order_date)
SELECT *,
       IF(member='N', NULL, DENSE_RANK() OVER (PARTITION BY customer_id, member
                                               ORDER BY order_date)) AS ranking
FROM data_table;
