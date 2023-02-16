-- bring information to bank (online)
With A as (
select --INV.INVDate,CN.CNDate,
	isnull(isnull(INV.Total,0) - isnull(CN.Total,0),0) 'Total'
	,isnull(cast(T0.CardCode as nvarchar(16)),'')'BPCode'
	,''as'A'
	,isnull(cast(ocrb.AcctName as nvarchar(35)),'') 'BankAccName'
	,isnull(cast(T0.DflIBAN as nvarchar(34)),'') 'IBAN'
	,''as'B'
	,''as'C'
	,isnull(cast(T0.Country as nvarchar(2)),'') 'SCountry'
	,left(concat(isnull(INV.InvNo,''),isnull(CN.CNNo,'')),35) 'INV1'
	,SUBSTRING(concat(isnull(INV.InvNo,''),isnull(CN.CNNo,'')),36,35) 'INV2'
	,SUBSTRING(concat(isnull(INV.InvNo,''),isnull(CN.CNNo,'')),71,35) 'CN1'
	,SUBSTRING(concat(isnull(INV.InvNo,''),isnull(CN.CNNo,'')),106,35) 'CN2'
	,isnull(cast(T0.DflSwift as nvarchar(34)),'') 'SwiftCode'
	,isnull(cast(odsc.BankName as nvarchar(35)),'') 'BankName'
	,isnull(cast(T0.BankCountr as nvarchar(2)),'') 'BankCountry'	
from ocrd T0
left join odsc on odsc.BankCode = T0.BankCode and odsc.CountryCod = T0.BankCountr
left join ocrb on (ocrb.CardCode = T0.CardCode) and ocrb.BankCode = T0.BankCode and ocrb.Country = T0.BankCountr
left join ( select CardCode,sum(DocTotal) - sum(PaidToDate) 'Total'
			,stuff ( (  select ',' + cast(b.NumAtCard  as nvarchar(max))					
						from OPCH b 
						where b.DocCur = 'EUR' and (b.CANCELED = 'N' and a.cardcode = b.CardCode and ( b.U_jatu_approve = 'Yes' or b.U_bank_payment = 'Y' ) ) and b.DocDate Between {?DateFrom} and {?DateTo}
						group by b.NumAtCard
						having sum(DocTotal) - sum(PaidToDate) > 0
						FOR XML PATH ('') ), 1, 1, ''
					) as 'INVNo'
			from OPCH a
			where a.DocCur = 'EUR' and (a.CANCELED = 'N' and (a.U_jatu_approve = 'Yes' or a.U_bank_payment = 'Y') ) and a.DocDate Between {?DateFrom} and {?DateTo}
			group by CardCode
			having sum(DocTotal) - sum(PaidToDate) > 0
			) INV on INV.CardCode = T0.CardCode
left join ( select CardCode,sum(DocTotal) - sum(PaidToDate) 'Total'
			,stuff ( (  select ',' + cast(b.NumAtCard as nvarchar(max))					
						from ORPC b 
						where b.DocCur = 'EUR' and (b.CANCELED = 'N' and a.cardcode = b.CardCode and (b.U_jatu_approve = 'Yes' or b.U_bank_payment = 'Y') ) and b.DocDate Between {?DateFrom} and {?DateTo}
						group by b.NumAtCard
						--having sum(DocTotal) - sum(PaidToDate) > 0
						FOR XML PATH ('') ), 1, 1, '' 
					) as 'CNNo'
			from ORPC a
			where a.DocCur = 'EUR' and (a.CANCELED = 'N' and (a.U_jatu_approve = 'Yes' or a.U_bank_payment = 'Y') ) and a.DocDate Between {?DateFrom} and {?DateTo}
			group by CardCode
			--having sum(DocTotal) - sum(PaidToDate) > 0
			) CN on CN.CardCode = T0.CardCode
where T0.CardType = 'S' --and T0.cardcode = 'NLV0004'
) select * from A where Total <> 0
