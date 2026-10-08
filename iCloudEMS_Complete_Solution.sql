-- ============================================================
-- iCloudEMS Support Engineer (AI) Technical Assignment
-- COMPLETE SOLUTION FILE — ALL TASKS (1-5)
-- Database: MySQL 8.0
-- ============================================================


-- ████████████████████████████████████████████████████████████
-- TASK 1 — MySQL Database & Data Processing       [30 MARKS]
-- ████████████████████████████████████████████████████████████

USE icloud_assessment;

-- ============================================================
-- 1.1  Confirm all six tables; report row counts         [1]
-- ============================================================

SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'programs',                COUNT(*) FROM programs
UNION ALL SELECT 'students',                COUNT(*) FROM students
UNION ALL SELECT 'admissions',              COUNT(*) FROM admissions
UNION ALL SELECT 'fee_transactions',        COUNT(*) FROM fee_transactions
UNION ALL SELECT 'fee_transaction_details', COUNT(*) FROM fee_transaction_details;

-- RESULT:
-- departments             →   5
-- programs                →  10
-- students                → 305
-- admissions              → 300
-- fee_transactions        → 516
-- fee_transaction_details → 889


-- ============================================================
-- 1.2  Identify duplicate admission numbers in students  [3]
-- ============================================================

SELECT admission_no, COUNT(*) AS occurrences
FROM students
GROUP BY admission_no
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, admission_no;

-- Detailed view of duplicates
SELECT s.student_id, s.admission_no, s.full_name,
       s.program_id, s.department_id, s.admission_year
FROM students s
INNER JOIN (
    SELECT admission_no FROM students GROUP BY admission_no HAVING COUNT(*) > 1
) dup ON s.admission_no = dup.admission_no
ORDER BY s.admission_no, s.student_id;

-- RESULT: 5 duplicate admission_no values found:
-- ADM10081 (student_id 81 & 302)
-- ADM10090 (student_id 90 & 303)
-- ADM10154 (student_id 154 & 301)
-- ADM10186 (student_id 186 & 304)
-- ADM10261 (student_id 261 & 305)


-- ============================================================
-- 1.3  Identify duplicate fee transactions               [3]
-- ============================================================

-- Date matters because a student may legitimately make two
-- identical payments on DIFFERENT dates (e.g. semester 1 and
-- semester 2 tuition both ₹15,000). Without date, we would
-- incorrectly flag those as duplicates. A true duplicate is
-- the same admission_no + type + amount on the SAME date.

SELECT admission_no, transaction_type, total_amount,
       transaction_date, COUNT(*) AS duplicate_count
FROM fee_transactions
GROUP BY admission_no, transaction_type, total_amount, transaction_date
HAVING COUNT(*) > 1
ORDER BY admission_no;

-- Full details of duplicates
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

-- RESULT: 8 sets of duplicates found:
-- ADM10057  DUE   8000  2025-04-19  (txn 100, 511)
-- ADM10125  DUE   8000  2025-02-13  (txn 217, 510)
-- ADM10136  DUE  15000  2025-04-05  (txn 235, 509)
-- ADM10191  DUE  12000  2025-01-18  (txn 326, 515)
-- ADM10191  DUE  18000  2025-09-01  (txn 328, 513)
-- ADM10201  PAID 20000  2025-09-14  (txn 345, 516)
-- ADM10226  PAID 18000  2025-07-21  (txn 385, 512)
-- ADM10289  DUE   8000  2025-08-24  (txn 486, 514)


-- ============================================================
-- 1.4  Find all students with outstanding/due amount     [3]
-- ============================================================

SELECT DISTINCT s.student_id, s.admission_no, s.full_name,
       p.program_name
FROM students s
JOIN programs p ON s.program_id = p.program_id
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'DUE'
ORDER BY s.admission_no;

-- RESULT: 176 student rows (including duplicates from dual admission_no)


-- ============================================================
-- 1.5  Total due amount, admission-number-wise           [3]
-- ============================================================

SELECT
    s.admission_no,
    s.full_name,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ft.total_amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ft.total_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN ft.transaction_type = 'CONCESSION' THEN ft.total_amount ELSE 0 END) AS total_concession,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ft.total_amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ft.total_amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'CONCESSION' THEN ft.total_amount ELSE 0 END)
        AS outstanding_balance
FROM students s
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
GROUP BY s.admission_no, s.full_name
HAVING outstanding_balance > 0
ORDER BY outstanding_balance DESC;

-- RESULT: 126 rows with positive outstanding balance
-- Top 3: ADM10017 (₹52,000), ADM10024 (₹42,000), ADM10191 (₹42,000)


-- ============================================================
-- 1.6  Top 10 students by total fee collected (PAID)     [2]
-- ============================================================

SELECT s.admission_no, s.full_name,
       SUM(ft.total_amount) AS total_paid
FROM students s
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'PAID'
GROUP BY s.admission_no, s.full_name
ORDER BY total_paid DESC
LIMIT 10;

