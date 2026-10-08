-- Task 1.1: Row counts
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'programs', COUNT(*) FROM programs
UNION ALL SELECT 'students', COUNT(*) FROM students
UNION ALL SELECT 'admissions', COUNT(*) FROM admissions
UNION ALL SELECT 'fee_transactions', COUNT(*) FROM fee_transactions
UNION ALL SELECT 'fee_transaction_details', COUNT(*) FROM fee_transaction_details;
