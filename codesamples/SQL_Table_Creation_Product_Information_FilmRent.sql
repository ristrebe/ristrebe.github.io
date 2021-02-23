-- Aim: Select relevant information on films in a film rent company

SELECT 
  film.film_id,
  title,
  name AS category,
  COALESCE(total_number_rents, 0) AS total_number_rents,
  COALESCE(total_revenue, 0) AS total_revenue,
  COALESCE(number_copies, 0) AS number_copies,
  COALESCE(top_20_actor, 0) AS top_20_actor
FROM
  film
INNER JOIN
  film_category
ON film.film_id = film_category.film_id
INNER JOIN
  category
ON film_category.category_id = category.category_id

-- Get the number of copies available of each film in the inventory
LEFT OUTER JOIN
  (
  SELECT
    COUNT(inventory.film_id) AS number_copies,
    film.film_id
  FROM 
    film
  INNER JOIN
    inventory
  ON film.film_id = inventory.film_id
  GROUP BY
    film.film_id
  ) copy_count
ON copy_count.film_id = film.film_id

-- Get the total number of rents for each film
LEFT OUTER JOIN
  (
  SELECT
    COUNT(rental_id) AS total_number_rents,
    film.film_id
  FROM 
    film
  INNER JOIN
    inventory
  ON film.film_id = inventory.film_id
  INNER JOIN
    rental
  ON inventory.inventory_id = rental.inventory_id
  GROUP BY
    film.film_id
  ) film_rents
ON copy_count.film_id = film_rents.film_id

-- Get the total revenue for each film
LEFT OUTER JOIN
  (
  SELECT
    SUM(amount) AS total_revenue,
    film.film_id
  FROM 
    film
  INNER JOIN
    inventory
  ON film.film_id = inventory.film_id
  INNER JOIN
    rental
  ON inventory.inventory_id = rental.inventory_id
  INNER JOIN
    payment
  ON rental.rental_id = payment.rental_id
  GROUP BY
    film.film_id
  ) revenue_film
ON copy_count.film_id = revenue_film.film_id

-- Get the information for each film if a top 20 actor with respect to revenue is starring in the film
LEFT OUTER JOIN
  (
  SELECT
    film.film_id,
    MAX(CASE WHEN film_actor.actor_id IN(
						 SELECT actors_most_profitable.actor_id 
						 FROM (
								SELECT
								  actor.actor_id,
								  SUM(amount) AS total_revenue
								FROM
								  actor
								INNER JOIN
								  film_actor
								ON actor.actor_id = film_actor.actor_id
								INNER JOIN
								  inventory
								ON film_actor.film_id = inventory.film_id
								INNER JOIN
								  rental
								ON rental.inventory_id = inventory.inventory_id
                                INNER JOIN
                                  payment
								ON rental.rental_id = payment.rental_id
								GROUP BY actor.actor_id
								ORDER BY total_revenue DESC
								LIMIT 20
                                ) actors_most_profitable
							)
   THEN 1 ELSE 0 END) AS top_20_actor
   FROM 
     film_actor
   RIGHT OUTER JOIN
     film
   ON film.film_id = film_actor.film_id
   GROUP BY
     film.film_id
    ) top_actors
ON copy_count.film_id = top_actors.film_id
GROUP BY
  film.film_id
ORDER BY total_revenue DESC
  
  