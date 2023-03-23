-- Stock Movement and Sales Average
--declare {?@DateAt} date
--declare {?@Month}} int
--set {?@DateAt} = '20221101'
--set {?@Month} = '1'

; with Sales as (
select OITW.ItemCode,OITW.WhsCode
,CEILING( ( ( isnull(DL.AVG3,0) + isnull(INVV.AVG3,0) ) - ( isnull(Re.AVG3,0) + isnull(CN.AVG3,0) ) ) /{?@Month} ) 'Sale'
--,isnull(DL.AVG3,0) DL3,isnull(INVV.AVG3,0) INV3,isnull(Re.AVG3,0) RE3,isnull(CN.AVG3,0) CN3
from OITW with(nolock)
----DL
left join (select ItemCode,WhsCode,CONVERT(DECIMAL(18,2),isnull( isnull(sum(Quantity),0) - isnull(sum(INVQ),0) ,0) ) 'AVG3'
			from ( select a.DocEntry,a.ItemCode,a.WhsCode,a.Quantity,sum(inv.Quantity) 'INVQ'	
					from dln1 a with(nolock) 
					join odln b with(nolock) on a.DocEntry = b.DocEntry
					left join (select a.Quantity,a.BaseEntry,a.BaseLine,a.ItemCode,a.WhsCode
								from inv1 a with(nolock) join oinv b with(nolock) on a.DocEntry = b.DocEntry
								where (b.CANCELED = 'N' and b.isIns = 'N') and (b.DocDate BETWEEN DATEADD(m,-{?@Month},{?@DateAt}) and {?@DateAt})
								) inv on a.DocEntry = inv.BaseEntry and a.LineNum = inv.BaseLine and a.ItemCode = inv.ItemCode and a.WhsCode = inv.WhsCode
					where b.CANCELED = 'N' and (b.DocDate BETWEEN DATEADD(m,-{?@Month},{?@DateAt}) and {?@DateAt})
					group by a.DocEntry,a.ItemCode,a.WhsCode,a.Quantity	
					) A1 group by ItemCode,WhsCode
			) DL on DL.ItemCode = OITW.ItemCode and DL.WhsCode = OITW.WhsCode 
----INV
left join (select a.ItemCode,a.WhsCode,CONVERT(DECIMAL(18,2),sum(a.Quantity)) 'AVG3'						
			from INV1 a with(nolock) join OINV b with(nolock) on a.DocEntry = b.DocEntry
			where ( b.CANCELED = 'N' and b.isIns = 'N' ) and (b.DocDate BETWEEN DATEADD(m,-{?@Month},{?@DateAt}) and {?@DateAt})
			group by ItemCode,WhsCode
			) INVV on INVV.ItemCode = OITW.ItemCode and INVV.WhsCode = OITW.WhsCode 
----Return
left join (select a.ItemCode,a.WhsCode,CONVERT(DECIMAL(18,2),sum(a.Quantity)) 'AVG3'					
			from RDN1 a with(nolock) join ORDN b with(nolock) on a.DocEntry = b.DocEntry
			where b.CANCELED = 'N' and (b.DocDate BETWEEN DATEADD(m,-{?@Month},{?@DateAt}) and {?@DateAt})
			group by ItemCode,WhsCode
			) Re on Re.ItemCode = OITW.ItemCode and RE.WhsCode = OITW.WhsCode 
----CN
left join ( select a.ItemCode,a.WhsCode,CONVERT(DECIMAL(18,2),sum(a.Quantity)) 'AVG3'
			from RIN1 a with(nolock) join ORIN b with(nolock) on a.DocEntry = b.DocEntry
			where (b.CANCELED = 'N' and a.NoInvtryMv = 'N') and (b.DocDate BETWEEN DATEADD(m,-{?@Month},{?@DateAt}) and {?@DateAt}) 
			group by ItemCode,WhsCode 	
			) CN on CN.ItemCode = OITW.ItemCode and CN.WhsCode = OITW.WhsCode 
	) --select * from Sales   where ItemCode =  'LCM-TPI-0017' and WhsCode = '00016RYB'
