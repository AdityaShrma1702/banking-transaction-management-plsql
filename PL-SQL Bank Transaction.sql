
-- ============================================================
-- BANKING TRANSACTION MANAGEMENT SYSTEM
-- Complete Oracle PL/SQL Project
-- Schema: PLSQL_USER
-- Database service: FREEPDB1
--
-- IMPORTANT:
-- 1. This script does not drop existing tables or data.
-- 2. Existing tables and sequences are preserved.
-- 3. Procedures, function, and trigger are created/replaced.
-- 4. Sample transactions are NOT executed automatically.
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- PART 1: CREATE TABLES AND SEQUENCES SAFELY
-- ============================================================

-- 1.1 BANK_ACCOUNTS
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE BANK_ACCOUNTS (
            ACCOUNT_ID NUMBER PRIMARY KEY,
            CUSTOMER_NAME VARCHAR2(100) NOT NULL,
            BALANCE NUMBER(12,2) DEFAULT 0 NOT NULL,
            CREATED_AT DATE DEFAULT SYSDATE
        )';
    DBMS_OUTPUT.PUT_LINE('BANK_ACCOUNTS table created.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE(
                'BANK_ACCOUNTS already exists; preserved.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

-- 1.2 BANK_TRANSACTIONS
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE BANK_TRANSACTIONS (
            TRANSACTION_ID NUMBER PRIMARY KEY,
            ACCOUNT_ID NUMBER NOT NULL,
            TRANSACTION_TYPE VARCHAR2(20) NOT NULL,
            AMOUNT NUMBER(12,2) NOT NULL,
            RELATED_ACCOUNT_ID NUMBER,
            TRANSACTION_DATE DATE DEFAULT SYSDATE,
            CONSTRAINT FK_TRANSACTION_ACCOUNT
                FOREIGN KEY (ACCOUNT_ID)
                REFERENCES BANK_ACCOUNTS(ACCOUNT_ID),
            CONSTRAINT CK_TRANSACTION_TYPE
                CHECK (TRANSACTION_TYPE IN (
                    ''OPENING'',
                    ''DEPOSIT'',
                    ''WITHDRAW'',
                    ''TRANSFER_IN'',
                    ''TRANSFER_OUT''
                )),
            CONSTRAINT CK_TRANSACTION_AMOUNT
                CHECK (AMOUNT > 0)
        )';
    DBMS_OUTPUT.PUT_LINE('BANK_TRANSACTIONS table created.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE(
                'BANK_TRANSACTIONS already exists; preserved.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

-- 1.3 BANK_AUDIT
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE BANK_AUDIT (
            AUDIT_ID NUMBER PRIMARY KEY,
            ACCOUNT_ID NUMBER NOT NULL,
            ACTION_TYPE VARCHAR2(30),
            OLD_BALANCE NUMBER(12,2),
            NEW_BALANCE NUMBER(12,2),
            ACTION_DATE DATE DEFAULT SYSDATE
        )';
    DBMS_OUTPUT.PUT_LINE('BANK_AUDIT table created.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE(
                'BANK_AUDIT already exists; preserved.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

-- 1.4 TRANSACTION_SEQ
BEGIN
    EXECUTE IMMEDIATE '
        CREATE SEQUENCE TRANSACTION_SEQ
        START WITH 1
        INCREMENT BY 1
        NOCACHE';
    DBMS_OUTPUT.PUT_LINE('TRANSACTION_SEQ created.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE(
                'TRANSACTION_SEQ already exists; preserved.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

-- 1.5 AUDIT_SEQ
BEGIN
    EXECUTE IMMEDIATE '
        CREATE SEQUENCE AUDIT_SEQ
        START WITH 1
        INCREMENT BY 1
        NOCACHE';
    DBMS_OUTPUT.PUT_LINE('AUDIT_SEQ created.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE(
                'AUDIT_SEQ already exists; preserved.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

-- ============================================================
-- PART 2: CREATE BALANCE AUDIT TRIGGER
-- Records old and new balances whenever an account balance
-- is updated.
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_BALANCE_AUDIT
AFTER UPDATE OF BALANCE ON BANK_ACCOUNTS
FOR EACH ROW
BEGIN
    INSERT INTO BANK_AUDIT (
        AUDIT_ID,
        ACCOUNT_ID,
        ACTION_TYPE,
        OLD_BALANCE,
        NEW_BALANCE,
        ACTION_DATE
    )
    VALUES (
        AUDIT_SEQ.NEXTVAL,
        :NEW.ACCOUNT_ID,
        'BALANCE_UPDATE',
        :OLD.BALANCE,
        :NEW.BALANCE,
        SYSDATE
    );
END;
/

-- ============================================================
-- PART 3: CREATE ACCOUNT PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE CREATE_ACCOUNT (
    P_ACCOUNT_ID IN NUMBER,
    P_CUSTOMER_NAME IN VARCHAR2,
    P_OPENING_BALANCE IN NUMBER
)
AS
BEGIN
    IF P_ACCOUNT_ID IS NULL
       OR TRIM(P_CUSTOMER_NAME) IS NULL
       OR P_OPENING_BALANCE IS NULL
       OR P_OPENING_BALANCE < 0
    THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Enter a valid account ID, customer name, and opening balance.'
        );
    END IF;

    INSERT INTO BANK_ACCOUNTS (
        ACCOUNT_ID,
        CUSTOMER_NAME,
        BALANCE,
        CREATED_AT
    )
    VALUES (
        P_ACCOUNT_ID,
        TRIM(P_CUSTOMER_NAME),
        P_OPENING_BALANCE,
        SYSDATE
    );

    IF P_OPENING_BALANCE > 0 THEN
        INSERT INTO BANK_TRANSACTIONS (
            TRANSACTION_ID,
            ACCOUNT_ID,
            TRANSACTION_TYPE,
            AMOUNT,
            TRANSACTION_DATE
        )
        VALUES (
            TRANSACTION_SEQ.NEXTVAL,
            P_ACCOUNT_ID,
            'OPENING',
            P_OPENING_BALANCE,
            SYSDATE
        );
    END IF;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Account created successfully. Account ID: ' || P_ACCOUNT_ID
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE(
            'Account ID already exists. No account was created.'
        );
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ============================================================
-- PART 4: DEPOSIT MONEY PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE DEPOSIT_MONEY (
    P_ACCOUNT_ID IN NUMBER,
    P_AMOUNT IN NUMBER
)
AS
BEGIN
    IF P_AMOUNT IS NULL OR P_AMOUNT <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Deposit amount must be greater than zero.'
        );
    END IF;

    UPDATE BANK_ACCOUNTS
    SET BALANCE = BALANCE + P_AMOUNT
    WHERE ACCOUNT_ID = P_ACCOUNT_ID;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Account not found.'
        );
    END IF;

    INSERT INTO BANK_TRANSACTIONS (
        TRANSACTION_ID,
        ACCOUNT_ID,
        TRANSACTION_TYPE,
        AMOUNT,
        TRANSACTION_DATE
    )
    VALUES (
        TRANSACTION_SEQ.NEXTVAL,
        P_ACCOUNT_ID,
        'DEPOSIT',
        P_AMOUNT,
        SYSDATE
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Deposit successful. Amount: ' || P_AMOUNT
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ============================================================
-- PART 5: WITHDRAW MONEY PROCEDURE
-- Checks the available balance before withdrawing.
-- ============================================================

CREATE OR REPLACE PROCEDURE WITHDRAW_MONEY (
    P_ACCOUNT_ID IN NUMBER,
    P_AMOUNT IN NUMBER
)
AS
    V_BALANCE BANK_ACCOUNTS.BALANCE%TYPE;
BEGIN
    IF P_AMOUNT IS NULL OR P_AMOUNT <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Withdrawal amount must be greater than zero.'
        );
    END IF;

    SELECT BALANCE
    INTO V_BALANCE
    FROM BANK_ACCOUNTS
    WHERE ACCOUNT_ID = P_ACCOUNT_ID
    FOR UPDATE;

    IF V_BALANCE < P_AMOUNT THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Insufficient balance.'
        );
    END IF;

    UPDATE BANK_ACCOUNTS
    SET BALANCE = BALANCE - P_AMOUNT
    WHERE ACCOUNT_ID = P_ACCOUNT_ID;

    INSERT INTO BANK_TRANSACTIONS (
        TRANSACTION_ID,
        ACCOUNT_ID,
        TRANSACTION_TYPE,
        AMOUNT,
        TRANSACTION_DATE
    )
    VALUES (
        TRANSACTION_SEQ.NEXTVAL,
        P_ACCOUNT_ID,
        'WITHDRAW',
        P_AMOUNT,
        SYSDATE
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Withdrawal successful. Amount: ' || P_AMOUNT
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20006,
            'Account not found.'
        );
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ============================================================
-- PART 6: TRANSFER MONEY PROCEDURE
-- Transfers money between two existing accounts.
-- ============================================================

CREATE OR REPLACE PROCEDURE TRANSFER_MONEY (
    P_SOURCE_ACCOUNT IN NUMBER,
    P_DESTINATION_ACCOUNT IN NUMBER,
    P_AMOUNT IN NUMBER
)
AS
    V_SOURCE_BALANCE BANK_ACCOUNTS.BALANCE%TYPE;
    V_DESTINATION_BALANCE BANK_ACCOUNTS.BALANCE%TYPE;
BEGIN
    IF P_SOURCE_ACCOUNT = P_DESTINATION_ACCOUNT THEN
        RAISE_APPLICATION_ERROR(
            -20007,
            'Source and destination accounts must be different.'
        );
    END IF;

    IF P_AMOUNT IS NULL OR P_AMOUNT <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20008,
            'Transfer amount must be greater than zero.'
        );
    END IF;

    SELECT BALANCE
    INTO V_SOURCE_BALANCE
    FROM BANK_ACCOUNTS
    WHERE ACCOUNT_ID = P_SOURCE_ACCOUNT
    FOR UPDATE;

    SELECT BALANCE
    INTO V_DESTINATION_BALANCE
    FROM BANK_ACCOUNTS
    WHERE ACCOUNT_ID = P_DESTINATION_ACCOUNT
    FOR UPDATE;

    IF V_SOURCE_BALANCE < P_AMOUNT THEN
        RAISE_APPLICATION_ERROR(
            -20009,
            'Insufficient balance in source account.'
        );
    END IF;

    UPDATE BANK_ACCOUNTS
    SET BALANCE = BALANCE - P_AMOUNT
    WHERE ACCOUNT_ID = P_SOURCE_ACCOUNT;

    UPDATE BANK_ACCOUNTS
    SET BALANCE = BALANCE + P_AMOUNT
    WHERE ACCOUNT_ID = P_DESTINATION_ACCOUNT;

    INSERT INTO BANK_TRANSACTIONS (
        TRANSACTION_ID,
        ACCOUNT_ID,
        TRANSACTION_TYPE,
        AMOUNT,
        RELATED_ACCOUNT_ID,
        TRANSACTION_DATE
    )
    VALUES (
        TRANSACTION_SEQ.NEXTVAL,
        P_SOURCE_ACCOUNT,
        'TRANSFER_OUT',
        P_AMOUNT,
        P_DESTINATION_ACCOUNT,
        SYSDATE
    );

    INSERT INTO BANK_TRANSACTIONS (
        TRANSACTION_ID,
        ACCOUNT_ID,
        TRANSACTION_TYPE,
        AMOUNT,
        RELATED_ACCOUNT_ID,
        TRANSACTION_DATE
    )
    VALUES (
        TRANSACTION_SEQ.NEXTVAL,
        P_DESTINATION_ACCOUNT,
        'TRANSFER_IN',
        P_AMOUNT,
        P_SOURCE_ACCOUNT,
        SYSDATE
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Transfer successful. Amount: ' || P_AMOUNT
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20010,
            'Source or destination account does not exist.'
        );
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ============================================================
-- PART 7: GET BALANCE FUNCTION
-- Returns the current balance of an account.
-- ============================================================

