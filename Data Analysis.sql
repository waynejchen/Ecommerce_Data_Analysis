use mavenfuzzyfactory;


-- Find top traffic sources
select 
  utm_source,
  utm_campaign,
  http_referer,
  count(distinct website_session_id) as sessions
from website_sessions
where
  substring(created_at,1,10) < '2012-04-12' 
group by
  utm_source,
  utm_campaign,
  http_referer
order by 4 desc;


-- Top 1 source session to order conversion rate
select
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.order_id) as orders,
  count(distinct o.order_id)/count(distinct ws.website_session_id) as session_to_order_conv_rate
from website_sessions ws
left join orders o on ws.website_session_id=o.website_session_id
where
  ws.created_at < '2012-04-14' and
  ws.utm_source = 'gsearch' and
  ws.utm_campaign = 'nonbrand';


-- Session volume BY week
select
  min(date(created_at)) as week_start_date,
  count(website_session_id) as sessions
from website_sessions
where
  created_at < '2012-05-10' and
  utm_source = 'gsearch' and
  utm_campaign = 'nonbrand'
group by
  year(created_at),
  week(created_at)
order by
  min(date(created_at));


-- Session to order conversion rate BY device
select 
  ws.device_type,
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.order_id) as orders,
  count(distinct o.order_id)/count(distinct ws.website_session_id) as session_to_order_conv_rate
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where 
  ws.created_at < '2012-05-11' and
  ws.utm_source = 'gsearch' and
  ws.utm_campaign = 'nonbrand'
group by
  ws.device_type;


-- Session volume BY device
select
  min(date(created_at)) as week_start_date,
  count(distinct case when device_type = 'desktop' then website_session_id else null end) as dtop_sessions,
  count(distinct case when device_type = 'mobile' then website_session_id else null end) as mob_sessions
from website_sessions
where
  created_at between '2012-04-15' and '2012-06-09' and
  utm_source = 'gsearch' and
  utm_campaign = 'nonbrand'
group by
  year(created_at),
  week(created_at);


-- Pageviews BY url
select
  pageview_url,
  count(distinct website_pageview_id) as pvs
from website_pageviews
where
  created_at < '2012-06-09'
group by 1
order by 2 desc;


-- Sessions BY landing page

-- STEP 1: find the first pageview for each session
drop table if exists first_pv_per_session;
create temporary table first_pv_per_session
select
  website_session_id,
  min(website_pageview_id) as first_pv_id
from website_pageviews
group by
  website_session_id;
  
-- STEP 2: find the url the customer saw on that first pageview
select
  wp.pageview_url as landing_page_url,
  count(distinct fp.website_session_id) as session_hitting_page
from first_pv_per_session fp
left join website_pageviews wp on fp.first_pv_id = wp.website_pageview_id
where
  wp.created_at < '2012-06-12'
group by 1
order by 2 desc;


-- Session bounce rate

-- STEP 1: find the bounced sessions
create temporary table bounced_sessions
select
  website_session_id,
  count(distinct website_pageview_id) as pvs
from website_pageviews
group by
  website_session_id
having
  count(distinct website_pageview_id) < 2;

-- STEP 2: aggregate all and bounced sessions
select
  count(distinct wp.website_session_id) as sessions,
  count(distinct bs.website_session_id) as bounced_sessions,
  count(distinct bs.website_session_id)/count(distinct wp.website_session_id) as bounce_rate
from website_pageviews wp
left join bounced_sessions bs on wp.website_session_id = bs.website_session_id
where
  created_at < '2012-06-14';


-- A/B test regarding bounce rate between two landing pages

-- STEP 1: find the launch date of /lander-1 to set the analysis timeframe
select
  pageview_url,
  min(created_at) as first_created_at
from website_pageviews
where pageview_url = '/lander-1'
group by
  pageview_url;
-- The timeframe would be between 2012-06-19 and 2012-07-28

-- STEP 2: find the landing page
create temporary table ld_pg
select
  website_session_id,
  min(website_pageview_id) as landing_pg
from website_pageviews
group by
  website_session_id;

