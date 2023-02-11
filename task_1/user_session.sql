DROP DATABASE IF EXISTS user_session;
CREATE DATABASE user_session;

USE user_session;

DROP TABLE IF EXISTS `group`;
CREATE TABLE `group` (
	id SERIAL PRIMARY KEY,
	group_name VARCHAR(100) UNIQUE NOT NULL,
	
	INDEX group_name_idx(group_name)
)  COMMENT = "Таблица групп";

DROP TABLE IF EXISTS `user`;
CREATE TABLE user (
	id SERIAL PRIMARY KEY,
	user_name VARCHAR(100) UNIQUE NOT NULL,
	group_id BIGINT UNSIGNED,
	
	FOREIGN KEY (group_id) REFERENCES `group`(id) ON DELETE SET NULL ON UPDATE CASCADE,
	
	INDEX users_name_idx(user_name)
	) COMMENT = "Таблица пользователей";
	
DROP TABLE IF EXISTS authorization_time;
CREATE TABLE authorization_time (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	login_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	FOREIGN KEY (user_id) REFERENCES `user`(id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = "Старт сессии пользователя";

CREATE OR REPLACE VIEW `session` AS (
SELECT
	a_t.user_id,
	u.user_name,
	a_t.login_datetime,
	u.group_id
FROM authorization_time as a_t
LEFT JOIN `user` AS u ON 
	a_t.user_id = u.id
);

