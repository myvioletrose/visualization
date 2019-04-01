--`media-data-science.Jim_adhoc2.story_length_ytd_a`
select fullVisitorId
, visitid 
, date
, geoNetwork.country as country
, geoNetwork.city as city
, hits.page.pagePath as page
, hits.customDimensions.value as story_id
, count(1) as pvs
from TABLE_DATE_RANGE([calcium-land-150922:132466937.ga_sessions_], 
USEC_TO_TIMESTAMP(UTC_USEC_TO_YEAR(current_date())), 	
--DATE_ADD(CURRENT_DATE(), -1, 'DAY'), 
DATE_ADD(CURRENT_DATE(), 0, 'DAY'))		
where hits.type = 'PAGE'
and hits.customDimensions.index = 7
group by 1, 2, 3, 4, 5, 6, 7	

--`media-data-science.Jim_adhoc2.story_length_ytd_b`
select id, type, ga_type, url, body, headline, summary, authors, primary_site, story_published_at
, extract(year from story_published_at) as year 
, extract(month from story_published_at) as month  
from `calcium-land-150922.datalake.story_metadata` sm 
join (select story_id from `media-data-science.Jim_adhoc2.story_length_ytd_a` group by 1) s on sm.id = s.story_id 

--`media-data-science.Jim_adhoc2.story_length_ytd_c`
with sub 
as (

	with a 
	as (
		SELECT id, authors 
		FROM `media-data-science.Jim_adhoc2.story_length_ytd_b`, 
		unnest(authors) as authors
	)

	select sub1.id as story_id 
	, sub2.authors as authors
	, sub1.num_of_authors as num_of_authors

	from (
		select id, count(1) as num_of_authors from a group by 1
	) sub1
	join (
		select id, STRING_AGG(authors) as authors from a group by 1
	) sub2 on sub1.id = sub2.id 

)

select id, type, ga_type, url, body, headline, summary
, sub.authors as authors
, sub.num_of_authors as num_of_authors
, primary_site
, story_published_at
, year
, month 
from `media-data-science.Jim_adhoc2.story_length_ytd_b` b 
join sub on b.id = sub.story_id


 