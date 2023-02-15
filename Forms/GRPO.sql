select case when opor.Docnum is null then '' else concat(nnmpor.BeginStr,opor.DocNum) END 'PO_Docnum'
,pdn1.U_brand'Brand',opdn.CardCode'Vendor_Code',opdn.CardName'Vendor_Name'
,concat(nnmpdn.BeginStr,opdn.docnum)'GRPO_DocNum',opdn.DocDate'GRPO_Date'
,case when opch.Docnum is null then '' else concat(nnmpdn.BeginStr,opch.Docnum) end 'AP_DocNum'
,opch.DocDate'AP_Date',opdn.NumAtCard,pdn1.ItemCode,pdn1.Dscription
,pdn1.OcrCode2,pdn1.OcrCode3,pdn1.OcrCode4,pdn1.Quantity,pdn1.WhsCode
,pdn1.PriceBefDi'UnitPrice_BeforDis',pdn1.Price'UnitPrice_AfterDis'
,format(pdn1.DiscPrcnt*0.01,'P')'DisPrcnt',pdn1.PriceBefDi-pdn1.Price'Price_Dis'
,pdn1.PriceBefDi*pdn1.Quantity 'Total_BeforDis',pdn1.linetotal'Total_AfterDis'
,pdn1.VatSum'Vat',pdn1.Linetotal+pdn1.vatsum'Net'
from xxxx..opdn
inner join xxxx..pdn1 on opdn.DocEntry = pdn1.DocEntry
left join xxxx..nnm1 nnmpdn on opdn.Series = nnmpdn.Series
left join xxxx..opor on pdn1.basetype = opor.ObjType and pdn1.BaseEntry = opor.DocEntry and opor.CANCELED = 'N'
left join xxxx..nnm1 nnmpor on opor.Series = nnmpor.Series
left join xxxx..opch on pdn1.TargetType = opch.ObjType and pdn1.TrgetEntry = opch.DocEntry and opch.CANCELED = 'N'
left join xxxx..nnm1 nnmpch on opch.Series = nnmpch.Series

where opdn.CANCELED = 'N' AND OPDN.DocDate BETWEEN @docdatefrom AND @docdateTo
