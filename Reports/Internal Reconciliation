-- Bill - paid (or CN) but see only in Internal Reconciliation

with Z as (
select bill.DocEntry,oadm.PrintHeadr'HeadName'
	,bill.U_CardCode'CusCode',bill.U_CardName'CusName'
	,concat(nnm1.BeginStr,bill.DocNum) 'BillDocNum',bill.DocNum'HeadNum'
	,bill.U_BillingDate 'BillDate' , bill1.INVDocEntry
	,bill.U_BillingDueDate 'BillDueDate'
	,bill1.DocNum
	,bill1.U_RefDocDate
	,bill1.U_RefDocDueDate
	,bill1.Ship,ocrd.GroupCode
	,isnull(Bill1.DocTotal,0) 'U_DocTotal'
	,isnull(bill1.U_PayableAmn,0) 'U_PayableAmn'
	,isnull(bill1.U_PayableAmn,0) - isnull(Bill1.ReconSum,0) 'U_Remaining'
	,case when isnull(bill1.U_PayableAmn,0) - isnull(Bill1.ReconSum,0) = 0 then 'Closed'
		when (isnull(bill1.U_PayableAmn,0) - isnull(Bill1.ReconSum,0)) = isnull(bill1.U_PayableAmn,0) then 'Open'
		when isnull(bill1.U_PayableAmn,0) - isnull(Bill1.ReconSum,0) > 0 then 'Partial'
	 end 'zStatus'
	,bill1.U_RefDocType,bill.U_remark 'Remark'
	,ocrd.CardType,ocrd.U_CusType,ocrd.GroupNum
from [@BILL] bill
left join ocrd on bill.U_CardCode = ocrd.CardCode and ocrd.CardType = 'C'
left join nnm1 on nnm1.Series = bill.Series and ObjectCode = 'bill'
join (select concat(bill1.U_RefPrefix,U_RefDocNo)'DocNum',bill1.U_RefDocDate,bill1.U_RefDocDueDate,bill1.U_RefDocType,bill1.DocEntry,bill1.U_PayableAmn,bill1.U_Remaining
		,inv.Ship,inv.DocEntry'INVDocEntry',inv.DocTotal,sum(ITR.ReconSum) 'ReconSum'
		from [@BILL1] bill1
		left join (select a.DocEntry,a.DocNum,a.ObjType,IIF(isnull(a.U_ShipToAdd,'')<>'',a.U_ShipToAdd,b.StreetS)'Ship',a.DocTotal
					from oinv a	
					left join inv12 b on a.DocEntry = b.DocEntry where a.CANCELED = 'N'
					Union all
					select a.DocEntry,a.DocNum,a.ObjType,IIF(isnull(a.U_ShipToAdd,'')<>'',a.U_ShipToAdd,b.StreetS)'Ship',a.DocTotal
					from orin a 
					left join rin12 b on a.DocEntry = b.DocEntry where a.CANCELED = 'N'
					union all
					select a.DocEntry,a.DocNum,a.ObjType,IIF(isnull(a.U_ShipToAdd,'')<>'',a.U_ShipToAdd,b.StreetS)'Ship',a.DocTotal
					from odpi a	
					left join dpi12 b on a.DocEntry = b.DocEntry where a.CANCELED = 'N'
				) inv on bill1.U_RefDocNo = inv.DocNum and bill1.U_RefDocType = inv.ObjType
		-- Internal Reconciliation
		left join (select a.SrcObjAbs,a.SrcObjTyp,a.ReconSum
					from itr1 a 
					left join oitr b on a.ReconNum = b.ReconNum where b.Canceled = 'N'
				) ITR on inv.ObjType = ITR.SrcObjTyp and inv.DocEntry = itr.SrcObjAbs
		group by concat(bill1.U_RefPrefix,U_RefDocNo),bill1.U_RefDocDate,bill1.U_RefDocDueDate,bill1.U_RefDocType,bill1.DocEntry,bill1.U_PayableAmn,bill1.U_Remaining,inv.Ship,inv.DocEntry,inv.DocTotal
	) bill1 on bill1.DocEntry = bill.DocEntry
,oadm
where bill.Canceled = 'N' --and bill.DocNum = '22100012'
)
select '1'as'CusType',* from Z where (CardType = 'C' and U_CusType = 'CA' and GroupNum in('-1','31') )	
Union all
select '2'as'CusType',* from Z where CardType = 'C' and U_CusType = 'CA' and GroupNum not in('-1','31')		
Union all
select '3'as'CusType',* from Z where CardType = 'C' and U_CusType not in('CA')
