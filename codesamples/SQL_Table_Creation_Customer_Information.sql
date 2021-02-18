##Aim: Select relevant information on customers of a film rent company

SELECT
  customer.customer_id,
  first_name,
  last_name,
  revenue,
  total_number_rents,
  name AS preferred_category,
  last_rent.rental_date AS date_last_rent
FROM ( 

##Select the category that is most often rent for each customer
  SELECT
    COUNT(film_category.category_id) AS frequency_category,
    name,
    ROW_NUMBER() over (PARTITION BY customer_id ORDER BY frequency_category DESC) sequence_1,
    rental.customer_id
  FROM 
    category
  INNER JOIN 
    film_category
  ON category.category_id = film_category.category_id
  INNER JOIN
    film
  ON film.film_id = film_category.film_id
  INNER JOIN
    inventory
  ON inventory.film_id = film.film_id
  INNER JOIN rental
    ON rental.inventory_id = inventory.inventory_id
  GROUP BY
    name,
    rental.customer_id
 ) category_selection
INNER JOIN
(

##Select the date of the last rent for each customer
  SELECT
    rental_id,
    rental_date,
    ROW_NUMBER() over (PARTITION BY customer_id ORDER BY rental_date DESC) AS sequence_2,
    customer_id
  FROM rental) last_rent
ON category_selection.customer_id = last_rent.customer_id
INNER JOIN 
  customer
ON customer.customer_id = last_rent.customer_id
INNER JOIN
  (
  
##Get the sum of revenues for each customer
  SELECT
    SUM(amount) AS revenue,
    customer_id
  FROM payment
  GROUP BY
    customer_id ) revenue
ON revenue.customer_id = last_rent.customer_id
INNER JOIN
  rental
ON last_rent.customer_id = rental.customer_id
INNER JOIN
  (
  
##Get the total number of rents for each customer
  SELECT
    COUNT(rental_id) AS total_number_rents,
    customer_id
   FROM rental
   GROUP BY
     customer_id) rent_count
ON last_rent.customer_id = rent_count.customer_id
WHERE sequence_1 = 1
AND sequence_2 = 1

##narrow down on only active customers
AND active = 1

GROUP BY
  first_name,
  last_name,
  date_last_rent,
  preferred_category
ORDER BY
  total_number_rents DESC