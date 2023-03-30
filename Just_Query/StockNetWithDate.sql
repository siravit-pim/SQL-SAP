--Stock (Instock - committed) //Date
select STOCK.ItemCode,STOCK.Supplytype,STOCK.Sales,STOCK.LocCode'Whs',isnull(STOCK.InStock,0) - sum(isnull(stock.Committ,0)) 'TotalStock'
			from	(select OILM.ItemCode,isnull(oilm.OcrCode4,'')'Supplytype',isnull(oilm.OcrCode2,'')'Sales',OILM.LocCode
					,sum(oivl.InQty) - sum(oivl.OutQty) 'InStock'
					,isnull((isnull(SO.SOQty,0) + isnull(TFR.TFRQty,0) + isnull(SO.INVRESQty,0) ) - (isnull(SO.DLQty,0) + isnull(SO.INQty,0)),0) 'Committ'								
					from XXXX..OILM with(nolock)
					left join XXXX..OIVL with(nolock) ON OIVL.[MessageID] = OILM.[MessageID] and OIVL.ItemCode = OILM.ItemCode
					left join (	select RDR1.ItemCode,RDR1.OcrCode4,RDR1.OcrCode2,RDR1.WhsCode
								,(select sum(isnull(rdr1.Quantity,0)) where rdr1.LineStatus = 'O')		'SOQty'
								,(select sum(isnull(DLN.DLQty,0)) where rdr1.LineStatus = 'O')			'DLQty'
								,(select sum(isnull(INV.INVQty,0)) where rdr1.LineStatus = 'O')			'INQty'
								,(select sum(isnull(INVRES.INVRESQty,0)) where rdr1.LineStatus = 'O')	'INVRESQty'
								from XXXX..rdr1 with(nolock) 
								----SO > DL > Return
								left join (select sum(DLN1.Quantity) - isnull(RDN.ReturnQty,0) - isnull(INV.CNQty,0)'DLQty', DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.OcrCode4,DLN1.OcrCode2,DLN1.WhsCode 
											from XXXX..DLN1 with(nolock)
											inner join XXXX..ODLN with(nolock) on oDLN.DocEntry = DLN1.DocEntry			
											left join (select sum(RDN1.Quantity)'ReturnQty',RDN1.ItemCode,RDN1.BaseEntry,RDN1.BaseLine,RDN1.OcrCode4,RDN1.OcrCode2,RDN1.WhsCode
														from XXXX..RDN1 with(nolock)
														inner join XXXX..ORDN with(nolock) on oRDN.DocEntry = RDN1.DocEntry
														where ORDN.CANCELED = 'N' 
														GROUP BY RDN1.ItemCode,RDN1.BaseEntry,RDN1.BaseLine,RDN1.OcrCode4,RDN1.OcrCode2,RDN1.WhsCode
														) RDN on DLN1.ItemCode = RDN.ItemCode and DLN1.DocEntry = RDN.BaseEntry and DLN1.LineNum = RDN.BaseLine	and isnull(RDN.OcrCode4,'') = isnull(DLN1.OcrCode4,'') and isnull(RDN.OcrCode2,'') = isnull(DLN1.OcrCode2,'') and RDN.WhsCode = DLN1.WhsCode 
											----SO > DL > AR > CN		
											left join (select RIN.CNQty,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode
														from XXXX..inv1 with(nolock)
														inner join XXXX..oinv with(nolock) on oinv.DocEntry = inv1.DocEntry
														right join (select sum(RIN1.Quantity)'CNQty',RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine,RIN1.OcrCode4,ORIN.U_Ref_INV,RIN1.OcrCode2,RIN1.WhsCode
																	from XXXX..rin1 with(nolock)
																	inner join XXXX..orin with(nolock) on orin.DocEntry = rin1.DocEntry
																	where ORIN.CANCELED = 'N' and RIN1.NoInvtryMv = 'N' and RIN1.BaseType <> 203 
																	GROUP BY RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine,RIN1.OcrCode4,ORIN.U_Ref_INV,RIN1.OcrCode2,RIN1.WhsCode
																	) RIN on INV1.ItemCode = RIN.ItemCode and ((INV1.DocEntry = RIN.BaseEntry) or (OINV.DocNum = RIN.U_Ref_INV)) and INV1.LineNum = RIN.BaseLine and isnull(INV1.OcrCode4,'') = isnull(RIN.OcrCode4,'') and isnull(INV1.OcrCode2,'') = isnull(RIN.OcrCode2,'') and INV1.WhsCode = RIN.WhsCode 	
														where OINV.CANCELED = 'N' and OINV.isIns = 'N' 							
														) INV on DLN1.ItemCode = INV.ItemCode and DLN1.DocEntry = INV.BaseEntry and DLN1.LineNum = INV.BaseLine
											where ODLN.CANCELED = 'N'  	
											Group by DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,RDN.ReturnQty,INV.CNQty,DLN1.OcrCode4,DLN1.OcrCode2,DLN1.WhsCode 
											) DLN on RDR1.ItemCode = DLN.ItemCode and RDR1.DocEntry = DLN.BaseEntry and RDR1.LineNum = DLN.BaseLine and isnull(RDR1.OcrCode4,'') = isnull(DLN.OcrCode4,'') and isnull(RDR1.OcrCode2,'') = isnull(DLN.OcrCode2,'') and RDR1.WhsCode = DLN.WhsCode 
								---- SO > AR > CN
								left join (select sum(INV1.Quantity) - isnull(RIN.CNQty,0)'INVQty',INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode 
											from XXXX..inv1 with(nolock)
											inner join XXXX..oinv with(nolock) on oinv.DocEntry = inv1.DocEntry
											left join (select sum(RIN1.Quantity)'CNQty',RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine,RIN1.OcrCode4,ORIN.U_Ref_INV,RIN1.OcrCode2,RIN1.WhsCode
														from XXXX..rin1 with(nolock)
														inner join XXXX..orin with(nolock) on orin.DocEntry = rin1.DocEntry
														where ORIN.CANCELED = 'N' and RIN1.NoInvtryMv = 'N' and RIN1.BaseType <> 203
														GROUP BY RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine,RIN1.OcrCode4,ORIN.U_Ref_INV,RIN1.OcrCode2,RIN1.WhsCode
														) RIN on INV1.ItemCode = RIN.ItemCode and ((INV1.DocEntry = RIN.BaseEntry) or (OINV.DocNum = RIN.U_Ref_INV)) and INV1.LineNum = RIN.BaseLine and isnull(INV1.OcrCode4,'') = isnull(RIN.OcrCode4,'') and isnull(INV1.OcrCode2,'') = isnull(RIN.OcrCode2,'') and INV1.WhsCode = RIN.WhsCode			
											where OINV.CANCELED = 'N'  and OINV.isIns = 'N' 
											Group by INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,RIN.CNQty,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode  
											) INV on RDR1.ItemCode = INV.ItemCode and RDR1.DocEntry = INV.BaseEntry and RDR1.LineNum = INV.BaseLine and isnull(RDR1.OcrCode4,'') = isnull(INV.OcrCode4,'') and isnull(RDR1.OcrCode2,'') = isnull(INV.OcrCode2,'') and RDR1.WhsCode = INV.WhsCode
								---- SO > AR Res > DL < CN
								left join (select sum(INV1.Quantity) - isnull(DLN.DLQty,0) 'INVRESQty',INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode
											from XXXX..inv1 with(nolock)
											left join XXXX..oinv with(nolock) on oinv.DocEntry = inv1.DocEntry
											left join (select sum(DLN1.Quantity)'DLQty',DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.OcrCode4,DLN1.OcrCode2,DLN1.WhsCode
														from XXXX..DLN1 with(nolock)
														inner join XXXX..ODLN with(nolock) on ODLN.DocEntry = DLN1.DocEntry
														where ODLN.CANCELED = 'N'
														GROUP BY DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.OcrCode4,DLN1.OcrCode2,DLN1.WhsCode
														) DLN on INV1.ItemCode = DLN.ItemCode and INV1.DocEntry = DLN.BaseEntry and INV1.LineNum = DLN.BaseLine and isnull(INV1.OcrCode4,'') = isnull(DLN.OcrCode4,'') and isnull(INV1.OcrCode2,'') = isnull(DLN.OcrCode2,'') and INV1.WhsCode = DLN.WhsCode
											where OINV.CANCELED = 'N' and OINV.isIns = 'Y'
											Group by INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,DLN.DLQty,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode
											) INVRES on RDR1.ItemCode = INVRES.ItemCode and RDR1.DocEntry = INVRES.BaseEntry and RDR1.LineNum = INVRES.BaseLine and isnull(RDR1.OcrCode4,'') = isnull(INVRES.OcrCode4,'') and isnull(RDR1.OcrCode2,'') = isnull(INVRES.OcrCode2,'') and RDR1.WhsCode = INVRES.WhsCode
								left join XXXX..ORDR with(nolock) on RDR1.DocEntry = ORDR.DocEntry															
								group by RDR1.itemcode,RDR1.OcrCode4,rdr1.LineStatus,RDR1.OcrCode2,rdr1.WhsCode
							) SO on OILM.ItemCode = SO.ItemCode  and Isnull(OILM.OcrCode4,'') = isnull(SO.OcrCode4,'') and isnull(OILM.OcrCode2,'') = isnull(SO.OcrCode2,'') and SO.WhsCode = OILM.LocCode
					----Transfer Request
					left join (select sum(WTQ1.Quantity)'TFRQty',OILM.ItemCode,OILM.OcrCode4,OILM.OcrCode2,WTQ1.WhsCode
								From XXXX..OILM with(nolock)
								left join XXXX..WTQ1 with(nolock) on (OILM.TransType = 1250000001) and (OILM.AccumType = 2) and (OILM.DocEntry = WTQ1.DocEntry) and (OILM.ItemCode = WTQ1.ItemCode) and (OILM.DocLineNum = WTQ1.LineNum) and WTQ1.LineStatus = 'O'	 										
								where OILM.TransType = 1250000001 ----TFR
								group by OILM.ItemCode,OILM.OcrCode4 ,OILM.OcrCode2,WTQ1.WhsCode
								) TFR on OILM.ItemCode = TFR.ItemCode and Isnull(OILM.OcrCode4,'') = isnull(TFR.OcrCode4,'') and isnull(OILM.OcrCode2,'') = isnull(TFR.OcrCode2,'') and TFR.WhsCode = OILM.LocCode				
					group by OILM.ItemCode,isnull(oilm.OcrCode4,''),isnull(SO.SOQty,0),isnull(TFR.TFRQty,0),isnull(SO.DLQty,0),isnull(SO.INQty,0),isnull(SO.INVRESQty,0),isnull(oilm.OcrCode2,''),OILM.LocCode
					) STOCK
where STOCK.itemcode = 'TOY-112130L010'
group by STOCK.ItemCode,STOCK.Supplytype,Sales,LocCode,STOCK.InStock
--) Stock on PCH1.ItemCode = Stock.ItemCode and isnull(pch1.OcrCode4,'') = isnull(Stock.Supplytype,'') and isnull(PCH1.OcrCode2,'') = isnull(Stock.Sales,'') and PCH1.WhsCode = STOCK.WHS
