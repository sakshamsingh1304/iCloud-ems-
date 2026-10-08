# Explanation and Methodology

This document explains the approach, logic, and methodology used to solve the iCloudEMS Technical Assignment in simple terms.

## Task 1: MySQL Database & Data Processing

**My Approach & Solution:**
I needed to analyze the provided database and find specific information like duplicates, total fees, and missing records. I wrote SQL queries for each sub-task to filter, group, and calculate the required data. 

**Logic & Methodology:**
*   **Finding Duplicates:** I used `GROUP BY` to group records that had the exact same details (like the same admission number or same transaction details). I then used `HAVING COUNT(*) > 1` to filter out any groups that had more than one record. For fee transactions, I made sure to include the `transaction_date` in the grouping, so two valid payments of the same amount on different days weren't falsely marked as duplicates.
*   **Calculating Dues:** To find out how much a student owed, I added up all their `DUE` amounts and subtracted all their `PAID` and `CONCESSION` amounts using a conditional `SUM(CASE WHEN...)` statement.
*   **Matching Parents to Children:** The `fee_transactions` table acts as the "parent" (the total payment), and `fee_transaction_details` is the "child" (the breakdown). I used `LEFT JOIN` to connect them. To find mismatches, I checked if the parent's total amount was different from the sum of the children's amounts. To find missing records (orphans), I looked for cases where the joined record was `NULL`.

---

## Task 2: Real-World Support Bug (Student ADM10025)

**My Approach & Solution:**
A student paid ₹15,000, but the system still said they owed ₹5,000. I investigated by looking at the parent transaction and its child records. I found that the parent record successfully saved ₹15,000, but one of the child records (the ₹5,000 Exam Fee) failed to save. I wrote an `INSERT` statement to add the missing ₹5,000 child record to fix the data.

**Logic & Methodology:**
*   **Why it broke:** The system tried to save the child record with an ID (`detail_id_seq`) that already existed, causing a "Duplicate entry" error.
*   **Why the system still showed success:** The database code wasn't wrapped in a "transaction" (Atomicity). When the child record failed to save, the application just ignored the error and told the student the payment was completely successful. 
*   **Why the due amount was wrong:** The background job that calculates due amounts only looks at the child records. Since the ₹5,000 child record was missing, it calculated the due amount incorrectly.
*   **How to prevent it:** Developers must use Database Transactions (`BEGIN` and `COMMIT/ROLLBACK`). This ensures that if *any* child record fails to save, the entire payment is cancelled, preventing partial data from being saved.

---

## Task 3: Parent/Child Transaction Reconciliation

**My Approach & Solution:**
I needed to verify that the `financial_transaction` (parent) table perfectly matched the `financial_transaction_detail` (child) table in the second database (`icloud_task3`). I wrote queries to compare the total amounts and the number of transactions between the two tables.

**Logic & Methodology:**
*   I created two separate summaries: one summarizing the parent table by admission number, and one summarizing the child table by admission number.
*   I then joined these two summaries together. If a parent record had no children, or a child record had no parent, the missing side would show up as `NULL`. I used `COALESCE` to turn those `NULL` values into `0`.
*   Finally, I compared the parent totals against the child totals. If they matched exactly, I labeled it `MATCH`. If there was any difference in the amount or the count, I labeled it `MISMATCH`.

---

## Task 4: API Troubleshooting

**My Approach & Solution:**
I analyzed two server logs to understand why API errors were happening.

**Logic & Methodology:**
*   **Scenario A (HTTP 200 with wrong due):** This was the exact same logic as Task 2. The database failed to save a child record because of a duplicate primary key, but the app didn't roll back the transaction and incorrectly sent a "Success" message to the user.
*   **Scenario B (HTTP 500 error):** The log showed a "Lock wait timeout exceeded" error. 
    *   **Logic:** This means the database was busy and locked the table. The app waited too long to save the payment and eventually crashed. The payment gateway collected the money, but the database didn't record it.
    *   **Methodology to fix:** The application needs a "Retry" mechanism to try saving again if the database is locked. It also needs a background reconciliation job to check the payment gateway every night and automatically record any payments that were missed by the database.

---

## Task 5: AI Technical Troubleshooting

**My Approach & Solution:**
The AI chatbot told a student their outstanding fee was ₹12,500, even though the live database showed they only owed ₹8,500. I investigated why the AI gave the wrong number.

**Logic & Methodology:**
*   **Logic:** The AI was not "hallucinating" (making things up). The log showed that the AI was given a "Snapshot generated: 2025-09-15 23:00". 
*   **Methodology:** The AI system is using a Retrieval-Augmented Generation (RAG) system with *stale* (old) data. The student made a payment *after* that snapshot was generated, so the live database was updated, but the AI's snapshot was not. 
*   **How to fix:** AI systems should never use cached snapshots for dynamic financial data. The AI should be programmed to make a real-time API call to the live database whenever a student asks for their balance.
