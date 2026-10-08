-- ====== TASK 1.2: Duplicate admission numbers in students ======
SELECT admission_no, COUNT(*) AS occurrences
FROM students
GROUP BY admission_no
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, admission_no;

SELECT '--- Details of duplicate students ---' AS '';

SELECT s.student_id, s.admission_no, s.full_name, s.program_id, s.department_id, s.admission_year
FROM students s
INNER JOIN (
    SELECT admission_no FROM students GROUP BY admission_no HAVING COUNT(*) > 1
) dup ON s.admission_no = dup.admission_no
ORDER BY s.admission_no, s.student_id;
