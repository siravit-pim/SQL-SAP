
-- Just table Intentory tranfer
-- 3 type OB / Borrow/ return
----****************************************************
------declare @docdatefrom as date
------declare @docdateto as date
	declare @database2 as nvarchar(200)
------declare @Balance as nvarchar(1)
------declare @itemgroup as nvarchar(1)
------set @docdatefrom = '20220401'
------set @docdateto = '20220430'
	-- declare @empsales nvarchar(100)
	set @database2 = 'XXXXXX'
------set @Balance = '2'
------set @itemgroup = ''
----****************************************************

select A.* from 
(select OBBA1.* from 
(select 'OB' as 'Type'
,case   when RowWTR.U_MKRWCM01 is not null then RowWTR.U_MKRWCM01 
		when RowWTR.U_MKRWCM02 is not null then RowWTR.U_MKRWCM02 
		when RowWTR.U_MKRWCM03 is not null then RowWTR.U_MKRWCM03
		else oslp.Memo end 'EMPSales'
,concat(nnm1.BeginStr,owtr.DocNum) 'DocNum',owtr.DocDate,concat(isnull(DATEDIFF(day,owtr.docdate,owtr.U_MKHDOB03),0),' ','day') 'Date_Borrow',owtr.U_MKHDOB03 'DueDate'
,RowWTR.ItemCode,RowWTR.Dscription,RowWTR.WhsFrom,RowWTR.WhsTo,RowWTR.unitMsr'UoM'
,isnull(RowWTR.QTY,0) 'BorrowQty'
,isnull(wtr.Quantity,0) 'ReturnQty'
,IIF(isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0) < 0, 0, isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0)) 'DiffQty'
,IIF(isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0) < 0, 0, isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0)) * 
	Case When RowWTR.ItemCode Like 'B-%' Then (CASE WHEN Plist1.Price <> 0 THEN Plist1.Price ELSE (CASE WHEN OITM.AvgPrice <> 0 THEN OITM.AvgPrice ELSE 0 END) END)*1.05 Else isnull(Plist2.Price,0) End 'TotalPrice'
,owtr.CardCode'BPCode',owtr.CardName'BPName',concat(OHEM.firstName,' ',OHEM.middleName,' ',OHEM.lastName)'TecName'
,wtr.DocRef'ReverseDoc',wtr.docdate'ReverseDate',owtr.U_internal_remark'Remark1',[@03OBJECT].Name 'Remark2'
,concat(isnull(DATEDIFF(day,owtr.docdate,GETDATE()),0),' ','day') N'วันที่ยืมถึงปัจจุบัน'
,concat(isnull(DATEDIFF(day,owtr.U_MKHDOB03,GETDATE()),0),' ','day') N'วันที่ยืมเกินจากDueDateถึงปัจจุบัน'
,case when OWTR.CardCode is not null then '' else OWTR.[Address] end 'Other', ''[Remark Status]
from xxxx..owtr
join (select ItemCode,Dscription,FromWhsCod'WhsFrom',WhsCode'WhsTo',Price,DocEntry,U_MKRWCM01,U_MKRWCM02,U_MKRWCM03,unitMsr,UomEntry,BaseType,sum(Quantity)'QTY'
		from xxxx..wtr1
		group by ItemCode,Dscription,FromWhsCod,WhsCode,Price,DocEntry,U_MKRWCM01,U_MKRWCM02,U_MKRWCM03,unitMsr,UomEntry,BaseType
		) RowWTR on RowWTR.DocEntry = owtr.DocEntry
left join xxxx..nnm1 on owtr.Series = nnm1.Series
left join (select concat(nnm1.BeginStr,max(owtr.DocNum))'DocRef',max(owtr.DocNum)'DocNum',max(owtr.docdate)'docdate',sum(wtr1.Quantity)'Quantity',owtr.U_MKHDOB06,wtr1.ItemCode			
			from xxxx..owtr
			inner join xxxx..wtr1 on wtr1.DocEntry = owtr.DocEntry
			left join xxxx..nnm1 on nnm1.Series = owtr.Series
			where (owtr.CANCELED = 'N' and wtr1.BaseType <> 0) 
					and (owtr.U_MKHDOB06 is not null or owtr.U_MKHDOB06 <> '') 
					and OWTR.DocDate <= @docdateto 
					and left(owtr.U_MKHDOB01,4) = 'TF-B'
				group by owtr.U_MKHDOB06,wtr1.ItemCode,nnm1.BeginStr
				) wtr on ((cast(owtr.docnum as varchar(max)) = wtr.U_MKHDOB06) or (concat(nnm1.BeginStr,owtr.DocNum) = wtr.U_MKHDOB06)) and wtr.ItemCode = RowWTR.ItemCode
