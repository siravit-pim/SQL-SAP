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

/* Can calculate with 2 method and can use decalare in FS, it's STD */
-- first method
SELECT $[$38.234000373.Number] - $[$38.34.Number]

-- second method
Declare @Price1 as Money
Declare @Price2 as Money
SET @Price1 = (SELECT $[$38.U_TEST1.number])
SET @Price2 = (SELECT $[$38.U_TEST2.number])
SELECT @Price1 * @Price2
