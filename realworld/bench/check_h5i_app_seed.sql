-- Compares the shared schema with rust-h5i-app's tables after seed.sql and
-- seed_h5i_app.sql: every diff column must be 0.
WITH pu AS (SELECT id, username, email, password_hash, coalesce(bio,'') bio, coalesce(image,'') image FROM public.users),
     cu AS (SELECT id, convert_from(username,'UTF8') username, convert_from(email,'UTF8') email, convert_from(password,'UTF8') password_hash, convert_from(bio,'UTF8') bio, convert_from(image,'UTF8') image FROM conduit.conduit_users),
     pa AS (SELECT id, author_id, slug, title, description, body, (extract(epoch FROM created_at)*1000)::bigint c, (extract(epoch FROM updated_at)*1000)::bigint u FROM public.articles),
     ca AS (SELECT id, author, convert_from(slug,'UTF8'), convert_from(title,'UTF8'), convert_from(description,'UTF8'), convert_from(body,'UTF8'), created, updated FROM conduit.conduit_articles),
     pt AS (SELECT at.article_id, t.name FROM public.article_tags at JOIN public.tags t ON t.id = at.tag_id),
     ct AS (SELECT article, convert_from(tag,'UTF8') FROM conduit.conduit_tags),
     pc AS (SELECT id, article_id, author_id, body, (extract(epoch FROM created_at)*1000)::bigint FROM public.comments),
     cc AS (SELECT id, article, author, convert_from(body,'UTF8'), created FROM conduit.conduit_comments)
SELECT 'users' t, (SELECT count(*) FROM pu) n, (SELECT count(*) FROM (SELECT * FROM pu EXCEPT SELECT * FROM cu) x) + (SELECT count(*) FROM (SELECT * FROM cu EXCEPT SELECT * FROM pu) x) diff
UNION ALL SELECT 'articles', (SELECT count(*) FROM pa), (SELECT count(*) FROM (SELECT * FROM pa EXCEPT SELECT * FROM ca) x) + (SELECT count(*) FROM (SELECT * FROM ca EXCEPT SELECT * FROM pa) x)
UNION ALL SELECT 'tags', (SELECT count(*) FROM pt), (SELECT count(*) FROM (SELECT * FROM pt EXCEPT SELECT * FROM ct) x) + (SELECT count(*) FROM (SELECT * FROM ct EXCEPT SELECT * FROM pt) x)
UNION ALL SELECT 'comments', (SELECT count(*) FROM pc), (SELECT count(*) FROM (SELECT * FROM pc EXCEPT SELECT * FROM cc) x) + (SELECT count(*) FROM (SELECT * FROM cc EXCEPT SELECT * FROM pc) x)
UNION ALL SELECT 'follows', (SELECT count(*) FROM public.follows), (SELECT count(*) FROM (SELECT follower_id, followee_id FROM public.follows EXCEPT SELECT follower, followed FROM conduit.conduit_follows) x) + (SELECT count(*) FROM (SELECT follower, followed FROM conduit.conduit_follows EXCEPT SELECT follower_id, followee_id FROM public.follows) x)
UNION ALL SELECT 'favorites', (SELECT count(*) FROM public.favorites), (SELECT count(*) FROM (SELECT user_id, article_id FROM public.favorites EXCEPT SELECT "user", article FROM conduit.conduit_favorites) x) + (SELECT count(*) FROM (SELECT "user", article FROM conduit.conduit_favorites EXCEPT SELECT user_id, article_id FROM public.favorites) x);
SELECT * FROM conduit.conduit_counters;
