CREATE KEYSPACE test WITH REPLICATION={'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE test.days_worked_by_previous_employees_by_job_title (
    job_title text,
    employee_name text,
    employee_id uuid,
    number_of_days_worked int,
    PRIMARY KEY (job_title, employee_name)
) WITH CLUSTERING ORDER BY (employee_name ASC);