-- STEP 3: find the bounced sessions
create temporary table bd_session
select
  website_session_id,
  count(distinct website_pageview_id) as pvs
from website_pageviews
group by
  website_session_id
having
  count(distinct website_pageview_id) < 2;

-- STEP 4: join data together
select
  wp.pageview_url as landing_page,
  count(distinct lp.website_session_id) as total_sessions,
  count(distinct bs.website_session_id) as bounced_sessions,
  count(distinct bs.website_session_id)/count(distinct lp.website_session_id) as bounce_rate
from ld_pg lp
left join website_pageviews wp on wp.website_pageview_id = lp.landing_pg
left join bd_session bs on bs.website_session_id = lp.website_session_id
left join website_sessions ws on ws.website_session_id = lp.website_session_id
where
  wp.created_at between '2012-06-19' and '2012-07-28' and
  ws.utm_source = 'gsearch' and
  ws.utm_campaign = 'nonbrand'
group by 1;


-- Bounce rate trend analysis comparing two landing pages

-- STEP 1: find the landing page(same as above)

-- STEP 2: find the bounced sessions(same as above)

-- STEP 3: join data together and aggregate
with a as
(
select
  wp.created_at,
  lp.website_session_id,
  wp.pageview_url,
  bs.website_session_id as bounced_website_session_id
from ld_pg lp
left join website_pageviews wp on wp.website_pageview_id = lp.landing_pg
left join bd_session bs on bs.website_session_id = lp.website_session_id
left join website_sessions ws on ws.website_session_id = lp.website_session_id
where
  wp.created_at between '2012-06-01' and '2012-08-31' and
  ws.utm_campaign = 'nonbrand'
)

select
  min(date(created_at)) as week_start_date,
  count(bounced_website_session_id)/count(website_session_id) as bounced_rate,
  count(distinct case when pageview_url = '/home' then website_session_id else null end) as home_sessions,
  count(distinct case when pageview_url = '/lander-1' then website_session_id else null end) as lander_sessions
from a
group by
  year(created_at),
  week(created_at);


-- Conversion rate funnel

with PageReachWithinSession as
(
with SessionCondition as
(
with PageNoted as 
(
-- STEP 1: Tag each page record
select
  website_pageview_id,
  wp.website_session_id,
  pageview_url,
  case when pageview_url = '/products' then 1 else 0 end as products,
  case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy,
  case when pageview_url = '/cart' then 1 else 0 end as cart,
  case when pageview_url = '/shipping' then 1 else 0 end as shipping,
  case when pageview_url = '/billing' then 1 else 0 end as billing,
  case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou
from website_pageviews wp
left join website_sessions ws on wp.website_session_id = ws.website_session_id
where
  wp.created_at between '2012-08-05' and '2012-09-05' and
  ws.utm_source = 'gsearch' and
  ws.utm_campaign = 'nonbrand'
)

-- STEP 2: Aggregate page records to session level
select distinct
  website_session_id,
  max(products) as products,
  max(mrfuzzy) as mrfuzzy,
  max(cart) as cart,
  max(shipping) as shipping,
  max(billing) as billing,
  max(thankyou) as thankyou
from PageNoted
group by
  website_session_id
)

-- STEP 3: Sum up reach data of each page
select
  count(distinct website_session_id) as sessions,
  sum(products) as to_products,
  sum(mrfuzzy) as to_mrfuzzy,
  sum(cart) as to_cart,
  sum(shipping) as to_shipping,
  sum(billing) as to_billing,
  sum(thankyou) as to_thankyou
from SessionCondition
)

-- STEP 4: Calculate conversion rate of each point
select
  (to_products/sessions) as lander_click_rt,
  (to_mrfuzzy/to_products) as products_click_rt,
  (to_cart/to_mrfuzzy) as mrfuzzy_click_rt,
  (to_shipping/to_cart) as cart_click_rt,
  (to_billing/to_shipping) as shipping_click_rt,
  (to_thankyou/to_billing) as billing_click_rt
from PageReachWithinSession;


-- Two billing pages' billing-to-order conversion rate comparison