CREATE OR REPLACE FUNCTION GET_BALANCE (
    P_ACCOUNT_ID IN NUMBER
)
RETURN NUMBER
AS
    V_BALANCE NUMBER(12,2);
BEGIN
    SELECT BALANCE
    INTO V_BALANCE
    FROM BANK_ACCOUNTS
    WHERE ACCOUNT_ID = P_ACCOUNT_ID;

    RETURN V_BALANCE;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

-- ============================================================
-- PART 8: GENERATE ACCOUNT REPORT PROCEDURE
-- Displays each account, its balance, and transaction count.
-- ============================================================

CREATE OR REPLACE PROCEDURE GENERATE_ACCOUNT_REPORT
AS
    CURSOR ACCOUNT_CURSOR IS
        SELECT
            A.ACCOUNT_ID,
            A.CUSTOMER_NAME,
            A.BALANCE,
            A.CREATED_AT,
            COUNT(T.TRANSACTION_ID) AS TOTAL_TRANSACTIONS
        FROM BANK_ACCOUNTS A
        LEFT JOIN BANK_TRANSACTIONS T
            ON A.ACCOUNT_ID = T.ACCOUNT_ID
        GROUP BY
            A.ACCOUNT_ID,
            A.CUSTOMER_NAME,
            A.BALANCE,
            A.CREATED_AT
        ORDER BY A.ACCOUNT_ID;

