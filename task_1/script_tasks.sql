USE user_session;

/*
1. Вывести для каждого пользователя 3 последних логина за последние 7 дней
*/

-- Решение в виде сводной таблицы
WITH ll AS (
	SELECT DISTINCT 
		user_id,
		NTH_VALUE (login_datetime, 3) OVER W AS `last_login - 2`,
		NTH_VALUE (login_datetime, 2) OVER W AS `last_login - 1`,
		FIRST_VALUE(login_datetime) OVER w AS last_login
	FROM `session`
	WHERE login_datetime >= CURRENT_TIMESTAMP() - INTERVAL 7 DAY 
	WINDOW w AS (PARTITION BY user_id ORDER BY login_datetime DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 3 FOLLOWING)
)

SELECT
	u.id,
	ll.last_login,
	ll.`last_login - 1`,
	ll.`last_login - 2`
FROM `user` AS u
LEFT JOIN ll ON u.id = ll.user_id
ORDER BY u.id
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
WITH tfd AS (
	SELECT DISTINCT 
		user_id,
		DAYOFMONTH(login_datetime) = 19 AS `19`,
		DAYOFMONTH(login_datetime) = 20 AS `20`,
		DAYOFMONTH(login_datetime) = 21 AS `21`
	FROM `session`
	WHERE MONTH(login_datetime) = 9 AND DAYOFMONTH(login_datetime) IN  (19, 20, 21)
	ORDER by user_id 
),
pvt AS (
	SELECT DISTINCT 
		user_id,
		FIRST_VALUE(`19`) OVER (PARTITION BY user_id ORDER BY `19`) AS `19.09`,
		FIRST_VALUE(`20`) OVER (PARTITION BY user_id ORDER BY `20`) AS `20.09`,
		FIRST_VALUE(`20`) OVER (PARTITION BY user_id ORDER BY `21`) AS `21.09`
	FROM tfd
)

SELECT
	u.user_name,
	IFNULL(pvt.`19.09`, 0) AS `19.09`,
	IFNULL(pvt.`20.09`, 0) AS `20.09`,
	IFNULL(pvt.`21.09`, 0) AS `21.09`
FROM `user` AS u
LEFT JOIN pvt ON u.id = pvt.user_id
; 

/*
6. Вывести таблицу вида:
12-16.09	19-23.09
user_name1	10	5
user_name2	7	3
где число - количество входов в неделю

(интервалы дат указаны произвольным образом, могут быть любыми. Вместо дат начала/окончания недели можно вывести порядковый номер недели или дату понедельника)
*/

WITH tfw AS (
	SELECT  
		user_id,
		WEEK(login_datetime) = 36 AS `36`,
		WEEK(login_datetime) = 37 AS `37`,
		WEEK(login_datetime) = 38 AS `38`,
		WEEK(login_datetime) = 39 AS `39`
	FROM `session`
	ORDER by user_id 
),
pvt AS (
	SELECT DISTINCT 
		user_id,
		sum(`36`) OVER (PARTITION BY user_id, `36`) AS `36`,
		sum(`37`) OVER (PARTITION BY user_id, `37`) AS `37`,
		sum(`38`) OVER (PARTITION BY user_id, `38`) AS `38`,
		sum(`39`) OVER (PARTITION BY user_id, `39`) AS `39`
	FROM tfw
)

SELECT DISTINCT 
	u.user_name,
	FIRST_VALUE(IFNULL(pvt.`36`, 0)) OVER (PARTITION BY user_id ORDER BY `36` DESC) AS `36 week`,
	FIRST_VALUE(IFNULL(pvt.`37`, 0)) OVER (PARTITION BY user_id ORDER BY `37` DESC) AS `37 week`,
	FIRST_VALUE(IFNULL(pvt.`38`, 0)) OVER (PARTITION BY user_id ORDER BY `38` DESC) AS `38 week`,
	FIRST_VALUE(IFNULL(pvt.`39`, 0)) OVER (PARTITION BY user_id ORDER BY `39` DESC) AS `39 week`
FROM `user` AS u
LEFT JOIN pvt ON u.id = pvt.user_id
; 
