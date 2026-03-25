--запити з використанням підзапитів

--знайти відділи, у яких максимальна патня > 4000
--SELECT position_in_wing, MAX(salary) AS max_salary
--FROM job
--GROUP BY position_in_wing
--HAVING MAX(salary)>4000;

--вивести користувачів, що лишили >2 відгуків
--SELECT u.nickname, COUNT(r.review_id) as review_count
--FROM user_ u
--	full outer join review r ON u.nickname=r.reviewer
--GROUP BY u.nickname
--HAVING  COUNT(r.review_id) > 2;


--вивести список релізів з оцінкою більше середнього
--SELECT project_release, release_version, rating
--FROM release_
--WHERE rating>(
--	SELECT AVG(rating)
--	FROM release_
--)
--ORDER BY rating ASC, project_release;

--вивести бета-версії що знаходяться на тадії розробки
--SELECT *
--FROM beta_branch
--WHERE beta_version IN (
--	SELECT beta_version
--	FROM beta_branch
--	WHERE stage='в розробці'
--);



--вивести назви релізів, і кількість відгуків, якщо реліз має принаймні один позитивний
--SELECT review_of_project, COUNT(*) AS numbers_of_review
--FROM review
--WHERE review_of_project IN (
--	SELECT review_of_project
--	FROM review
--	WHERE grade='позитивний'
--)
--GROUP BY review_of_project;

--вивести список проєктів з profit більше середнього
--SELECT title, profit
--FROM project
--WHERE profit>(
--	SELECT AVG(profit)
--	FROM project
--)
--ORDER BY title DESC;