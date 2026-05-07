CREATE TABLE investment (
    id int PRIMARY KEY,
    name varchar(70) not NULL,
    amount int NOT NULL,
    date_ date NOT NULL,
    project int,

    CONSTRAINT fk_project
        FOREIGN KEY (project)
        REFERENCES project(project_id)
        on DELETE SET NULL
        on UPDATE CASCADE
);