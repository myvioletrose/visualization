/*
Commodities
Soybean
BlackRock (BLK)
*/

-----------------------------------			
------------- forward ------------- 			
-----------------------------------			
WITH SUB3			
AS (			
			
	with sub2		
	as (		
			
		with sub	
		as (	
			select bloomberg_id
			, date(universal_datetime) as universal_datetime
			from `calcium-land-150922.datalake.bombora`
			where _PARTITIONTIME >= timestamp(date_add(current_date(), INTERVAL -74 DAY))
			and _PARTITIONTIME < timestamp(date_add(current_date(), INTERVAL -60 DAY))
			and bloomberg_id is not null
			--and intent_topic_1 is not null
			and intent_topic_1 in ('BlackRock (BLK)')
			--and topic_1_score > 0.5
			--and topic_1 in ('BlackRock (BLK)')
			group by 1, 2
		)  -- end of sub	
			
		select sub.bloomberg_id as bloomberg_id	
		, 'BlackRock (BLK)' as topic 	
		, sub.universal_datetime as base_period	
		, 1 as flag	
		from sub	
			
		union all	
			
		select x.bloomberg_id as bloomberg_id	
		, x.topic as topic	
		, x.universal_datetime as base_period	
		, x.flag as flag 	
		from (	
			select b.bloomberg_id as bloomberg_id
			, case when x.bloomberg_id is null then 0 else 1 end as flag  -- 0 stands for control group 
			, b.intent_topic_1 as topic
			, date(universal_datetime) as universal_datetime
			from `calcium-land-150922.datalake.bombora` b 
			left join (select bloomberg_id from sub group by 1) x on b.bloomberg_id = x.bloomberg_id
			where _PARTITIONTIME >= timestamp(date_add(current_date(), INTERVAL -74 DAY))
			and _PARTITIONTIME < timestamp(date_add(current_date(), INTERVAL -60 DAY))
			and b.bloomberg_id is not null
			--and topic_1_score > 0.5
			and intent_topic_1 is not null
			group by 1, 2, 3, 4
		) x	
		where x.flag = 0	
			
	)  -- end of sub2		
			
	select bloomberg_id		
	, flag		
	, forward_topic		
	, case when day_diff < 15 then 'within 14-day forward'  -- two weeks going forward about reading that forward topic		
		when day_diff >= 15 and day_diff < 22 then '15-to-21 day forward'  -- third week forward	
		when day_diff >= 22 and day_diff < 29 then '22-to-28 day forward'  -- fourth week forward	
		when day_diff >= 29 and day_diff < 36 then '29-to-35 day forward'  -- fifth week forward	
		when day_diff >= 36 and day_diff < 43 then '36-to-42 day forward'  -- sixth week forward	
		when day_diff >= 43 and day_diff < 64 then '43-to-63 day forward'  -- seventh to ninth week forward	
		else '64-day or more forward' end as bucket  -- tenth week or more forward 	
			
	from (		
			
		select x.bloomberg_id as bloomberg_id	
		, x.flag as flag	
		, x.base_topic as base_topic	
		, x.forward_topic as forward_topic	
		--, date_diff(x.base_period, x.forward_period, DAY) as day_diff	
		, abs(date_diff(x.base_period, x.forward_period, DAY)) as day_diff	
			
		from (	
			
			-- get what everyone (test + control groups) read about in the forward period 
			select sub2.bloomberg_id as bloomberg_id
			, sub2.flag as flag 
			, sub2.topic as base_topic
			, sub2.base_period as base_period
			, date(b.universal_datetime) as forward_period
			, b.topic_1 as forward_topic 
			
			from `calcium-land-150922.datalake.bombora` b 
			join sub2 on b.bloomberg_id = sub2.bloomberg_id  -- it is ok to join them by many-to-many b/c we are calculating day_diff for each topic-to-topic combo
			
			where _PARTITIONTIME >= timestamp(date_add(current_date(), INTERVAL -60 DAY))
			and _PARTITIONTIME < timestamp(date_add(current_date(), INTERVAL 0 DAY))
			and b.bloomberg_id is not null
			and topic_1_score > 0.5
			--and intent_topic_1 is not null
			group by 1, 2, 3, 4, 5, 6
			
		) x	
			
	) y		
			
	group by 1, 2, 3, 4		
			
)  -- end of SUB3			
			
SELECT timeline			
, forward_topic			
, test_yes			
, control_yes			
, test_no			
, control_no			
, round( (test_yes / test_no) / (control_yes / control_no), 2 ) as odds			
			
FROM (			
	select sub3.bucket as timeline		
	, sub3.forward_topic as forward_topic		
	, sub3.test_yes as test_yes 		
	, sub3.control_yes as control_yes		
	, total.test_total - sub3.test_yes as test_no		
	, total.control_total - sub3.control_yes as control_no		
			
	from (		
		select bucket	
		, forward_topic	
		, sum(case when flag = 1 then 1 else 0 end) as test_yes	
		, sum(case when flag = 0 then 1 else 0 end) as control_yes	
		from SUB3	
		group by 1, 2	
	) sub3		
	join (		
		select bucket	
		, count(distinct case when flag = 1 then bloomberg_id end) as test_total	
		, count(distinct case when flag = 0 then bloomberg_id end) as control_total	
		from SUB3	
		group by 1	
	) total on sub3.bucket = total.bucket		
) calculation 			
			
WHERE calculation.test_yes >=5			
AND calculation.control_yes >=5			
AND calculation.test_no >=5			
AND calculation.control_no >=5			
			
order by round( (test_yes / test_no) / (control_yes / control_no), 2 ) desc			