left join xxxx..oslp on owtr.SlpCode = oslp.SlpCode
left join xxxx..[@03OBJECT] on [@03OBJECT].Code = owtr.U_MKHDOB01
left join xxxx..ohem on  owtr.U_MKHDOB07 = ohem.empID
left join xxxx..OITM on  RowWTR.ItemCode = OITM.ItemCode
left join xxxx..OITB on  OITM.ItmsGrpCod = OITB.ItmsGrpCod
left join xxxx..itm1 Plist1 on RowWTR.ItemCode = Plist1.ItemCode and RowWTR.UomEntry = Plist1.UomEntry and Plist1.PriceList = '1' --Pricelist
left join xxxx..itm1 Plist2 on RowWTR.ItemCode = Plist2.ItemCode and RowWTR.UomEntry = Plist2.UomEntry and Plist2.PriceList = '2' --Pricelist
left join xxxx..[@ICMT0001] on [@ICMT0001].Code = OITM.U_ICMT0001
where ((owtr.CANCELED = 'N' and RowWTR.BaseType <> 0)	and isnull(owtr.U_MKHDOB06,'') = '' and left(owtr.U_MKHDOB01,4) = 'TF-B')
		and OWTR.DocDate < @docdatefrom
		and (ISNULL([@ICMT0001].Code,'') = isnull(nullif(@itemgroup,''),[@ICMT0001].Code) )
	) OBBA1 where ( BorrowQty - ReturnQty > 0 ) 

-------------------------------------------------------------
union all 
select INVVA1.* from 
(select 'zBorrow/Return' as 'Type'
,case   when RowWTR.U_MKRWCM01 is not null then RowWTR.U_MKRWCM01 
		when RowWTR.U_MKRWCM02 is not null then RowWTR.U_MKRWCM02 
		when RowWTR.U_MKRWCM03 is not null then RowWTR.U_MKRWCM03
		else oslp.Memo end 'EMPSales'
,concat(nnm1.BeginStr,owtr.DocNum) 'DocNum',owtr.DocDate,concat(isnull(DATEDIFF(day,owtr.docdate,owtr.U_MKHDOB03),0),' ','day') 'Date_Borrow',owtr.U_MKHDOB03 'DueDate'
,RowWTR.ItemCode,RowWTR.Dscription,RowWTR.WhsFrom,RowWTR.WhsTo,RowWTR.unitMsr'UoM'
,isnull(RowWTR.QTY,0) 'BorrowQty',isnull(wtr.Quantity,0) 'ReturnQty'
,IIF(isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0) < 0, 0, isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0)) 'DiffQty'
,IIF(isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0) < 0, 0, isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0)) * 
 Case When RowWTR.ItemCode Like 'B-%' Then (CASE WHEN Plist1.Price <> 0 THEN Plist1.Price ELSE (CASE WHEN OITM.AvgPrice <> 0 THEN OITM.AvgPrice ELSE 0 END) END)*1.05 Else isnull(Plist2.Price,0) End 'TotalPrice'
,owtr.CardCode'BPCode',owtr.CardName'BPName',concat(OHEM.firstName,' ',OHEM.middleName,' ',OHEM.lastName)'TecName'
,wtr.DocRef'ReverseDoc',wtr.docdate'ReverseDate',owtr.U_internal_remark'Remark1',[@03OBJECT].Name 'Remark2'
,concat(isnull(DATEDIFF(day,owtr.docdate,GETDATE()),0),' ','day') N'วันที่ยืมถึงปัจจุบัน'
,concat(isnull(DATEDIFF(day,owtr.U_MKHDOB03,GETDATE()),0),' ','day') N'วันที่ยืมเกินจากDueDateถึงปัจจุบัน'
,case when OWTR.CardCode is not null then '' else OWTR.[Address] end 'Other', ''[Remark Status]
from xxxx..owtr
join (select ItemCode,Dscription,FromWhsCod'WhsFrom',WhsCode'WhsTo',Price,DocEntry,U_MKRWCM01,U_MKRWCM02,U_MKRWCM03,unitMsr,UomEntry,BaseType,sum(Quantity)'QTY'
		from xxxx..wtr1
		group by ItemCode,Dscription,FromWhsCod,WhsCode,Price,DocEntry,U_MKRWCM01,U_MKRWCM02,U_MKRWCM03,unitMsr,UomEntry,BaseType
		) RowWTR on RowWTR.DocEntry = owtr.DocEntry