-- RESULT:
-- 1. ADM10226  Myra Malhotra   ₹61,000
-- 2. ADM10008  Anika Singh     ₹49,000
-- 3. ADM10159  Ananya Chauhan  ₹49,000
-- 4. ADM10295  Diya Rao        ₹46,000
-- 5. ADM10107  Vihaan Joshi    ₹45,000
-- 6. ADM10242  Ishaan Bose     ₹45,000
-- 7. ADM10202  Vihaan Gupta    ₹43,000
-- 8. ADM10067  Saanvi Mehta    ₹43,000
-- 9. ADM10193  Vivaan Rao      ₹40,000
-- 10. ADM10137 Ayaan Kumar     ₹40,000


-- ============================================================
-- 1.7  Top programs by total fee collected               [2]
-- ============================================================

SELECT p.program_id, p.program_name,
       SUM(ft.total_amount) AS total_collected
FROM programs p
JOIN students s ON p.program_id = s.program_id
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'PAID'
GROUP BY p.program_id, p.program_name
ORDER BY total_collected DESC;

-- RESULT:
-- 1. BCA                     ₹6,73,000
-- 2. BBA                     ₹5,26,000
-- 3. M.Tech Computer Science ₹4,64,000
-- 4. Diploma Mechanical      ₹4,24,000
-- 5. B.Tech Mechanical       ₹3,85,000
-- 6. MBA                     ₹3,74,000
-- 7. MCA                     ₹3,33,000
-- 8. B.Tech Computer Science ₹3,03,000
-- 9. B.Com (Hons)            ₹3,03,000
-- 10. B.Tech Electronics     ₹2,58,000


-- ============================================================
-- 1.8  Parent-child amount mismatches                    [4]
-- ============================================================

SELECT ft.transaction_id,
       ft.admission_no,
       ft.transaction_type,
       ft.total_amount AS parent_amount,
       COALESCE(SUM(ftd.amount), 0) AS child_total,
       ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS difference
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd
    ON ft.transaction_id = ftd.transaction_id
GROUP BY ft.transaction_id, ft.admission_no,
         ft.transaction_type, ft.total_amount
HAVING ft.total_amount <> COALESCE(SUM(ftd.amount), 0)
ORDER BY ABS(ft.total_amount - COALESCE(SUM(ftd.amount), 0)) DESC;

-- RESULT: 26 mismatched transactions found
-- Ranging from ₹20,000 shortfall to ₹737 shortfall


-- ============================================================
-- 1.9  Parent transactions with no child records         [3]
-- ============================================================

SELECT ft.transaction_id, ft.admission_no, ft.transaction_date,
       ft.transaction_type, ft.total_amount, ft.status
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd
    ON ft.transaction_id = ftd.transaction_id
WHERE ftd.detail_id IS NULL
ORDER BY ft.transaction_id;

-- RESULT: 10 parent transactions have zero child records:
-- txn 34, 83, 110, 128, 179, 201, 253, 287, 427, 514


-- ============================================================
-- 1.10 Orphan child records (no parent)                  [3]
-- ============================================================

SELECT ftd.detail_id, ftd.transaction_id, ftd.admission_no,
       ftd.fee_head, ftd.amount, ftd.status
FROM fee_transaction_details ftd
LEFT JOIN fee_transactions ft
    ON ftd.transaction_id = ft.transaction_id
WHERE ft.transaction_id IS NULL
ORDER BY ftd.detail_id;

-- RESULT: 10 orphan child records (transaction_ids 1016–1025)
-- These reference non-existent parent transactions


-- ============================================================
-- 1.11 Single reconciliation report                      [3]
-- ============================================================

SELECT
    COALESCE(p.admission_no, c.admission_no) AS admission_number,
    COALESCE(p.txn_count, 0)   AS transaction_count,
    COALESCE(p.txn_amount, 0)  AS transaction_amount,
    COALESCE(c.detail_count, 0) AS detail_count,
    COALESCE(c.detail_amount, 0) AS detail_amount,
    COALESCE(p.txn_amount, 0) - COALESCE(c.detail_amount, 0) AS difference
FROM
    (SELECT admission_no, COUNT(*) AS txn_count,
            SUM(total_amount) AS txn_amount
     FROM fee_transactions GROUP BY admission_no) p
LEFT JOIN
    (SELECT admission_no, COUNT(*) AS detail_count,
            SUM(amount) AS detail_amount
     FROM fee_transaction_details GROUP BY admission_no) c
    ON p.admission_no = c.admission_no
UNION
SELECT
    COALESCE(p.admission_no, c.admission_no),
    COALESCE(p.txn_count, 0),
    COALESCE(p.txn_amount, 0),
    COALESCE(c.detail_count, 0),
    COALESCE(c.detail_amount, 0),
    COALESCE(p.txn_amount, 0) - COALESCE(c.detail_amount, 0)
FROM
    (SELECT admission_no, COUNT(*) AS txn_count,
            SUM(total_amount) AS txn_amount
     FROM fee_transactions GROUP BY admission_no) p
RIGHT JOIN
    (SELECT admission_no, COUNT(*) AS detail_count,
            SUM(amount) AS detail_amount
     FROM fee_transaction_details GROUP BY admission_no) c
    ON p.admission_no = c.admission_no
ORDER BY admission_number;


-- ████████████████████████████████████████████████████████████
-- TASK 2 — Real-World Support Bug                 [20 MARKS]
-- ████████████████████████████████████████████████████████████

-- ============================================================
-- 2.1  Investigate the issue using SQL                   [5]
-- ============================================================

