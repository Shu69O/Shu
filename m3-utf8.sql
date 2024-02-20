--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.


select c.customer_id, initcap(concat_ws(' ', c.first_name, c.last_name)) as "FL",  a.address, c2.city, c3.country
from customer c 
join address a on c.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
join country c3 on c2.country_id = c3.country_id 
order by c.customer_id 




--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.



select s.store_id, count(*) as quantity_customers
from store s
join customer c on s.store_id = c.store_id 
group by s.store_id 






--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.


select s.store_id, count(*) as quantity_customers
from store s
join customer c on s.store_id = c.store_id 
group by s.store_id 
having count(*) > 300




-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.


select s.store_id, count(*) as quantity_customers, c2.city, concat_ws(' ', s2.first_name, s2.last_name) as "FL" 
from store s
join customer c on s.store_id = c.store_id 
join address a on s.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
join staff s2 on s.manager_staff_id =s2.staff_id
group by s.store_id, c2.city_id , s2.staff_id 
having count(*) > 300




--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select c.customer_id, concat_ws(' ', c.first_name, c.last_name) as "NL", count(r.rental_id)
from customer c
join rental r on c.customer_id = r.customer_id 
group by c.customer_id 
order by count(r.rental_id)  desc
limit 5




--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select concat_ws(' ', c.first_name, c.last_name) as "FL" , count(r.rental_id) as qty_rental, 
	   round(sum(p.amount)) as general_expenses, min(p.amount), max(p.amount)
from payment p
join rental r on p.rental_id = r.rental_id 
join customer c on p.customer_id = c.customer_id 
group by c.customer_id 
order by general_expenses desc



--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
 
select c.city, c2.city
from city c 
cross join city c2
where c.city != c2.city


select c.city, c2.city
from city c, city c2
where c.city != c2.city



--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.
 

select customer_id, round(avg(return_date::date - rental_date::date), 2) as avg_quantity_days
from rental 
group by customer_id 
order by customer_id 




--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select f.title, f.rating, f.release_year, count(r.rental_id) as number_of_rented, 
	   sum(p.amount) as amount_of_profit
from film f 
join inventory i on f.film_id = i.film_id 
join rental r on i.inventory_id = r.inventory_id 
join payment p on r.rental_id = p.rental_id 
group by f.film_id 
order by number_of_rented desc



--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.






--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".


select concat_ws(' ', s2.first_name, s2.last_name), count(p.customer_id) as number_of_sales,
	case 
		when count(p.customer_id) > 7300 then 'Да'
		else 'Нет'
	end as "Премия"
from store s 
join staff s2 on s.manager_staff_id = s2.staff_id 
join payment p on s2.staff_id = p.staff_id 
group by s2.staff_id  



