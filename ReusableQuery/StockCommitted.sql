----Stock Committed ขาดแค่ Production
select SO.ItemCode,(isnull(SO.SOQty,0)+isnull(TFR.TFRQty,0))-(isnull(SO.DLQty,0)+isnull(SO.INQty,0))'Committed' from 
		(select RDR1.ItemCode,sum(rdr1.Quantity)'SOQty',sum(DLN.DLQty)'DLQty',sum(INV.INVQty)'INQty' 
		from XXXX..rdr1
		----SO > DL > Return
		left join (select sum(isnull(DLN1.Quantity,0))-isnull(RDN.ReturnQty,0)-isnull(INV.CNQty,0)'DLQty',DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine
					from XXXX..DLN1 
					inner join XXXX..ODLN on oDLN.DocEntry = DLN1.DocEntry			
					left join (select sum(isnull(RDN1.Quantity,0))'ReturnQty',RDN1.ItemCode,RDN1.BaseEntry,RDN1.BaseLine
								from XXXX..RDN1 
								inner join XXXX..oRDN on oRDN.DocEntry = RDN1.DocEntry
								where ORDN.CANCELED = 'N' 
								GROUP BY RDN1.ItemCode,RDN1.BaseEntry,RDN1.BaseLine
								) RDN on DLN1.ItemCode = RDN.ItemCode and DLN1.DocEntry = RDN.BaseEntry and DLN1.LineNum = RDN.BaseLine			
					----SO > DL > AP > CN		
					left join (select RIN.CNQty,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine
								from XXXX..inv1 
								inner join XXXX..oinv on oinv.DocEntry = inv1.DocEntry
								right join (select sum(isnull(RIN1.Quantity,0))'CNQty',RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine
											from XXXX..rin1 
											inner join XXXX..orin on orin.DocEntry = rin1.DocEntry
											where ORIN.CANCELED = 'N' and RIN1.NoInvtryMv = 'N' and RIN1.BaseType <> 203
											GROUP BY RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine
											) RIN on INV1.ItemCode = RIN.ItemCode and INV1.DocEntry = RIN.BaseEntry and INV1.LineNum = RIN.BaseLine			
								where OINV.CANCELED = 'N' and OINV.isIns = 'N'
								) INV on DLN1.ItemCode = INV.ItemCode and DLN1.DocEntry = INV.BaseEntry and DLN1.LineNum = INV.BaseLine
					where ODLN.CANCELED = 'N' 
					Group by DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,RDN.ReturnQty,INV.CNQty
					) DLN on RDR1.ItemCode = DLN.ItemCode and RDR1.DocEntry = DLN.BaseEntry and RDR1.LineNum = DLN.BaseLine
		---- SO > AP > CN
		left join (select sum(isnull(INV1.Quantity,0))-isnull(RIN.CNQty,0)'INVQty',INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine
					from XXXX..inv1 
					inner join XXXX..oinv on oinv.DocEntry = inv1.DocEntry
					left join (select sum(isnull(RIN1.Quantity,0))'CNQty',RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine
								from XXXX..rin1 
								inner join XXXX..orin on orin.DocEntry = rin1.DocEntry
								where ORIN.CANCELED = 'N' and RIN1.NoInvtryMv = 'N' and RIN1.BaseType <> 203
								GROUP BY RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine
								) RIN on INV1.ItemCode = RIN.ItemCode and INV1.DocEntry = RIN.BaseEntry and INV1.LineNum = RIN.BaseLine			
					where OINV.CANCELED = 'N' and OINV.isIns = 'N'
					Group by INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,RIN.CNQty
					) INV on RDR1.ItemCode = INV.ItemCode and RDR1.DocEntry = INV.BaseEntry and RDR1.LineNum = INV.BaseLine
		left join XXXX..ORDR on RDR1.DocEntry = ORDR.DocEntry
		where rdr1.LineStatus = 'O' 
				AND ((ORDR.DocDate BETWEEN @docdatefrom AND @docdateto)or (ORDR.TaxDate BETWEEN @taxdatefrom AND @taxdateto)) 
		group by RDR1.itemcode
		) SO
left join (select sum(isnull(WTQ1.Quantity,0))'TFRQty',OILM.ItemCode 
			From XXXX..OILM 
			left join XXXX..WTQ1 on (OILM.TransType = 1250000001) and (OILM.AccumType = 2) and (OILM.DocEntry = WTQ1.DocEntry) and (OILM.ItemCode = WTQ1.ItemCode) and (OILM.DocLineNum = WTQ1.LineNum) and WTQ1.LineStatus = 'O'	 										
			where OILM.TransType = 1250000001 ----TFR
			group by OILM.ItemCode
			) TFR on SO.ItemCode = TFR.ItemCode
