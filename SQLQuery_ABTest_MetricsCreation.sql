##A/B test on user level: SQL query for metrics creation
SELECT 
  assigned_users.user_id,
  test_assignment,
  MAX(CASE WHEN date(views.event_time) BETWEEN date(assigned_users.event_time) AND date(assigned_users.event_time) + 30 THEN 1 ELSE 0 END) AS views_binary,
  COUNT(CASE WHEN date(views.event_time) BETWEEN date(assigned_users.event_time) AND date(assigned_users.event_time) + 30 THEN parameter_value ELSE NULL END) AS number_views,
  MAX(CASE WHEN date(created_at) BETWEEN date(assigned_users.event_time) AND date(assigned_users.event_time) + 30 THEN 1 ELSE 0 END) AS orders_binary,
  COUNT(DISTINCT (CASE WHEN date(created_at) BETWEEN date(assigned_users.event_time) AND date(assigned_users.event_time) + 30 THEN invoice_id ELSE NULL END)) AS number_orders,
  COUNT(DISTINCT (CASE WHEN date(created_at) BETWEEN date(assigned_users.event_time) AND date(assigned_users.event_time) + 30 THEN line_item_id ELSE NULL END)) AS number_line_items,
  SUM(CASE WHEN date(created_at) BETWEEN date(assigned_users.event_time) AND date(assigned_users.event_time) + 30 THEN price ELSE 0 END) AS total_revenue
FROM (

##Create test assignment table on user level
  SELECT
           user_id,
           event_time,
           MAX(CASE WHEN parameter_name = 'test_id'
               THEN CAST(parameter_value AS INT)
               ELSE NULL END) AS test_id,
           MAX(CASE WHEN parameter_name = 'test_assignment'
               THEN CAST(parameter_value AS INT)
               ELSE NULL END) AS test_assignment
     FROM dsv1069.events
     WHERE event_name = 'test_assignment'
     GROUP BY
           user_id,
           event_time,
           event_id
      ) assigned_users
      
##Join tables for metric creation:
##events table for metrics views binary amd number views	  
LEFT OUTER JOIN (
  SELECT 
    *
  FROM 
    dsv1069.events
  WHERE 
    event_name = 'view_item'
  AND 
    parameter_name = 'item_id'
  ) views
ON assigned_users.user_id = views.user_id

##orders table for metrics orders binary, number orders, number line items and total revenue
LEFT OUTER JOIN 
  dsv1069.orders
ON 
  orders.user_id = assigned_users.user_id
WHERE test_id = 7
GROUP BY
  assigned_users.user_id,
  test_assignment;