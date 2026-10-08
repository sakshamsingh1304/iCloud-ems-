SELECT '====== TASK 3.1: Row Counts ======' AS '';
SELECT 'financial_transaction' AS table_name, COUNT(*) AS row_count FROM financial_transaction
UNION ALL
SELECT 'financial_transaction_detail', COUNT(*) FROM financial_transaction_detail;

SELECT '====== TASK 3.2: Verify Data Integrity ======' AS '';
SELECT 'Expected parent rows' AS check_item, 41 AS expected, COUNT(*) AS actual,
       CASE WHEN COUNT(*) = 41 THEN 'OK' ELSE 'DATA LOSS' END AS status
FROM financial_transaction
UNION ALL
SELECT 'Expected child rows', 76, COUNT(*),
       CASE WHEN COUNT(*) = 76 THEN 'OK' ELSE 'DATA LOSS' END
FROM financial_transaction_detail;

SELECT '====== TASK 3.3: Reconcile Parent and Child Amounts Per Transaction ======' AS '';
SELECT
    ft.transaction_id,
    ft.admission_no,
    ft.total_amount AS parent_amount,
    COALESCE(SUM(ftd.amount), 0) AS child_amount,
    ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS difference,
    CASE WHEN ft.total_amount = COALESCE(SUM(ftd.amount), 0) THEN 'MATCH' ELSE 'MISMATCH' END AS status
FROM financial_transaction ft
LEFT JOIN financial_transaction_detail ftd ON ft.transaction_id = ftd.transaction_id
GROUP BY ft.transaction_id, ft.admission_no, ft.total_amount
ORDER BY ft.transaction_id;

SELECT '====== TASK 3.4: Transaction Count Reconciliation Per Admission ======' AS '';
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

SELECT '====== TASK 3.5: All Mismatches (Amount and/or Count) ======' AS '';
-- Amount mismatches per transaction
SELECT
    ft.transaction_id,
    ft.admission_no,
    ft.total_amount AS parent_amount,
    COALESCE(SUM(ftd.amount), 0) AS child_amount,
    ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS amount_difference,
    'AMOUNT MISMATCH' AS mismatch_type
FROM financial_transaction ft
LEFT JOIN financial_transaction_detail ftd ON ft.transaction_id = ftd.transaction_id
GROUP BY ft.transaction_id, ft.admission_no, ft.total_amount
HAVING ft.total_amount <> COALESCE(SUM(ftd.amount), 0)
ORDER BY ft.transaction_id;

SELECT '====== TASK 3.6: Orphans (both directions) ======' AS '';
SELECT '--- Parent transactions with no child records ---' AS '';
SELECT ft.transaction_id, ft.admission_no, ft.total_amount, ft.status
FROM financial_transaction ft
LEFT JOIN financial_transaction_detail ftd ON ft.transaction_id = ftd.transaction_id
WHERE ftd.detail_id IS NULL
ORDER BY ft.transaction_id;

SELECT '--- Child records whose parent does not exist ---' AS '';
SELECT ftd.detail_id, ftd.transaction_id, ftd.admission_no, ftd.fee_head, ftd.amount, ftd.status
FROM financial_transaction_detail ftd
LEFT JOIN financial_transaction ft ON ftd.transaction_id = ft.transaction_id
WHERE ft.transaction_id IS NULL
ORDER BY ftd.detail_id;

SELECT '====== TASK 3.7: Final Reconciliation Report ======' AS '';
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