select ITEM.[Item Group]
	,item.ItmsGrpCod
	,ITEM.ItemCode 'Item No.',ITEM.ItemName 'Item Description'
	,oitw.WhsCode 'WH'
	,ITEM.InvntryUom 'Inventory UoM'
	,oitw.OnHand 'Instock'
	,isnull(SO.SOQty,0) 'SO Open'	
	,isnull(TFRfrom.TFRfromQty,0) 'Inventory Transfer'
	,isnull(PO.POQty,0) 'PO Open'	
	,isnull(TFRto.TFRtoQty,0) 'Inventory Transfer Request'
	,isnull(PR.PRQty,0) 'Purchase Requst Open'
	,oitw.OnHand - ( ( isnull(SO.SOQty,0) + isnull(TFRfrom.TFRfromQty,0) ) - ( isnull(PO.POQty,0) + isnull(TFRto.TFRtoQty,0) + isnull(PR.PRQty,0) ) ) 'Available'
	,oitw.MinStock 'Minimum Inventory Level'
	,oitw.MaxStock 'Maximum Level'
	,oitw.MinOrder 'Required Level'
	,isnull(SALES.Sale,0) 'Sales Avr.'
	--,TFR.*
from oitw with(nolock)
join ( select oitm.ItemCode,oitm.ItemName,oitm.InvntryUom,oitb.ItmsGrpNam'Item Group',oitm.ItmsGrpCod
		from oitm with(nolock) 
		left join oitb with(nolock) on oitm.ItmsGrpCod = oitb.ItmsGrpCod 
		where oitm.InvntItem = 'Y' and oitm.ItemType = 'I' 
		) ITEM on item.ItemCode = oitw.ItemCode 
left join SALES with(nolock) on OITW.ItemCode = SALES.ItemCode and SALES.WhsCode = OITW.WhsCode and SALES.Sale > 0
----PR
left join (select ItemCode,WhsCode,isnull(sum(Quantity),0) - isnull(sum(qty),0) 'PRQty'
			from ( select PR.DocEntry,PR.ItemCode,PR.WhsCode,PR.Quantity,isnull(sum(PQ.PQQty),0) + isnull(sum(PO.POQty),0) 'Qty'
					from prq1 PR with(nolock)
					join oprq with(nolock) on pr.DocEntry = oprq.DocEntry
					left join ( select pqt1.DocEntry,pqt1.ItemCode,pqt1.Quantity'PQQty',pqt1.BaseEntry,pqt1.BaseLine
								from pqt1 with(nolock) join opqt with(nolock) on pqt1.DocEntry = opqt.DocEntry
								where opqt.CANCELED = 'N' 
								) PQ on ( PR.DocEntry = PQ.BaseEntry and PR.LineNum = PQ.BaseLine ) and PR.ItemCode = PQ.ItemCode 
					left join (	select por1.DocEntry,por1.ItemCode,por1.Quantity'POQty',por1.BaseEntry,por1.BaseLine
								from por1 with(nolock) join opor with(nolock) on por1.DocEntry = opor.DocEntry
								where opor.CANCELED = 'N' 
								) PO on ( PR.DocEntry = PO.BaseEntry and PR.LineNum = PO.BaseLine ) and PR.ItemCode = PO.ItemCode 
					where ( OPRQ.CANCELED = 'N' and PR.LineStatus = 'O' )
					group by PR.DocEntry,PR.ItemCode,PR.WhsCode,PR.Quantity
				) A group by ItemCode,WhsCode
			) PR on PR.ItemCode = OITW.ItemCode and PR.WhsCode = OITW.WhsCode
