show databases;


use chinook;

select * from employee;  

update 
	employee
set
	reports_to = 0 
where 
	reports_to is null;
    
    

select * from customer;

select 
	count(case when company is not null then 1 end ) as not_null,
    count(case when company is null then 1 end ) as 'null'
from customer;
    
alter table 
	customer 
drop column company;


select 
	count(case when fax is not null then 1 end ) as not_null,
    count(case when fax is null then 1 end ) as 'null'
    from customer;
    
    
    alter table 
	customer 
drop column fax;


select * from invoice;

select * from invoice_line_id;

select * from track;

select * from playlist_track;

select * from playlist;

select * from album;

select * from artist;

select * from media_type;

select * from genre;






-- ****************************************************************************************************************************************************************************************************************************************   

-- objective question 2

    
select 
	t.name top_selling_track,
    a.name top_artist, 
    g.name top_genre 
from 
	track t
	left join invoice_line il on t.track_id = il.track_id
	left join invoice i on i.invoice_id = il.invoice_id
	left join album al on al.album_id = t.album_id
	left join artist a on a.artist_id = al.artist_id
	left join genre g on g.genre_id = t.genre_id
where 
	billing_country = "usa"
group by 1,2,3
order by sum(quantity) desc
limit 10;

    
    
    

-- ******************************************************************************************************************************************************************************************************   

-- objectove question 3


select 
	city, 
    country, 
    count(customer_id) 
from customer
group by 1,2
order by country;

select 
	country,
    count(customer_id) 
from customer
group by 1
order by 1;

select 
	count(distinct country) countries
from customer;
    
    
    
-- ******************************************************************************************************************************************************************************************************   

-- objectove question 4


select 
	billing_country, 
    billing_state, 
	billing_city, 
    count(invoice_id) num_of_invoices,
    sum(total) total_revenue_city
from invoice
group by 1,2,3
order by count(invoice_id) desc, sum(total) desc
;


    
-- ******************************************************************************************************************************************************************************************************   

-- objectove question 5


with temp1 as
	(
	select 
		first_name,
        last_name,
		country,
        sum(t.unit_price * il.quantity) total_revenue 
	from customer c
		left join invoice i on i.customer_id = c.customer_id
		left join invoice_line il on il.invoice_id = i.invoice_id 
		left join track t on t.track_id = il.track_id
	group by 1,2,3
	order by country
),
temp2 as
	(
	select 
		country,
		first_name,
		last_name,
		row_number() over(partition by country order by total_revenue desc) n
	from temp1
)
select 
	concat(first_name," ",last_name) name,
	country
from temp2
where n <= 5;



-- *******************************************************************************************************************************************************************************   
--  objective question 6
with temp1 as(
	select 
		first_name,
		last_name,
		t.name track_name,
		sum(quantity) total_quantity,
		row_number()over(partition by first_name,last_name  order by sum(quantity) desc) rn
	from customer c
		left join invoice i on i.customer_id = c.customer_id
		left join invoice_line il on il.invoice_id = i.invoice_id
		left join track t on t.track_id = il.track_id
	group by 1,2,3
	order by sum(quantity) desc
)

select 
	concat(first_name," ",last_name) name,
    track_name
from temp1
where  rn=1;  

-- *******************************************************************************************************************************************************************************   

-- objective question 7 


select 
	customer_id,
    count(invoice_id) num_invoices,
    round(avg(total),2) avg_sales 
from invoice
group by 1
order by count(invoice_id) desc, avg(total) desc;


-- *******************************************************************************************************************************************************************************   

-- objective question 8

with cust_in_1st_3m as 
(
	select 
		count(customer_id) ttl 
	from invoice
	where 
		invoice_date between '2017-01-01' and '2017-03-31'
),

cust_in_last_3m as
(
	select 
		count(customer_id) l_num 
	from invoice
	where 
		invoice_date between '2020-10-01' and '2020-12-31' 
) 
select 
	round(((select ttl from cust_in_1st_3m)-(select l_num from cust_in_last_3m))/(select ttl from cust_in_1st_3m) * 100,2) as churn_rate
;
-- assuming that total number of customers in the beginning is equal to the customers joining in the first 3 months.
-- also that churn rate will be calculated on the basis of the number of customers left in the last 3 months. 



-- *******************************************************************************************************************************************************************************   

-- objective question 9



with cte as
(
	select 
		sum(total) total_revenue_for_usa 
    from invoice
	where billing_country = 'usa'
),
genre_sales as
(
	select  
		g.genre_id,
        g.name,
        sum(t.unit_price * il.quantity) total_revenue_for_genre 
    from track t
		left join genre g on g.genre_id = t.genre_id
		left join invoice_line il on il.track_id = t.track_id
		left join invoice i on i.invoice_id = il.invoice_id
	where billing_country = 'usa'
	group by 1,2 
	order by total_revenue_for_genre desc
),
ranking as
(
	select 
		genre_id,
		name, 
		round(total_revenue_for_genre/(select total_revenue_for_usa from cte) * 100,2) percentage_contribution,
		dense_rank() over(order by round(total_revenue_for_genre/(select total_revenue_for_usa from cte) * 100,2) desc) rk 
	from genre_sales
)

