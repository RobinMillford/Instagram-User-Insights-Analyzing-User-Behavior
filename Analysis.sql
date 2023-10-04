create database insta;


use insta;



-- 1. Find the 5 oldest users.
SELECT
Top 5
name, createdtime
FROM users
ORDER BY createdtime ASC;


    --2. day of the week do most users register on 
    --We need to figure out when to schedule an ad campgain
SELECT
Top 1
DATENAME(WEEKDAY, TRY_CONVERT(datetime, createdtime)) AS day_of_week, COUNT(*) AS registrations
FROM users
WHERE TRY_CONVERT(datetime, createdtime) IS NOT NULL
GROUP BY DATENAME(WEEKDAY, TRY_CONVERT(datetime, createdtime))
ORDER BY registrations DESC;


-- 3. We want to target our inactive users with an email campaign. Find the users who have never posted a photo.
SELECT UserID, name
FROM users
WHERE UserID NOT IN (
    SELECT DISTINCT UserID
    FROM photos
);


-- 4. We're running a new contest to see who can get the most likes on a single photo
SELECT TOP 1 u.UserID, u.name, MAX(l.createdtime) AS max_likes_time, p.Photoid, COUNT(*) AS num_likes
FROM users u
INNER JOIN photos p ON u.UserID = p.UserID
INNER JOIN likes l ON p.Photoid = l.Photoid
GROUP BY u.UserID, u.name, p.Photoid
ORDER BY num_likes DESC, max_likes_time DESC;

-- 5. Our Investors want to know...How many times does the average user post? (total number of photos/total number of users)
SELECT COUNT(*) / COUNT(DISTINCT UserID) AS avg_photos_per_user
FROM photos;


-- 6. user ranking by postings higher to lower
SELECT u.UserID, u.name, COUNT(p.Photoid) AS num_posts
FROM users u
LEFT JOIN photos p ON u.UserID = p.UserID
GROUP BY u.UserID, u.name
ORDER BY num_posts DESC;


-- 7. Total Posts by users (longer versionof SELECT COUNT(*)FROM photos)
SELECT u.UserID, u.name, COUNT(p.Photoid) AS num_posts
FROM users u
LEFT JOIN photos p ON u.UserID = p.UserID
GROUP BY u.UserID, u.name;


-- 8. Total numbers of users who have posted at least one time
SELECT COUNT(DISTINCT UserID) AS num_users
FROM photos;


-- 9. top 5 most commonly used hashtags
SELECT
Top 5
tagtext, COUNT(*) AS num_uses
FROM photo_tags
JOIN tags ON photo_tags.tagId = tags.tagID
GROUP BY tagtext
ORDER BY num_uses DESC;


-- 10. users who have liked every single photo on the site
SELECT DISTINCT l.UserID, u.Name
FROM likes l
INNER JOIN (
    SELECT UserID
    FROM likes
    GROUP BY UserID
    HAVING COUNT(DISTINCT PhotoID) = (SELECT COUNT(DISTINCT PhotoID) FROM photos)
) AS liked_all_photos ON l.UserID = liked_all_photos.UserID
INNER JOIN users u ON l.UserID = u.UserID;


-- 11. Find users who have never commented on a photo
SELECT u.UserID, u.name
FROM users u
LEFT JOIN comments c
ON u.UserID = c.UserID
WHERE c.comment IS NULL;


-- 12. the percentage of our users who have either never commented on a photo or have commented on every photo
SELECT COUNT(DISTINCT users.UserID) AS total_users,
    (SELECT COUNT(DISTINCT UserID) FROM likes) AS users_with_likes,
    (SELECT COUNT(DISTINCT UserID) FROM comments) AS users_with_comments,
    (SELECT COUNT(DISTINCT likes.UserID) FROM likes
    JOIN photos ON likes.PhotoID = photos.PhotoID
    WHERE NOT EXISTS (SELECT * FROM comments WHERE comments.UserID = likes.UserID AND comments.PhotoID = photos.PhotoID)) AS users_with_likes_only,
    (SELECT COUNT(DISTINCT UserID) FROM users
    WHERE UserID NOT IN (SELECT DISTINCT UserID FROM comments)) AS users_without_comments,
    ((SELECT COUNT(DISTINCT UserID) FROM users WHERE UserID NOT IN (SELECT DISTINCT UserID FROM comments))
    + (SELECT COUNT(DISTINCT likes.UserID) FROM likes
    JOIN photos ON likes.PhotoID = photos.PhotoID
    WHERE NOT EXISTS (SELECT * FROM comments WHERE comments.UserID = likes.UserID AND comments.PhotoID = photos.PhotoID)))
    / COUNT(DISTINCT users.UserID) * 100 AS bot_celeb_percentage
FROM users;


-- 13. users who have ever commented on a photo
SELECT DISTINCT UserID
FROM comments;

-- 14. the percentage of our users who have either never commented on a photo or have commented on photos before.

SELECT
    (COUNT(DISTINCT CASE WHEN c.userID IS NULL THEN u.userID END) * 1.0 / COUNT(DISTINCT u.userID)) * 100 AS percentage
FROM
    users u
    LEFT JOIN comments c ON u.userID = c.userID;