-- Step A: All fee_transactions for ADM10025
SELECT * FROM fee_transactions
WHERE admission_no = 'ADM10025'
ORDER BY transaction_date;
-- RESULT:
-- txn 517 | 2025-06-10 | DUE  | ₹15,000 | Success
-- txn 518 | 2025-09-15 | PAID | ₹15,000 | Success

-- Step B: All fee_transaction_details for ADM10025
SELECT * FROM fee_transaction_details
WHERE admission_no = 'ADM10025'
ORDER BY transaction_id;
-- RESULT:
-- detail 903 | txn 517 | Tuition Fee | ₹10,000 | Success
-- detail 904 | txn 517 | Exam Fee    | ₹5,000  | Success
-- detail 905 | txn 518 | Tuition Fee | ₹10,000 | Success
-- ** MISSING: Exam Fee ₹5,000 for txn 518 **

-- Step C: Parent-level summary
SELECT
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END) AS outstanding
FROM fee_transactions
WHERE admission_no = 'ADM10025';
-- RESULT: Due=15000, Paid=15000, Outstanding=0 (correct at parent level)


-- ============================================================
-- 2.2  Identify the root cause                          [5]
-- ============================================================

-- Check parent vs child for transaction 518
SELECT ft.transaction_id,
       ft.total_amount AS parent_amount,
       COALESCE(SUM(ftd.amount), 0) AS child_total,
       ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS shortfall
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ft.transaction_id = 518
GROUP BY ft.transaction_id, ft.total_amount;
-- RESULT: parent=15000, child=10000, shortfall=5000

-- Show child records for transaction 518
SELECT * FROM fee_transaction_details WHERE transaction_id = 518;
-- RESULT: Only 1 record (Tuition Fee ₹10,000). Exam Fee ₹5,000 is MISSING.

-- ROOT CAUSE:
-- The fee_transaction_details insert for "Exam Fee ₹5,000" in transaction 518
-- FAILED due to "Duplicate entry '3024' for key 'detail_id_seq'" (a primary
-- key collision). The error was caught by a generic exception handler, but
-- the database transaction was NOT rolled back.
--
-- The parent record (fee_transactions) recorded the full ₹15,000 payment
-- correctly, but the child table (fee_transaction_details) only has ₹10,000.
--
-- The DueCalculationJob calculates outstanding fees using CHILD records
-- (fee_transaction_details aggregation), NOT the parent table. So it
-- computed: ₹15,000 (due details) - ₹10,000 (paid details) = ₹5,000
-- outstanding — which is WRONG.


-- ============================================================
-- 2.3  Proof of discrepancy                              [4]
-- ============================================================

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
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END),
    SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END),
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END)
FROM fee_transaction_details ftd
JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ftd.admission_no = 'ADM10025';

-- RESULT:
-- Parent level: Due=15000, Paid=15000, Outstanding=0    ← CORRECT
-- Child level:  Due=15000, Paid=10000, Outstanding=5000 ← WRONG (5000 gap)


-- ============================================================
-- 2.4  What went wrong — plain English                   [2]
-- ============================================================

