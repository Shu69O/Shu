--Задание 1
--1. Выведите название самолетов, которые имеют менее 50 посадочных мест?

--explain analyze --105/1.5
select distinct *
from (
	select model, count(a.aircraft_code) over (partition by a.aircraft_code) as num_seats
	from seats s 
	join aircrafts a on s.aircraft_code = a.aircraft_code)
where num_seats < 50


--explain analyze --35/1.5
select model, count(a.aircraft_code) as num_seats
from seats s 
join aircrafts a on s.aircraft_code = a.aircraft_code
group by model, a.aircraft_code 
having count(a.aircraft_code) < 50


--задание 2
--2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.


								
--explain analyze --30 254/60
select "month"::date as "date", "sum" as total_amount, round(((sum - lag(sum) over (order by "month")) 
	/ (lag(sum) over (order by "month") + sum / sum)) * 100, 2) || ' %' as perc_difference
from (
	select date_trunc('month', book_date) as "month" , sum(total_amount)
	from bookings b 
	group by date_trunc('month', book_date)
	)



--Задание 3
--3. Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.


--explain analyze --197 000/670
select model, array_agg(distinct tf.fare_conditions) as arr
from aircrafts a 
join flights f on a.aircraft_code = f.aircraft_code 
join ticket_flights tf on f.flight_id = tf.flight_id 
group by model
having 'Business' != all(array_agg(distinct tf.fare_conditions))


--Задание 4
--4. Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день, 
--учитывая только те самолеты, которые летали пустыми и только те дни, где из одного аэропорта
-- таких самолетов вылетало более одного.


Группируем по аэропорту, времени вылета и модели самолета и нумеруем места с помощью окон
После нужно найти пустые самолеты, т.е из пасадочных билетов вычесть общее количество билетов
По оставшимся билетам считаем кол-во мест у каждой модели самолета, если все места совподают по общему кол-ву мест
(12/12 допустим) делаем фильтр на кол-во вылетов в этом аэропорту более 1

	

--5. Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов.
--Выведите в результат названия аэропортов и процентное отношение.
--Решение должно быть через оконную функцию.


--explain analyze --1330/20
select airport_name, percent_of_all
from 
(
	select flight_no, departure_airport,
		round(count(flight_no) * 100.0 / sum(count(*)) over (), 2) || ' %' as percent_of_all
	from flights
	group by flight_no, departure_airport
) t2
join airports a on t2.departure_airport = a.airport_code 
order by airport_name
	

--explain analyze --1223/23
select airport_name, sum(percent_of_all) || ' %' as percent_of_all
from 
(
	select flight_no, departure_airport,
		round(count(flight_no) * 100.0 / sum(count(*)) over (), 2) as percent_of_all
	from flights
	group by flight_no, departure_airport
) t2
join airports a on t2.departure_airport = a.airport_code 
group by airport_name



--6. Выведите количество пассажиров по каждому коду сотового оператора, если учесть,
-- что код оператора - это три символа после +7


select substring(contact_data ->> 'phone' from 3 for 3), count(book_ref) as num_passenger
from tickets t 
group by substring(contact_data ->> 'phone' from 3 for 3)



--7. Классифицируйте финансовые обороты (сумма стоимости перелетов) по маршрутам:
-- До 50 млн - low
-- От 50 млн включительно до 150 млн - middle
-- От 150 млн включительно - high
-- Выведите в результат количество маршрутов в каждом полученном классе



--explain analyze--158 942/736
select class_amount, sum(num_routes) as num_routes_2
from (
	select f.departure_airport as departure_airport, f.arrival_airport,
		count(distinct f.departure_airport) as num_routes, 
		count(distinct f.arrival_airport) as num_routes_arrival,
		case 
			when sum(tf.amount) < 50*10^6 then 'low'
			when sum(tf.amount) < 150*10^6 then 'middle'
			else 'high'
		end as class_amount
	from flights f
	join ticket_flights tf on f.flight_id = tf.flight_id
	group by f.departure_airport, f.arrival_airport
	) t1
group by class_amount




--8. Вычислите медиану стоимости перелетов, медиану размера бронирования и отношение медианы 
--бронирования к медиане стоимости перелетов, округленной до сотых




select (select percentile_cont(0.5) within group (order by total_amount) from bookings b) as book_median, 
	percentile_cont(0.5) within group (order by amount) as routes_median,
	round(cast( ((select percentile_cont(0.5) within group (order by total_amount) from bookings b) /
	percentile_cont(0.5) within group (order by amount)) as numeric), 2) as attitude
from ticket_flights tf  

	


--9. Найдите значение минимальной стоимости полета 1 км для пассажиров. 
--  То есть нужно найти расстояние между аэропортами и с учетом стоимости перелетов получить искомый результат
--  Для поиска расстояния между двумя точками на поверхности Земли используется модуль earthdistance.
--  Для работы модуля earthdistance необходимо предварительно установить модуль cube.
--  Установка модулей происходит через команду: create extension название_модуля.	
	
create extension cube

create extension earthdistance


--explain analyze --34226 / 5640
select min(cost_per_1km)
from
(
	select t2.a_air_code, t2.a_air_name, t2.a2_air_code, t2.a2_air_name, t2.cube_dist, 
		f.flight_id, f.flight_no, tf.amount, tf.amount / t2.cube_dist as cost_per_1km
	from
	(
	select a.airport_code as a_air_code, a.airport_name as a_air_name, 
		a2.airport_code as a2_air_code, a2.airport_name as a2_air_name, 
	earth_distance(ll_to_earth(a.latitude, a.longitude), ll_to_earth(a2.latitude, a2.longitude)) / 1000 as cube_dist
	from airports a, airports a2 
	where a.airport_code != a2.airport_code
	order by cube_dist desc
	) t2
	join flights f on t2.a_air_code = f.departure_airport
	join ticket_flights tf on f.flight_id = tf.flight_id
)