-- STEP 1: find the date billing2 page launched
with billing2_ranking as
(
select
  *,
  rank() over(order by created_at) as ranking
from website_pageviews
where pageview_url = "/billing-2"
)

select
  created_at as first_created_at,
  website_pageview_id as first_pv_id
from billing2_ranking
where ranking = 1;

-- STEP 2: calculate the conversion rate
select
  wp.pageview_url as billing_version_seen,
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.order_id) as orders,
  count(distinct o.order_id)/count(distinct ws.website_session_id) as billing_to_order_rt
from website_sessions ws
left join website_pageviews wp on ws.website_session_id = wp.website_session_id
left join orders o on ws.website_session_id = o.website_session_id
where
  ws.created_at between '2012-09-10' and '2012-11-10' and
  wp.pageview_url in ('/billing','/billing-2')
group by
  wp.pageview_url;


-- Session and order amount by month
select
  year(ws.created_at) as year_date,
  month(ws.created_at) as month_date,
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.order_id) as orders
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where
  ws.utm_source = 'gsearch' and
  ws.created_at < '2012-11-27'
group by
  1,2;



select distinct
  utm_source,
  utm_campaign,
  http_referer
from website_sessions
where
  created_at < '2012-11-27';


-- Session traffic trend by month
select
  year(created_at) as yr,
  month(created_at) as mo,
  count(distinct case when utm_source = 'gsearch' then website_session_id end) as gsearch_paid_sessions,
  count(distinct case when utm_source = 'bsearch' then website_session_id end) as bsearch_paid_sessions,
  count(distinct case when utm_source is null and http_referer is not null then website_session_id end) as organic_search_sessions,
  count(distinct case when utm_source is null and http_referer is null then website_session_id end) as direct_type_in_sessions
from website_sessions
where
  created_at < '2012-11-27'
group by
  1,2;


-- Two sources' session amount comparison
select
  min(date(created_at)) as week_start_date,
  count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_sessions,
  count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_sessions
from website_sessions
where
  utm_campaign = 'nonbrand'
  and created_at > '2012-08-22'
  and created_at < '2012-11-29'
group by
  year(created_at),
  week(created_at);


-- Percentage of mobile sessions by utm_source
select
  utm_source,
  count(distinct website_session_id) as sessions,
  count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_sessions,
  count(distinct case when device_type = 'mobile' then website_session_id else null end)/count(distinct website_session_id) as pct_mobile
from website_sessions
where
  created_at > '2012-08-22'
  and created_at < '2012-11-30'
  and utm_campaign = 'nonbrand'
group by
  1;


-- Session-to-order conversion rate by device type and utm source
select
  ws.device_type,
  ws.utm_source,
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.order_id) as orders,
  count(distinct o.order_id)/count(distinct ws.website_session_id) as conv_rate
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where
  ws.utm_source in ('gsearch','bsearch')
  and ws.created_at > '2012-08-22' 
  and ws.created_at < '2012-09-19'
  and ws.utm_campaign = 'nonbrand'
group by
  1,2;


-- Session traffic by utm_source, device, and week
select
  min(date(created_at)) as week_start_date,
  count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as g_dtop_sessions,
  count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end) as b_dtop_sessions,
  count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end)
  /count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as b_pct_of_g_dtop,
  count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as g_mob_sessions,
  count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end) as b_mob_sessions,
  count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end)
  /count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as b_pct_of_g_mob
from website_sessions
where
  created_at > '2012-11-04'
  and created_at < '2012-12-22'
  and utm_campaign = 'nonbrand'
group by
  year(created_at),
  week(created_at);


-- Direct and organic search growth moving along paid searches
select
  year(created_at) as yr,
  month(created_at) as mo,
  count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as nonbrand,
  count(distinct case when utm_campaign = 'brand' then website_session_id else null end) as brand,
  count(distinct case when utm_campaign = 'brand' then website_session_id else null end)
  /count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as brand_pct_of_nonbrand,
  count(distinct case when http_referer is null then website_session_id else null end) as direct,
  count(distinct case when http_referer is null then website_session_id else null end)
  /count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as direct_pct_of_nonbrand,
  count(distinct case when http_referer is not null and utm_source is null then website_session_id else null end) as organic,
  count(distinct case when http_referer is not null and utm_source is null then website_session_id else null end)
  /count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as organic_pct_of_nonbrand
