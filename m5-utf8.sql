--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.



select *, row_number() over(order by payment_date) as num_pay_on_date,
	row_number() over(partition by customer_id order by payment_date) as num_pay_per_scustomers,
	sum(amount) over(partition by customer_id order by payment_date, amount) as sum_pay_on_date,
	rank() over(partition by customer_id order by amount desc)
from payment
order by payment_date --customer_id


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.

select customer_id, lag(amount, 1, 0.0) over(partition by customer_id order by payment_date), amount
from payment 



--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select customer_id, amount,lead(amount) over(partition by customer_id order by payment_date),
	amount - lead(amount, 1, 0.0) over(partition by customer_id order by payment_date)  as difference
from payment 



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

--explain analyze --1947/19
select *
from (
	select *, row_number() over (partition by customer_id order by rental_date desc)
	from rental)
where row_number = 1


--explain analyze --1494/19
select *
from (
	select *, row_number() over (partition by customer_id order by payment_date desc)
	from payment)
where row_number = 1



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.


select *, sum(amount) over(partition by customer_id order by payment_date)
from payment 
where payment_date::text like '2005-08-%' 





--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку


select *
from (
	select *, row_number() over(order by payment_date) as num
	from payment
	where payment_date::date = '2005-08-20')
where num % 100 = 0 



--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм







