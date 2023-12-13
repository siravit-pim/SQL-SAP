-- incoming - recieve
select oadm.PrintHeadr
	,orct.DocEntry,concat(nnm1.BeginStr,orct.DocNum)'DocNum'
	,orct.DocDate
	,orct.U_INCCustomerCode'CusCode',isnull(orct.U_INCCustomerName,ocrd.CardName)'CusName'
	,orct.DocTotal
	,rct.U_incom_ref,rct.DocNumber,rct.DocDate'RefDate'
	,isnull(rct.SumTotal,0)'SumTotal'
	,isnull((select isnull(rct.Total,0) where rct.TypePay = '1' ),0) 'TotalRCT' 
	,isnull((select isnull(rct.Total,0) where rct.TypePay = '2' ),0) 'TotalVPM' --Pay
	,orct.DocTotal-isnull(rct.SumTotal,0) 'Remaining'
from orct
left join nnm1 on orct.Series = nnm1.Series
left join OCRD on orct.U_INCCustomerCode = ocrd.CardCode
left join (select U_incom_ref,DocNumber,DocTotal'Total',TypePay,DocDate
				,sum(DocTotal) OVER(PARTITION BY U_incom_ref order by DocDate,DocEntry)'SumTotal'
			from ( select a.U_incom_ref,concat(nnm1.BeginStr,a.DocNum)'DocNumber',a.DocEntry,a.DocDate,'1'TypePay
						,iif(isnull(a.TrsfrSum,0)=0,a.doctotal,a.TrsfrSum)'DocTotal'
					from ORCT a left join nnm1 on a.Series = nnm1.Series
					where a.Canceled = 'N' and a.DocType = 'C'  and a.docdate <= {?dateat}
						Union all
					select a.U_incom_ref,concat(nnm1.BeginStr,a.DocNum)'DocNumber',a.DocEntry,a.DocDate,'2'TypePay
						,iif(isnull(a.U_inc_amount_ref,0)=0,a.doctotal,a.U_inc_amount_ref)'Total'
					from OVPM a left join nnm1 on a.Series = nnm1.Series
					where a.Canceled = 'N'						and a.docdate <= {?dateat}
				) A 
		) RCT on RCT.U_incom_ref = orct.DocNum
,oadm
where orct.Canceled = 'N' and orct.DocType = 'A' ) 
