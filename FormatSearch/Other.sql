/* rule: in the Format search not need to input `FROM` or `JOIN` */

-- direct use UDF table and specify row.column, system
select distinct 
	( $[$23.10.0] / cast(b.U_packperkg as float) )
from  [@PACKSIZE] b 
where $[$23.U_packing_size.0] = b.Code
-----------------------------------
	
-- just show `Text` if any condition is TRUE
SELECT 
	CASE 
		WHEN $[OPCH.DocType] = 'S' THEN 'Services'
	    WHEN $[OPCH.DocType] = 'I'  THEN 'Goods'         
		ELSE 'Goods/Services'
	END
-----------------------------------

-- JION with another table with direct specify row.column, system
select distinct 
	ORPC.NumAtCard
from OJDT
left join ORPC on $[$25.1] = ORPC.[DocNum]
-----------------------------------

-- direct calculated
SELECT ( $[$0_U_G.C_0_3.Number] * $[$0_U_G.C_0_7.Number] ) / 100.0
-----------------------------------