select 
	ranking.genre_id,
    ranking.name genre_name,
    a.name artist_name, 
    percentage_contribution,
    rk as `ranking`
from ranking
	left join track t on t.genre_id = ranking.genre_id
	left join album al on al.album_id = t.album_id
	left join artist a on a.artist_id = al.artist_id
where rk=1 
group by 1,2,3,4
;



-- *******************************************************************************************************************************************************************************   

-- objective question 10

select 
	concat(first_name, ' ', last_name) name_of_customer,
    count(distinct g.name) no_of_genres
from customer c 
	left join invoice i on i.customer_id = c.customer_id
	left join invoice_line il on il.invoice_id = i.invoice_id
	left join track t on t.track_id = il.track_id
	left join genre g on g.genre_id = t.genre_id
group by 1 
having count(distinct g.name) >= 3
order by count(distinct g.name) desc;


-- *******************************************************************************************************************************************************************************   

-- objective question 11

with cte as
(
	select 
		t.genre_id,
        g.name,
        sum(t.unit_price * il.quantity) sale_performance 
	from track t
		left join genre g on g.genre_id = t.genre_id
		left join invoice_line il on il.track_id = t.track_id
		left join invoice i on i.invoice_id = il.invoice_id
	where billing_country = 'usa'
	group by 1, 2
)
select 
	name,
    sale_performance,
	dense_rank() over(order by sale_performance desc) `rank` 
from cte
;




-- *******************************************************************************************************************************************************************************   

-- objective question 12


select 
	first_name,
    last_name
from customer 
where customer_id not in (
	select 
		customer_id 
	from invoice
	where invoice_date > (select max(invoice_date) from invoice) - interval 3 month
)
;


-- *******************************************************************************************************************************************************************************   

-- *******************************************************************************************************************************************************************************   

-- *******************************************************************************************************************************************************************************   

-- *******************************************************************************************************************************************************************************   

-- *******************************************************************************************************************************************************************************   

-- *******************************************************************************************************************************************************************************   

-- subjective question 1

with genre_sales as
(
	select  
		g.genre_id,
		g.name,
		sum(t.unit_price * il.quantity) total_revenue_for_genre 
	from track t
		left join genre g on g.genre_id = t.genre_id
		left join invoice_line il on il.track_id = t.track_id
		left join invoice i on i.invoice_id = il.invoice_id
	where billing_country = 'usa'
	group by 1,2
	order by total_revenue_for_genre desc
),


ranking as
(
	select 
		genre_id,
		name,
		total_revenue_for_genre,
		dense_rank() over(order by total_revenue_for_genre desc) rk 
	from genre_sales
),


genre_album as
(
	select 
		ranking.genre_id,
		ranking.name genre_name,
        al.title album_name 
    from ranking
		left join track t on t.genre_id = ranking.genre_id
		left join album al on al.album_id = t.album_id
		left join artist a on a.artist_id = al.artist_id
	where rk = 1
	group by 1,2,3
),


best_album as
(
	select 
		al.album_id,
        title,
        sum(t.unit_price * il.quantity) 
	from album al
		left join track t on t.album_id = al.album_id
		left join invoice_line il on il.track_id = t.track_id
	group by 1,2
	order by sum(t.unit_price * il.quantity) desc
)
select 
	genre_id,
    genre_name,
    album_name 
from genre_album 
	inner join best_album on best_album.title = genre_album.album_name
limit 3
;



-- *******************************************************************************************************************************************************************************   

-- subjective question 2


select  
	g.genre_id,
    g.name, 
    sum(t.unit_price * il.quantity) total_revenue_for_genre 
from track t
	left join genre g on g.genre_id = t.genre_id
	left join invoice_line il on il.track_id = t.track_id
	left join invoice i on i.invoice_id = il.invoice_id
where billing_country <> 'usa'
group by 1,2
order by total_revenue_for_genre desc
;


-- *******************************************************************************************************************************************************************************   

-- subjective question 3

 with cte as
(
	select 
		i.customer_id,
        max(invoice_date),
        min(invoice_date),
        abs(timestampdiff(month, max(invoice_date), min(invoice_date))) time_for_each_customer,
        sum(total) sales,
        sum(quantity) items,
        count(invoice_date) frequency 
	from invoice i
		left join customer c on c.customer_id = i.customer_id
		left join invoice_line il on il.invoice_id = i.invoice_id
	group by 1
	order by time_for_each_customer desc
),


