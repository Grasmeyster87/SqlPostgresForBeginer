-- Buckup таблцы customers
CREATE OR REPLACE FUNCTION buckup_customers() RETURNS void AS $$
	DROP TABLE IF EXISTS backedup_customers;

	CREATE TABLE backedup_customers AS
	SELECT * FROM customers;
	--SELECT * INTO backedup_customers
	--FROM customers;
$$ LANGUAGE SQL;

SELECT buckup_customers();

SELECT COUNT(*) FROM backedup_customers;
SELECT * FROM backedup_customers;

-- Функция по возврату среднего значения значения столбца freight 
-- из таблицы orders

CREATE OR REPLACE FUNCTION get_avg_freight() RETURNS float8 AS $$
	SELECT AVG(freight)
	FROM orders;
$$ LANGUAGE SQL;

SELECT * FROM get_avg_freight();

-- Написать функцию которая принимает два целочисленніх параметра
-- используемых как граница для генерации случайного числа 
-- в пределах собственно етой границы,
-- включая сами граничные значения 
-- (необходимо вычислить разницу между границами 
-- и прибавить единицу). 
-- На полученное число умножить результат функции random(), 
-- и прибачить к результату значение нижней границы, 
-- применить функцию floor()к конечному результату чтобы не уехать за границу, 
-- и получить целое число.

CREATE OR REPLACE FUNCTION get_avg_freight() RETURNS float8 AS $$
	SELECT AVG(freight)
	FROM orders;
$$ LANGUAGE SQL;

SELECT * FROM get_avg_freight();

CREATE OR REPLACE FUNCTION random_between(low int, hight int) RETURNS int AS $$
BEGIN
	RETURN floor(random() * (hight - low + 1) + low);
END
$$ LANGUAGE plpgsql;

SELECT random_between(1, 8)
FROM generate_series(1, 10);

-- Написать функцию которая возвращает зарплату самую низкую и высокую 
-- среди сотрудников заданного города

ALTER TABLE employees
ADD COLUMN salary numeric(12,2);

UPDATE employees
SET salary=64.47
WHERE employee_id=1;

UPDATE employees
SET salary=52.42
WHERE employee_id=2;

UPDATE employees
SET salary=78.47
WHERE employee_id=3;

UPDATE employees
SET salary=62.95
WHERE employee_id=4;

UPDATE employees
SET salary=55.56
WHERE employee_id=5;

UPDATE employees
SET salary=54.92
WHERE employee_id=6;

UPDATE employees
SET salary=64.35
WHERE employee_id=7;

UPDATE employees
SET salary=75.60
WHERE employee_id=8;

UPDATE employees
SET salary=0.00
WHERE employee_id=9;
SELECT employee_id, salary FROM employees
order by employee_id


CREATE OR REPLACE FUNCTION get_salary_bounds_by_city(emp_city varchar, out min_salary numeric, out max_salary numeric) AS $$
	SELECT MIN(salary), MAX(salary)
	FROM employees
	WHERE city = emp_city
$$ LANGUAGE SQL;

SELECT * FROM get_salary_bounds_by_city('London');

SELECT * FROM employees;

-- Создать функцию которая корректирует зарплату на заданный процент,
-- но некорректирует зарплату если процент превышает верхний заданный уровень.
-- Верхний предел равен 70%, процент коррекции равен 15.

CREATE OR REPLACE FUNCTION correct_salary(upper_boundary numeric DEFAULT 70, correction_rate numeric DEFAULT 0.15)
RETURNS void AS 
$$
    UPDATE employees
    SET salary = salary + (salary * correction_rate)
    WHERE salary <= upper_boundary
$$ LANGUAGE SQL;

SELECT salary from employees ORDER BY salary;
SELECT correct_salary();

-- Модифицировать функцию корректирующую зарплату таким образом,
-- чтобы в результате коррекции она так же выводила измененные записи

