-- очистка старих таблиць і типів
DROP TABLE IF EXISTS contract CASCADE;
DROP TABLE IF EXISTS job CASCADE;
DROP TABLE IF EXISTS working_on CASCADE;
DROP TABLE IF EXISTS wing CASCADE;
DROP TABLE IF EXISTS beta_branch CASCADE;
DROP TABLE IF EXISTS review CASCADE;
DROP TABLE IF EXISTS user_ CASCADE;
DROP TABLE IF EXISTS release_ CASCADE;
DROP TABLE IF EXISTS project CASCADE;
DROP TABLE IF EXISTS worker CASCADE;
DROP TABLE IF EXISTS outside_testers CASCADE;

DROP TYPE IF EXISTS contract_status CASCADE;
DROP TYPE IF EXISTS job_rank CASCADE;
DROP TYPE IF EXISTS working_on_stage CASCADE;
DROP TYPE IF EXISTS beta_branch_status CASCADE;
DROP TYPE IF EXISTS review_status CASCADE;
DROP TYPE IF EXISTS user_status CASCADE;
DROP TYPE IF EXISTS project_type CASCADE;

create table if not exists worker(
  worker_id serial PRIMARY KEY, --Унікальний код для кожного працівника
  worker_name varchar(64) NOT NULL,
  email varchar(64) unique NOT NULL, --Електронна пошта має бути унікальною
  phone char(12) unique NOT NULL, --Номер телефону має бути унікальним
  date_of_birth date NOT NULL
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'project_type') THEN
        create type project_type as enum ('гра','графічний редактор','веб-сайт','система обліку','система тестування','мобільний додаток','консольна гра','desktop-застосунок');
    END IF;
END$$;

create table if not exists project(
  title varchar(40) PRIMARY KEY, --Проєкт має бути названий унікально
  budget int NOT NULL CHECK (budget > 0), --Студія не розробляти проєкти без бюджету, тому він має бути > 0
  profit int NOT NULL,
  type_ project_type
);

create table if not exists release_(
  release_version numeric(2,1), --Версія є десятковим дробом з однією цифорю після коми
  rating numeric(2,1) CHECK (rating>0 AND rating<10), --Рейтинг є десятковим дробом за десятибальною шкалою
  project_release varchar(30) NOT NULL references project(title), --Зовнішній ключ, що посилається на project(title)
  primary key(release_version, project_release) --Композитний ключ, що поєднує release_version та project_release
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        create type user_status as enum ('відійшов','активний','неактивний');
    END IF;
END$$;

create table if not exists user_(
  nickname varchar(50) PRIMARY KEY, --Ім'я користувача має бути унікальним, оскільки є первинним ключем
  status user_status NOT NULL,
  activation_date date NOT NULL  
);

create table if not exists outside_testers(
	tester varchar(50),
	tested_project varchar(30),
	tested_version numeric(2,1),

	primary key(tester,tested_project,tested_version),
	
	foreign key(tester)
		references user_(nickname),
	foreign key(tested_project, tested_version)
		references release_(project_release,release_version)
);


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'review_status') THEN
        create type review_status as enum ('позитивний','негативний','нейтральний');
    END IF;
END$$;

create table if not exists review(
  review_id serial PRIMARY KEY, --Номер відгуку у системі, є первинним ключем
  review_body text,
  review_date date NOT NULL,
  grade review_status NOT NULL,
  reviewer varchar(50) NOT NULL, --Зовнішній ключ
  review_of_project varchar(30) NOT NULL, --Зовнішній ключ
  review_of_version numeric(2,1) NOT NULL, --Зовнішній ключ
  foreign key(reviewer,review_of_project,review_of_version) -- Зовнішні ключі, outside_testers(tester,tested_project, tested_version)
    references outside_testers(tester,tested_project, tested_version)
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'beta_branch_status') THEN
        create type beta_branch_status as enum ('в розробці','остання','застаріла');
    END IF;
END$$;

create table if not exists beta_branch(
  beta_version serial PRIMARY KEY, --Номер бета версії, первинний ключ
  stage beta_branch_status NOT NULL,
  changelog text NOT NULL,
  beta_of_project varchar(30) NOT NULL, --Зовнішній ключ
  version_of_the_release numeric(2,1) NOT NULL, --Зовнішній ключ
  foreign key(beta_of_project,version_of_the_release)  -- Зовнішні ключі, посилання на release_(project_release,release_version)
    references release_(project_release,release_version)
);