BEGIN
    DBMS_OUTPUT.PUT_LINE('======================================');
    DBMS_OUTPUT.PUT_LINE('       BANK ACCOUNT REPORT');
    DBMS_OUTPUT.PUT_LINE('======================================');

    FOR ACCOUNT_REC IN ACCOUNT_CURSOR LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Account ID: ' || ACCOUNT_REC.ACCOUNT_ID
        );

        DBMS_OUTPUT.PUT_LINE(
            'Customer: ' || ACCOUNT_REC.CUSTOMER_NAME
        );

        DBMS_OUTPUT.PUT_LINE(
            'Balance: ' || ACCOUNT_REC.BALANCE
        );

        DBMS_OUTPUT.PUT_LINE(
            'Created At: ' ||
            TO_CHAR(ACCOUNT_REC.CREATED_AT, 'DD-MON-YYYY HH24:MI:SS')
        );

        DBMS_OUTPUT.PUT_LINE(
            'Transactions: ' || ACCOUNT_REC.TOTAL_TRANSACTIONS
        );

        DBMS_OUTPUT.PUT_LINE('--------------------------------------');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('          END OF REPORT');
    DBMS_OUTPUT.PUT_LINE('======================================');
END;
/

-- ============================================================
-- PART 9: VERIFICATION QUERIES
-- These queries inspect the objects and data without changing
-- account balances or repeating transactions.
-- ============================================================