left join xxxx..nnm1 on owtr.Series = nnm1.Series
left join (select concat(nnm1.BeginStr,max(owtr.DocNum))'DocRef',max(owtr.DocNum)'DocNum',max(owtr.docdate)'docdate',sum(wtr1.Quantity)'Quantity',owtr.U_MKHDOB06,wtr1.ItemCode			
			from xxxx..owtr
			inner join xxxx..wtr1 on wtr1.DocEntry = owtr.DocEntry
			left join xxxx..nnm1 on nnm1.Series = owtr.Series
			where (owtr.CANCELED = 'N' and wtr1.BaseType <> 0) 
					and (owtr.U_MKHDOB06 is not null or owtr.U_MKHDOB06 <> '') 
					and OWTR.DocDate between @docdatefrom and @docdateto
					and left(owtr.U_MKHDOB01,4) = 'TF-B'
				group by owtr.U_MKHDOB06,wtr1.ItemCode,nnm1.BeginStr
				) wtr on ((cast(owtr.docnum as varchar(max)) = wtr.U_MKHDOB06) or (concat(nnm1.BeginStr,owtr.DocNum) = wtr.U_MKHDOB06)) and wtr.ItemCode = RowWTR.ItemCode
left join xxxx..oslp on owtr.SlpCode = oslp.SlpCode
left join xxxx..[@03OBJECT] on [@03OBJECT].Code = owtr.U_MKHDOB01
left join xxxx..ohem on  owtr.U_MKHDOB07 = ohem.empID
left join xxxx..OITM on  RowWTR.ItemCode = OITM.ItemCode
left join xxxx..OITB on  OITM.ItmsGrpCod = OITB.ItmsGrpCod
left join xxxx..itm1 Plist1 on RowWTR.ItemCode = Plist1.ItemCode and RowWTR.UomEntry = Plist1.UomEntry and Plist1.PriceList = '1' --Pricelist
left join xxxx..itm1 Plist2 on RowWTR.ItemCode = Plist2.ItemCode and RowWTR.UomEntry = Plist2.UomEntry and Plist2.PriceList = '2' --Pricelist
left join xxxx..[@ICMT0001] on [@ICMT0001].Code = OITM.U_ICMT0001
where ((owtr.CANCELED = 'N' and RowWTR.BaseType <> 0) and isnull(owtr.U_MKHDOB06,'') = '' and left(owtr.U_MKHDOB01,4) = 'TF-B')
		and OWTR.DocDate between @docdatefrom and @docdateto
		and (ISNULL([@ICMT0001].Code,'') = isnull(nullif(@itemgroup,''),[@ICMT0001].Code) )
	) INVVA1 where '1' = @Balance

-------------------------------------------------------------
union all 
select INVVA2.* from 
(select 'zBorrow/Return' as 'Type'
,case   when RowWTR.U_MKRWCM01 is not null then RowWTR.U_MKRWCM01 
		when RowWTR.U_MKRWCM02 is not null then RowWTR.U_MKRWCM02 
		when RowWTR.U_MKRWCM03 is not null then RowWTR.U_MKRWCM03
		else oslp.Memo end 'EMPSales'
,concat(nnm1.BeginStr,owtr.DocNum) 'DocNum',owtr.DocDate,concat(isnull(DATEDIFF(day,owtr.docdate,owtr.U_MKHDOB03),0),' ','day') 'Date_Borrow',owtr.U_MKHDOB03 'DueDate'
,RowWTR.ItemCode,RowWTR.Dscription,RowWTR.WhsFrom,RowWTR.WhsTo,RowWTR.unitMsr'UoM'
,isnull(RowWTR.QTY,0) 'BorrowQty',isnull(wtr.Quantity,0) 'ReturnQty'
,IIF(isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0) < 0, 0, isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0)) 'DiffQty'
,IIF(isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0) < 0, 0, isnull(RowWTR.QTY,0) - isnull(wtr.Quantity,0)) * Case When RowWTR.ItemCode Like 'B-%' Then (CASE WHEN Plist1.Price <> 0 THEN Plist1.Price ELSE (CASE WHEN OITM.AvgPrice <> 0 THEN OITM.AvgPrice ELSE 0 END) END)*1.05 Else isnull(Plist2.Price,0) End 'TotalPrice'
,owtr.CardCode'BPCode',owtr.CardName'BPName',concat(OHEM.firstName,' ',OHEM.middleName,' ',OHEM.lastName)'TecName'
,wtr.DocRef'ReverseDoc',wtr.docdate'ReverseDate',owtr.U_internal_remark'Remark1',[@03OBJECT].Name 'Remark2'
,concat(isnull(DATEDIFF(day,owtr.docdate,GETDATE()),0),' ','day') N'วันที่ยืมถึงปัจจุบัน'
,concat(isnull(DATEDIFF(day,owtr.U_MKHDOB03,GETDATE()),0),' ','day') N'วันที่ยืมเกินจากDueDateถึงปัจจุบัน'
,case when OWTR.CardCode is not null then '' else OWTR.[Address] end 'Other', ''[Remark Status]
from xxxx..owtr
join (select ItemCode,Dscription,FromWhsCod'WhsFrom',WhsCode'WhsTo',Price,DocEntry,U_MKRWCM01,U_MKRWCM02,U_MKRWCM03,unitMsr,UomEntry,BaseType,sum(Quantity)'QTY'
		from xxxx..wtr1
		group by ItemCode,Dscription,FromWhsCod,WhsCode,Price,DocEntry,U_MKRWCM01,U_MKRWCM02,U_MKRWCM03,unitMsr,UomEntry,BaseType
		) RowWTR on RowWTR.DocEntry = owtr.DocEntry
