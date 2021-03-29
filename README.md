# example-cassandra-dsbulk-with-sed-and-awk

Learn how to combine the [DataStax Bulk Loader](https://docs.datastax.com/en/dsbulk/doc/dsbulk/reference/dsbulkCmd.html) with sed and awk to do Cassandra data operations.

In this walkthrough, we will be using dsbulk to unload data from a [DataStax Astra](http://astra.datastax.com/) instance, do data transformations using awk and sed, and then load it into a Dockerized Apache Cassandra instance. You can do this walkthrough with any combination of 2 Cassandra distrubutions of the following types: Apache Cassandra, DataStax Enterprise, and DataStax Astra as well as moving data within the same instance. More on that [here](https://docs.datastax.com/en/dsbulk/doc/dsbulk/reference/dsbulkCmd.html). If you are working with deployed instances, you can use their contact points and more on that can be found [here](https://docs.datastax.com/en/dsbulk/doc/dsbulk/reference/commonOptions.html).

## Prerequisites
- DataStax Astra
- DataStax Bulk Loader (make sure to add to PATH)
- Docker
- GNU awk
- GNU sed

## 1. Clone this repo and `cd` into it
```bash
git clone https://github.com/Anant/example-cassandra-dsbulk-with-sed-and-awk.git
```
```bash
cd example-cassandra-dsbulk-with-sed-and-awk
```

## 2. Set-up DataStax Astra

### 2.1 - Sign up for a free DataStax Astra account if you do not have one already

### 2.2 - Hit the `Create Database` button on the dashboard

### 2.3 - Hit the `Get Started` button on the dashboard
This will be a pay-as-you-go method, but they won't ask for a payment method until you exceed $25 worth of operations on your account. We won't be using nearly that amount, so it's essentially a free Cassandra database in the cloud.

### 2.4 - Define your database
- Database name: whatever you want
- Keyspace name: `test`
- Cloud: whichever GCP region applies to you. 
- Hit `create database` and wait a couple minutes for it to spin up and become `active`.

### 2.5 - Generate application token
- Once your database is active, connect to it. 
- Once on `dashboard/<your-db-name>`, click the `Settings` menu tab. 
- Select `Admin User` for role and hit generate token. 
- **COPY DOWN YOUR CLIENT ID AND CLIENT SECRET** as they will be used by dsbulk

### 2.6 - Download `Secure Bundle`
- Hit the `Connect` tab in the menu
- Click on `Node.js` (doesn't matter which option under `Connect using a driver`)
- Download `Secure Bundle`
- Move `Secure Bundle` into the cloned directory.

### 2.7 - Load CSV data
- Hit the `Upload Data` button
- Drag-n-drop the `previous_employees_by_title.csv` file into the section.
- Once uploaded successfully, hit the `Next` button
- Make sure the table name is called `previous_employees_by_title`
- Change `employee_id` from text to uuid
- Change `first_day` and `last_day` to timestamp
- Select `job_title` as the Partition Key
- Select `employee_name` as the clustering column
- Hit the `Next` button
- Select `test` as the target keyspace
- Hit the `Next` button to begin loading the csv. 
- If the upload fails, just try it again and it should work by the 2nd try.

## 3. Setup Dockerized Apache Cassandra

### 3.1 - Start docker container, expose port 9042, and mount this directory to the root of the container.
```bash
docker run --name cassandra -p 9042:9042 -d -v "$(pwd)":/example-cassandra-dsbulk-with-sed-and-awk cassandra:latest
```

### 3.1 - Create Destination Table
```bash
docker exec -it cassandra cqlsh
```
```bash
source '/example-cassandra-dsbulk-with-sed-and-awk/days_worked_by_previous_employees_by_job_title.cql'
```

## 4. Extract, Transform, and Load from DataStax Astra to Dockerized Apache Cassandra with dsbulk, sed, and awk.
We will cover 2 methods for loading data into Dockerized Apache Cassandra after unloading it from DataStax Astra. The first method breaks up the unloading and loading steps into 2 seperate methods. The second method does everything in one pipe. The scenario is as follows: Someone on our team wants us to take the `previous_employees_by_title` table and create a new table that has the time worked in days instead of a start time and end time. **NOTE:** This can be done within the same instance, but for the purposes of showing more of what dsbulk can do, we opted for moving data between DataStax Astra and a Dockerized instance of Apache Cassandra.

### 4.1 - Unload to CSV file after extracting and transforming.
In this command, we are unloading from DataStax Astra, running an awk script, doing a sed transformation, and then writing the output to a CSV. The awk script cleans up the timestamp format of the `first_day` and `last_day` columns so that we can use the `mktime()` function to calculate the time in number of seconds. Then, the script prints out the first 3 columns and then the calculated duration of time worked in days per row. We also have some conditionals saying if that the value returned is negative, then make it positive. This occurred because we used a CSV generator and calculated random datetimes for those 2 columns for ~100,000 rows. Then, we use sed to fix the header that awk spits out with what we want for the destination table and write the output to a new CSV called `days_worked_by_previous_employees_by_job_title.csv`.

**NOTE:** Input your specific variables for the placeholders in the command

```bash
dsbulk unload -k test -t previous_employees_by_title -b "/path/to/secure-connect-<db>.zip" -u <Client ID> -p <Client Secret> | gawk -F, -f duration_calc.awk | sed 's/job_title,employee_name,employee_id,0/job_title,employee_name,employee_id,number_of_days_worked/' > days_worked_by_previous_employees_by_job_title.csv
```

### 4.2 - Load via CSV file to Dockerized Apache Cassandra Instance
```bash
dsbulk load -url /path/to/example-cassandra-dsbulk-with-sed-and-awk/days_worked_by_previous_employees_by_job_title.csv -k test -t days_worked_by_previous_employees_by_job_title
```

### 4.3 - Confirm via CQLSH
```bash
select count(*) from test.days_worked_by_previous_employees_by_job_title ;
```

### 4.3 - Truncate table
```bash
truncate table test.days_worked_by_previous_employees_by_job_title ;
```

### 4.4 - Do everything in one command
```bash
dsbulk unload -k test -t previous_employees_by_title -b "/path/to/secure-connect-<db>.zip" -u <Client ID> -p <Client Secret> | gawk -F, -f duration_calc.awk | sed 's/job_title,employee_name,employee_id,0/job_title,employee_name,employee_id,number_of_days_worked/' | dsbulk load -k test -t days_worked_by_previous_employees_by_job_title
```

### 4.5 - Confirm via CQLSH
```bash
select count(*) from test.days_worked_by_previous_employees_by_job_title ;
```

And that wraps up how we can quickly do some Cassandra data operations using dsbulk, awk, and sed.

## Additional Resources
- Live Walkthrough
- Accompanying Blog
- Accompanying SlideShare
- https://github.com/datastax/dsbulk
- https://docs.datastax.com/en/dsbulk/doc/dsbulk/reference/dsbulkCmd.html
- https://docs.datastax.com/en/dsbulk/doc/dsbulk/install/dsbulkInstall.html
- https://www.datastax.com/blog/introducing-datastax-bulk-loader
- https://www.datastax.com/blog/datastax-bulk-loader-more-loading
- https://www.datastax.com/blog/datastax-bulk-loader-examples-loading-other-locations
- https://docs.datastax.com/en/astra/docs/loading-and-unloading-data-with-datastax-bulk-loader.html