-- 9.1 Check current schema.
SELECT USER AS CURRENT_SCHEMA
FROM DUAL;

-- 9.2 Check tables, sequences, procedures, function, and trigger.
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME IN (
    'BANK_ACCOUNTS',
    'BANK_TRANSACTIONS',
    'BANK_AUDIT',
    'TRANSACTION_SEQ',
    'AUDIT_SEQ',
    'TRG_BALANCE_AUDIT',
    'CREATE_ACCOUNT',
    'DEPOSIT_MONEY',
    'WITHDRAW_MONEY',
    'TRANSFER_MONEY',
    'GET_BALANCE',
    'GENERATE_ACCOUNT_REPORT'
)
ORDER BY OBJECT_TYPE, OBJECT_NAME;

-- 9.3 Check compilation errors.
SELECT NAME, TYPE, LINE, POSITION, TEXT
FROM USER_ERRORS
WHERE NAME IN (
    'TRG_BALANCE_AUDIT',
    'CREATE_ACCOUNT',
    'DEPOSIT_MONEY',
    'WITHDRAW_MONEY',
    'TRANSFER_MONEY',
    'GET_BALANCE',
    'GENERATE_ACCOUNT_REPORT'
)
ORDER BY NAME, SEQUENCE;

-- 9.4 Display existing accounts.
SELECT
    ACCOUNT_ID,
    CUSTOMER_NAME,
    BALANCE,
    CREATED_AT
FROM BANK_ACCOUNTS
ORDER BY ACCOUNT_ID;

-- 9.5 Display transaction history.
SELECT
    TRANSACTION_ID,
    ACCOUNT_ID,
    TRANSACTION_TYPE,
    AMOUNT,
    RELATED_ACCOUNT_ID,
    TRANSACTION_DATE
FROM BANK_TRANSACTIONS
ORDER BY TRANSACTION_ID;

-- 9.6 Display audit history.
SELECT
    AUDIT_ID,
    ACCOUNT_ID,
    ACTION_TYPE,
    OLD_BALANCE,
    NEW_BALANCE,
    ACTION_DATE
FROM BANK_AUDIT
ORDER BY AUDIT_ID;

-- 9.7 Test the GET_BALANCE function for an existing account.
-- Change 101 if that account does not exist.
SELECT GET_BALANCE(101) AS ACCOUNT_BALANCE
FROM DUAL;

-- 9.8 Generate the account report.
BEGIN
    GENERATE_ACCOUNT_REPORT;
END;
/

-- ============================================================
-- END OF SETUP SCRIPT
--
-- No account creation, deposit, withdrawal, or transfer calls
-- are automatically executed by this file.
-- Run intentional sample transactions separately.
-- ============================================================


