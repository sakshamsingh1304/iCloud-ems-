-- ============================================================
-- iCloudEMS Support Engineer (AI) Technical Assignment
-- COMPLETE SOLUTION - All Tasks (1-5)
-- ============================================================

-- ============================================================
-- TASK 1 — MySQL Database & Data Processing (30 MARKS)
-- ============================================================

-- --------------------------------------------------------
-- 1.1 Confirm all six tables were created and populated.
--     Report the row count of each table. [1]
-- --------------------------------------------------------

SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'programs', COUNT(*) FROM programs
UNION ALL
SELECT 'students', COUNT(*) FROM students
UNION ALL
SELECT 'admissions', COUNT(*) FROM admissions
UNION ALL
SELECT 'fee_transactions', COUNT(*) FROM fee_transactions
UNION ALL
SELECT 'fee_transaction_details', COUNT(*) FROM fee_transaction_details;

-- --------------------------------------------------------
-- 1.2 Identify duplicate admission numbers in the
--     students table. [3]
-- --------------------------------------------------------

SELECT admission_no, COUNT(*) AS occurrences
FROM students
GROUP BY admission_no
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, admission_no;

-- Show the full details of duplicate students
SELECT s.*
FROM students s
INNER JOIN (
    SELECT admission_no
    FROM students
    GROUP BY admission_no
    HAVING COUNT(*) > 1
) dup ON s.admission_no = dup.admission_no
ORDER BY s.admission_no, s.student_id;

-- --------------------------------------------------------
-- 1.3 Identify duplicate fee transactions — records that
--     share the same admission number, transaction type,
--     amount and date, appearing more than once. [3]
-- --------------------------------------------------------

-- Date matters because a student could legitimately make
-- two identical payments on different dates. If we only
-- checked admission_no + amount + type we would flag
-- legitimate separate transactions as duplicates.

SELECT admission_no, transaction_type, total_amount,
       transaction_date, COUNT(*) AS duplicate_count
FROM fee_transactions
GROUP BY admission_no, transaction_type, total_amount, transaction_date
HAVING COUNT(*) > 1
ORDER BY admission_no;

-- Show full details of duplicate transactions
SELECT ft.*
FROM fee_transactions ft
INNER JOIN (
    SELECT admission_no, transaction_type, total_amount, transaction_date
    FROM fee_transactions
    GROUP BY admission_no, transaction_type, total_amount, transaction_date
    HAVING COUNT(*) > 1
) dup ON ft.admission_no = dup.admission_no
    AND ft.transaction_type = dup.transaction_type
    AND ft.total_amount = dup.total_amount
    AND ft.transaction_date = dup.transaction_date
ORDER BY ft.admission_no, ft.transaction_date;

-- --------------------------------------------------------
-- 1.4 Find all students who currently have an
--     outstanding/due amount. [3]
-- --------------------------------------------------------

SELECT DISTINCT s.student_id, s.admission_no, s.full_name,
       p.program_name, d.department_name
FROM students s
JOIN programs p ON s.program_id = p.program_id
JOIN departments d ON s.department_id = d.department_id
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'DUE'
ORDER BY s.admission_no;

-- --------------------------------------------------------
-- 1.5 Calculate the total due amount, admission-number-wise,
--     for every student with an outstanding balance. [3]
-- --------------------------------------------------------

-- Outstanding balance = Total DUE - Total PAID - Total CONCESSION
SELECT
    s.admission_no,
    s.full_name,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ft.total_amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ft.total_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN ft.transaction_type = 'CONCESSION' THEN ft.total_amount ELSE 0 END) AS total_concession,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ft.total_amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ft.total_amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'CONCESSION' THEN ft.total_amount ELSE 0 END) AS outstanding_balance
FROM students s
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
GROUP BY s.admission_no, s.full_name
HAVING outstanding_balance > 0
ORDER BY outstanding_balance DESC;

-- --------------------------------------------------------
-- 1.6 Find the top 10 students by total fee collected
--     (paid). [2]
-- --------------------------------------------------------

SELECT s.admission_no, s.full_name,
       SUM(ft.total_amount) AS total_paid
FROM students s
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'PAID'
GROUP BY s.admission_no, s.full_name
ORDER BY total_paid DESC
LIMIT 10;

-- --------------------------------------------------------
-- 1.7 Find the top programs by total fee collected. [2]
-- --------------------------------------------------------

SELECT p.program_id, p.program_name,
       SUM(ft.total_amount) AS total_collected
FROM programs p
JOIN students s ON p.program_id = s.program_id
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'PAID'
GROUP BY p.program_id, p.program_name
ORDER BY total_collected DESC;

-- --------------------------------------------------------
-- 1.8 Identify transactions where the parent transaction
--     amount does not equal the sum of its child
--     transaction-detail amounts. [4]
-- --------------------------------------------------------