from website_sessions
where
  created_at < '2012-12-23'
group by
  1,2;
  

-- 2012 session and order volume by month
select
  year(ws.created_at) as yr,
  month(ws.created_at) as mo,
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.order_id) as orders
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where
  ws.created_at < '2013-01-01'
group by
  1,2;


-- 2012 session and order volume by week
select
  min(date(ws.created_at)) as week_start_date,
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.order_id) as orders
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where
  ws.created_at < '2013-01-01'
group by
  yearweek(ws.created_at);


-- Average session volume by weekday and hour
with a as
(
select
  date(created_at) as created_date,
  weekday(created_at) as wkday,
  hour(created_at) as hr,
  count(distinct website_session_id) as sessions
from website_sessions
where
  created_at between '2012-09-15' and '2012-11-15'
group by
  1,2,3
)

select
  hr,
  round(avg(case when wkday = 0 then sessions else null end),1) as mon,
  round(avg(case when wkday = 1 then sessions else null end),1) as tues,
  round(avg(case when wkday = 2 then sessions else null end),1) as weds,
  round(avg(case when wkday = 3 then sessions else null end),1) as thurs,
  round(avg(case when wkday = 4 then sessions else null end),1) as fri,
  round(avg(case when wkday = 5 then sessions else null end),1) as sat,
  round(avg(case when wkday = 6 then sessions else null end),1) as sun
from a
group by
  1;


-- Sales volume, revenue, and margin by year and month
select
  year(created_at) yr,
  month(created_at) mo,
  count(distinct order_id) as number_of_sales,
  sum(price_usd) as total_revenue,
  sum(price_usd - cogs_usd) as total_margin
from orders
where
  created_at < '2013-01-04'
group by
  1,2;


-- Sale analysis by year and month
select
  year(ws.created_at) as yr,
  month(ws.created_at) as mo,
  count(distinct o.order_id) as orders,
  count(distinct o.order_id)/count(distinct ws.website_session_id) as conv_rate,
  sum(o.price_usd)/count(distinct ws.website_session_id) as revnue_per_session,
  count(distinct case when o.primary_product_id = 1 then o.order_id else null end) as product_one_orders,
  count(distinct case when o.primary_product_id = 2 then o.order_id else null end) as product_two_orders
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where
  ws.created_at between '2012-04-01' and '2013-04-04'
group by
  1,2;


-- Product page clickthrough rate comparison
with b as
(
with a as
(
-- STEP 1: deliminate comparison time periods and retrieve products pages

select
  *,
  case
  when created_at >= '2012-10-06' and created_at < '2013-01-06' then 'A. Pre_Product_2'
  when created_at >= '2013-01-06' and created_at < '2013-04-06' then 'B. Post_Product_2'
  else null
  end as time_period
from website_pageviews
where
  created_at >= '2012-10-06'
  and created_at < '2013-04-06'
  and pageview_url = '/products'
)
-- STEP 2: find pages next to product pages (Whether clicked through? If yes, what is the next page?)

select
  a.time_period,
  a.website_session_id,
  a.website_pageview_id,
  a.pageview_url as products,
  wp.pageview_url as next_pg
from a
left join website_pageviews wp on a.website_session_id = wp.website_session_id
                              and a.website_pageview_id < wp.website_pageview_id
)
-- STEP 3: calculate clickthrough rate

select
  time_period,
  count(distinct website_session_id) as sessions,
  count(distinct case when next_pg is not null then website_session_id else null end) as w_next_pg,
  count(distinct case when next_pg is not null then website_session_id else null end)
  /count(distinct website_session_id) as pct_w_next_pg,
  count(distinct case when next_pg = '/the-original-mr-fuzzy' then website_session_id else null end) as to_mrfuzzy,
  count(distinct case when next_pg = '/the-original-mr-fuzzy' then website_session_id else null end)
  /count(distinct website_session_id) as pct_to_mrfuzzy,
  count(distinct case when next_pg = '/the-forever-love-bear' then website_session_id else null end) as to_lovebear,
  count(distinct case when next_pg = '/the-forever-love-bear' then website_session_id else null end)
  /count(distinct website_session_id) as pct_to_lovebear
