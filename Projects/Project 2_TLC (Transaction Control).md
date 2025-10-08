## Project 2: TLC (Transaction Control)
#### 1. In my SQL Server, create a database named "transaction_control". Set charset=utf8mb4 and collation=utf8mb4_unicode_ci.
```sql
CREATE DATABASE transaction_control CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 2. Create table: account

- Originally, account1 and account 2 have $1000 separately.

```sql
CREATE TABLE transaction_control.account(
    id int UNSIGNED PRIMARY KEY,
    balance double unsigned
);

-- add values into account
INSERT INTO transaction_control.account(id, balance)
VALUES (1,1000),
       (2,1000);
```

#### 3. Create table: transfer

```sql
CREATE TABLE transaction_control.transfer(
    id int UNSIGNED PRIMARY KEY,
    from_account_id int unsigned,
    to_account_id int unsigned,
    amount double
); 
```
#### 4. Start Transaction
- Transfer $450 from acocunt1 to account 2, which means that:
    - the transaction occur once
    - account1 amount -450
    - account 2 ammount +450

```sql
START TRANSACTION; 
INSERT INTO transaction_control.transfer(id, from_account_id, to_account_id, amount)
VALUES (1,1,2,450);
```
#### 5. Update account

```sql
UPDATE transaction_control.account
SET balance = balance - 450
WHERE id = 1;

UPDATE transaction_control.account
SET balance = balance + 450
WHERE id = 2;
```
#### 6. Observe the result

```sql
SELECT * FROM transaction_control.account;
SELECT * FROM transaction_control.transfer;
```






```
