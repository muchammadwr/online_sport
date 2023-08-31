DROP TABLE info;

CREATE TABLE info
(
    product_name VARCHAR(1000),
    product_id VARCHAR(11) PRIMARY KEY,
    description VARCHAR(7000)
);

DROP TABLE finance;

CREATE TABLE finance
(
    product_id VARCHAR(11) PRIMARY KEY,
    listing_price FLOAT,
    sale_price FLOAT,
    discount FLOAT,
    revenue FLOAT
);

DROP TABLE reviews;

CREATE TABLE reviews
(
    product_id VARCHAR(11) PRIMARY KEY,
    rating FLOAT,
    reviews FLOAT
);

DROP TABLE traffic;

CREATE TABLE traffic
(
    product_id VARCHAR(11) PRIMARY KEY,
    last_visited TIMESTAMP
);

DROP TABLE brands;

CREATE TABLE brands
(
    product_id VARCHAR(11) PRIMARY KEY,
    brand VARCHAR(7)
);


--- 1. Counting missing values

SELECT COUNT(*) AS total_rows,
    COUNT(description) AS count_description,
    COUNT(listing_price) AS count_listing_price,
    COUNT(last_visited) AS count_last_visited
FROM info AS i
LEFT JOIN finance AS f
ON i.product_id = f.product_id
LEFT JOIN traffic AS t
ON i.product_id = t.product_id

--- 2. Nike vs Adidas pricing

SELECT 
    brand, 
    CAST(listing_price AS integer) AS listing_price, 
    COUNT(f) 
FROM brands AS b
LEFT JOIN finance AS f
    ON b.product_id = f.product_id
LEFT JOIN traffic AS t
    ON b.product_id = t.product_id
WHERE listing_price > 0
GROUP BY 
    brand, 
    listing_price
ORDER BY listing_price DESC;

--- 3. Labeling price ranges

SELECT
    b.brand,
    COUNT(*),
    SUM(revenue) AS total_revenue,
    CASE
        WHEN f.listing_price < 42 THEN 'Budget'
        WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
        WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
        ELSE 'Elite' END AS price_category
FROM finance AS f
LEFT JOIN brands AS b
ON f.product_id = b.product_id
GROUP BY 
    b.brand, 
    price_category
HAVING b.brand IS NOT NULL
ORDER BY total_revenue DESC;

--- 4. Average discount by brand

SELECT
    brand,
    AVG(discount) * 100 AS average_discount
FROM brands AS b
LEFT JOIN finance AS f
ON b.product_id = f.product_id
WHERE brand IS NOT NULL
GROUP BY brand
HAVING AVG(discount) * 100 IS NOT NULL

--- 5. Correlation between revenue and reviews

SELECT
    CORR(reviews, revenue) AS review_revenue_corr
FROM reviews AS r
LEFT JOIN finance AS f
ON r.product_id = f.product_id

--- 6. Ratings and reviews by product description length

SELECT
    TRUNC(LENGTH(description), -2) as description_length,
    ROUND(AVG(rating::numeric), 2) as average_rating
FROM info AS i
LEFT JOIN reviews AS r 
ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;

--- 7. Reviews by month and brand

SELECT 
    brand, 
    DATE_PART('month', last_visited) AS month,
    COUNT(reviews) AS num_reviews
FROM traffic AS t
LEFT JOIN brands AS b 
    ON t.product_id = b.product_id
LEFT JOIN reviews AS r 
    ON t.product_id = r.product_id
GROUP BY 
    brand, 
    month
HAVING 
    brand IS NOT NULL AND 
    DATE_PART('month', t.last_visited) IS NOT NULL
ORDER BY 
    brand, 
    month;

--- 8. Footwear product performance

WITH footwear AS (
    SELECT 
        description, 
        revenue
    FROM info AS i 
    LEFT JOIN finance AS f 
    ON i.product_id = f.product_id
    WHERE 
        description ILIKE '%shoe%' OR 
        description ILIKE '%trainer%' OR 
        description ILIKE '%foot%' AND
        description IS NOT NULL
)

SELECT COUNT(*) AS num_footwear_products,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median_footwear_revenue
FROM footwear;

--- 9. Clothing product performance

WITH footwear AS (
    SELECT 
        description, 
        revenue
    FROM info AS i 
    LEFT JOIN finance AS f 
    ON i.product_id = f.product_id
    WHERE 
        i.description ILIKE '%shoe%' OR 
        i.description ILIKE '%trainer%' OR 
        i.description ILIKE '%foot%' AND
        i.description IS NOT NULL
)

SELECT COUNT(product_name) AS num_clothing_products,
     percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median_clothing_revenue
FROM info
JOIN finance ON info.product_id = finance.product_id
WHERE description NOT IN(SELECT description FROM footwear)