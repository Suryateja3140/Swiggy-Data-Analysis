select * from swiggy_data

--Null check
select
	sum(case when state is null then 1 else 0 end) as null_state,
	sum(case when city is null then 1 else 0 end) as null_city,
	sum(case when order_date is null then 1 else 0 end) as null_order_date,
	sum(case when restaurant_name is null then 1 else 0 end) as null_restaurant,
	sum(case when location is null then 1 else 0 end) as null_location,
	sum(case when category is null then 1 else 0 end) as null_category,
	sum(case when dish_name is null then 1 else 0 end) as null_dish,
	sum(case when price_INR is null then 1 else 0 end) as null_price,
	sum(case when rating is null then 1 else 0 end) as null_rating,
	sum(case when rating_count is null then 1 else 0 end) as null_rating_count
	from swiggy_data;

--Blank or empty
 select * from swiggy_data
 where state = '' or city = '' or restaurant_name = '' or location = '' or category = '' or dish_name = ''


 --Duplicates Detection
 select
 state,city,order_date,restaurant_name,location,category,
 dish_name,price_INR, rating,rating_count,count(*) as CNT
 from swiggy_data
 group by
 state, city,order_date,restaurant_name,location,category,
 dish_name,price_INR, rating,rating_count
 having count(*)>1

 --delete duplictaion
 with cte as (
 select *, row_number() over(
 partition by state,city,order_date,restaurant_name,location, category,
 dish_name,price_INR,rating,rating_count
 order by (select null)
 ) as rn
 from swiggy_data
 )
 delete from cte where rn>1

 --dimension table
 --date table
 create table dimensions_date (
 date_id int identity(1,1) primary key,
 full_date date,
 year int,
 month int,
 month_name varchar(20),
 quarter int,
 day int,
 week int
 )

 select * from dimensions_date

 --dim_location
 create table dimensions_location (
 location_id int identity(1,1) primary key,
 state varchar(100),
 city varchar(100),
 location varchar(200)
 );

 --dim_restaurant
 create table dimensions_restaurant (
 restaurant_id int identity(1,1) primary key,
 restaurant_name varchar(200)
 );

 --dim_category

 create table dimensions_category (
 category_id int identity(1,1) primary key,
 category varchar(200)
 );

 --dim_dish
 create table dimensions_dish (
 dish_id int identity(1,1) primary key,
 dish_name varchar(200)
 );

 --fact table
 create table facts_swiggy_order (
 order_id int identity(1,1) primary key,
 date_id int,
 price_INR decimal,
 rating decimal(4,2),
 rating_count int,
 location_id int,
 restaurant_id int,
 category_id int,
 dish_id int,
 foreign key (date_id) references dimensions_date(date_id),
 foreign key (location_id) references dimensions_location(location_id),
 foreign key (restaurant_id) references dimensions_restaurant(restaurant_id),
 foreign key (category_id) references dimensions_category(category_id),
 foreign key (dish_id) references dimensions_dish(dish_id)
);

select * from facts_swiggy_order

--insert data dim_date
insert into dimensions_date(full_date, year, month, month_name, quarter, day, week)
select distinct
order_date,
year(order_date),
month(order_date),
datename(month,order_date),
datepart(quarter,order_date),
day(order_date),
datepart(week,order_date)
from swiggy_data
where order_date is not null

--dim_location
insert into dimensions_location(state,city,location)
select distinct
state,
city,
location from swiggy_data

select * from dimensions_location

---dim_restaurant
insert into dimensions_restaurant(restaurant_name)
select distinct
restaurant_name
from swiggy_data;

--dim_category
insert into dimensions_category(category)
select distinct
category from swiggy_data;

--dim_dish
insert into dimensions_dish(dish_name)
select distinct
dish_name
from swiggy_data

--fact table
insert into facts_swiggy_order
(
date_id,
price_INR,
rating,
rating_count,
location_id,
restaurant_id,
category_id,
dish_id
)

select
dd.date_id,
s.price_INR,
s.rating,
s.rating_count,

dl.location_id,
dr.restaurant_id,
dc.category_id,
dsh.dish_id
from swiggy_data s

join dimensions_date dd
on dd.full_date = s.Order_Date

join dimensions_location dl
on dl.state = s.State
and dl.city = s.city
and dl.location = s.location

join dimensions_restaurant dr
on dr.restaurant_name = s.Restaurant_Name

join dimensions_category dc
on dc.category = s.Category

join dimensions_dish dsh
on dsh.dish_name = s.dish_name

select * from facts_swiggy_order

