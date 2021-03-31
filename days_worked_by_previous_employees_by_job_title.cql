CREATE KEYSPACE test WITH REPLICATION={'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE test.days_worked_by_previous_employees_by_job_title (
    job_title text,
    employee_name uuid,
    employee_name text,
    number_of_days_worked int,
    PRIMARY KEY (job_title, employee_id)
) WITH CLUSTERING ORDER BY (employee_id ASC);
