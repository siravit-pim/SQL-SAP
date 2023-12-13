Concat (
    Day(OWTR.U_PostDate),
    '-',
    CASE
        when Month(OWTR.U_PostDate) = 1 then N'ม.ค.'
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
    END,
    '-',
    Year(OWTR.U_PostDate) + 543 -- AD to BE
) 'PostDate'

-------------------------
Case
	When MONTH(DocDate) = '1' then N'มกราคม'
	when MONTH(DocDate) = '2' then N'กุมภาพันธ์'
	when MONTH(DocDate) = '3' then N'มีนาคม'
	when MONTH(DocDate) = '4' then N'เมษายน'
	when MONTH(DocDate) = '5' then N'พฤษภาคม'
	when MONTH(DocDate) = '6' then N'มิถุนายน'
	when MONTH(DocDate) = '7' then N'กรกฎาคม'
	when MONTH(DocDate) = '8' then N'สิงหาคม'
	when MONTH(DocDate) = '9' then N'กันยายน'
	when MONTH(DocDate) = '10' then N'ตุลาคม'
	when MONTH(DocDate) = '11' then N'พฤศจิกายน'
	when MONTH(DocDate) = '12' then N'ธันวาคม'
end 'Month'