select * from fact_swiggy f
join dimensions_date d on f.date_id = d.date_id
join dimensions_location l on f.location_id = l.location_id
join dimensions_restaurant r on f.restaurant_id = r.restaurant_id
join dimensions_category c on f.category_id = c.category_id
join dimensions_dish di on f.dish_id = di.dish_id

--Kpi
--total revenue
select
FORMAT(sum(convert(float,price_INR))/1000000, 'N2') + 'INR Millions'
as total_revenue
from facts_swiggy_order

--Average dish price
select
FORMAT(avg(convert(float,price_INR)),'N2') + 'INR'
as total_revenue
from facts_swiggy_order

--average rating
select
AVG(rating) as avg_rating
from facts_swiggy_order

--monthly order trends
select
d.year,
d.month,
d.month_name,
COUNT(*) as total_orders
from facts_swiggy_order f
join dimensions_date d on f.date_id = d.date_id
group by d.year,
d.month,
d.month_name

--month wise revenue
select
d.year,
d.month,
d.month_name,
SUM(price_INR) as total_orders
from facts_swiggy_order f
join dimensions_date d on f.date_id = d.date_id
group by d.year,
d.month,
d.month_name


---auaterly trend
select
d.year,
d.quarter,
COUNT(*) as total_orders
from facts_swiggy_order f
join dimensions_date d on f.date_id = d.date_id
group by d.year,
d.quarter


--yearly trends
select
d.year,
count(*) as total_orders
from facts_swiggy_order f
join dimensions_date d on f.date_id = d.date_id
group by d.year


--orderby day of week
select
DATENAME(weekday, d.full_date) as day_name,
COUNT(*) as total_orders
from facts_swiggy_order f
join dimensions_date d on f.date_id = d.date_id
group by DATENAME(weekday,d.full_date),
datepart(weekday,d.full_date)
order by DATEPART(weekday,d.full_date)



--Top 10 cities by order values
select Top 10
l.city,
COUNT(*) as total_orders from facts_swiggy_order f
join dimensions_location l
on l.location_id = f.location_id
group by l.city
order by COUNT(*) desc


--Top 10 cities by revenue
select Top 10
l.city,
sum(price_INR) as total_revenue from facts_swiggy_order f
join dimensions_location l
on l.location_id = f.location_id
group by l.city
order by SUM(f.price_INR) desc

--rrevenue contribution by states
select
l.state,
SUM(f.price_INR) as total_revenue from facts_swiggy_order f
join dimensions_location l
on l.location_id = f.location_id
group by l.state
order by SUM(f.price_INR) desc

--Top 10 restaurants by orders
select 
r.restaurant_name,
sum(f.price_INR) as total_revenue from facts_swiggy_order f
join dimensions_restaurant r
on r.restaurant_id = f.restaurant_id
group by r.restaurant_name
order by sum(f.price_INR) desc

---Top categories by order values
select
c.category,
COUNT(*) as total_orders
from facts_swiggy_order f
join dimensions_category c on f.category_id = c.category_id
group by c.category
order by total_orders desc

--most ordered dishes
select
d.dish_name,
COUNT(*) as order_count
from facts_swiggy_order f
join dimensions_dish d on f.dish_id = d.dish_id
group by d.dish_name
order by order_count desc

--cuisine performance(orders + avg rating)
select
c.category,
COUNT(*) as total_orders,
AVG(f.rating)as avg_rating
from facts_swiggy_order f
join dimensions_category c on f.category_id = c.category_id
group by c.category
order by total_orders desc


--Total orders by price range
SELECT
  CASE
    WHEN CONVERT(float, price_inr) < 100 THEN 'under 100'
    WHEN CONVERT(float, price_inr) BETWEEN 100 AND 199 THEN '100-199'
    WHEN CONVERT(float, price_inr) BETWEEN 200 AND 299 THEN '200-299'
    WHEN CONVERT(float, price_inr) BETWEEN 300 AND 499 THEN '300-499'
    ELSE '500+'
  END AS price_range,
  COUNT(*) AS total_orders
FROM facts_swiggy_order
GROUP BY
  CASE
    WHEN CONVERT(float, price_inr) < 100 THEN 'under 100'
    WHEN CONVERT(float, price_inr) BETWEEN 100 AND 199 THEN '100-199'
    WHEN CONVERT(float, price_inr) BETWEEN 200 AND 299 THEN '200-299'
    WHEN CONVERT(float, price_inr) BETWEEN 300 AND 499 THEN '300-499'
    ELSE '500+'
  END
ORDER BY total_orders DESC;


--rating count distribution(1-5)
select
rating,
count(*) as rating_count
from facts_swiggy_order f
group by rating
order by rating







