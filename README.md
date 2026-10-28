# banking-transaction-management-plsql
An Oracle SQL and PL/SQL-based Banking Transaction Management System featuring account creation, deposits, withdrawals, fund transfers, balance validation, transaction tracking, and audit functionality.

# Banking Transaction Management System using PL/SQL

## Overview
The Banking Transaction Management System is a database project developed using Oracle SQL and PL/SQL. It demonstrates basic banking operations, transaction management, balance validation, and auditing of account balance changes.

## Objectives
- Manage bank accounts.
- Perform deposits and withdrawals.
- Transfer money between accounts.
- Retrieve account balances.
- Maintain transaction records.
- Track balance changes using audit functionality.
- Generate account reports.

## Technologies Used
- Oracle Database
- Oracle SQL
- PL/SQL
- VS Code with an Oracle-compatible extension

## Database Objects

### Tables
- `BANK_ACCOUNTS`
- `BANK_TRANSACTIONS`
- `BANK_AUDIT`

### Sequences
- `TRANSACTION_SEQ`
- `AUDIT_SEQ`

### Trigger
- `TRG_BALANCE_AUDIT`

### Procedures
- `CREATE_ACCOUNT`
- `DEPOSIT_MONEY`
- `WITHDRAW_MONEY`
- `TRANSFER_MONEY`
- `GENERATE_ACCOUNT_REPORT`

### Function
- `GET_BALANCE`

## Features
1. Account creation
2. Deposit money
3. Withdraw money
4. Transfer funds between accounts
5. Check account balance
6. Audit balance changes
7. Generate account reports

## Requirements
- Oracle Database access
- An Oracle-compatible SQL client
- Permission to create tables, sequences, triggers, procedures, and functions

## How to Run
1. Clone or download this repository.
2. Connect your SQL client to your Oracle database.
3. Open the main `.sql` script.
4. Execute the script using script execution mode if required by your SQL client.
5. Enable or open DBMS Output to view messages printed using `DBMS_OUTPUT.PUT_LINE`.
6. Run the included test blocks and queries to verify the operations.

Note: Execution steps may vary depending on your Oracle client and extension.

## Sample Operations
The project demonstrates account creation, deposits, withdrawals, transfers, balance checking, and account reporting using test data.

Add screenshots of successful execution and query results here.

## Security
- Do not upload database passwords or credentials.
- Use fictional test account information.
- Do not upload real customer banking data or sensitive database exports.

## Author
Aditya Abhishek

## License
No license has been specified.