-- EXPLANATION:
-- 1. Student ADM10025 had ₹15,000 assessed as DUE (transaction 517).
-- 2. The student paid ₹15,000 (transaction 518), and the payment
--    gateway confirmed SUCCESS.
-- 3. The application correctly inserted the PARENT record
--    (fee_transactions #518 for ₹15,000 PAID).
-- 4. It then started inserting CHILD records (fee_transaction_details):
--    a. Tuition Fee ₹10,000 → inserted successfully (detail_id 905)
--    b. Exam Fee ₹5,000    → FAILED (duplicate detail_id collision)
-- 5. The error was caught by a generic exception handler that logged
--    the error but did NOT rollback the transaction. The HTTP 200
--    response was returned to the student anyway.
-- 6. The DueCalculationJob recalculated the outstanding balance using
--    the CHILD table (fee_transaction_details), not the parent table.
--    Since only ₹10,000 in PAID details existed, it computed:
--    ₹15,000 (due) - ₹10,000 (paid) = ₹5,000 outstanding.
-- 7. The ERP therefore still shows ₹5,000 as due — even though the
--    payment was fully successful.


-- ============================================================
-- 2.5  SQL/data correction for ADM10025                  [2]
-- ============================================================

-- Insert the missing Exam Fee child record
INSERT INTO fee_transaction_details
    (detail_id, transaction_id, admission_no, fee_head, amount, status)
VALUES (
    (SELECT max_id FROM
        (SELECT MAX(detail_id) + 1 AS max_id
         FROM fee_transaction_details) t),
    518,
    'ADM10025',
    'Exam Fee',
    5000,
    'Success'
);

-- Verify the fix: transaction 518 now balances
SELECT ft.transaction_id,
       ft.total_amount AS parent_amount,
       SUM(ftd.amount) AS child_total,
       ft.total_amount - SUM(ftd.amount) AS difference
FROM fee_transactions ft
JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ft.transaction_id = 518
GROUP BY ft.transaction_id, ft.total_amount;
-- EXPECTED: parent=15000, child=15000, difference=0

-- Verify outstanding is now ₹0
SELECT
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS outstanding
FROM fee_transaction_details ftd
JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ftd.admission_no = 'ADM10025';
-- EXPECTED: Outstanding = 0


-- ============================================================
-- 2.6  Prevention — process or system level              [2]
-- ============================================================

-- 1. ATOMICITY — Use database transactions (BEGIN … COMMIT/ROLLBACK)
--    so that ALL child inserts succeed or NONE do. If any child insert
--    fails, the entire transaction (including the parent) rolls back.
--
-- 2. AUTO_INCREMENT — Change detail_id to AUTO_INCREMENT to eliminate
--    manual ID generation and the duplicate-key error that caused this.
--
-- 3. PROPER ERROR HANDLING — The application must NOT return HTTP 200
--    if any child insert fails. The exception handler should trigger
--    a rollback and return an error to the client.
--
-- 4. FOREIGN KEY ENFORCEMENT — Add a foreign key constraint:
--    ALTER TABLE fee_transaction_details
--        ADD CONSTRAINT fk_txn_detail
--        FOREIGN KEY (transaction_id)
--        REFERENCES fee_transactions(transaction_id);
--
-- 5. POST-INSERT VALIDATION — After inserting all children, verify
--    SUM(child.amount) == parent.total_amount before committing.
--
-- 6. DUE CALCULATION — The DueCalculationJob should ideally use the
--    authoritative parent table for totals, or at minimum cross-check
--    parent vs. child totals and flag discrepancies.


-- ████████████████████████████████████████████████████████████
-- TASK 3 — Parent/Child Transaction Reconciliation [20 MARKS]
-- Database: icloud_task3
-- ████████████████████████████████████████████████████████████

USE icloud_task3;

-- ============================================================
-- 3.1  Confirm tables created and populated              [2]
-- ============================================================

SELECT 'financial_transaction' AS table_name, COUNT(*) AS row_count
FROM financial_transaction
UNION ALL
SELECT 'financial_transaction_detail', COUNT(*)
FROM financial_transaction_detail;

-- RESULT:
-- financial_transaction        → 41 rows
-- financial_transaction_detail → 76 rows


-- ============================================================
-- 3.2  Verify data loaded without loss                   [1]
-- ============================================================

SELECT 'Expected parent rows' AS check_item, 41 AS expected,
       COUNT(*) AS actual,
       CASE WHEN COUNT(*) = 41 THEN 'OK' ELSE 'DATA LOSS' END AS status
FROM financial_transaction
UNION ALL
SELECT 'Expected child rows', 76, COUNT(*),
       CASE WHEN COUNT(*) = 76 THEN 'OK' ELSE 'DATA LOSS' END
FROM financial_transaction_detail;

-- RESULT: Both OK — no data loss


-- ============================================================
-- 3.3  Reconcile parent and child amounts per txn        [4]
-- ============================================================

SELECT
    ft.transaction_id,
    ft.admission_no,
    ft.total_amount AS parent_amount,
    COALESCE(SUM(ftd.amount), 0) AS child_amount,
    ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS difference,
    CASE WHEN ft.total_amount = COALESCE(SUM(ftd.amount), 0)
         THEN 'MATCH' ELSE 'MISMATCH' END AS status
FROM financial_transaction ft
LEFT JOIN financial_transaction_detail ftd
    ON ft.transaction_id = ftd.transaction_id
GROUP BY ft.transaction_id, ft.admission_no, ft.total_amount
ORDER BY ft.transaction_id;

-- RESULT: 10 MISMATCH transactions found:
-- txn 7(20000), 9(3352), 22(6000), 27(2908), 33(3224),
-- 34(5150), 35(2537), 36(14000), 38(1867), 40(9000)


-- ============================================================
-- 3.4  Reconcile transaction counts per admission        [4]
-- ============================================================

SELECT
    COALESCE(p.admission_no, c.admission_no) AS admission_no,
    COALESCE(p.parent_count, 0) AS parent_txn_count,
    COALESCE(c.child_distinct_count, 0) AS child_distinct_txn_count,
    COALESCE(p.parent_count, 0) - COALESCE(c.child_distinct_count, 0) AS count_diff,
    CASE WHEN COALESCE(p.parent_count, 0) = COALESCE(c.child_distinct_count, 0)
         THEN 'MATCH' ELSE 'MISMATCH' END AS status
FROM
    (SELECT admission_no, COUNT(*) AS parent_count
     FROM financial_transaction GROUP BY admission_no) p
LEFT JOIN
    (SELECT admission_no, COUNT(DISTINCT transaction_id) AS child_distinct_count
     FROM financial_transaction_detail GROUP BY admission_no) c
ON p.admission_no = c.admission_no
UNION
SELECT
    COALESCE(p.admission_no, c.admission_no),
    COALESCE(p.parent_count, 0),
    COALESCE(c.child_distinct_count, 0),
    COALESCE(p.parent_count, 0) - COALESCE(c.child_distinct_count, 0),
    CASE WHEN COALESCE(p.parent_count, 0) = COALESCE(c.child_distinct_count, 0)
         THEN 'MATCH' ELSE 'MISMATCH' END
FROM
    (SELECT admission_no, COUNT(*) AS parent_count
     FROM financial_transaction GROUP BY admission_no) p
RIGHT JOIN
    (SELECT admission_no, COUNT(DISTINCT transaction_id) AS child_distinct_count
     FROM financial_transaction_detail GROUP BY admission_no) c
ON p.admission_no = c.admission_no
ORDER BY admission_no;

-- RESULT: 6 MISMATCH admissions by count:
-- ADM20002 (2 parent, 3 child — orphan child with txn_id 143)
-- ADM20005 (2 parent, 1 child — no children for txn 7)
-- ADM20008 (2 parent, 3 child — orphan child with txn_id 142)
-- ADM20015 (2 parent, 3 child — orphan child with txn_id 144)
-- ADM20016 (1 parent, 0 child — no children at all)
-- ADM20027 (2 parent, 1 child — no children for txn 36)


-- ============================================================
-- 3.5  Identify ALL mismatches (amount and/or count)     [4]
-- ============================================================

SELECT
    ft.transaction_id,
    ft.admission_no,
    ft.total_amount AS parent_amount,
    COALESCE(SUM(ftd.amount), 0) AS child_amount,
    ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS amount_difference,
    'AMOUNT MISMATCH' AS mismatch_type
FROM financial_transaction ft
LEFT JOIN financial_transaction_detail ftd
    ON ft.transaction_id = ftd.transaction_id
GROUP BY ft.transaction_id, ft.admission_no, ft.total_amount
HAVING ft.total_amount <> COALESCE(SUM(ftd.amount), 0)
ORDER BY ft.transaction_id;

-- RESULT: 10 amount mismatches:
-- txn  7 (ADM20005): ₹20,000 vs ₹0       → ₹20,000 gap (no children)
-- txn  9 (ADM20006): ₹14,000 vs ₹10,648  → ₹3,352 gap
-- txn 22 (ADM20016): ₹6,000  vs ₹0       → ₹6,000 gap (no children)
-- txn 27 (ADM20020): ₹20,000 vs ₹17,092  → ₹2,908 gap
-- txn 33 (ADM20025): ₹11,000 vs ₹7,776   → ₹3,224 gap
-- txn 34 (ADM20026): ₹11,000 vs ₹5,850   → ₹5,150 gap
-- txn 35 (ADM20026): ₹20,000 vs ₹17,463  → ₹2,537 gap
-- txn 36 (ADM20027): ₹14,000 vs ₹0       → ₹14,000 gap (no children)
-- txn 38 (ADM20028): ₹16,000 vs ₹14,133  → ₹1,867 gap
-- txn 40 (ADM20029): ₹9,000  vs ₹0       → ₹9,000 gap (no children)


-- ============================================================
-- 3.6  Orphans — both directions                         [3]
-- ============================================================

-- Parent transactions with NO child records
SELECT ft.transaction_id, ft.admission_no, ft.total_amount, ft.status
FROM financial_transaction ft
LEFT JOIN financial_transaction_detail ftd
    ON ft.transaction_id = ftd.transaction_id
WHERE ftd.detail_id IS NULL
ORDER BY ft.transaction_id;

-- RESULT: 4 parentless transactions:
-- txn  7 (ADM20005, ₹20,000)
-- txn 22 (ADM20016, ₹6,000)
-- txn 36 (ADM20027, ₹14,000)
-- txn 40 (ADM20029, ₹9,000)

-- Child records whose PARENT does not exist
SELECT ftd.detail_id, ftd.transaction_id, ftd.admission_no,
       ftd.fee_head, ftd.amount, ftd.status
FROM financial_transaction_detail ftd
LEFT JOIN financial_transaction ft
    ON ftd.transaction_id = ft.transaction_id
WHERE ft.transaction_id IS NULL
ORDER BY ftd.detail_id;

-- RESULT: 4 orphan child records:
-- detail 79 | txn 141 | ADM20029 | Development Fee | ₹2,000
-- detail 80 | txn 142 | ADM20008 | Exam Fee        | ₹3,500
-- detail 81 | txn 143 | ADM20002 | Tuition Fee     | ₹4,000
-- detail 82 | txn 144 | ADM20015 | Development Fee | ₹2,000


-- ============================================================
-- 3.7  Final reconciliation report                       [2]
-- ============================================================

SELECT
    COALESCE(p.admission_no, c.admission_no) AS admission_no,
    COALESCE(p.parent_amount, 0) AS parent_amount,
    COALESCE(c.child_amount, 0) AS child_amount,
    COALESCE(p.parent_amount, 0) - COALESCE(c.child_amount, 0) AS difference,
    COALESCE(p.parent_count, 0) AS parent_count,
    COALESCE(c.child_count, 0) AS child_count,
    CASE
        WHEN COALESCE(p.parent_amount, 0) = COALESCE(c.child_amount, 0)
         AND COALESCE(p.parent_count, 0) = COALESCE(c.child_count, 0)
        THEN 'MATCH'
        ELSE 'MISMATCH'
    END AS status
FROM
    (SELECT admission_no,
            SUM(total_amount) AS parent_amount,
            COUNT(*) AS parent_count
     FROM financial_transaction
     GROUP BY admission_no) p
LEFT JOIN
    (SELECT admission_no,
            SUM(amount) AS child_amount,
            COUNT(DISTINCT transaction_id) AS child_count
     FROM financial_transaction_detail
     GROUP BY admission_no) c
ON p.admission_no = c.admission_no
UNION
SELECT
    COALESCE(p.admission_no, c.admission_no),
    COALESCE(p.parent_amount, 0),
    COALESCE(c.child_amount, 0),
    COALESCE(p.parent_amount, 0) - COALESCE(c.child_amount, 0),
    COALESCE(p.parent_count, 0),
    COALESCE(c.child_count, 0),
    CASE
        WHEN COALESCE(p.parent_amount, 0) = COALESCE(c.child_amount, 0)
         AND COALESCE(p.parent_count, 0) = COALESCE(c.child_count, 0)
        THEN 'MATCH'
        ELSE 'MISMATCH'
    END
FROM
    (SELECT admission_no,
            SUM(total_amount) AS parent_amount,
            COUNT(*) AS parent_count
     FROM financial_transaction
     GROUP BY admission_no) p
RIGHT JOIN
    (SELECT admission_no,
            SUM(amount) AS child_amount,
            COUNT(DISTINCT transaction_id) AS child_count
     FROM financial_transaction_detail
     GROUP BY admission_no) c
ON p.admission_no = c.admission_no
ORDER BY admission_no;

-- RESULT: 30 admission numbers total
-- 17 MATCH, 13 MISMATCH


-- ████████████████████████████████████████████████████████████
-- TASK 4 — API Troubleshooting                    [15 MARKS]
-- ████████████████████████████████████████████████████████████

-- ============================================================
-- SCENARIO A — ADM10025 / PAY45872 / HTTP 200 but wrong due
-- ============================================================

-- 4A.1  Root Cause Analysis                              [3]
-- ---------------------------------------------------------------
-- From the logs:
-- 1. PaymentController received the request — OK
-- 2. PaymentGateway returned SUCCESS — the money was collected
-- 3. FeeService inserted fee_transactions record (txn 518) — OK
-- 4. FeeService inserted fee_transaction_details for "Tuition Fee ₹10,000" — OK
-- 5. FeeService FAILED to insert "Exam Fee ₹5,000" — ERROR:
--    "Duplicate entry '3024' for key 'detail_id_seq'"
--    → The application tried to use detail_id 3024 which already
--      existed. This is a primary key collision caused by a faulty
--      sequence/ID generation mechanism.
-- 6. CRITICAL: "caught by generic exception handler, transaction
--    NOT rolled back" — the error was swallowed and the partial
--    insert was left in place.
-- 7. PaymentController returned HTTP 200 to the client — the student
--    was told payment was successful (which it was at gateway level).
-- 8. DueCalculationJob recalculated using fee_transaction_details
--    aggregation, resulting in ₹5,000 outstanding because the ₹5,000
--    Exam Fee child record was never inserted.

-- 4A.2  Issue Classification                             [1]
-- ---------------------------------------------------------------
-- Classification: APPLICATION + DATA
-- - Application bug: The error handler does not rollback the
--   transaction on child insert failure, and still returns HTTP 200.
-- - Data bug: The detail_id generation is producing duplicates
--   (possibly a non-thread-safe sequence or race condition).

-- 4A.3  SQL to verify the issue                          [2]
-- ---------------------------------------------------------------

-- Verify parent vs child mismatch for transaction 518
SELECT ft.transaction_id, ft.total_amount AS parent_amount,
       COALESCE(SUM(ftd.amount), 0) AS child_total,
       ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS missing_amount
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ft.transaction_id = 518
GROUP BY ft.transaction_id, ft.total_amount;

-- Check if detail_id 3024 already exists
SELECT * FROM fee_transaction_details WHERE detail_id = 3024;

-- Check outstanding calculated from details
SELECT
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END)
    AS outstanding_from_details
