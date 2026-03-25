-- різні типи джоінів

--кількість працівників, що посідають однакову посаду
--SELECT j.job_name, COUNT(c.worker)
--FROM contract c
--	inner join job j ON c.job=j.job_id
--GROUP BY j.job_name;

--ВИВЕСТИ ТАБЛИЦЮ contract з іменами працівників, назвами посад та їхнім рангом
--SELECT w.worker_name, j.job_name, j.rank_, c.start_time, c.end_time, c.state_
--FROM contract c
--	left join job j ON c.job=j.job_id
--	left join worker w ON c.worker=w.worker_id


--вивести працівників і продемонструвати, які працівники є керівниками і яких відділів
--SELECT wo.worker_name, wi.wing_name
--FROM worker wo
--	full outer join wing wi ON wo.worker_id=wi.wing_head


--вивести контактну інформацію всіх керівників відділів
--SELECT wo.worker_name, wo.email, wi.wing_name
--FROM worker wo
--	right join wing wi ON wi.wing_head=wo.worker_id;