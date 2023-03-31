-- SQL
,concat (
		Day(OWTR.U_PostDate),'-'
		,case when Month(OWTR.U_PostDate) = 1 then N'ม.ค.'
		when Month(OWTR.U_PostDate) = 2 then N'ก.พ.'
		when Month(OWTR.U_PostDate) = 3 then N'มี.ค.'
		when Month(OWTR.U_PostDate) = 4 then N'เม.ย.'
		when Month(OWTR.U_PostDate) = 5 then N'พ.ค.'
		when Month(OWTR.U_PostDate) = 6 then N'มิ.ย.'
		when Month(OWTR.U_PostDate) = 7 then N'ก.ค.'
		when Month(OWTR.U_PostDate) = 8 then N'ส.ค.'
		when Month(OWTR.U_PostDate) = 9 then N'ก.ย.'
		when Month(OWTR.U_PostDate) = 10 then N'ต.ค.'
		when Month(OWTR.U_PostDate) = 11 then N'พ.ย.'
		when Month(OWTR.U_PostDate) = 12 then N'ธ.ค.'
		END 
		,'-',Year(OWTR.U_PostDate) +543 
		) 'U_PostDate'

-- crstal report
switch (month({PWHT.TaxDate})=1 ,"ม.ค.",
month({PWHT.TaxDate})=2 ,"ก.พ.",
month({PWHT.TaxDate})=3 ,"มี.ค.",
month({PWHT.TaxDate})=4 ,"เม.ย.",
month({PWHT.TaxDate})=5 ,"พ.ค.",
month({PWHT.TaxDate})=6 ,"มิ.ย.",
month({PWHT.TaxDate})=7 ,"ก.ค.",
month({PWHT.TaxDate})=8 ,"ส.ค.",
month({PWHT.TaxDate})=9 ,"ก.ย.",
month({PWHT.TaxDate})=10 ,"ต.ค.",
month({PWHT.TaxDate})=11 ,"พ.ย.",
month({PWHT.TaxDate})=12 ,"ธ.ค.")
----
Year({PWHT.TaxDate})+543