FROM fee_transaction_details ftd
JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ftd.admission_no = 'ADM10025';

-- 4A.4  Fix and Testing                                  [2]
-- ---------------------------------------------------------------
-- IMMEDIATE FIX (data correction):
--   INSERT the missing child record (as done in Task 2.5 above).
--
-- APPLICATION FIX:
-- 1. Wrap the parent insert + ALL child inserts in a single
--    database transaction (BEGIN ... COMMIT). On any failure → ROLLBACK.
-- 2. Replace manual detail_id generation with AUTO_INCREMENT.
-- 3. Change the exception handler to trigger ROLLBACK and return
--    an appropriate error response (HTTP 500 or 4xx), NOT HTTP 200.
-- 4. Add a post-insert validation step: verify
--    SUM(child amounts) = parent amount before COMMIT.
--
-- TESTING:
-- 1. Insert a test payment and intentionally cause a child failure
--    → verify the entire transaction rolls back.
-- 2. Confirm no partial records remain in fee_transaction_details.
-- 3. Confirm the API returns an error (not 200) on failure.
-- 4. Run a reconciliation query to ensure parent = SUM(child).


-- ============================================================
-- SCENARIO B — ADM10089 / PAY51190 / HTTP 500
-- ============================================================

-- 4B.5  Root Cause Analysis                              [3]
-- ---------------------------------------------------------------
-- From the logs:
-- 1. PaymentController received the request — OK
-- 2. PaymentGateway returned SUCCESS — money was collected by gateway
-- 3. FeeService got "Lock wait timeout exceeded" on fee_transactions
--    → This means another transaction was holding a lock on the
--      fee_transactions table for too long (>30 seconds typically).
--    → Common causes: long-running query, deadlock, or another
--      concurrent transaction that is not committing/rolling back.
-- 4. Insert into fee_transactions FAILED completely.
-- 5. PaymentController returned HTTP 500 (unhandled exception).
-- 6. ReconciliationJob flagged: "Gateway shows SUCCESS for PAY51190
--    but no matching fee_transactions record found."
--
-- ROOT CAUSE: Lock contention / database concurrency issue.
-- The payment gateway successfully collected ₹12,000 from the student,
-- but the application could not persist the record in the database
-- due to a lock timeout. The money was taken but no record exists.

