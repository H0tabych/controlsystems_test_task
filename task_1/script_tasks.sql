USE user_session;

/*
1. Вывести для каждого пользователя 3 последних логина за последние 7 дней
*/

-- Решение в виде сводной таблицы

SELECT DISTINCT 
	user_id,
	user_name,
	NTH_VALUE (login_datetime, 3) OVER W AS `last_login - 2`,
	NTH_VALUE (login_datetime, 2) OVER W AS `last_login - 1`,
	FIRST_VALUE(login_datetime) OVER w AS last_login
FROM `session`
WHERE login_datetime >= CURRENT_TIMESTAMP() - INTERVAL 7 DAY 
WINDOW w AS (PARTITION BY user_id ORDER BY login_datetime DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 3 FOLLOWING)
;

-- решение в виде плоской таблицы
WITH s AS (
	SELECT DISTINCT 
		user_id,
		user_name,
		login_datetime,
		DENSE_RANK() OVER w AS last_for_7_days
	FROM `session` 
	WHERE login_datetime >= CURRENT_TIMESTAMP() - INTERVAL 7 DAY 
	WINDOW w AS (PARTITION BY user_id ORDER BY login_datetime DESC)
)

SELECT 
	user_id,
	user_name,
	login_datetime
FROM s
WHERE last_for_7_days <= 3
;

/*
2. Вывести для каждого пользователя максимальный интервал между двумя соседними входами
*/
WITH it AS (
	SELECT 
		user_id,
		user_name,
		TO_SECONDS(login_datetime) - TO_SECONDS(LAG(login_datetime) OVER w) AS interval_login_sec
	FROM `session`
	WINDOW w AS (PARTITION BY user_id ORDER BY login_datetime)
)

SELECT DISTINCT 
	user_id,
	user_name,
	MAX(interval_login_sec) OVER w AS max_interval_login_sec
FROM it
WINDOW w AS (PARTITION BY user_id);

/*
3. Вывести для каждого пользователя разницу по времени между первым и последним входом
*/

SELECT DISTINCT 
	user_id,
	user_name,
	TO_SECONDS(MAX(login_datetime) OVER w) - TO_SECONDS(MIN(login_datetime) OVER w) AS first_last_diff_sec
FROM `session`
WINDOW w AS (PARTITION BY user_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);

/*
4. Вывести пользователей, выполнивших последний вход среди пользователей своей группы
*/
SELECT DISTINCT
	group_id,
	FIRST_VALUE(user_name) OVER w AS user_name,
	FIRST_VALUE(login_datetime) OVER w AS last_user_login
FROM `session`
WINDOW w AS (PARTITION BY group_id ORDER BY login_datetime DESC);

/*
5. Вывести таблицу вида:
19.09	20.09	21.09
user_name1	1	0	1
user_name2	1	1	0
где 1/0 - был/не был вход
*/

/*
6. Вывести таблицу вида:
12-16.09	19-23.09
user_name1	10	5
user_name2	7	3
где число - количество входов в неделю

(интервалы дат указаны произвольным образом, могут быть любыми. Вместо дат начала/окончания недели можно вывести порядковый номер недели или дату понедельника)
*/