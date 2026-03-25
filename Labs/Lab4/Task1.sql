--містять агрегаційні функції

--середня платня у відділі
--SELECT position_in_wing, AVG(salary)
--FROM job
--GROUP BY position_in_wing;

--мінімальна зарплата у відділі
--SELECT position_in_wing, MIN(salary)
--FROM job
--GROUP BY position_in_wing;

--сумарна зарплата на відділ
--SELECT position_in_wing, SUM(salary)
--FROM job
--GROUP BY position_in_wing;

--мінімальний рейтинг проєкту
--SELECT project_release, MIN(rating)
--FROM release_
--GROUP BY project_release;

--середній рейтинг для всіх версій проєкту
SELECT project_release, AVG(rating)
FROM release_
GROUP BY project_release;

--середня робоча сила
--SELECT AVG(workforce)
--FROM wing;

--кількість коритсувачів кожного проєкту
--SELECT tested_project, COUNT(tester)
--FROM outside_testers
--GROUP BY tested_project;