--PO
left join (select ItemCode,WhsCode,isnull(sum(Quantity),0) - isnull(sum(qty),0) 'POQty'
			from ( select PO.DocEntry,PO.ItemCode,PO.WhsCode,PO.Quantity,isnull(sum(PDN.GRPOQty),0) + isnull(sum(PCH.INVQty),0) + isnull(sum(INVRes1.Qty),0) 'Qty'--+ isnull(sum(INVRes2.Qty),0) 			
						from por1 PO with(nolock)
						join opor on PO.DocEntry = opor.DocEntry
						---- GRPO < Return
						left join ( select ItemCode,BaseEntry,BaseLine,isnull(sum(Quantity),0) -  isnull(sum(GRPOQty),0)  'GRPOQty' ,BaseType
									from ( select PDN1.DocEntry,PDN1.ItemCode,PDN1.BaseEntry,PDN1.BaseLine,PDN1.Quantity,isnull(sum(Retur.Qty),0) + isnull(sum(PCH.Qty),0) 'GRPOQty' ,PDN1.BaseType
											from PDN1 with(nolock) 
											join OPDN with(nolock) on PDN1.DocEntry = oPDN.DocEntry
											left join ( select ItemCode,BaseEntry,BaseLine,isnull(sum(A.Qty),0)'Qty'
														from ( select a.DocEntry,a.ItemCode,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
																from RPD1 a with(nolock) 
																join ORPD b with(nolock) on a.DocEntry = b.DocEntry
																where b.CANCELED = 'N' 
															) A group by ItemCode,BaseEntry,BaseLine
														) Retur on Retur.BaseEntry = PDN1.DocEntry and Retur.BaseLine = PDN1.LineNum and Retur.ItemCode = PDN1.ItemCode
											left join ( select ItemCode,BaseEntry,BaseLine,isnull(sum(B.Qty),0)'Qty'
														from (select PCH1.DocEntry,PCH1.ItemCode,PCH1.BaseEntry,PCH1.BaseLine,isnull(sum(CN.Qty),0)'Qty'
																from PCH1 with(nolock) 
																join OPCH with(nolock) on PCH1.DocEntry = OPCH.DocEntry
																right join (select a.DocEntry,a.ItemCode,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
																			from RPC1 a with(nolock)
																			join ORPC b with(nolock) on a.DocEntry = b.DocEntry
																			where b.CANCELED = 'N' and a.NoInvtryMv = 'N'
																			) CN on CN.BaseEntry = PCH1.DocEntry and CN.BaseLine = PCH1.LineNum  and PCH1.ItemCode = CN.ItemCode
																where oPCH.CANCELED = 'N'  and OPCH.isIns = 'N'
																group by PCH1.DocEntry,PCH1.ItemCode,PCH1.BaseEntry,PCH1.BaseLine
															) B group by ItemCode,BaseEntry,BaseLine
														) PCH on PCH.BaseEntry = PDN1.DocEntry and PCH.BaseLine = PDN1.LineNum  and PCH.ItemCode = PDN1.ItemCode
											where oPDN.CANCELED = 'N' 
											group by PDN1.DocEntry,PDN1.ItemCode,PDN1.BaseEntry,PDN1.BaseLine,PDN1.Quantity,PDN1.BaseType
											) A group by ItemCode,BaseEntry,BaseLine,BaseType
									) PDN on (PO.DocEntry = PDN.BaseEntry and PO.LineNum = PDN.BaseLine) and PO.ItemCode = PDN.ItemCode and PDN.BaseType = PO.ObjType
						---- INV < CN
						left join ( select ItemCode,BaseEntry,BaseLine,sum(INVQty) 'INVQty',BaseType
									from ( select PCH1.DocEntry,PCH1.ItemCode,pch1.BaseEntry,pch1.BaseLine,PCH1.Quantity - isnull(sum(CN.Qty),0)'INVQty',PCH1.BaseType
											from PCH1 with(nolock) 
											join OPCH with(nolock) on PCH1.DocEntry = OPCH.DocEntry
											left join (select a.DocEntry,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
														from RPC1 a with(nolock) 
														join ORPC b with(nolock) on a.DocEntry = b.DocEntry
														where b.CANCELED = 'N' and a.NoInvtryMv = 'N'
														) CN on CN.BaseEntry = PCH1.DocEntry and CN.BaseLine = PCH1.LineNum 
											where oPCH.CANCELED = 'N'  and OPCH.isIns = 'N' 
											group by PCH1.DocEntry,PCH1.ItemCode,pch1.BaseEntry,pch1.BaseLine,PCH1.Quantity,PCH1.BaseType
											) A group by ItemCode,BaseEntry,BaseLine,BaseType
									) PCH on (PO.DocEntry = PCH.BaseEntry and PO.LineNum = PCH.BaseLine) and PO.ItemCode = PCH.ItemCode and PCH.BaseType = PO.ObjType
						----INV_RES > GRPO
						left join ( select PCH1.DocEntry,PCH1.ItemCode,PCH1.BaseEntry,PCH1.BaseLine,isnull(sum(GRPO.Qty),0)'Qty',PCH1.BaseType
									from PCH1 with(nolock) 
									join OPCH with(nolock) on PCH1.DocEntry = OPCH.DocEntry
									left join ( select PDN1.DocEntry,PDN1.ItemCode,pdn1.BaseEntry,pdn1.BaseLine,PDN1.Quantity'Qty'
												from PDN1 with(nolock) 
												join OPDN with(nolock) on PDN1.DocEntry = oPDN.DocEntry											
												where OPDN.CANCELED = 'N' 
												group by PDN1.DocEntry,PDN1.ItemCode,pdn1.BaseEntry,pdn1.BaseLine,PDN1.Quantity
												) GRPO on GRPO.BaseEntry = PCH1.DocEntry and GRPO.BaseLine = PCH1.LineNum 							
									where OPCH.CANCELED = 'N' and OPCH.isIns = 'Y'
									group by PCH1.DocEntry,PCH1.ItemCode,PCH1.BaseEntry,PCH1.BaseLine,PCH1.Quantity,PCH1.BaseType
									) INVRes1 on (PO.DocEntry = INVRes1.BaseEntry and PO.LineNum = INVRes1.BaseLine) and PO.ItemCode = INVRes1.ItemCode and INVRes1.BaseType = PO.ObjType
						----INV_RES < CN
						left join ( select PCH1.DocEntry,PCH1.ItemCode,PCH1.BaseEntry,PCH1.BaseLine,isnull(sum(CN.Qty),0)'Qty',PCH1.BaseType
									from PCH1 with(nolock) 
									join OPCH with(nolock) on PCH1.DocEntry = OPCH.DocEntry
									left join (select a.DocEntry,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
												from RPC1 a with(nolock) 
												join ORPC b with(nolock) on a.DocEntry = b.DocEntry
												where b.CANCELED = 'N' and a.NoInvtryMv = 'N'
												) CN on CN.BaseEntry = PCH1.DocEntry and CN.BaseLine = PCH1.LineNum 				
									where OPCH.CANCELED = 'N' and OPCH.isIns = 'Y'
									group by PCH1.DocEntry,PCH1.ItemCode,PCH1.BaseEntry,PCH1.BaseLine,PCH1.Quantity,PCH1.BaseType
									) INVRes2 on (PO.DocEntry = INVRes2.BaseEntry and PO.LineNum = INVRes2.BaseLine) and PO.ItemCode = INVRes2.ItemCode and INVRes2.BaseType = PO.ObjType	 		
						where ( OPOR.CANCELED = 'N' and PO.LineStatus = 'O')
						group by PO.DocEntry,PO.ItemCode,PO.WhsCode,PO.Quantity
				) A group by ItemCode,WhsCode
			) PO on PO.ItemCode = OITW.ItemCode and PO.WhsCode = OITW.WhsCode