from b
group by
  1;


-- Two product conversion funnels
with c as
(
with b as
(
with a as
(
-- STEP 1: find sessions clicking pages of two products

select
  distinct website_session_id,
  case
  when pageview_url = '/the-original-mr-fuzzy' then 'mrfuzzy'
  when pageview_url = '/the-forever-love-bear' then 'lovebear'
  else null
  end as pg_seen
from website_pageviews
where
  created_at between '2013-01-06' and '2013-04-10'
  and pageview_url in ('/the-original-mr-fuzzy','/the-forever-love-bear')
)
-- STEP 2: denote product-page information to each session

select distinct
  a.website_session_id,
  wp.website_pageview_id,
  wp.pageview_url,
  a.pg_seen
from website_pageviews wp
right join a on a.website_session_id = wp.website_session_id
)
-- STEP 3: count the amount of clicks each point in the funnel

select
  pg_seen as product_seen,
  count(distinct website_session_id) as sessions,
  count(distinct case when pageview_url = '/cart' then website_pageview_id else null end) as to_cart,
  count(distinct case when pageview_url = '/shipping' then website_pageview_id else null end) as to_shipping,
  count(distinct case when pageview_url = '/billing-2' then website_pageview_id else null end) as to_billing,
  count(distinct case when pageview_url = '/thank-you-for-your-order' then website_pageview_id else null end) as to_thankyou
from b
group by
  1
)
-- STEP 4: calculate the converate in each point

select
  product_seen,
  to_cart/sessions as product_page_click_rt,
  to_shipping/to_cart as cart_click_rt,
  to_billing/to_shipping as shipping_click_rt,
  to_thankyou/to_billing as billing_click_rt
from c
group by
  1;


-- Pre/post analysis regarding cross sale strategy

with b as
(
with a as
(
-- STEP 1: pull out data of cart page in specified time period, attach timestamp

select distinct
  website_pageview_id,
  website_session_id,
  pageview_url,
  case
  when created_at >= '2013-08-25' and created_at <= '2013-09-25' then 'A.Pre_Cross_Sell'
  when created_at >= '2013-09-25' and created_at <= '2013-10-24' then 'B.Post_Cross_Sell'
  else null
  end as time_period
from website_pageviews
where
  created_at >= '2013-08-25'
  and created_at <= '2013-10-24'
  and pageview_url = '/cart'
)
-- STEP 2: pull out clickthrough situation
select distinct
  a.website_session_id,
  a.website_pageview_id,
  min(wp.website_pageview_id) as ct_pageview_id,
  a.pageview_url,
  a.time_period
from a
left join website_pageviews wp on a.website_session_id = wp.website_session_id
                              and a.website_pageview_id < wp.website_pageview_id
group by
  1,2,4,5
)
-- STEP 3: calcute statistics
select
  b.time_period,
  count(distinct case when b.pageview_url = '/cart' then b.website_session_id else null end) as cart_sessions,
  count(distinct case when ct_pageview_id is not null then b.website_session_id else null end) as clickthroughs,
  count(distinct case when ct_pageview_id is not null then b.website_session_id else null end)/
  count(distinct case when b.pageview_url = '/cart' then b.website_session_id else null end) as cart_ctr,
  sum(o.items_purchased)/
  count(distinct o.order_id) as products_per_order,
  sum(o.price_usd)/
  count(distinct o.order_id) as aov,
  sum(o.price_usd)/
  count(distinct case when b.pageview_url = '/cart' then b.website_session_id else null end) as rev_per_cart_session
from b
left join orders o on b.website_session_id = o.website_session_id
group by
  1;


