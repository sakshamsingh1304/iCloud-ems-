# Technical Review Preparation Guide

This document outlines the logic, approach, and methodology used to complete the iCloudEMS Technical Assignment. It is intended to serve as a speaking guide for the technical review session.

## Task 1: MySQL Database & Data Processing

### Approach & Methodology
The goal of Task 1 was to analyze the `task1_university_erp_dataset.sql` dataset, perform aggregations, and identify data anomalies.

1.  **Finding Duplicates (Task 1.2 & 1.3)**: 
    *   **Logic**: A duplicate is defined as multiple records sharing the same unique identifying composite keys.
    *   **Methodology**: I used the `GROUP BY` clause combined with `HAVING COUNT(*) > 1`. For students, I grouped by `admission_no`. For fee transactions, I grouped by `admission_no`, `transaction_type`, `total_amount`, and crucially, `transaction_date` to ensure legitimate payments made on different dates were not flagged.
2.  **Aggregating Due Amounts (Task 1.4, 1.5, 1.6, 1.7)**:
    *   **Logic**: A student's outstanding balance is the sum of their `DUE` transactions minus their `PAID` and `CONCESSION` transactions.
    *   **Methodology**: I used conditional aggregation (`SUM(CASE WHEN transaction_type = 'X' THEN total_amount ELSE 0 END)`) joined across the `students`, `programs`, and `fee_transactions` tables.
3.  **Parent-Child Mismatches & Orphans (Task 1.8, 1.9, 1.10)**:
    *   **Logic**: The `fee_transactions` table acts as the parent (total payment), while `fee_transaction_details` acts as the child (itemized breakdown). They should match exactly.
    *   **Methodology**: 
        *   To find mismatches, I used a `LEFT JOIN` from parent to child, grouped by the parent ID, and compared `parent.total_amount` against `SUM(child.amount)`.
        *   To find orphans, I used `LEFT JOIN` in both directions and filtered for `WHERE [foreign_key] IS NULL`.

---

## Task 2: Real-World Support Bug (ADM10025)

### Approach & Methodology
*   **The Problem**: Student `ADM10025` paid ₹15,000, and the parent record showed the payment successfully. However, the system still indicated an outstanding balance of ₹5,000.
*   **The Investigation**: I queried both the parent and child tables for `ADM10025`. The parent transaction #518 showed ₹15,000. The child records for transaction #518 only added up to ₹10,000 (Tuition Fee). The ₹5,000 Exam Fee record was missing.
*   **The Root Cause**: According to the prompt's logs, the application threw a "Duplicate entry '3024' for key 'detail_id_seq'" error. The child insert failed. Because the database inserts were *not* wrapped in a database transaction, the application caught the error, left the partial data in the database, and returned an HTTP 200 Success anyway. 
*   **The Calculation Error**: The `DueCalculationJob` calculates outstanding fees by summing up the *child* records, completely ignoring the parent record. Because the child record was missing, the job calculated a false outstanding balance.
*   **The Fix**: I provided an `INSERT` statement to add the missing child record. I recommended enforcing database transactions (`BEGIN` ... `COMMIT/ROLLBACK`), using `AUTO_INCREMENT` for the primary key, and fixing the generic exception handler to return an HTTP 500 on database failures.

---

## Task 3: Parent/Child Transaction Reconciliation

### Approach & Methodology
The goal was to analyze `task3_reconciliation_dataset.sql` and reconcile the `financial_transaction` and `financial_transaction_detail` tables.

*   **Logic**: A healthy database requires the count and monetary sum of parent records per `admission_no` to match the count of distinct parent IDs and the sum of monetary amounts in the child records.
*   **Methodology**: I created subqueries (derived tables) that aggregated the parent table by `admission_no` and aggregated the child table by `admission_no`. I then used a `LEFT JOIN` and `RIGHT JOIN` combined with a `UNION` (to simulate a `FULL OUTER JOIN`, which MySQL does not support directly). I used `COALESCE` to handle `NULL` values representing orphan records. I categorized the output using a `CASE` statement to flag each admission number as either `MATCH` or `MISMATCH`.

---

## Task 4: API Troubleshooting

### Approach & Methodology
1.  **Scenario A (HTTP 200 with incorrect due)**: 
    *   This is identical to the Task 2 bug. The gateway processed the payment, but the database suffered a primary key constraint error on a child record. Lack of atomicity (no database transaction rollback) caused partial data corruption.
2.  **Scenario B (HTTP 500)**:
    *   **The Problem**: The gateway processed the payment, but the API returned a 500 error, and no database record was created.
    *   **Root Cause**: The logs show a "Lock wait timeout exceeded" error. The application attempted to write to the `fee_transactions` table but was blocked by another process holding a lock on the table for too long. The insert failed entirely.
    *   **The Fix**: Implemented automatic retry logic with exponential backoff for lock timeouts. Additionally, I recommended building a "Gateway Reconciliation Job" that periodically checks the payment gateway for successful payments and verifies they exist in the ERP database to catch dropped transactions.

---

## Task 5: AI Technical Troubleshooting

### Approach & Methodology
*   **The Problem**: A student's actual outstanding fee was ₹8,500, but the AI chatbot reported it as ₹12,500.
*   **The Investigation**: The prompt indicated the LLM's retrieved context stated "Snapshot generated: 2025-09-15 23:00 IST... Outstanding Fee: ₹12,500". The LLM correctly reported the information it was given. 
*   **Root Cause**: The issue is not an LLM hallucination, but rather **Stale Context in the Retrieval-Augmented Generation (RAG) system**. A payment (e.g., of ₹4,000) was made *after* the snapshot was generated, or the snapshot had not yet been updated in the vector database to reflect recent live transactions.
*   **The Fix**: Financial data (balances, due amounts) changes dynamically and is sensitive. AI assistants should not rely on pre-computed snapshots or vector embeddings for this data. Instead, the AI application should use function-calling to execute a live API request to the backend database to retrieve the real-time balance at the moment the user asks the question.
