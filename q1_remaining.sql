SELECT '====== TASK 1.3: Duplicate Fee Transactions ======' AS '';
SELECT admission_no, transaction_type, total_amount,
       transaction_date, COUNT(*) AS duplicate_count
FROM fee_transactions
GROUP BY admission_no, transaction_type, total_amount, transaction_date
HAVING COUNT(*) > 1
ORDER BY admission_no;

SELECT '--- Full details of duplicates ---' AS '';
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

SELECT '====== TASK 1.4: Students with Outstanding/Due Amount ======' AS '';
SELECT DISTINCT s.student_id, s.admission_no, s.full_name,
       p.program_name
FROM students s
JOIN programs p ON s.program_id = p.program_id
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'DUE'
ORDER BY s.admission_no;

SELECT '====== TASK 1.5: Total Due Amount Admission-wise ======' AS '';
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

SELECT '====== TASK 1.6: Top 10 Students by Fee Collected (PAID) ======' AS '';
SELECT s.admission_no, s.full_name,
       SUM(ft.total_amount) AS total_paid
FROM students s
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'PAID'
GROUP BY s.admission_no, s.full_name
ORDER BY total_paid DESC
LIMIT 10;

SELECT '====== TASK 1.7: Top Programs by Fee Collected ======' AS '';
SELECT p.program_id, p.program_name,
       SUM(ft.total_amount) AS total_collected
FROM programs p
JOIN students s ON p.program_id = s.program_id
JOIN fee_transactions ft ON s.admission_no = ft.admission_no
WHERE ft.transaction_type = 'PAID'
GROUP BY p.program_id, p.program_name
ORDER BY total_collected DESC;

SELECT '====== TASK 1.8: Parent-Child Amount Mismatches ======' AS '';
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

SELECT '====== TASK 1.9: Parent Transactions with No Child Records ======' AS '';
SELECT ft.transaction_id, ft.admission_no, ft.transaction_date,
       ft.transaction_type, ft.total_amount, ft.status
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ftd.detail_id IS NULL
ORDER BY ft.transaction_id;

SELECT '====== TASK 1.10: Orphan Child Records (No Parent) ======' AS '';
SELECT ftd.detail_id, ftd.transaction_id, ftd.admission_no,
       ftd.fee_head, ftd.amount, ftd.status
FROM fee_transaction_details ftd
LEFT JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ft.transaction_id IS NULL
ORDER BY ftd.detail_id;

SELECT '====== TASK 1.11: Reconciliation Report ======' AS '';
SELECT
    COALESCE(p.admission_no, c.admission_no) AS admission_number,
    COALESCE(p.txn_count, 0) AS transaction_count,
    COALESCE(p.txn_amount, 0) AS transaction_amount,
    COALESCE(c.detail_count, 0) AS detail_count,
    COALESCE(c.detail_amount, 0) AS detail_amount,
    COALESCE(p.txn_amount, 0) - COALESCE(c.detail_amount, 0) AS difference
FROM
    (SELECT admission_no, COUNT(*) AS txn_count, SUM(total_amount) AS txn_amount
     FROM fee_transactions GROUP BY admission_no) p
LEFT JOIN
    (SELECT admission_no, COUNT(*) AS detail_count, SUM(amount) AS detail_amount
     FROM fee_transaction_details GROUP BY admission_no) c
ON p.admission_no = c.admission_no
UNION
SELECT
    COALESCE(p.admission_no, c.admission_no) AS admission_number,
    COALESCE(p.txn_count, 0) AS transaction_count,
    COALESCE(p.txn_amount, 0) AS transaction_amount,
    COALESCE(c.detail_count, 0) AS detail_count,
    COALESCE(c.detail_amount, 0) AS detail_amount,
    COALESCE(p.txn_amount, 0) - COALESCE(c.detail_amount, 0) AS difference
FROM
    (SELECT admission_no, COUNT(*) AS txn_count, SUM(total_amount) AS txn_amount
     FROM fee_transactions GROUP BY admission_no) p
RIGHT JOIN
    (SELECT admission_no, COUNT(*) AS detail_count, SUM(amount) AS detail_amount
     FROM fee_transaction_details GROUP BY admission_no) c
ON p.admission_no = c.admission_no
ORDER BY admission_number;