-- 4B.6  Issue Classification                             [1]
-- ---------------------------------------------------------------
-- Classification: DATABASE + APPLICATION
-- - Database: Lock contention / long-running transaction holding
--   exclusive locks on fee_transactions.
-- - Application: No retry mechanism, and no reconciliation flow
--   to handle gateway-success / database-failure scenarios.

-- 4B.7  Fix, Testing, and Reconciliation                 [3]
-- ---------------------------------------------------------------
-- IMMEDIATE FIX (manual reconciliation):
-- 1. Query the payment gateway API for PAY51190 details to confirm
--    the exact amount and status.
-- 2. Manually insert the missing records:

-- INSERT INTO fee_transactions
--     (transaction_id, admission_no, transaction_date,
--      transaction_type, total_amount, status)
-- VALUES (
--     (SELECT max_id FROM (SELECT MAX(transaction_id)+1 AS max_id
--      FROM fee_transactions) t),
--     'ADM10089', '2025-09-16', 'PAID', 12000, 'Success'
-- );
-- (Then insert corresponding fee_transaction_details)

-- SYSTEMIC FIX:
-- 1. RETRY LOGIC: Implement automatic retry (with exponential backoff)
--    for lock-wait-timeout errors before giving up.
-- 2. IDEMPOTENT WRITES: Use payment_id as a unique key to prevent
--    double inserts on retry.
-- 3. GATEWAY RECONCILIATION JOB: A scheduled job should compare
--    gateway-confirmed payments against fee_transactions. Any payment
--    the gateway shows as SUCCESS but with no database record should
--    be flagged and auto-inserted (or queued for manual review).
-- 4. TRANSACTION TIMEOUT TUNING: Investigate why locks are held too
--    long — review slow queries, batch jobs, and index coverage.
-- 5. CONNECTION POOL / TIMEOUT SETTINGS: Adjust innodb_lock_wait_timeout
--    and ensure transactions commit/rollback promptly.
--
-- TESTING:
-- 1. Simulate lock contention and verify retry logic kicks in.
-- 2. Confirm that after retries, the record is eventually persisted.
-- 3. Run the gateway reconciliation job and verify it catches the
--    mismatch and either auto-inserts or raises an alert.
-- 4. Verify the student's outstanding balance is updated correctly
--    after manual reconciliation.


