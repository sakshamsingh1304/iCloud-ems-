SELECT '====== TASK 2.1: Investigate ADM10025 ======' AS '';

SELECT '--- All fee_transactions for ADM10025 ---' AS '';
SELECT * FROM fee_transactions WHERE admission_no = 'ADM10025' ORDER BY transaction_date;

SELECT '--- All fee_transaction_details for ADM10025 ---' AS '';
SELECT * FROM fee_transaction_details WHERE admission_no = 'ADM10025' ORDER BY transaction_id;

SELECT '--- Due vs Paid Summary from fee_transactions (parent) ---' AS '';
SELECT
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN transaction_type = 'CONCESSION' THEN total_amount ELSE 0 END) AS total_concession,
    SUM(CASE WHEN transaction_type = 'DUE' THEN total_amount ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'PAID' THEN total_amount ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'CONCESSION' THEN total_amount ELSE 0 END) AS outstanding
FROM fee_transactions
WHERE admission_no = 'ADM10025';

SELECT '====== TASK 2.2: Root Cause - Check Transaction 518 ======' AS '';

SELECT '--- Parent vs Child for transaction 518 ---' AS '';
SELECT ft.transaction_id, ft.total_amount AS parent_amount,
       COALESCE(SUM(ftd.amount), 0) AS child_total,
       ft.total_amount - COALESCE(SUM(ftd.amount), 0) AS shortfall
FROM fee_transactions ft
LEFT JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ft.transaction_id = 518
GROUP BY ft.transaction_id, ft.total_amount;

SELECT '--- Child records for transaction 518 ---' AS '';
SELECT * FROM fee_transaction_details WHERE transaction_id = 518;

SELECT '====== TASK 2.3: Proof of Discrepancy ======' AS '';
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

SELECT '====== TASK 2.5: Data Correction ======' AS '';

SELECT '--- Next available detail_id ---' AS '';
SELECT MAX(detail_id) + 1 AS next_detail_id FROM fee_transaction_details;

INSERT INTO fee_transaction_details (detail_id, transaction_id, admission_no, fee_head, amount, status)
VALUES (
    (SELECT max_id FROM (SELECT MAX(detail_id) + 1 AS max_id FROM fee_transaction_details) t),
    518, 'ADM10025', 'Exam Fee', 5000, 'Success'
);

SELECT '--- After fix: transaction 518 reconciliation ---' AS '';
SELECT ft.transaction_id, ft.total_amount AS parent_amount,
       SUM(ftd.amount) AS child_total,
       ft.total_amount - SUM(ftd.amount) AS difference
FROM fee_transactions ft
JOIN fee_transaction_details ftd ON ft.transaction_id = ftd.transaction_id
WHERE ft.transaction_id = 518
GROUP BY ft.transaction_id, ft.total_amount;

SELECT '--- After fix: outstanding verification ---' AS '';
SELECT
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END) AS total_due,
    SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN ft.transaction_type = 'DUE' THEN ftd.amount ELSE 0 END)
    - SUM(CASE WHEN ft.transaction_type = 'PAID' THEN ftd.amount ELSE 0 END) AS outstanding
FROM fee_transaction_details ftd
JOIN fee_transactions ft ON ftd.transaction_id = ft.transaction_id
WHERE ftd.admission_no = 'ADM10025';
