CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'22-09-2017'),
(3,'21-04-2017');

drop table if exists users;
CREATE TABLE users(userid int,signup_date date); 

set datestyle =dmy;
INSERT INTO users(userid,signup_date) 
 VALUES (1,'02-09-2014'),
(2,'15-01-2015'),
(3,'11-04-2014');

drop table if exists sales;
CREATE TABLE sale(userid integer,created_date date,product_id integer); 

INSERT INTO sale(userid,created_date,product_id) 
 VALUES (1,'19-04-2017',2),
(3,'18-12-2019',1),
(2,'20-07-2020',3),
(1,'23-10-2019',2),
(1,'19-03-2018',3),
(3,'20-12-2016',2),
(1,'09-11-2016',1),
(1,'20-05-2016',3),
(2,'24-09-2017',1),
(1,'11-03-2017',2),
(1,'11-03-2016',1),
(3,'10-11-2016',1),
(3,'07-12-2017',2),
(3,'15-12-2016',2),
(2,'08-11-2017',2),
(2,'10-09-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sale;
select * from product;
select * from users;
select * from goldusers_signup;

--1.what is total amount each customer spent on zomato ?
select s.userid,sum(p.price) as spent
from sale s
inner join product p
on p.product_id =s.product_id
group by 1
order by 2 desc;

--2.How many days has each customer visited zomato?

select s.userid,count(distinct s.created_date) as no_of_days_visited
from  sale s
group by 1
order by 2 desc;

--3.what was the first product purchased by each customer?

select userid,product_id,product_name,created_date from 
(select s.userid,p.product_id,p.product_name, s.created_date,
dense_rank() over(partition by s.userid order by s.created_date) as dn
from sale s
inner join product p
on s.product_id = p.product_id)x
where dn=1;

--4.what is most purchased item on menu & how many times was 
		--it purchased by all customers ?

select s.userid,count(s.product_id) from sale s
where s.product_id =
(select product_id from sale 
 group by 1
 order by count(product_id) desc limit 1
)
group by 1;

/*select userid,product_id 
from sale
order by userid
*/

--5.which item was most popular for each customer?

select userid,product_id from 
(select userid,product_id, 
dense_rank() over(partition by userid order by count(product_id) desc) as dn
from sale
group by 1,2)x
where dn=1;

--6.which item was purchased first by customer after they become a member ?

select userid, product_id,created_date,gold_signup_date from 
(select s.userid,s.product_id,s.created_date,g.gold_signup_date,
dense_rank() over (partition by s.userid order by s.created_date) as dn
from sale s
inner join goldusers_signup g
on s.userid = g.userid
and g.gold_signup_date < s.created_date)x
where dn=1;

--7. which item was purchased just before the customer became a member?
select userid, product_id,created_date,gold_signup_date from 
(select s.userid,s.product_id,s.created_date,g.gold_signup_date, 
dense_rank() over (partition by s.userid order by s.created_date desc) as dn
from sale s
inner join goldusers_signup g
on s.userid = g.userid
and g.gold_signup_date > s.created_date)x
where dn=1;

--8.what is total orders and amount spent for each member before they become a member?
select userid, count(product_id),sum(price) from 
(select s.userid,s.product_id,s.created_date,g.gold_signup_date,p.price
from sale s
inner join product p
on p.product_id=s.product_id
inner join goldusers_signup g
on s.userid = g.userid
and g.gold_signup_date > s.created_date)x
group by 1
order by 1;

/*
9.If buying each product generates points for eg 5rs=2 zomato point 
  and each product has different purchasing points for eg for p1 5rs=1 
  zomato point,for p2 10rs=5 zomato point and p3 5rs=1 zomato point  
  calculate points collected by each customer 
  and for which product most points have been given till now.*/
with cte as
(select distinct s.userid,p.product_id,p.price,
case when p.product_name ='p1' then (p.price/5)*2
	when p.product_name ='p2' then (p.price/10)*5
	when p.product_name ='p3' then (p.price/5)*1
	else '00'
	end as zomato_points
from sale s
inner join product p
on p.product_id = s.product_id
order by 1,2),
cte2 as (
select product_id,sum(price) as prod_price,sum(zomato_points) as prod_points 
from cte
group by 1
order by 2 desc
limit 1)
select userid,sum(price)as user_price,sum(zomato_points) as user_point 
from cte
group by 1
order by 2 desc
limit 1;

/*10. In the first year after a customer joins the gold program 
(including the join date ) irrespective of what customer has purchased earn 
5 zomato points for every 10rs spent who earned 
more 1 or 3 what int earning in first yr ? 1zp = 2rs*/

select s.userid,s.product_id,s.created_date,g.gold_signup_date,p.price,
 p.price/2 as points
from sale s
inner join product p
on p.product_id=s.product_id
inner join goldusers_signup g
on s.userid = g.userid
and g.gold_signup_date <= s.created_date
and s.created_date <=  g.gold_signup_date+365;

--11. rnk all transaction of the customers?
select userid,created_date,rank() over 
(partition by userid order by created_date) as rn
from sale;

/*12. rank all transaction for each member whenever they are 
zomato gold member for every non gold member transaction mark as na.*/

select userid,created_date,
case when gold_signup_date is not null then rank() over 
(partition by userid order by created_date desc)
else null end as ranking from 
(select s.userid,s.created_date,g.gold_signup_date 
from sale s
left join goldusers_signup g
on g.userid = s.userid
and s.created_date >  g.gold_signup_date)x;




 

 




