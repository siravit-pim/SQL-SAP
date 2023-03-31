-- Ref Docnumber Sales Order
with A as (
select 'Invoice' TypeDoc,OINV.DocEntry,OINV.DocNum
	,OINV.U_PostDate,OINV.U_PostRec,OINV.U_PostShipTo,OINV.U_PostEMS
	,stuff ( 
		( select ',' + concat(nnm1.BeginStr,cast(ORDR.DocNum  as nvarchar(max)) )
			from INV1
			left join ORDR on ORDR.DocEntry = INV1.BaseEntry and INV1.BaseType = 17 --SO	
			left join nnm1 on nnm1.Series = ordr.Series
			where (INV1.DocEntry = OINV.DocEntry) and ORDR.CANCELED = 'N' and INV1.BaseType = 17
			group by nnm1.BeginStr,ORDR.DocNum
			FOR XML PATH ('') 
		), 1, 1, ''
	) as 'SONo'
	,oadm.CompnyName
from OINV
,OADM
where OINV.CANCELED = 'N' --and OINV.DocEntry = 876
-- **************************************************
Union all
-- **************************************************
select 'Transfer' TypeDoc,owtr.DocEntry,Owtr.DocNum
	,OWTR.U_PostDate,OWTR.U_PostRec,OWTR.U_PostShipTo,OWTR.U_PostEMS
	,stuff ( 
		( select ',' + concat(nnm1.BeginStr,cast(wtr21.RefDocNum  as nvarchar(max)) )
			from wtr21
			left join ORDR on ORDR.DocEntry = wtr21.RefDocEntr and wtr21.ObjectType = 67 --SO
			left join nnm1 on nnm1.Series = ordr.Series
			where (owtr.DocEntry = wtr21.DocEntry) and ORDR.CANCELED = 'N' and wtr21.ObjectType = 67
			FOR XML PATH ('') 
		), 1, 1, ''
	) as 'SONo' 
	,oadm.CompnyName
from OWTR
,OADM
where owtr.CANCELED = 'N' --and owtr.DocEntry in(2495,3025)
)
select * 
from A
where SoNo is not null and isnull(U_PostEMS,'') <> ''
