WITH median_table (Company, n, Median, Modulo) AS
   (SELECT
       Company,
       MAX(salary_sequence) AS n,
       (MAX(salary_sequence)+1)/2 AS Median,
       (MAX(salary_sequence))%2 AS Modulo
    FROM
       (SELECT
           Id,
           Company,
           Salary,
           ROW_NUMBER() OVER (PARTITION BY Company ORDER BY Salary) AS salary_sequence
        FROM
           Employee) sorted_salary
    GROUP BY
       Company),
sorted_salary (Id, Company, Salary, salary_sequence) AS
   (SELECT
       Id,
       Company,
       Salary,
       ROW_NUMBER() OVER (PARTITION BY Company ORDER BY Salary) AS salary_sequence
    FROM
       Employee)
SELECT
   Id,
   sorted_salary.Company,
   Salary
FROM
   sorted_salary
INNER JOIN
   median_table
ON
   sorted_salary.Company = median_table.Company
WHERE
   CASE WHEN Modulo = 1 THEN salary_sequence = ROUND(Median, 0)
        ELSE (salary_sequence = ROUND(Median, 1) + 0.5 OR salary_sequence = ROUND(Median, 1) - 0.5)
        END