SELECT ft.transaction_id,
       ft.admission_no,
       ft.transaction_type,
       ft.total_amount AS parent_amount,
       COALESCE(SUM(ftd.amount), 0) AS child_total,
       ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS difference
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
GROUP BY ft.transaction_id, ft.admission_no, ft.transaction_type, ft.total_amount
HAVING ft.total_amount <> COALESCE(SUM(ftd.amount), 0)
ORDER BY ABS(ft.total_amount - COALESCE(SUM(ftd.amount), 0)) DESC;

-- --------------------------------------------------------
-- 1.9 Identify parent transactions that have no child
--     records at all. [3]
-- --------------------------------------------------------

SELECT ft.transaction_id, ft.admission_no, ft.transaction_date,
       ft.transaction_type, ft.total_amount, ft.status
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ftd.detail_id IS NULL
ORDER BY ft.transaction_id;

-- --------------------------------------------------------
-- 1.10 Identify child records whose parent transaction
--      does not exist. [3]
-- --------------------------------------------------------

SELECT ftd.detail_id, ftd.transaction_id, ftd.admission_no,
       ftd.fee_head, ftd.amount, ftd.status
FROM fee_transaction_details ftd
LEFT JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ft.transaction_id IS NULL
ORDER BY ftd.detail_id;

-- --------------------------------------------------------
-- 1.11 Produce a single reconciliation report with columns:
--      Admission Number, Transaction Count, Transaction Amount,
--      Detail Count, Detail Amount, Difference. [3]
-- --------------------------------------------------------

SELECT
    COALESCE(parent.admission_no, child.admission_no) AS admission_number,
    COALESCE(parent.txn_count, 0) AS transaction_count,
    COALESCE(parent.txn_amount, 0) AS transaction_amount,
    COALESCE(child.detail_count, 0) AS detail_count,
    COALESCE(child.detail_amount, 0) AS detail_amount,
    COALESCE(parent.txn_amount, 0) - COALESCE(child.detail_amount, 0) AS difference
FROM
    (SELECT admission_no,
            COUNT(*) AS txn_count,
            SUM(total_amount) AS txn_amount
     FROM fee_transactions
     GROUP BY admission_no) parent
LEFT JOIN
    (SELECT admission_no,
            COUNT(*) AS detail_count,
            SUM(amount) AS detail_amount
     FROM fee_transaction_details
     GROUP BY admission_no) child
ON parent.admission_no = child.admission_no
UNION
SELECT
    COALESCE(parent.admission_no, child.admission_no) AS admission_number,
    COALESCE(parent.txn_count, 0) AS transaction_count,
    COALESCE(parent.txn_amount, 0) AS transaction_amount,
    COALESCE(child.detail_count, 0) AS detail_count,
    COALESCE(child.detail_amount, 0) AS detail_amount,
    COALESCE(parent.txn_amount, 0) - COALESCE(child.detail_amount, 0) AS difference
FROM
    (SELECT admission_no,
            COUNT(*) AS txn_count,
            SUM(total_amount) AS txn_amount
     FROM fee_transactions
     GROUP BY admission_no) parent
RIGHT JOIN
    (SELECT admission_no,
            COUNT(*) AS detail_count,
            SUM(amount) AS detail_amount
     FROM fee_transaction_details
     GROUP BY admission_no) child
ON parent.admission_no = child.admission_no
ORDER BY admission_number;


-- ============================================================
-- TASK 2 — Real-World Support Bug (20 MARKS)
-- ============================================================

-- --------------------------------------------------------
-- 2.1 Investigate the issue using SQL. [5]
-- --------------------------------------------------------

-- Step A: View all fee_transactions for ADM10025
SELECT * FROM fee_transactions
WHERE admission_no = 'ADM10025'
ORDER BY transaction_date;

-- Step B: View all fee_transaction_details for ADM10025
SELECT * FROM fee_transaction_details
WHERE admission_no = 'ADM10025'
ORDER BY transaction_id;

-- Step C: Check due vs paid summary for ADM10025
SELECT
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN transaction_type = 'CONCESSION' THEN total_amount ELSE 0 END) AS total_concession,
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'CONCESSION' THEN total_amount ELSE 0 END) AS outstanding
FROM fee_transactions
WHERE admission_no = 'ADM10025';

-- --------------------------------------------------------
-- 2.2 Identify the root cause. [5]
-- --------------------------------------------------------

-- Check parent vs child for transaction 518 (the ₹15,000 payment)
SELECT ft.transaction_id, ft.total_amount AS parent_amount,
       COALESCE(SUM(ftd.amount), 0) AS child_total,
       ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS shortfall
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ft.transaction_id = 518
GROUP BY ft.transaction_id, ft.total_amount;