-- ████████████████████████████████████████████████████████████
-- TASK 5 — AI Technical Troubleshooting           [15 MARKS]
-- ████████████████████████████████████████████████████████████

-- ============================================================
-- 5.1  Possible reasons the AI gave an incorrect answer  [3]
-- ============================================================

-- 1. STALE DATA / CACHE: The retrieved context shows "Snapshot
--    generated: 2025-09-15 23:00 IST" but a ₹5,000 payment was made
--    on 2025-09-10. If the snapshot was generated BEFORE that payment
--    was processed into the system, the context would still show
--    ₹12,500. The live DB now shows ₹8,500 (₹12,500 - ₹5,000 + any
--    new dues), but the AI used an old snapshot.
--
-- 2. RAG RETRIEVAL USING OUTDATED INDEX: The vector database or
--    document store the AI queries may not have been refreshed after
--    the last payment. The retrieval layer returned stale student
--    records.
--
-- 3. DATABASE SYNC LAG: The AI system may read from a read replica
--    that is lagging behind the primary database.
--
-- 4. EMBEDDING MISMATCH: The AI's retrieval might have pulled a
--    record for the wrong snapshot date or the wrong student.
--
-- 5. LLM HALLUCINATION (less likely here): The LLM could in theory
--    fabricate a number, but since the retrieved context explicitly
--    says ₹12,500, the LLM correctly echoed that value — the problem
--    is upstream in retrieval, not in the LLM itself.


-- ============================================================
-- 5.2  Issue category and justification                  [4]
-- ============================================================

-- CATEGORY: Data Retrieval / RAG-Retrieval (Stale Context)
--
-- JUSTIFICATION:
-- The evidence clearly shows this is NOT an LLM hallucination. The
-- retrieved context document explicitly states "Outstanding Fee: ₹12,500"
-- and the AI faithfully reported that number. The LLM did its job
-- correctly — it answered based on the context it was given.
--
-- The root issue is in the DATA RETRIEVAL layer:
-- - The snapshot was generated at "2025-09-15 23:00 IST"
-- - The last payment of ₹5,000 was on 2025-09-10
-- - The live DB currently shows ₹8,500
-- - This means EITHER:
--   a) The snapshot was generated BEFORE the payment was reflected
--      (processing delay), OR
--   b) A new due was added between 2025-09-10 and 2025-09-15, and
--      then another payment was made after 2025-09-15, bringing it
--      to ₹8,500 — but the snapshot still reflects the old ₹12,500
--
-- In either case, the AI's retrieval layer served a STALE snapshot
-- to the LLM, which then correctly reported the outdated number.