DROP FUNCTION IF EXISTS correct_salary;
CREATE OR REPLACE FUNCTION correct_salary(upper_boundary numeric DEFAULT 70, correction_rate numeric DEFAULT 0.15)
RETURNS setof employees AS 
$$
    UPDATE employees
    SET salary = salary + (salary * correction_rate)
    WHERE salary <= upper_boundary
    RETURNING *;
$$ LANGUAGE SQL;

SELECT salary from employees ORDER BY salary;
SELECT * FROM correct_salary();

-- Модифицировать предыдущую функцию,
-- так что бы она возвращала колонки last_name, first_name, title, salary

DROP FUNCTION IF EXISTS correct_salary;
CREATE OR REPLACE FUNCTION correct_salary(upper_boundary numeric DEFAULT 70, correction_rate numeric DEFAULT 0.15)
RETURNS table(last_name text, first_name text, title text, salary numeric) AS 
$$
    UPDATE employees
    SET salary = salary + (salary * correction_rate)
    WHERE salary <= upper_boundary
    RETURNING last_name text, first_name, title, salary;
$$ LANGUAGE SQL;

SELECT salary from employees ORDER BY salary;
SELECT * FROM correct_salary();

-- Написать функцию которая принимает метод доставки (ship_via in orders table),
-- и возвращает записи из таблицы orders в которых freight меньше значения определяемого 
-- алгоритму: ищем максимум фрахта среди заказов по заданному методу доставки.
-- Корректируем найденный максимум в сторону понижения. Вычисляем среднее значение фрахта
-- по заданному методу доставки. Вычисляем значение по срднему найденному методу доставки.
-- Вычисляем среднее значение между средним найденным на предыдущем шаге и скоректированым максимумом.
-- Возвращаем все заказы в которых значения фракта меньше найденного на предыдущем шаге среднего.

CREATE OR REPLACE FUNCTION get_orders_by_shipping(ship_method int) RETURNS setof orders AS $$
DECLARE
    average numeric;
    maximum numeric;
    middle numeric;    
BEGIN
    SELECT MAX (freight) INTO maximum
    FROM orders
    WHERE ship_via = ship_method;

    SELECT AVG (freight) INTO average
    FROM orders
    WHERE ship_via = ship_method;

    maximum = maximum - (maximum * 0.3);

    middle = (maximum + average) / 2;

    RETURN QUERY
    SELECT *
    FROM orders
    WHERE freight < middle;

END
$$ LANGUAGE plpgsql;

SELECT * FROM get_orders_by_shipping(1);
SELECT COUNT(*) FROM get_orders_by_shipping(1);

-- Задание по ИФЛ. Написать функцию принимает:
--  уровень максимальной и минимальной зарплаты
-- по умолчанию максимальная зарплата 80 минимальная 30
-- коефициент роста зарплаты по умолчанию 20%
-- если зарплата которую передали выше если зарплата выше минимальной то возвращается false
-- если зарплата ниже минимальной то увеличивается на коефициент роста и проверяется,
-- не станет ли зарплата после повышения превышать максимальную
-- если превысит возвращаем false в противном случае true

CREATE OR REPLACE FUNCTION should_increase_salary(
    cur_salary numeric,
    max_salary numeric DEFAULT 80,
    min_salary numeric DEFAULT 30,
    increase_rate numeric DEFAULT 0.2
) RETURNS bool AS
$$
DECLARE 
    new_salary numeric;
BEGIN
    IF cur_salary >= max_salary OR cur_salary >= min_salary THEN
        RETURN false;
    END IF;

    IF cur_salary < min_salary THEN
        new_salary = cur_salary + (cur_salary * increase_rate);
    END IF;

    IF new_salary > max_salary THEN
        RETURN false;
    ELSE
        RETURN true;
    END IF;
END
$$ LANGUAGE plpgsql;

SELECT should_increase_salary(40, 80, 30, 0.2);
SELECT should_increase_salary(79, 81, 80, 0.2);
SELECT should_increase_salary(79, 95, 90, 0.2);