create table if not exists wing(
  wing_name varchar(40) PRIMARY KEY, --Назва відділу є первинним ключем
  workforce int NOT NULL CHECK (workforce > 0), --Для існування відділу він має містити хоч одного працівника
  wing_head int NOT NULL references worker(worker_id), --Зовнішній ключ, посилання на worker(worker_id)
  amendment int references beta_branch(beta_version)  --Зовнішній ключ, посилання на beta_branch(beta_version)
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'working_on_stage') THEN
        create type working_on_stage as enum ('аналіз вимог','проєктування','реалізація','технічний супровід','тестування');
    END IF;
END$$;

create table if not exists working_on( --зв'язок багато-до-багатьох між сутностями project, wing
  project_ varchar(40) not null references project(title),
  wing_ varchar(40) not null references wing(wing_name),
  stage working_on_stage,
  primary key(project_, wing_, stage) --Композитний ключ, посилання на project_, wing_, stage
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_rank') THEN
        create type job_rank as enum ('junior','middle','senior');
    END IF;
END$$;
create table if not exists job(
  job_id serial PRIMARY KEY, --Первинний ключ
  job_name varchar(40) NOT NULL,
  salary int CHECK (salary > 0) NOT NULL, --Платня має бути більшою за 0
  rank_ job_rank,
  position_in_wing varchar(40) NOT NULL references wing(wing_name)
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contract_status') THEN
        create type contract_status as enum ('дійсний','закритий','подовжений','перерваний');
    END IF;
END$$;

create table if not exists contract( --Асоціативна сутність 
  worker int NOT NULL references worker(worker_id),
  job int NOT NULL references job(job_id),
  start_time date NOT NULL,
  end_time date NOT NULL,
  state_ contract_status,
  primary key (worker, job) --Композитний ключ, посилання на worker, job
);

-- ЗАПОВНЕННЯ ТАБЛИЦЬ
INSERT INTO worker(worker_id,worker_name,email,phone,date_of_birth) VALUES
  (1, 'Jack','jack@gmail.com','012345678901','1999-01-01'),
  (2, 'Mary','mary@gmail.com','012345678902','2002-05-01'),
  (3, 'Lucy','lucy@gmail.com','012345678903','2000-08-03'),
  (4, 'John','john@gmail.com','012345678904','1998-02-14'),
  (5, 'Anna','anna@gmail.com','012345678905','2001-06-21'),
  (6, 'Peter','peter@gmail.com','012345678906','1997-11-30'),
  (7, 'Sofia','sofia@gmail.com','012345678907','2003-04-12'),
  (8, 'Mark','mark@gmail.com','012345678908','1996-09-09'),
  (9, 'Emma','emma@gmail.com','012345678909','2000-12-01'),
  (10,'David','david@gmail.com','012345678910','1995-07-17'),
  (11,'Leo','leo@gmail.com','012345678911','1994-03-03'),
  (12,'Mia','mia@gmail.com','012345678912','2002-08-08'),
  (13,'Nick','nick@gmail.com','012345678913','1993-11-11');

INSERT INTO project(title,budget,profit,type_) VALUES
  ('StarCRAFT', 10000000, 9000000,'гра'),
  ('Khoot',4,3,'веб-сайт'),
  ('Paint',1,10000,'графічний редактор'),
  ('APelsinze',50000,250000,'консольна гра'),
  ('SBO',100,200,'desktop-застосунок'),
  ('DECSTOPhELPER',10000,10001,'desktop-застосунок'),
  ('neverBORNE',52430,52430000,'консольна гра'),
  ('CAMPUSWAMPUS',453,354,'система обліку'),
  ('ALFRED',1,7,'система тестування'),
  ('duobank',4000,17600000,'мобільний додаток'),
  ('50gram',37,1850,'мобільний додаток'),
  ('HARMONY',200000,43,'веб-сайт'),
  ('chatLGBT',75420133,1,'веб-сайт');

INSERT INTO release_(release_version,rating,project_release) VALUES
  (1.0,9.8,'APelsinze'),
  (2.0,5.6,'APelsinze'),
  (3.0,5.0,'APelsinze'),
  (1.0,1.6,'Paint'),
  (1.0,7.2,'StarCRAFT'),
  (2.0,6.9,'StarCRAFT'),
  (1.0,1.1,'Khoot'),
  (1.0,7.1,'SBO'),
  (1.0,3.1,'DECSTOPhELPER'),
  (1.0,1.7,'neverBORNE'),
  (1.0,2.9,'CAMPUSWAMPUS'),
  (1.0,9.7,'ALFRED'),
  (1.0,1.1,'duobank'),
  (2.0,7.3,'duobank'),
  (3.0,9.9,'duobank'),
  (1.0,8.0,'50gram'),
  (2.0,5.0,'50gram'),
  (1.0,2.0,'HARMONY'),
  (1.0,9.8,'chatLGBT'),
  (2.0,9.8,'chatLGBT');

INSERT INTO user_(nickname,status,activation_date) VALUES
  ('valdzemarus','неактивний','1948-03-02'),
  ('IGOR_KOLOMOISKYI_1963','активний','2016-12-19'),
  ('user123','активний', '2001-09-05'),
  ('aaaaaa568','відійшов','2008-08-08'),
  ('Lihozor','відійшов','2020-01-11'),
  ('Horr','активний','2019-02-02'),
  ('Capella','неактивний','2024-05-06');

INSERT INTO outside_testers(tester, tested_project, tested_version) VALUES
	('valdzemarus','APelsinze',1.0),
	('valdzemarus','neverBORNE',1.0),
	('valdzemarus','ALFRED',1.0),
	('valdzemarus','Paint',1.0),
	('Lihozor','50gram',2.0),
	('Lihozor','chatLGBT',1.0),
	('Lihozor','SBO',1.0),
	('Lihozor','CAMPUSWAMPUS',1.0),
	('Horr','SBO',1.0),
	('Horr','50gram',1.0),
	('Horr','DECSTOPhELPER',1.0),
	('Horr','ALFRED',1.0),
	('Capella','duobank',1.0),
	('Capella','50gram',1.0),
	('Capella','chatLGBT',1.0),
	('Capella','chatLGBT',2.0),
	('user123','Paint',1.0),
	('user123','HARMONY',1.0),
	('aaaaaa568','StarCRAFT',2.0),
	('aaaaaa568','Khoot',1.0),
	('aaaaaa568','APelsinze',1.0),
	('IGOR_KOLOMOISKYI_1963','chatLGBT', 2.0),
	('IGOR_KOLOMOISKYI_1963','duobank', 2.0),
	('IGOR_KOLOMOISKYI_1963','duobank', 3.0);
	

INSERT INTO review(review_id, review_body, review_date,grade,reviewer,review_of_project,review_of_version) VALUES
  (1,'good','1948-03-03','позитивний','valdzemarus','APelsinze',1.0),
  (2,'does not have part two','1988/03/03','негативний','valdzemarus','neverBORNE',1.0),
  (3,'better than Jenkins','1948-03-03','позитивний','valdzemarus','ALFRED',1.0),
  (4,'base, fundamental','1948-03-03','позитивний','valdzemarus','Paint',1.0),
  (5,'causes cancer 0/10','2020-01-13','негативний','Lihozor','50gram',2.0),
  (6,'рекомендую сімї і дітям','2020-01-14','позитивний','Lihozor','chatLGBT',1.0),
  (7,'записав свою пику, 10/10','2020-01-15','позитивний','Lihozor','SBO',1.0),
  (8,'рекомендую ворогам і хейтерам','2020-01-16','негативний','Lihozor','CAMPUSWAMPUS',1.0),
  (9,'немає ШІ','2005-10-10','негативний','user123','Paint',1.0),
  (10,'додайте ШІ','2006-11-11','негативний','user123','Paint',1.0),
  (11,'не APelsinze','2009-02-03','негативний','aaaaaa568','StarCRAFT',2.0),
  (12,'записав свою пику, 10/10','2020-01-15','позитивний','Horr','SBO',1.0),
  (13,'ljlfqnt hjv-rjke','2020-02-16','позитивний','Horr','50gram',1.0),
  (14,'вкрав мою картку','2020-03-11','негативний','Horr','DECSTOPhELPER',1.0),
  (15,'+: не Jenkins, -:мій відгук купили','2020-04-13','позитивний','Horr','ALFRED',1.0),
  (16,'не знає як повернути приват банк','2016-12-19','негативний','IGOR_KOLOMOISKYI_1963','chatLGBT', 2.0),
  (17,'НІ націоналізації банків!','2017-12-20','позитивний','IGOR_KOLOMOISKYI_1963','duobank', 2.0),
  (18,'прозоре відмивання коштів','2018-12-25','позитивний','IGOR_KOLOMOISKYI_1963','duobank', 3.0);

INSERT INTO beta_branch(beta_version,stage,changelog,beta_of_project,version_of_the_release) VALUES
	(1,'застаріла','тестування бойової системи','APelsinze',1.0),
	(2,'остання','моніторинг системи збереження','APelsinze',2.0),
	(3,'в розробці','написання скрипта для зміненої концепції системи збереження','APelsinze',3.0),
	(4,'остання','тестування вбудованих інструментівв','Paint',1.0),
	(5,'застаріла','3Д моделювання','StarCRAFT',1.0),
	(6,'в розробці','створення плану реалізації','StarCRAFT',2.0),
	(7,'в розробці','зміна палітри інтерфейсу','Khoot',1.0),
	(8,'в розробці','зміна інтерфейсу','SBO',1.0),
	(9,'остання','робимо шось корисне' ,'DECSTOPhELPER', 1.0),
	(10,'остання','додаємо болото' ,'neverBORNE', 1.0),
	(11,'остання','прибираємо кампус, додаємо вампуса' ,'CAMPUSWAMPUS', 1.0),
	(12,'застаріла','переписуємо Jenkins' ,'ALFRED', 1.0),
	(13,'остання','пишемо код з нуля' ,'ALFRED', 1.0),
	(14,'застаріла','вирізаємо систему корупційних відносин ','duobank', 1.0),
	(15,'остання','додаємо можливість переглядати придбаних суддів та рахунки за кордоном' ,'duobank', 2.0),
	(16,'остання','додано відмивання коштів','duobank',3.0),
	(17,'застаріла','ДОПОМОЖІТЬ','50gram',1.0),
 	(18,'остання','Все добре','50gram',2.0),
 	(19,'остання','Додали розбрат і платну косметику для профіля','HARMONY',1.0),
	(20,'застаріла','Додано веселку','chatLGBT',1.0),
	(21,'застаріла','Додано ще одну веселку','chatLGBT',2.0),
	(22,'в розробці','Додано ще одну веселку','chatLGBT',2.0);
	
INSERT INTO wing(wing_name,workforce,wing_head,amendment) VALUES
  ('Програмування',6,3,1),
  ('Дизайн',4,6,3),
  ('2Д-арт-відділ',4,8,3),
  ('3Д-арт-відділ',4,9,8),
  ('Звук',3,13,8);
  
INSERT INTO working_on(project_,wing_,stage) VALUES
  ('Paint','Програмування','проєктування'),
  ('Khoot','Дизайн','реалізація'),
  ('StarCRAFT','3Д-арт-відділ','аналіз вимог'),
  ('StarCRAFT','Дизайн','реалізація'),
  ('neverBORNE','Програмування','технічний супровід'),
  ('chatLGBT','2Д-арт-відділ','реалізація'),
  ('duobank','Звук','реалізація'),
  ('50gram','Програмування','аналіз вимог'),
  ('HARMONY','Дизайн','реалізація');


INSERT INTO job(job_id,job_name,salary,rank_,position_in_wing) VALUES
  (1, 'розробник', 5000,'senior','Програмування'),
  (2, 'графічний дизайнер', 3500,'middle','Дизайн'),
  (3, 'художник', 3750,'middle','3Д-арт-відділ'),
  (4, 'саунд-дизайнер', 2700,'junior','Звук'),
  (5, 'концепт-художник', 5000,'middle','2Д-арт-відділ'),
  (6, 'веб-дизайнер', 3450,'middle','Дизайн'),
  (7, 'бухгалтер', 3700,'middle','Програмування'),
  (8, 'саунд-дизайнер', 4400,'middle','Звук'),
  (9, 'розробник', 3000,'junior','Програмування'),
  (10, 'розробник', 4300,'middle','Програмування'),
  (11, 'веб-дизайнер', 3450,'senior','Дизайн');

INSERT INTO contract(worker,job,start_time,end_time,state_) VALUES
  (1,11,'2019-01-01','2029-01-01','дійсний'),
  (2,11,'2022-05-01','2032-05-01','закритий'),
  (3,10,'2020-08-03','2030-08-03','перерваний'),
  (4,10,'2018-02-14','2028-02-14','дійсний'),
  (5,4,'2021-06-21','2031-06-21','закритий'),
  (6,6,'2017-11-30','2027-11-30','перерваний'),
  (7,3,'2023-04-12','2033-04-12','перерваний'),
  (8,5,'2016-09-09','2026-09-09','дійсний'),
  (9,3,'2020-12-01','2030-12-01','дійсний'),
  (10,2,'2015-07-17','2025-07-17','подовжений'),
  (11,7,'2014-03-03','2024-03-03','закритий'),
  (12,1,'2022-08-08','2032-08-08','дійсний'),
  (13,8,'2013-11-11','2023-11-11','закритий'),
  (13,9,'2013-11-11','2023-11-11','закритий');

--SELECT

--мета: вивести з таблиці job перелік посад з рангом (використати concate)
-- очікуваний резаультат: виведення ідентифікатора посади та назви посади разом з рангом
--Select 
--	job_id, 
--	concat(job_name,' ',rank_) as job_name_rank
--from job;

--мета: вивести з таблиці working_on назви усіх проєктів, що знаходяться на стадії розробки: 'реалізація'
--очікуваний результат: виведення 4 проєктів, у яких у колонці stage='реалізація'
--select project_, stage
--from working_on
--where stage='реалізація';


--мета: вивести з таблиці review назви проєктів, що отримали принаймні один позитивний відгук(використати distinct)
--очікуваний результат: виведення назв 7 проєктів, що мають принаймні один позитивний відгук 
--select distinct(review_of_project)
--from review
--where grade='позитивний';

--мета: вивести з таблиці job працівників рангу middle із зарплатнею >3600 і < 4350 (додати сортуваання order by)
--очікуваний результат: виведення всієї інформації з таблиці job для 3 посад, що відповіаютьь умовам, посортованим за збільшенням зарплати
--select *
--from job
--where rank_='middle' AND salary BETWEEN 3600 AND 4350
--order by salary ASC;

--мета: вивести з таблиці job усіх дизайнерів (використати LIKE)
--очікуваний результат: виведення назви посади, рангу та відділу для всіх посад, що у своїй назві мають частку "дизайнер"
--select job_name, rank_, position_in_wing
--from job
--where job_name LIKE '%дизайнер';

--мета / очікуваний результат: вивести з таблиці jobs кількість посад із зарплатнею >3600 (count)
--select count(job_id) as counter
--from job
--where salary > 3600;

--мета: вивести з таблиці outside_testers всіх користувачів будь-якої версії duobank (distinct)
--очікуваний результат: виведення імені користувача та для перевірки відповідного для них значення колонки tested_project
--select distinct(tester), tested_project
--from outside_testers
--where tested_project='duobank';

--мета: вивести з таблиці project усі проєкти у яких profit>budget
--очікуваний результат: виведення назви проєкту та значення profit, budget для переірки правильності виконання
--select title, profit, budget
--from project
--where profit>budget;

--мета: вивести з таблиці review користувачів, що написали відгук до chatLGBT
--очікування: виведення імені користувача та назви проєкту, до якого був залишений відгук, для перевірки правильності виконання
--select reviewer, review_of_project
--from review
--where review_of_project='chatLGBT';

--UPDATE

--мета: оновити таблицю job так щоб платня всіх співробітників >=4000
--очікуваний результат: встановлена мінімальна зарплата 4000 
--update job
--set salary=4000
--where salary < 4000;
--select * from job;

--мета: оновити таблицю project піднявши profit для Khoot
--очікуваний результат: змінене значення profit для проєкту Khoot
--update project
--set profit = 400
--where title = 'Khoot';
--select * from project;

--мета: оновити таблицю user так щоб усі користувачі зі статусом 'відійшов' стали неактивними
--очікуваний результат: статус "відійшов" для всіх користувачів замінено на "неактивний"
--update user_
--set status='неактивний'
--where status='відійшов';
--select * from user_;

--	DELETE

--мета: видалити негативні відгуки з таблиці review
--очікуваний резьтат: видалення усіх негативний відгуків з таблиці review
--delete from review
--where grade='негативний';
--select * from review;

--мета: видалити відгуки, залишені до 2000 року з таблиці review
--очікуваний результат: видалення усіх відгуків, залишених до 2000 року, з таблиці review
--delete from review
--where review_date < '2000-01-01';
--select * from review;

--мета: видалити куплені відгуки з таблиці review
--очікуваний результат: видалення з таблиці review відгуків від користувача 'IGOR_KOLOMOISKYI_1963' для проєкту 'duobank'
--delete from review
--where reviewer='IGOR_KOLOMOISKYI_1963' AND review_of_project='duobank';
--select * from review;


-- ЛАБОРАТОРНА 4

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