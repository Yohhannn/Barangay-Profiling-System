CREATE DATABASE barangay_marigondon_overhaul_data;

CREATE TABLE SYSTEM_ACCOUNT (
    SYS_USER_ID      INTEGER         PRIMARY KEY,
    SYS_USER_PIN     INTEGER         NOT NULL,
    SYS_USER_FNAME   VARCHAR(50)     NOT NULL,
    SYS_USER_LNAME   VARCHAR(50)     NOT NULL,
    SYS_USER_MI      CHAR(1)         NOT NULL
);

INSERT INTO SYSTEM_ACCOUNT (SYS_USER_ID, SYS_USER_PIN, SYS_USER_FNAME, SYS_USER_LNAME, SYS_USER_MI)
VALUES
    (1, 123, 'John', 'Doe', 'A'),
    (2, 111111, 'Rexshimura', 'Zahard', 'P'),
    (3, 000000, 'Diddy', 'Nigga', 'X');

INSERT INTO SYSTEM_ACCOUNT (SYS_USER_ID, SYS_USER_PIN, SYS_USER_FNAME, SYS_USER_LNAME, SYS_USER_MI)
VALUES
	(4, 111111, 'Yizaha', 'Vhalthasar', 'X');

CREATE TABLE ETHNICITY(
    ETH_ID INT PRIMARY KEY,
    ETH_TRIBE_NAME VARCHAR(30) NOT NULL
);

CREATE TABLE RELIGION(
    REL_ID INT PRIMARY KEY,
    REL_NAME VARCHAR(30) NOT NULL
);

ALTER TABLE SYSTEM_ACCOUNT
ADD COLUMN SYS_PERMISSION VARCHAR(10) NOT NULL DEFAULT 'NORMAL'
CHECK (SYS_PERMISSION IN ('NORMAL', 'ADMIN'));

UPDATE SYSTEM_ACCOUNT
SET SYS_PERMISSION = 'ADMIN'
WHERE SYS_USER_ID = 4;

SELECT * FROM ETHNICITY;
SELECT * FROM RELIGION;
SELECT * FROM SYSTEM_ACCOUNT;