-- Show what child records exist for transaction 518
SELECT * FROM fee_transaction_details WHERE transaction_id = 518;

-- --------------------------------------------------------
-- 2.3 Write a query that clearly proves the issue
--     (demonstrates the discrepancy). [4]
-- --------------------------------------------------------

-- The DueCalculationJob calculates outstanding using
-- fee_transaction_details aggregation, NOT fee_transactions.
-- If child details are incomplete, the due calculation is wrong.

-- Proof: Compare parent-level vs detail-level calculations
SELECT
    'From fee_transactions (parent)' AS source,
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END) AS outstanding
FROM fee_transactions
WHERE admission_no = 'ADM10025'
UNION ALL
SELECT
    'From fee_transaction_details (child)' AS source,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS outstanding
FROM fee_transaction_details ftd
JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ftd.admission_no = 'ADM10025';

-- --------------------------------------------------------
-- 2.4 Explain, in plain terms, what went wrong. [2]
-- --------------------------------------------------------

-- EXPLANATION:
-- The student ADM10025 had a DUE of ₹15,000 (transaction 517) and
-- then made a PAID of ₹15,000 (transaction 518).
-- However, when inserting fee_transaction_details for transaction 518,
-- only the Tuition Fee (₹10,000) child record was inserted successfully.
-- The Exam Fee (₹5,000) child record FAILED to insert due to a
-- "Duplicate entry for key 'detail_id_seq'" error (as shown in Task 4 logs).
-- The error was caught by a generic exception handler, and the transaction
-- was NOT rolled back.
--
-- The DueCalculationJob calculates outstanding using fee_transaction_details
-- aggregation (NOT fee_transactions parent table). Since only ₹10,000 of
-- the ₹15,000 payment was recorded in details, the system calculated
-- ₹15,000 (due) - ₹10,000 (paid in details) = ₹5,000 outstanding.
-- This is incorrect — the payment was fully successful at the gateway level.

-- --------------------------------------------------------
-- 2.5 Provide the SQL/data correction required to fix
--     ADM10025's record. [2]
-- --------------------------------------------------------

-- Insert the missing child record for the Exam Fee of ₹5,000
-- First find the next available detail_id
SELECT MAX(detail_id) + 1 AS next_detail_id FROM fee_transaction_details;

-- Insert the missing detail
INSERT INTO fee_transaction_details (detail_id, transaction_id, admission_no, fee_head, amount, status)
VALUES (
    (SELECT max_id FROM (SELECT MAX(detail_id) + 1 AS max_id FROM fee_transaction_details) t),
    518,
    'ADM10025',
    'Exam Fee',
    5000,
    'Success'
);

-- Verify the fix
SELECT ft.transaction_id, ft.total_amount AS parent_amount,
       SUM(ftd.amount) AS child_total,
       ft.total_amount - SUM(ftd.amount) AS difference
FROM fee_transactions ft
JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ft.transaction_id = 518
GROUP BY ft.transaction_id, ft.total_amount;

-- Verify outstanding is now ₹0
SELECT
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS outstanding
FROM fee_transaction_details ftd
JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ftd.admission_no = 'ADM10025';

-- --------------------------------------------------------
-- 2.6 How to prevent this class of issue from happening
--     again — process or system level. [2]
-- --------------------------------------------------------

-- PREVENTION MEASURES:
-- 1. WRAP IN A DATABASE TRANSACTION: The parent and all child inserts
--    should be wrapped in a single DB transaction (BEGIN...COMMIT).
--    If any child insert fails, the entire transaction should ROLLBACK,
--    ensuring atomicity (all-or-nothing).
--
-- 2. USE AUTO-INCREMENT for detail_id: Replace the manually-generated
--    detail_id with an AUTO_INCREMENT column to prevent duplicate key errors.
--
-- 3. PROPER ERROR HANDLING: The application should NOT return HTTP 200
--    if child record inserts fail. The generic exception handler should
--    trigger a rollback and return an error to the client.
--
-- 4. ADD FOREIGN KEY CONSTRAINT: Add a foreign key from
--    fee_transaction_details.transaction_id to fee_transactions.transaction_id
--    to enforce referential integrity.
--
-- 5. RECONCILIATION CHECKS: Add a post-insert validation that verifies
--    parent.total_amount == SUM(child.amount) before committing.
--
-- 6. DUE CALCULATION FIX: The DueCalculationJob should use the parent
--    fee_transactions table (which has the correct amount) instead of
--    aggregating from fee_transaction_details (which may be incomplete).


-- ============================================================
-- TASK 3 — Parent/Child Transaction Reconciliation (20 MARKS)
-- Uses icloud_task3 database
-- ============================================================