average_time as
(
	select 
		avg(time_for_each_customer) average 
	from cte
),-- 1244.3220 days or 40.36 months


categorization as
(
	select 
		*,
		case
			when time_for_each_customer > (select average from average_time) then "long-term customer" 
            else "short-term customer" 
		end category
	from cte
)

select 
	category,
    sum(sales) total_spending,
    sum(items) basket_size,
    count(frequency) frequency 
from categorization
group by 1 ;


-- *******************************************************************************************************************************************************************************   

-- subjective question 4

with cte as
(
	select 
		invoice_id,
        count(distinct g.name) num 
    from invoice_line il
		left join track t on t.track_id = il.track_id
		left join genre g on  g.genre_id = t.genre_id
	group by 1 
    having count(distinct g.name) > 1
)


select 
	cte.invoice_id,
    num,
    g.name 
from cte
	left join invoice_line il on il.invoice_id = cte.invoice_id
	left join track t on t.track_id = il.track_id
	left join genre g on  g.genre_id = t.genre_id
group by 1,2,3;




with cte as
(
	select 
		invoice_id,
        count(distinct al.title) num 
	from invoice_line il
		left join track t on t.track_id = il.track_id
		left join album al on al.album_id = t.album_id
	group by 1 
		having count(distinct al.title) > 1
)

select 
	cte.invoice_id,
    num,
    al.title 
from cte
	left join invoice_line il on il.invoice_id = cte.invoice_id
	left join track t on t.track_id = il.track_id
	left join album al on  al.album_id = t.album_id
group by 1,2,3;


with cte as
(
	select 
		invoice_id,
        count(distinct a.name) num 
	from invoice_line il
		left join track t on t.track_id = il.track_id
		left join album al on al.album_id = t.album_id
		left join artist a on a.artist_id = al.artist_id
group by 1 
having count(distinct a.name) > 1
)


select 
	cte.invoice_id,
	num,
    a.name 
from cte
	left join invoice_line il on il.invoice_id = cte.invoice_id
	left join track t on t.track_id = il.track_id
	left join album al on  al.album_id = t.album_id
	left join artist a on a.artist_id = al.artist_id
group by 1,2,3;

-- *******************************************************************************************************************************************************************************   

-- subjective question 5


with cust_in_first_3M as
(
select 
	billing_country,
    billing_state,
	billing_city,
    count(customer_id) ttl 
from invoice
where invoice_date between '2017-01-01' and '2017-03-31'
group by 1,2,3
),

cust_in_last_3M as
(
select 
	billing_country,
    billing_state,
	billing_city,
    count(customer_id) l_num 
from invoice
where invoice_date between '2020-10-01' and '2020-12-31' 
group by 1,2,3
),

Invoices as(
	select 
	billing_country,
    billing_state,
	billing_city,
    count(invoice_id) num_invoices, 
    avg(total) avg_sales 
from invoice
group by 1,2,3
order by count(invoice_id) desc, avg(total) desc
)

select 
	F.billing_country,
    F.billing_state,
    F.billing_city,
    num_invoices,
    avg_sales,
    ttl,
    l_num,
    (ttl - coalesce(l_num,0))/ttl * 100 churn_rate 
from cust_in_first_3M F
	left join  cust_in_last_3M L on F.billing_city = L.billing_city
    join invoices i on F.billing_city=i.billing_city
    order by 1,2,3
;



-- *******************************************************************************************************************************************************************************   

-- subjective question 6


select 
	i.customer_id,
    concat(first_name, " ", last_name) name,
    billing_country,
    
    sum(total) total_spending,
    count(invoice_id) num_of_orders 
from invoice i
	left join customer c on c.customer_id = i.customer_id
group by 1,2,3
order by name
;


-- *******************************************************************************************************************************************************************************   
-- *******************************************************************************************************************************************************************************   
-- *******************************************************************************************************************************************************************************   
-- *******************************************************************************************************************************************************************************   
-- *******************************************************************************************************************************************************************************   
-- *******************************************************************************************************************************************************************************   
-- *******************************************************************************************************************************************************************************   

-- data for PPT


select count(distinct(country)) from customer;

select count(distinct(name)) from genre;

select count(distinct(name)) from artist;

select count(distinct(customer_id))from customer;

select country,count(customer_id) from customer group by 1;

with cte as
(
	select 
		t.genre_id,
        g.name,
        sum(t.unit_price * il.quantity) sale_performance 
	from track t
		left join genre g on g.genre_id = t.genre_id
		left join invoice_line il on il.track_id = t.track_id
		left join invoice i on i.invoice_id = il.invoice_id
	
	group by 1, 2
)
select 
	name,
    sale_performance,
	dense_rank() over(order by sale_performance desc) `rank` ,
     (sale_performance/(select sum(sale_performance) from cte))*100 market_share 
from cte
;