--SO
left join (select ItemCode,WhsCode,isnull(sum(Quantity),0) - isnull(sum(qty),0) 'SOQty'
			from ( select SO.DocEntry,SO.ItemCode,SO.WhsCode,SO.Quantity,isnull(sum(DLN.GRPOQty),0) + isnull(sum(INV.INVQty),0) + isnull(sum(INVRes1.Qty),0) 'Qty'--+ isnull(sum(INVRes2.Qty),0) 			
						from RDR1 SO with(nolock)
						join ordr on SO.DocEntry = ORDR.DocEntry
						---- DL < Return
						left join ( select ItemCode,BaseEntry,BaseLine,isnull(sum(Quantity),0) -  isnull(sum(GRPOQty),0)  'GRPOQty',BaseType
									from ( select DLN1.DocEntry,DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.Quantity,isnull(sum(Retur.Qty),0) + isnull(sum(INV.Qty),0) 'GRPOQty',DLN1.BaseType
											from DLN1 with(nolock) 
											join ODLN with(nolock) on DLN1.DocEntry = oDLN.DocEntry
											left join ( select ItemCode,BaseEntry,BaseLine,isnull(sum(A.Qty),0)'Qty'
														from ( select a.DocEntry,a.ItemCode,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
																from RDN1 a with(nolock) 
																join ORDN b with(nolock) on a.DocEntry = b.DocEntry
																where b.CANCELED = 'N' 
															) A group by ItemCode,BaseEntry,BaseLine
														) Retur on Retur.BaseEntry = DLN1.DocEntry and Retur.BaseLine = DLN1.LineNum and Retur.ItemCode = DLN1.ItemCode
											left join ( select ItemCode,BaseEntry,BaseLine,isnull(sum(B.Qty),0)'Qty'
														from (select INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,isnull(sum(CN.Qty),0)'Qty'
																from INV1 with(nolock) 
																join OINV with(nolock) on INV1.DocEntry = OINV.DocEntry
																right join (select a.DocEntry,a.ItemCode,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
																			from RIN1 a with(nolock)
																			join ORIN b with(nolock) on a.DocEntry = b.DocEntry
																			where b.CANCELED = 'N' and a.NoInvtryMv = 'N'
																			) CN on CN.BaseEntry = INV1.DocEntry and CN.BaseLine = INV1.LineNum and INV1.ItemCode = CN.ItemCode
																where oINV.CANCELED = 'N'  and OINV.isIns = 'N'
																group by INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine
															) B group by ItemCode,BaseEntry,BaseLine
														) INV on INV.BaseEntry = DLN1.DocEntry and INV.BaseLine = DLN1.LineNum  and INV.ItemCode = DLN1.ItemCode
											where oDLN.CANCELED = 'N' --and DLN1.ItemCode =  'LBM-XXX-0487'
											group by DLN1.DocEntry,DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.Quantity,DLN1.BaseType
											) A group by ItemCode,BaseEntry,BaseLine,BaseType
									) DLN on (SO.DocEntry = DLN.BaseEntry and SO.LineNum = DLN.BaseLine) and SO.ItemCode = DLN.ItemCode and DLN.BaseType = SO.ObjType
						---- INV < CN
						left join ( select ItemCode,BaseEntry,BaseLine,sum(INVQty) 'INVQty',BaseType
									from ( select INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.Quantity - isnull(sum(CN.Qty),0)'INVQty',INV1.BaseType
											from INV1 with(nolock) 
											join OINV with(nolock) on INV1.DocEntry = OINV.DocEntry
											left join (select a.DocEntry,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
														from RIN1 a with(nolock) 
														join ORIN b with(nolock) on a.DocEntry = b.DocEntry
														where b.CANCELED = 'N' and a.NoInvtryMv = 'N'
														) CN on CN.BaseEntry = INV1.DocEntry and CN.BaseLine = INV1.LineNum
											where oINV.CANCELED = 'N'  and OINV.isIns = 'N' --and INV1.ItemCode =  'LBM-XXX-0487'
											group by INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.Quantity,INV1.BaseType
											) A group by ItemCode,BaseEntry,BaseLine,BaseType
									) INV on (SO.DocEntry = INV.BaseEntry and SO.LineNum = INV.BaseLine) and SO.ItemCode = INV.ItemCode and INV.BaseType = SO.ObjType
						----INV_RES > DL
						left join ( select INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,isnull(sum(GRPO.Qty),0)'Qty',INV1.BaseType
									from INV1 with(nolock) 
									join OINV with(nolock) on INV1.DocEntry = OINV.DocEntry
									left join ( select DLN1.DocEntry,DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.Quantity'Qty'
												from DLN1 with(nolock) 
												join ODLN with(nolock) on DLN1.DocEntry = oDLN.DocEntry											
												where ODLN.CANCELED = 'N' 
												group by DLN1.DocEntry,DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.Quantity
												) GRPO on GRPO.BaseEntry = INV1.DocEntry and GRPO.BaseLine = INV1.LineNum 							
									where OINV.CANCELED = 'N' and OINV.isIns = 'Y'
									group by INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.Quantity,INV1.BaseType
									) INVRes1 on (SO.DocEntry = INVRes1.BaseEntry and SO.LineNum = INVRes1.BaseLine) and SO.ItemCode = INVRes1.ItemCode and INVRes1.BaseType = SO.ObjType
						----INV_RES < CN
						left join ( select INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,isnull(sum(CN.Qty),0)'Qty',INV1.BaseType
									from INV1 with(nolock) 
									join OINV with(nolock) on INV1.DocEntry = OINV.DocEntry
									left join (select a.DocEntry,a.BaseEntry,a.BaseLine,a.Quantity'Qty'
												from RIN1 a with(nolock) 
												join ORIN b with(nolock) on a.DocEntry = b.DocEntry
												where b.CANCELED = 'N' and a.NoInvtryMv = 'N'
												) CN on CN.BaseEntry = INV1.DocEntry and CN.BaseLine = INV1.LineNum 							
									where OINV.CANCELED = 'N' and OINV.isIns = 'Y'
									group by INV1.DocEntry,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.Quantity,INV1.BaseType
									) INVRes2 on (SO.DocEntry = INVRes2.BaseEntry and SO.LineNum = INVRes2.BaseLine) and SO.ItemCode = INVRes2.ItemCode and INVRes2.BaseType = SO.ObjType			
						where ( ORDR.CANCELED = 'N' and SO.LineStatus = 'O')
						group by SO.DocEntry,SO.ItemCode,SO.Quantity,SO.WhsCode
				) A group by ItemCode,WhsCode
			) SO on SO.ItemCode = OITW.ItemCode and SO.WhsCode = OITW.WhsCode
