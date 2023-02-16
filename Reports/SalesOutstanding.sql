-- base ARInv - receive (internalReconcil)
with Z as (
select oadm.PrintHeadr'HeadName'
,oinv.CardCode,oinv.CardName,oinv.DocEntry'INV_Entry'
,concat(iif(concat(nnm1.BeginStr,'-')='-','',concat(nnm1.BeginStr,'-')),oinv.DocNum) 'INV_DocNum'
,oinv.DocDate'INV_Date',oinv.DocDueDate'INV_DueDate',OINV.SlpCode'EMPCode'
,IIF(isnull(oinv.U_ShipToAdd,'')<>'',oinv.U_ShipToAdd,inv12.StreetS)'Ship'
,oinv.DocTotal 'INV_BefVat'
,isnull(InternalRec.Paid,0) 'INV_Vax'
,oinv.DocTotal - isnull(InternalRec.Paid,0)'INV_Total'
,ocrd.GroupCode,ocrd.CardType,ocrd.U_CusType,ocrd.GroupNum,OSLP.SlpName
from oinv
left join OCRD on OINV.CardCode = OCRD.CardCode
join inv12 on oinv.DocEntry = inv12.DocEntry
left join nnm1 on oinv.Series = nnm1.Series 
left join oslp on oinv.SlpCode = oslp.SlpCode
left join (select ITR1.SrcObjAbs,ITR1.SrcObjTyp,sum(ITR1.ReconSum)'Paid'--,OITR.InitObjTyp,OITR.InitObjAbs
			from ITR1
			left join oitr on itr1.ReconNum = oitr.ReconNum
			where OITR.Canceled = 'N' and ITR1.SrcObjTyp = 13 and OITR.ReconDate <= {?dateat}
			group by ITR1.SrcObjAbs,ITR1.SrcObjTyp		
		) InternalRec on oinv.DocEntry = InternalRec.SrcObjAbs
,oadm
where oinv.CANCELED = 'N' and oinv.doctotal > 0
)
-- group in crystal reports
select '1'as'Yummy',* from (
select '1'as'CusType',* from Z where CardType = 'C' and U_CusType = 'CA' and GroupNum in('-1','31')
	Union all
select '2'as'CusType',* from Z where CardType = 'C' and U_CusType = 'CA' and GroupNum not in('-1','31')
	Union all
select '3'as'CusType',* from Z where CardType = 'C' and U_CusType not in('CA')
) A  
	Union all
select '2'as'Yummy',* from (
select '1'as'CusType',* from Z where CardType = 'C' and U_CusType = 'CA' and GroupNum in('-1','31')
	Union all
select '2'as'CusType',* from Z where CardType = 'C' and U_CusType = 'CA' and GroupNum not in('-1','31')
	Union all
select '3'as'CusType',* from Z where CardType = 'C' and U_CusType not in('CA')
) B where INV_Total <> 0 