-- ============================================================
-- 5.3  How to investigate the complete flow              [3]
-- ============================================================

-- INVESTIGATION FLOW:
--
-- 1. USER QUERY → AI APPLICATION
--    - Check the AI application logs to confirm the exact user query
--      was received correctly ("outstanding fee for ADM10501").
--    - Verify no query rewriting or misinterpretation occurred.
--
-- 2. AI APPLICATION → DATA RETRIEVAL / API
--    - Check what retrieval query the AI application generated.
--    - Was it querying a live API? A cached document store? A vector DB?
--    - Log the exact data source queried and the parameters used.
--
-- 3. DATA RETRIEVAL / API → DATABASE
--    - If the system uses a live API, check the API endpoint logs.
--    - Query the live database directly:
--      SELECT outstanding_fee FROM student_fees
--      WHERE admission_no = 'ADM10501';
--    - Compare the live value (₹8,500) against what the retrieval
--      layer returned (₹12,500).
--    - Check the snapshot generation timestamp and the payment history
--      to identify when the data went stale.
--
-- 4. DATABASE → CONTEXT / RAG
--    - Check when the RAG index was last refreshed.
--    - Verify the document/embedding for ADM10501 in the vector store.
--    - Compare the stored embedding's associated text with the current
--      database values.
--
-- 5. CONTEXT / RAG → LLM
--    - Review the exact prompt + retrieved context sent to the LLM.
--    - Verify the LLM received the stale ₹12,500 figure.
--
-- 6. LLM → FINAL RESPONSE
--    - Confirm the LLM's response matches the context it was given.
--    - In this case, the LLM correctly echoed ₹12,500 from context,
--      confirming the problem is upstream (stale retrieval), not
--      in the LLM.


-- ============================================================
-- 5.4  Independently verify the actual database value    [2]
-- ============================================================

-- Run directly against the LIVE (primary) database:
-- SELECT admission_no, outstanding_fee, last_payment_date, last_payment_amount
-- FROM student_fee_summary
-- WHERE admission_no = 'ADM10501';

-- Or calculate from transaction records:
-- SELECT
--   SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END)
--   - SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END)
--   - SUM(CASE WHEN transaction_type = 'CONCESSION' THEN total_amount ELSE 0 END)
--     AS current_outstanding
-- FROM fee_transactions
-- WHERE admission_no = 'ADM10501';

-- Compare this live value (expected ₹8,500) against:
-- a) What the API returns (hit the fee API endpoint directly)
-- b) What the RAG/vector store has indexed
-- c) What the AI assistant reported (₹12,500)
-- Any discrepancy between (a) and (b) confirms stale retrieval data.


-- ============================================================
-- 5.5  Technical solution to prevent recurrence          [2]
-- ============================================================

-- 1. REAL-TIME API CALLS: For financial queries (fees, balances,
--    payments), the AI should make a LIVE API call to the database
--    instead of relying on pre-generated snapshots or cached embeddings.
--    This ensures the answer is always based on the current state.
--
-- 2. TIMESTAMP-AWARE RETRIEVAL: If snapshots must be used, include
--    the snapshot timestamp in the AI's response:
--    "As of 2025-09-15 23:00, your outstanding fee is ₹12,500.
--     Note: This may not reflect recent payments."
--
-- 3. FREQUENT INDEX REFRESH: Increase the RAG index refresh frequency
--    (e.g., every 15 minutes instead of daily) for financial data.
--
-- 4. HYBRID APPROACH: Use RAG for static information (program details,
--    policies) but LIVE API calls for dynamic/transactional data
--    (outstanding fees, payment status, exam results).
--
-- 5. STALENESS DETECTION: Before answering, the AI should check if
--    the retrieved context is older than a configurable threshold
--    (e.g., 1 hour). If stale, fetch fresh data via API.
--
-- 6. GUARDRAILS: Add a system prompt instruction telling the LLM to
--    flag that financial figures come from a snapshot and may not be
--    current, prompting the user to verify with the finance office
--    if the snapshot is old.


-- ============================================================
-- 5.6  How to test the AI's response after the fix       [1]
-- ============================================================

-- 1. Update the student fee record in the database to a known value
--    (e.g., set ADM10501 outstanding to ₹8,500).
-- 2. If using live API: Verify the API returns ₹8,500 for ADM10501.
-- 3. Ask the AI: "What is the outstanding fee for ADM10501?"
-- 4. Verify the AI responds with ₹8,500 (matching live DB).
-- 5. Then make a test payment of ₹500, reducing outstanding to ₹8,000.
-- 6. Immediately ask the AI the same question again.
-- 7. Verify the AI now responds with ₹8,000 (confirming real-time
--    data retrieval, not stale cache).
-- 8. Run this test for multiple students to confirm consistency.
-- 9. Add automated regression tests that compare AI responses against
--    known database values after each code deployment.


-- ============================================================
-- END OF SOLUTION
-- ============================================================