----TFR-from
left join (select ItemCode,WhsFrom,isnull(sum(Quantity),0) - isnull(sum(qty),0) 'TFRfromQty'
			from ( select WTQ1.DocEntry,WTQ1.ItemCode,WTQ1.FromWhsCod'WhsFrom',WTQ1.Quantity,isnull(sum(TF.TFQty),0) 'Qty'
						from WTQ1 with(nolock)
						join OWTQ with(nolock) on WTQ1.DocEntry = OWTQ.DocEntry
						left join ( select WTR1.DocEntry,WTR1.ItemCode,WTR1.BaseEntry,WTR1.BaseLine,WTR1.FromWhsCod,WTR1.Quantity'TFQty'
									from WTR1 with(nolock) join OWTR with(nolock) on WTR1.DocEntry = OWTR.DocEntry
									where OWTR.CANCELED = 'N' 
									) TF on (WTQ1.DocEntry = TF.BaseEntry and WTQ1.LineNum = TF.BaseLine) and WTQ1.ItemCode = TF.ItemCode and WTQ1.FromWhsCod = TF.FromWhsCod
						where ( OWTQ.CANCELED = 'N' and WTQ1.LineStatus = 'O') 
						group by WTQ1.DocEntry,WTQ1.ItemCode,WTQ1.FromWhsCod,WTQ1.Quantity
				) A group by ItemCode,WhsFrom
			) TFRfrom on TFRfrom.ItemCode = OITW.ItemCode and TFRfrom.WhsFrom = OITW.WhsCode
