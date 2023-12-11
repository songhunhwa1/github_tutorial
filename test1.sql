/*
Author: hunhwa.song 
File name: visit_ord_cnt_by_lovers.sql
Note:
  최근 3개월간 고객별 러버스등급별 방문수와 주문수를 이용해 구매전환율 구한후,
  각 그룹별 구매전환율의 통계적 차이를 분석하기 위한 쿼리
*/

with visits as
(
select
 cast(m_no as int) as cust_no,
 count(distinct cast(visit_dt as date)) as visit_cnt
from `bq-datafarm.data_warehouse.cba_user_visit_1d` 
where 1=1
  and visit_dt >= '2023-10-06' 
  and visit_dt < '2023-12-06' 
  and m_no is not null
  and m_no != '-'
group by m_no
),

orders as
(
select
  cust_no,
  case when member_group = 12 then '3_퍼플'
       when member_group = 14 then '2_라벤더'
       when member_group = 15 then '1_화이트'
       when member_group = 16 then '0_프렌즈'
  else null end as mem_grp,
  cast(ord_dt as date) as ord_date
from `bq-datafarm.data_warehouse.std_ord_prd_1d`
where 1=1
  and ord_dt >= '2023-10-06'
  and ord_dt < '2023-12-06'
  and ord_status < 40
  and ord_type = 'NORMAL'  
  and ptype = '1p'
  and member_group in (12, 14, 15, 16)
  and cust_no is not null
)

select
  vis.*,
  ord.member_group,
  ord.ord_cnt,
  round(ord_cnt/visit_cnt,3) as ord_ratio
from visits as vis
inner join (
  select
    cust_no,
    max(mem_grp) as member_group,
    count(distinct ord_date) as ord_cnt
  from orders
  group by 
    cust_no,
    mem_grp
  ) as ord
  on vis.cust_no = ord.cust_no
where 1=1
  and round(ord_cnt/visit_cnt,3) < 1.0
  and vis.visit_cnt >= 10 -- 10번 이상 방문한 경우만
  and rand() <= 0.095 -- 샘플링

