## Project 1: Create, Alter, Modify table

#### 1. Create a database named "cloned_covid19". Assigned charset = utf8mb4 and collation = utf8mb4_unicode_ci

```sql
CREATE DATABASE cloned_covid19 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;  
```
#### 2. Create a Table named locations. Import the dataset (a csv file) and make sure all of the data types are corrected matching.
```sql
CREATE TABLE cloned_covid19.locations(
    id int unsigned,
    country_name varchar(200),
    province_name varchar(200),
    iso2 char(2),
    iso3 char(3),
    latitude float,
    longitude float,
    population bigint
);
```sql
- import files
- choose the file
- customize. configure metadata structure
  
<img src="pictures/01.png" width="50%">

#### 3. In Table locations the 496th rows is a null in column iso2. Update null into 'NA'.

```sql
UPDATE locations
SET iso3 = 'NA'
WHERE id = 496;

-- check if id 496 iso3 = 'NA'
SELECT * FROM locations
WHERE id = 496;
```

#### 4.Update iso2, iso3 and province_name. Use 'NULL' if there is null in the data.
```sql
UPDATE locations
SET province_name = 'NULL'
WHERE province_name IS NULL;

UPDATE locations
SET iso2 = 'NULL'
WHERE province_name IS NULL;

UPDATE locations
SET iso3 = 'NULL'
WHERE province_name IS NULL;
```
#### 5. Add a constraint. ID in the table needs to be PRIMARY KEY
```sql
ALTER TABLE cloned_covid19.locations
ADD PRIMARY KEY(id);
```

#### 6. Import another table named 'accumulative_cases'. Match the required data type as belowed.

id int unsigned,
calendar_id int unsigned,
location_id int unsigned,
confirmed bigint,
deaths bigint

<img src="pictures/02.png" width="50%">


- import the data as we've previously demonstrated.
- This time, I find that all of the data type is correct. Just make some adjustment regarding 'UNSIGNED'.

#### 7. In table accumulative_cases, add PRIMARY KEY to id.
```sql
ALTER TABLE cloned_covid19.accumulative_cases
ADD CONSTRAINT PRIMARY KEY(id);
```

#### 8. Add a foreign key. Use locaiton_id in accumulative_cases and make a constraint named 'fk_accumulative_cases_locations' to have references on id in the locaiton table.

- In the beginning, I cannot successfully run the foreign key code because the system error shows that -> SQL Error [3780] [HY000]: Referencing column 'location_id' and referenced column 'id' in foreign key constraint 'fk_accumulative__locations' are incompatible.
- To fix the incompatible issue, id in accumulative_cases table is 'int UNSIGNED' but id in location table is 'INT'. We need to fix that first.

```sql
ALTER TABLE cloned_covid19.accumulative_cases
MODIFY location_id INT;
```
- Now, data types of the two foreign keys are the same, so we can make the foreign key.
```sql
ALTER TABLE cloned_covid19.accumulative_cases
ADD CONSTRAINT fk_accumulative__locations FOREIGN KEY(location_id) REFERENCES locations(id);
```


