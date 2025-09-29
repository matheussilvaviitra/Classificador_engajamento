-- pedidos de ajuda e respsotas a pedidos de ajuda em mídias por ambiente

select
	e.name 
	,0 AS posts
	,0 AS posts_replies
	,count(distinct s2.id) as help_requests
	,count(s.id) as help_requests_replies
from statuses s 
left join statuses s2 ON s.in_response_to_id = s2.id 
left join lectures l ON s2.statusable_id  = l.id and s2.statusable_type  = 'Lecture'
left join subjects s3 on s3.id = l.subject_id  
left join spaces s4 on s4.id = s3.space_id 
left join courses c on c.id = s4.course_id 
left join environments e on e.id = c.environment_id 
where s2.`type` = 'Help' and e.name like 'UF%'
group by e.name



-- comentários em disiciplinas por ambiente
select
	e.name 
	,count(distinct s2.id) posts
	,count(s.id) as posts_replies
	,0 as help_requests
	,0 as help_requests_replies
from statuses s 
left join statuses s2 ON s.in_response_to_id = s2.id 
left join spaces s4 on s4.id = s2.statusable_id  and s2.statusable_type  = 'Space'
left join courses c on c.id = s4.course_id 
left join environments e on e.id = c.environment_id 
where s2.`type` in ('Answer', 'Activity') and e.name like 'UF%'
group by e.name 


-- comentários em disiciplinas por ambiente
select
	e.name 
	,count(distinct s2.id) posts
	,count(s.id) as posts_replies
	,0 as help_requests
	,0 as help_requests_replies
from statuses s 
left join statuses s2 ON s.in_response_to_id = s2.id 
left join spaces s4 on s4.id = s2.statusable_id  and s2.statusable_type  = 'Space'
left join courses c on c.id = s4.course_id 
left join environments e on e.id = c.environment_id 
where s2.`type` = 'Activity' and s.`type` = 'Answer' and e.name like 'UF%'
group by e.name 


-- posts no próprio mural 
select
	count(s.id) as posts
from statuses s 
where s.`type` = 'Activity' and s.statusable_type = 'User' 