----TFR-from
left join (select ItemCode,Whsto,isnull(sum(Quantity),0) - isnull(sum(qty),0) 'TFRtoQty'
			from ( select WTQ1.DocEntry,WTQ1.ItemCode,WTQ1.WhsCode'WhsTo',WTQ1.Quantity,isnull(sum(TF.TFQty),0) 'Qty'
						from WTQ1 with(nolock)
						join OWTQ with(nolock) on WTQ1.DocEntry = OWTQ.DocEntry
						left join ( select WTR1.DocEntry,WTR1.ItemCode,WTR1.BaseEntry,WTR1.BaseLine,WTR1.WhsCode,WTR1.Quantity'TFQty'
									from WTR1 with(nolock) join OWTR with(nolock) on WTR1.DocEntry = OWTR.DocEntry
									where OWTR.CANCELED = 'N' 
									) TF on (WTQ1.DocEntry = TF.BaseEntry and WTQ1.LineNum = TF.BaseLine) and WTQ1.ItemCode = TF.ItemCode and WTQ1.WhsCode = TF.WhsCode
						where ( OWTQ.CANCELED = 'N' and WTQ1.LineStatus = 'O') 
						group by WTQ1.DocEntry,WTQ1.ItemCode,WTQ1.WhsCode,WTQ1.Quantity
				) A group by ItemCode,WhsTo
			) TFRto on TFRto.ItemCode = OITW.ItemCode and TFRto.WhsTo = OITW.WhsCode
--where oitw.ItemCode =  'LCM-TPI-0017' --and oitw.WhsCode = '00016RYF'