-- Products refund rate by year and month
select
  year(oi.created_at) as yr,
  month(oi.created_at) as mo,
  count(distinct case when product_id = 1 then oi.order_id else null end) as p1_orders,
  count(distinct case when product_id = 1 then oir.order_item_refund_id else null end)/
  count(distinct case when product_id = 1 then oi.order_id else null end) as p1_refund_rt,
  count(distinct case when product_id = 2 then oi.order_id else null end) as p2_orders,
  count(distinct case when product_id = 2 then oir.order_item_refund_id else null end)/
  count(distinct case when product_id = 2 then oi.order_id else null end) as p2_refund_rt,
  count(distinct case when product_id = 3 then oi.order_id else null end) as p3_orders,
  count(distinct case when product_id = 3 then oir.order_item_refund_id else null end)/
  count(distinct case when product_id = 3 then oi.order_id else null end) as p3_refund_rt,
  count(distinct case when product_id = 4 then oi.order_id else null end) as p4_orders,
  count(distinct case when product_id = 4 then oir.order_item_refund_id else null end)/
  count(distinct case when product_id = 4 then oi.order_id else null end) as p4_refund_rt
from order_items oi
left join order_item_refunds oir on oi.order_id = oir.order_id
where
  oi.created_at < '2014-10-15'
group by
  1,2;


-- Stats of users' repeat session
with a as
(
-- STEP 1: pull out users with repeat session amount

select
  user_id,
  sum(is_repeat_session) as repeat_sessions
from website_sessions
where created_at >= '2014-01-01' 
      and created_at < '2014-11-01'
      and user_id in (select distinct 
                        user_id 
					  from website_sessions
                      where 
                        created_at >= '2014-01-01' 
                        and created_at < '2014-11-01'
                        and is_repeat_session = 0)
group by
  1
)
-- STEP 2: aggregate users amount by repeat sessions

select
  repeat_sessions,
  count(user_id) as users
from a
group by
  1
order by 
  1;


-- Data difference stats between first and second sessions
with c as
(
with b as
(
with a as
(
-- STEP 1: pull out new users within prescribed time period

select distinct
  user_id,
  created_at as first_visit_time,
  website_session_id,
  is_repeat_session
from website_sessions
where
  created_at between '2014-01-01' and '2014-11-03'
  and is_repeat_session = 0
)
-- STEP 2: find users' second sessions

select
  a.user_id,
  date(a.first_visit_time) as first_time,
  min(date(ws.created_at)) as second_time
from a
left join website_sessions ws on a.user_id = ws.user_id
                             and a.website_session_id < ws.website_session_id
where
  ws.is_repeat_session = 1
  and ws.created_at between '2014-01-01' and '2014-11-03'
group by
  1,2
)
-- STEP 3: compute date difference for first-to-second sessions

select 
  user_id,
  first_time,
  second_time,
  datediff(second_time,first_time) as first_to_second
from b
)
-- STEP 4: compute date difference stats

select
  avg(first_to_second) as avg_days_first_to_second,
  min(first_to_second) as min_days_first_to_second,
  max(first_to_second) as max_days_first_to_second
from c;


-- New and repeat sessions by channel group
with a as
(
-- STEP 1: append channel group stamps to each session

select
  *,
  case
  when utm_source is null and http_referer in ('https://www.gsearch.com','https://www.bsearch.com') then 'organic_search'
  when utm_campaign = 'nonbrand' then 'paid_nonbrand'
  when utm_campaign = 'brand' then 'paid_brand'
  when utm_source is null and http_referer is null then 'direct_type_in'
  when utm_source = 'socialbook' then 'paid_social'
  else null
  end as channel_group
from website_sessions
where
  created_at between '2014-01-01' and '2014-11-05'
)
-- STEP 2: compute session amount by each channel

select
  channel_group,
  count(distinct case when is_repeat_session = 0 then website_session_id else null end) as new_sessions,
  count(distinct case when is_repeat_session = 1 then website_session_id else null end) as repeat_sessions
from a
group by
  1;


-- New v.s. repeat session sale performance analysis
select
  ws.is_repeat_session,
  count(distinct ws.website_session_id) as sessions,
  count(distinct o.website_session_id)/
  count(distinct ws.website_session_id) as conv_rate,
  sum(price_usd)/
  count(distinct ws.website_session_id) as rev_per_session
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where
  ws.created_at between '2014-01-01' and '2014-11-08'
group by
  1










  


















































