-- main table not need to from or join
select distinct ( $[$23.10.0] / cast(b.U_packperkg as float) )
from  [@PACKSIZE] b 
where $[$23.U_packing_size.0] = b.Code

-----------------------------------
-- not need to from
SELECT 
CASE WHEN $[OPCH.DocType] = 'S' THEN 'Services'
     WHEN $[OPCH.DocType] = 'I'  THEN 'Goods'         
		ELSE 'Goods/Services'
END

-- or
SELECT ( $[$0_U_G.C_0_3.Number] * $[$0_U_G.C_0_7.Number] ) / 100.0
-----------------------------------

-- information from another table
select distinct ORPC.NumAtCard
from OJDT
left join ORPC on $[$25.1] = ORPC.[DocNum]