left join xxxx..nnm1 on owtr.Series = nnm1.Series
left join (select concat(nnm1.BeginStr,max(owtr.DocNum))'DocRef',max(owtr.DocNum)'DocNum',max(owtr.docdate)'docdate',sum(wtr1.Quantity)'Quantity',owtr.U_MKHDOB06,wtr1.ItemCode			
			from xxxx..owtr
			inner join xxxx..wtr1 on wtr1.DocEntry = owtr.DocEntry
			left join xxxx..nnm1 on nnm1.Series = owtr.Series
			where (owtr.CANCELED = 'N' and wtr1.BaseType <> 0) 
					and (owtr.U_MKHDOB06 is not null or owtr.U_MKHDOB06 <> '') 
					and OWTR.DocDate between @docdatefrom and @docdateto
					and left(owtr.U_MKHDOB01,4) = 'TF-B'
				group by owtr.U_MKHDOB06,wtr1.ItemCode,nnm1.BeginStr
				) wtr on ((cast(owtr.docnum as varchar(max)) = wtr.U_MKHDOB06) or (concat(nnm1.BeginStr,owtr.DocNum) = wtr.U_MKHDOB06)) and wtr.ItemCode = RowWTR.ItemCode
left join xxxx..oslp on owtr.SlpCode = oslp.SlpCode
left join xxxx..[@03OBJECT] on [@03OBJECT].Code = owtr.U_MKHDOB01
left join xxxx..ohem on  owtr.U_MKHDOB07 = ohem.empID
left join xxxx..OITM on  RowWTR.ItemCode = OITM.ItemCode
left join xxxx..OITB on  OITM.ItmsGrpCod = OITB.ItmsGrpCod
left join xxxx..itm1 Plist1 on RowWTR.ItemCode = Plist1.ItemCode and RowWTR.UomEntry = Plist1.UomEntry and Plist1.PriceList = '1' --Pricelist
left join xxxx..itm1 Plist2 on RowWTR.ItemCode = Plist2.ItemCode and RowWTR.UomEntry = Plist2.UomEntry and Plist2.PriceList = '2' --Pricelist
left join xxxx..[@ICMT0001] on [@ICMT0001].Code = OITM.U_ICMT0001
where ((owtr.CANCELED = 'N' and RowWTR.BaseType <> 0) and isnull(owtr.U_MKHDOB06,'') = '' and left(owtr.U_MKHDOB01,4) = 'TF-B')
		and OWTR.DocDate between @docdatefrom and @docdateto
		and ( RowWTR.QTY - isnull(wtr.Quantity,0) <> 0 )	
		and (ISNULL([@ICMT0001].Code,'') = isnull(nullif(@itemgroup,''),[@ICMT0001].Code) )
	) INVVA2 where '2' = @Balance and ( BorrowQty - ReturnQty > 0 ) 
		) A  ,xxxx..oadm where oadm.CompnyName = @database2

----*************************************************************************************

order by [type],docnum, docdate
