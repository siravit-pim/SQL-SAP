-- grouping multiple rows like concat() with each data set
stuff ( (  
		select ',' + cast(b.NumAtCard  as nvarchar(max))					
		from OPCH b 
		group by b.NumAtCard
		FOR XML PATH ('') 
	), 1, 1, ''
) as 'INVNo'
  
-- ref: https://medium.com/t-t-software-solution/mssql-รวมข้อมูลหลายๆ-rows-ให้อยู่ใน-1-column-ด้วย-sql-for-xml-path-fb2b3456668f
