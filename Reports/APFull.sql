-- Full information `AP` module. Including `Stock` available, so use information `Inventory` module (in-out transfer, freezing for count) and  `AR` module for calculated quantity (commited).

-- create view table #1
drop table if exists xxxx..[APFULL_PO]; ----PO
    select 
        sum(por1.Quantity) over(partition by por1.ItemCode,opor.DocEntry)'Quantity'
        ,sum(por1.Quantity) over(partition by por1.ItemCode,opor.DocEntry) 'POQty'
        ,concat(nnm1.BeginStr,opor.docnum)'PDN_BaseRef',concat(nnm1.BeginStr,opor.docnum)'Docnum'
        ,por1.DiscPrcnt,por1.DiscPrcnt'PODiscPrcnt'
        ,por1.PriceBefDi,por1.Price,por1.DocEntry,por1.LineNum,por1.itemcode,OPOR.NumAtCard
    into xxxx..[APFULL_PO]
    from xxxx..opor
    inner join xxxx..por1 on opor.DocEntry = por1.DocEntry
    left join xxxx..nnm1  on opor.Series = nnm1.Series
    where opor.CANCELED = 'N' 
;
drop table if exists xxxx..[APFULL_GRPO]; ----GRPO
    select 
    isnull(PO.PODiscPrcnt,0)'PODiscPrcnt',pdn1.Quantity,isnull(PO.POQty,0)'POQty',
    pdn1.U_remark_temp,pdn1.U_status_temp,pdn1.U_pricelist,pdn1.Dscription,pdn1.basetype,pdn1.Linetotal,
    pdn1.VatSum,pdn1.U_dismaster,pdn1.PriceBefDi,pdn1.price,pdn1.WhsCode,opdn.docdate,opdn.TaxDate,
    opdn.NumAtCard,pdn1.DocEntry,pdn1.LineNum,pdn1.itemcode,pdn1.BaseEntry,pdn1.BaseLine,PDN1.VatPrcnt,
    pdn1.U_rebate1,pdn1.U_rebate2,pdn1.U_rebate3,pdn1.U_rebate1_dis,pdn1.U_rebate2_dis,pdn1.U_rebate3_dis,PO.PDN_BaseRef,
    concat(nnm1.BeginStr,opdn.Docnum)'DocNum',po.DocEntry'PODocentry',isnull(po.PriceBefDi,0)'POPriceBefDi',isnull(po.Price,0)'POPrice'			
    into xxxx..[APFULL_GRPO]
    from xxxx..opdn -- GRPO <--- AP
    inner join xxxx..pdn1 on opdn.DocEntry = pdn1.DocEntry
    left join xxxx..nnm1  on opdn.Series = nnm1.Series
    left join (select * from xxxx..[APFULL_PO]
                ) po on pdn1.BaseEntry = po.DocEntry and pdn1.ItemCode = po.ItemCode and pdn1.BaseLine = po.LineNum 
    where opdn.CANCELED = 'N'
;
drop table if exists xxxx..[APFULL_SALE]; 
    select sale.ItemCode,sale.InvoiceDate,case when isnull(cn.NoInvtryMv,'N') = 'Y' then 0 else sale.Quantity end 'Quantity'
    into xxxx..[APFULL_SALE]
    from xxxx..SalesByInvoice sale
    left join ( select rin1.ItemCode,rin1.NoInvtryMv,rin1.linenum,rin1.WhsCode,concat(isnull(nnm1.BeginStr,''),orin.DocNum) 'CNNo'
                from xxxx..rin1 
                join xxxx..orin on orin.DocEntry = rin1.DocEntry
                left join xxxx..nnm1 on nnm1.Series = orin.Series
                where orin.CANCELED = 'N'
                ) cn on cn.CNNo = sale.InvoiceNum and cn.ItemCode = sale.ItemCode and cn.WhsCode = sale.Warehouse and cn.LineNum = sale.LineNum
    where sale.CANCELED = 'N' and ( InvoiceDate BETWEEN DATEADD(m,-13,getdate()) and getdate() )
;
drop table if exists xxxx..[APFULL_Stock]; ----Stock
select STOCK.ItemCode,STOCK.Supplytype,STOCK.Sales,STOCK.LocCode'Whs'
		--,isnull(STOCK.InStock,0)'InStock'
		,sum(isnull(STOCK.Committ,0))'Commit'
		,isnull(STOCK.InStock,0)'TotalStock'
		--,isnull(STOCK.InStock,0) - sum(isnull(stock.Committ,0)) 'TotalStock'
into xxxx..[APFULL_STOCK]
			from	(select OILM.ItemCode,isnull(oilm.OcrCode4,'')'Supplytype',isnull(oilm.OcrCode2,'')'Sales',OILM.LocCode
					,sum(oivl.InQty) - sum(oivl.OutQty) 'InStock',isnull((isnull(SO.SOQty,0) + isnull(TFR.TFRQty,0) + isnull(SO.INVRESQty,0) ) - (isnull(SO.DLQty,0) + isnull(SO.INQty,0)),0) 'Committ'								
					from xxxx..OILM
					left join xxxx..OIVL ON OIVL.[MessageID] = OILM.[MessageID] and OIVL.ItemCode = OILM.ItemCode
					left join (	select RDR1.ItemCode,RDR1.OcrCode4,RDR1.OcrCode2,RDR1.WhsCode
								,(select sum(isnull(rdr1.Quantity,0)) where rdr1.LineStatus = 'O')		'SOQty'
								,(select sum(isnull(DLN.DLQty,0)) where rdr1.LineStatus = 'O')			'DLQty'
								,(select sum(isnull(INV.INVQty,0)) where rdr1.LineStatus = 'O')			'INQty'
								,(select sum(isnull(INVRES.INVRESQty,0)) where rdr1.LineStatus = 'O')	'INVRESQty'
								from xxxx..rdr1 
								----SO > DL > Return
								left join (select sum(DLN1.Quantity) - isnull(RDN.ReturnQty,0) - isnull(INV.CNQty,0)'DLQty', DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.OcrCode4,DLN1.OcrCode2,DLN1.WhsCode 
											from xxxx..DLN1
											inner join xxxx..ODLN on oDLN.DocEntry = DLN1.DocEntry			
											left join (select sum(RDN1.Quantity)'ReturnQty',RDN1.ItemCode,RDN1.BaseEntry,RDN1.BaseLine,RDN1.OcrCode4,RDN1.OcrCode2,RDN1.WhsCode
														from xxxx..RDN1
														inner join xxxx..ORDN on oRDN.DocEntry = RDN1.DocEntry
														where ORDN.CANCELED = 'N' 
														GROUP BY RDN1.ItemCode,RDN1.BaseEntry,RDN1.BaseLine,RDN1.OcrCode4,RDN1.OcrCode2,RDN1.WhsCode
														) RDN on DLN1.ItemCode = RDN.ItemCode and DLN1.DocEntry = RDN.BaseEntry and DLN1.LineNum = RDN.BaseLine	and isnull(RDN.OcrCode4,'') = isnull(DLN1.OcrCode4,'') and isnull(RDN.OcrCode2,'') = isnull(DLN1.OcrCode2,'') and RDN.WhsCode = DLN1.WhsCode 
											----SO > DL > AR > CN		
											left join (select RIN.CNQty,INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode
														from xxxx..inv1
														inner join xxxx..oinv on oinv.DocEntry = inv1.DocEntry
														right join (select sum(RIN1.Quantity)'CNQty',RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine,RIN1.OcrCode4,ORIN.U_Ref_INV,RIN1.OcrCode2,RIN1.WhsCode
																	from xxxx..rin1
																	inner join xxxx..orin on orin.DocEntry = rin1.DocEntry
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
											from xxxx..inv1
											inner join xxxx..oinv on oinv.DocEntry = inv1.DocEntry
											left join (select sum(RIN1.Quantity)'CNQty',RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine,RIN1.OcrCode4,ORIN.U_Ref_INV,RIN1.OcrCode2,RIN1.WhsCode
														from xxxx..rin1
														inner join xxxx..orin on orin.DocEntry = rin1.DocEntry
														where ORIN.CANCELED = 'N' and RIN1.NoInvtryMv = 'N' and RIN1.BaseType <> 203
														GROUP BY RIN1.ItemCode,RIN1.BaseEntry,RIN1.BaseLine,RIN1.OcrCode4,ORIN.U_Ref_INV,RIN1.OcrCode2,RIN1.WhsCode
														) RIN on INV1.ItemCode = RIN.ItemCode and ((INV1.DocEntry = RIN.BaseEntry) or (OINV.DocNum = RIN.U_Ref_INV)) and INV1.LineNum = RIN.BaseLine and isnull(INV1.OcrCode4,'') = isnull(RIN.OcrCode4,'') and isnull(INV1.OcrCode2,'') = isnull(RIN.OcrCode2,'') and INV1.WhsCode = RIN.WhsCode			
											where OINV.CANCELED = 'N'  and OINV.isIns = 'N' 
											Group by INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,RIN.CNQty,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode  
											) INV on RDR1.ItemCode = INV.ItemCode and RDR1.DocEntry = INV.BaseEntry and RDR1.LineNum = INV.BaseLine and isnull(RDR1.OcrCode4,'') = isnull(INV.OcrCode4,'') and isnull(RDR1.OcrCode2,'') = isnull(INV.OcrCode2,'') and RDR1.WhsCode = INV.WhsCode
								---- SO > AR Res > DL < CN
								left join (select sum(INV1.Quantity) - isnull(DLN.DLQty,0) 'INVRESQty',INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode
											from xxxx..inv1
											left join xxxx..oinv on oinv.DocEntry = inv1.DocEntry
											left join (select sum(DLN1.Quantity)'DLQty',DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.OcrCode4,DLN1.OcrCode2,DLN1.WhsCode
														from xxxx..DLN1
														inner join xxxx..ODLN on ODLN.DocEntry = DLN1.DocEntry
														where ODLN.CANCELED = 'N'
														GROUP BY DLN1.ItemCode,DLN1.BaseEntry,DLN1.BaseLine,DLN1.OcrCode4,DLN1.OcrCode2,DLN1.WhsCode
														) DLN on INV1.ItemCode = DLN.ItemCode and INV1.DocEntry = DLN.BaseEntry and INV1.LineNum = DLN.BaseLine and isnull(INV1.OcrCode4,'') = isnull(DLN.OcrCode4,'') and isnull(INV1.OcrCode2,'') = isnull(DLN.OcrCode2,'') and INV1.WhsCode = DLN.WhsCode
											where OINV.CANCELED = 'N' and OINV.isIns = 'Y'
											Group by INV1.ItemCode,INV1.BaseEntry,INV1.BaseLine,DLN.DLQty,INV1.OcrCode4,INV1.OcrCode2,INV1.WhsCode
											) INVRES on RDR1.ItemCode = INVRES.ItemCode and RDR1.DocEntry = INVRES.BaseEntry and RDR1.LineNum = INVRES.BaseLine and isnull(RDR1.OcrCode4,'') = isnull(INVRES.OcrCode4,'') and isnull(RDR1.OcrCode2,'') = isnull(INVRES.OcrCode2,'') and RDR1.WhsCode = INVRES.WhsCode
								left join xxxx..ORDR on RDR1.DocEntry = ORDR.DocEntry															
								group by RDR1.itemcode,RDR1.OcrCode4,rdr1.LineStatus,RDR1.OcrCode2,rdr1.WhsCode
							) SO on OILM.ItemCode = SO.ItemCode  and Isnull(OILM.OcrCode4,'') = isnull(SO.OcrCode4,'') and isnull(OILM.OcrCode2,'') = isnull(SO.OcrCode2,'') and SO.WhsCode = OILM.LocCode
					----Transfer Request
					left join (select sum(WTQ1.Quantity)'TFRQty',OILM.ItemCode,OILM.OcrCode4,OILM.OcrCode2,WTQ1.WhsCode
								From xxxx..OILM
								left join xxxx..WTQ1 on (OILM.TransType = 1250000001) and (OILM.AccumType = 2) and (OILM.DocEntry = WTQ1.DocEntry) and (OILM.ItemCode = WTQ1.ItemCode) and (OILM.DocLineNum = WTQ1.LineNum) and WTQ1.LineStatus = 'O'	 										
								where OILM.TransType = 1250000001 ----TFR
								group by OILM.ItemCode,OILM.OcrCode4 ,OILM.OcrCode2,WTQ1.WhsCode
								) TFR on OILM.ItemCode = TFR.ItemCode and Isnull(OILM.OcrCode4,'') = isnull(TFR.OcrCode4,'') and isnull(OILM.OcrCode2,'') = isnull(TFR.OcrCode2,'') and TFR.WhsCode = OILM.LocCode				
					group by OILM.ItemCode,isnull(oilm.OcrCode4,''),isnull(SO.SOQty,0),isnull(TFR.TFRQty,0),isnull(SO.DLQty,0),isnull(SO.INQty,0),isnull(SO.INVRESQty,0),isnull(oilm.OcrCode2,''),OILM.LocCode
					) STOCK
			--where STOCK.itemcode = 'ISU-8973587200'
			group by STOCK.ItemCode,STOCK.Supplytype,Sales,LocCode,STOCK.InStock ; 
------*****************************************************************************************************************************************************
------*****************************************************************************************************************************************************
-- put view table #1 for create table #2
-- Union 3 table OINV / ODPO / ORPC
drop table if exists xxxx..[APFULL_APFULL]; 
select * 
into xxxx..[APFULL_APFULL]
from (
select '1AP' as 'GroupType'
    ,CONCAT(NNM1.BeginStr,OPCH.DocNum) N'เลขที่เอกสาร AP Invoice',OPCH.DocDate 'PostingDate AP Invoice',OPCH.TaxDate 'DocumentDate AP Invoice',OPCH.DocDueDate 'DueDate AP Invoice'
    ,pch1.VisOrder+1 N'จำนวนแถวรายการ'
    ,PCH1.LineTotal N'มูลค่าตาม AP Invoice ก่อน VAT',pch5.WTAmnt 'Withholding Tax',PCH1.VatSum 'มูลค่า VAT ตาม AP Invoice',PCH1.LineTotal + PCH1.VatSum 'มูลค่าตาม AP Invoice หลัง VAT'
    ,opch.CardCode N'รหัสผู้จำหน่าย',opch.CardName N'ขื่อผู้จำหน่าย'
    ,isnull(pdn.DocNum,'') N'เลขที่เอกสาร GRPO',pdn.DocDate N'วันที่ทำเอกสาร GRPO'
    ,pdn.TaxDate N'วันที่ใบกำกับภาษี',isnull(opch.NumAtCard,pdn.NumAtCard) N'เลขที่ใบกำกับภาษี'
    ,oocrr2.OcrName 'Sales',oocrr3.OcrName 'Status',oocrr4.OcrName 'SupplyType'
    ,isnull(oitm.U_brand,'') N'ยี่ห้อ',OITB.ItmsGrpNam N'ประเภท',pch1.Itemcode N'หมายเลขอะไหล่',pch1.Dscription N'รายการอะไหล่'
    ,isnull(PDN.PDN_BaseRef,PORR.Docnum) N'เลขที่ใบสั่งซื้อ',pdn.WhsCode N'คลัง GRPO'
    ,iif(isnull(pdn.POQty,0)=0,porr.Quantity,pdn.POQty) N'จำนวนสั่งตามหน้า PO'
    ,pdn.Quantity N'จำนวนรับหน้า GRPO',pch1.Quantity N'จำนวนรับหน้า AP',round( pch1.Quantity - pdn.Quantity ,2) N'ผลต่างจำนวนรับระหว่าง AP กับ GRPO'
    ,sum(pch1.Quantity) over(partition by pch1.itemcode,isnull(PDN.PDN_BaseRef,PORR.Docnum) ) N'จำนวนรับทุก AP ของ PO ใบนี้ (ผลรวมจำนวน AP ที่เคยรับ)'
    ,sum(pch1.Quantity) over(partition by pch1.itemcode,isnull(PDN.PDN_BaseRef,PORR.Docnum) ) - iif(isnull(pdn.POQty,0)=0,isnull(porr.Quantity,0),pdn.POQty) N'ผลต่างจำนวนทุก AP กับจำนวน PO'
    --,isnull(sum(pdn.Quantity) over(partition by isnull(pdn.PODocentry,pdn.BaseEntry),pch1.itemcode order by pdn.docentry,opch.docentry,pch1.Linenum),0) ----sum by line
    ,isnull(pdn.U_remark_temp,pch1.U_remark_temp) N'หมายเหตุผู้อนุมัติ',isnull(pdn.U_status_temp,pch1.U_status_temp) N'Field รอ CN หน้า GRPO',CONCAT(nnmrpc.BeginStr,orpc.docnum) N'เลขที่ CN ในระบบ SAPB1'
    ,iif(pch1.U_pricelist=0,pdn.U_pricelist,pch1.U_pricelist) N'ราคาตั้งของราคาที่ได้รับจริง ณ ช่วงเวลานั้น'
    ,pch1.PriceBefDi N'ราคาตั้งใน AP (UnitPrice)'
    ,pdn.PriceBefDi N'ราคาในระบบ GRPO',pdn.POPrice N'ราคาที่สั่ง PO'
    ,pdn.Price N'ราคาที่ได้รับจริง GRPO',pch1.Price N'ราคาที่ได้รับจริง AP',round( pdn.Price - pch1.Price ,2) N'ผลต่างราคาที่ได้รับจริง (GRPO-AP)'
    ,format(((pch1.U_pricelist - pch1.Price) / nullif(pch1.U_pricelist,0)*100) *0.01,'P') N'ส่วนลดคิดเป็น(%)'
    ,format(iif(pch1.U_dismaster=0,pdn.U_dismaster,pch1.U_dismaster)*0.01,'P') N'UD ส่วนลดที่ถูกต้อง master(%)'
    ,format(iif(pdn.PODiscPrcnt=0,porr.DiscPrcnt,pdn.PODiscPrcnt)*0.01,'P') N'ส่วนลดตาม PO(%)'
    ,format((((pch1.U_pricelist - pch1.Price) / nullif(pch1.U_pricelist,0)*100) - pch1.U_dismaster ) *0.01,'P') N'ผลต่างจากส่วนลดที่ถูกต้อง/หน่วย(%)'
    ,round( pch1.PriceBefDi*pch1.Quantity ,2) N'มูลค่าที่สั่งซื้อก่อนลด (ก่อน VAT) ราคาตั้ง ณ เวลานั้น*จำนวน'	--ก่อนลด/ก่อนVat
    ,round( pch1.GPBefDisc*pch1.Quantity ,2)  N'มูลค่าที่สั่งซื้อก่อนลด (รวม VAT)'						--ก่อนลด/รวมVat
    ,pch1.LineTotal N'มูลค่าที่สั่งซื้อหลังลด (ก่อน VAT) ราคาตั้ง ณ เวลานั้น*จำนวน'					--หลังลด/ก่อนVat
    ,pch1.GTotal N'มูลค่าที่สั่งซื้อหลังลด (รวม VAT)'											--หลังลด/รวมVat
    ,format(pch1.U_rebate1		* 0.01,'P')	N'(%)ส่วนลดเงินสด Rebate 1'
    ,format(pch1.U_rebate2		* 0.01,'P')	N'(%)ส่วนลดเงินสด Rebate 2'
    ,format(pch1.U_rebate1_dis	* 0.01,'P')	N'(%)Rebate 1 หลังหัก'
    ,format(pch1.U_rebate2_dis	* 0.01,'P')	N'(%)Rebate 2 หลังหัก'
    ,round( (pch1.U_rebate1*0.01)		* (pch1.PriceBefDi*pch1.Quantity) ,2) N'มูลค่าส่วนลดก่อน VAT (Rebate 1)'		--'TotalRebate1_BeforDis_BeforVAT'
    ,round( (pch1.U_rebate1*0.01)		* (pch1.GPBefDisc*pch1.Quantity)  ,2) N'มูลค่าส่วนลดรวม VAT (Rebate 1)'		--'TotalRebate1_BeforDis_AfterVAT'
    ,round( (pch1.U_rebate2*0.01)		* (pch1.PriceBefDi*pch1.Quantity) ,2) N'มูลค่าส่วนลดก่อน VAT (Rebate 2)'		--'TotalRebate2_BeforDis_BeforVAT'
    ,round( (pch1.U_rebate2*0.01)		* (pch1.GPBefDisc*pch1.Quantity)  ,2) N'มูลค่าส่วนลดรวม VAT (Rebate 2)'		--'Totalrebate2_BeforDis_AfterVAT'
    ,round( (pch1.U_rebate1_dis*0.01)	* pch1.LineTotal				  ,2) N'มูลค่าส่วนลดหลังหักก่อน VAT (Rebate 1)'--'TotalRebate1_AfterDis_BeforVAT' 
    ,round( (pch1.U_rebate1_dis*0.01)	* pch1.GTotal					  ,2) N'มูลค่าส่วนลดหลังหักรวม VAT (Rebate 1)'--'TotalRebate1_AfterDis_AfterVAT' 
    ,round( (pch1.U_rebate2_dis*0.01)	* pch1.LineTotal				  ,2) N'มูลค่าส่วนลดหลังหักก่อน VAT (Rebate 2)'--'TotalRebate2_AfterDis_BeforVAT' 
    ,round( (pch1.U_rebate2_dis*0.01)	* pch1.GTotal					  ,2) N'มูลค่าส่วนลดหลังหักรวม VAT (Rebate 2)'--'TotalRebate2_AfterDis_AfterVAT' 			
    ,pdn.Linetotal N'มูลค่าสินค้า GRPO',pdn.VatSum N'ภาษี GRPO' ,round( pdn.LineTotal+pdn.VatSum ,2) N'รวมทั้งสิ้น GRPO'
    ,STOCK.TotalStock 'Total Stock'
    ,CASE WHEN STOCK.Supplytype = 'STCK'  THEN STOCK.TotalStock END 'STOCK'	
    ,CASE WHEN STOCK.Supplytype = 'EMER'  THEN STOCK.TotalStock END 'EO'
    ,CASE WHEN STOCK.Supplytype = 'EPOW'  THEN STOCK.TotalStock END 'POW' 
    ,CASE WHEN STOCK.Supplytype = 'SOEM'  THEN STOCK.TotalStock END 'OEM' 
    ,CASE WHEN STOCK.Supplytype = 'IMPT'  THEN STOCK.TotalStock END 'IMPORT'
    ,CASE WHEN STOCK.Supplytype = 'DIRECT'THEN STOCK.TotalStock END 'DIRECT'
    ,round( (isnull(Sale.AVG6,0) + isnull(Sale.AVG3,0)) / 2 ,2) 'sAVG'
    ,round( isnull(Sale.AVG12,0) ,2) 'AVG12'
    ,round( isnull(Sale.AVG6,0) ,2) 'AVG6'
    ,round( isnull(Sale.AVG3,0) ,2) 'AVG3'
    ,round( isnull(STOCK.TotalStock,0) / NULLIF((( round(isnull(Sale.AVG6,0) ,1) + round(isnull(Sale.AVG3,0) ,1) ) / 2),0) ,2) N'M.SALES ทั้งหมด'
    ,round( isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) / NULLIF(((round(isnull(Sale.AVG6,0) ,1) + round(isnull(Sale.AVG3,0) ,1)) / 2),0) ,2) N'M.Sales เฉพาะ IC'
    ,round( isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) ,2) N'Stock ที่เป็น Sales IC เท่านั้น'
    ,round( isnull(STOCK.TotalStock,0) - isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) ,2) N'Stock จอง + EO(Stock Total - IC)'
from xxxx..opch
inner join xxxx..pch1 on opch.DocEntry = pch1.DocEntry
left join  xxxx..pch5 on pch1.DocEntry = pch5.AbsEntry
left join (select * from xxxx..[APFULL_GRPO]
			) PDN on pch1.BaseType = '20' and pch1.BaseEntry = pdn.DocEntry and pch1.ItemCode = pdn.ItemCode and pch1.BaseLine = PDN.LineNum 
left join (select * from xxxx..[APFULL_PO]
			) PORR on pch1.BaseType = '22' and pch1.BaseEntry = porr.DocEntry and pch1.ItemCode = porr.ItemCode and pch1.BaseLine = porr.LineNum 
left join xxxx..ORPC on (OPCH.NumAtCard = ORPC.U_Ref_INV) and ORPC.CANCELED = 'N'
left join xxxx..NNM1 nnmrpc on nnmrpc.Series = orpc.Series
left join xxxx..nnm1 on opch.Series = nnm1.Series
left join xxxx..oocr oocrr4 on pch1.OcrCode4 = oocrr4.OcrCode and oocrr4.DimCode = '4'
left join xxxx..oocr oocrr3 on pch1.OcrCode3 = oocrr3.OcrCode and oocrr3.DimCode = '3'
left join xxxx..oocr oocrr2 on pch1.OcrCode2 = oocrr2.OcrCode and oocrr2.DimCode = '2'
left join xxxx..ocrd on opch.CardCode = ocrd.cardcode
left join xxxx..oitm on pch1.itemcode = oitm.ItemCode
left join xxxx..oitb on oitm.ItmsGrpCod = oitb.ItmsGrpCod
left join xxxx..[@BRANDS] on OITM.U_brand = [@BRANDS].Code
--Stock (Instock - committed)
left join ( select * from xxxx..[APFULL_Stock]
			) Stock on PCH1.ItemCode = Stock.ItemCode and isnull(pch1.OcrCode4,'') = isnull(Stock.Supplytype,'') and isnull(PCH1.OcrCode2,'') = isnull(Stock.Sales,'') and PCH1.WhsCode = STOCK.WHS
--sale
left join (select itemcode
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG3,0))) / 3 'AVG3'
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG6,0))) / 6 'AVG6'
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG12,0))) / 12 'AVG12'
			from (select itemcode
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-3,getdate()) and  getdate()) 'AVG3'
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-6,getdate()) and  getdate()) 'AVG6'
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-12,getdate()) and getdate()) 'AVG12'
			from xxxx..[APFULL_SALE]			
			group by itemcode,InvoiceDate 			
			) A	group by itemcode
			) Sale  on OITM.ItemCode = Sale.ItemCode
where ( OPCH.cardcode <> 'AP00015' )  and opch.CANCELED = 'N' 
------*****************************************************************************************************************************************************
----ODPO
Union all
select '2DP' as 'GroupType'
    ,CONCAT(NNM1.BeginStr,ODPO.DocNum) N'เลขที่เอกสาร AP Invoice',ODPO.DocDate 'PostingDate AP Invoice',ODPO.TaxDate 'DocumentDate AP Invoice',ODPO.DocDueDate 'DueDate AP Invoice'
    ,DPO1.VisOrder+1 N'จำนวนแถวรายการ'
    ,DPO1.LineTotal N'มูลค่าตาม AP Invoice ก่อน VAT',DPO5.WTAmnt 'Withholding Tax',DPO1.VatSum 'มูลค่า VAT ตาม AP Invoice',DPO1.LineTotal + DPO1.VatSum 'มูลค่าตาม AP Invoice หลัง VAT'
    ,oDPO.CardCode N'รหัสผู้จำหน่าย',oDPO.CardName N'ขื่อผู้จำหน่าย'
    ,isnull(pdn.DocNum,'') N'เลขที่เอกสาร GRPO',pdn.DocDate N'วันที่ทำเอกสาร GRPO'
    ,pdn.TaxDate N'วันที่ใบกำกับภาษี',isnull(oDPO.NumAtCard,pdn.NumAtCard) N'เลขที่ใบกำกับภาษี'
    ,oocrr2.OcrName 'Sales',oocrr3.OcrName 'Status',oocrr4.OcrName 'SupplyType'
    ,isnull(oitm.U_brand,'') N'ยี่ห้อ',OITB.ItmsGrpNam N'ประเภท',DPO1.Itemcode N'หมายเลขอะไหล่',DPO1.Dscription N'รายการอะไหล่'
    ,isnull(PDN.PDN_BaseRef,PORR.Docnum) N'เลขที่ใบสั่งซื้อ',pdn.WhsCode N'คลัง GRPO'
    ,iif(isnull(pdn.POQty,0)=0,porr.Quantity,pdn.POQty) N'จำนวนสั่งตามหน้า PO'
    ,pdn.Quantity N'จำนวนรับหน้า GRPO',DPO1.Quantity N'จำนวนรับหน้า AP',round( DPO1.Quantity - pdn.Quantity ,2) N'ผลต่างจำนวนรับระหว่าง AP กับ GRPO'
    ,sum(DPO1.Quantity) over(partition by DPO1.itemcode,isnull(PDN.PDN_BaseRef,PORR.Docnum) ) N'จำนวนรับทุก AP ของ PO ใบนี้ (ผลรวมจำนวน AP ที่เคยรับ)'
    ,sum(DPO1.Quantity) over(partition by DPO1.itemcode,isnull(PDN.PDN_BaseRef,PORR.Docnum) ) - iif(isnull(pdn.POQty,0)=0,isnull(porr.Quantity,0),pdn.POQty) N'ผลต่างจำนวนทุก AP กับจำนวน PO'
    --,isnull(sum(pdn.Quantity) over(partition by isnull(pdn.PODocentry,pdn.BaseEntry),DPO1.itemcode order by pdn.docentry,oDPO.docentry,DPO1.Linenum),0) ----sum by line
    ,isnull(pdn.U_remark_temp,DPO1.U_remark_temp) N'หมายเหตุผู้อนุมัติ',isnull(pdn.U_status_temp,DPO1.U_status_temp) N'Field รอ CN หน้า GRPO',CONCAT(nnmrpc.BeginStr,orpc.docnum) N'เลขที่ CN ในระบบ SAPB1'
    ,iif(DPO1.U_pricelist=0,pdn.U_pricelist,DPO1.U_pricelist) N'ราคาตั้งของราคาที่ได้รับจริง ณ ช่วงเวลานั้น'
    ,DPO1.PriceBefDi N'ราคาตั้งใน AP (UnitPrice)'
    ,pdn.PriceBefDi N'ราคาในระบบ GRPO',pdn.POPrice N'ราคาที่สั่ง PO'
    ,pdn.Price N'ราคาที่ได้รับจริง GRPO',DPO1.Price N'ราคาที่ได้รับจริง AP',round( pdn.Price - DPO1.Price ,2) N'ผลต่างราคาที่ได้รับจริง (GRPO-AP)'
    ,format(((DPO1.U_pricelist - DPO1.Price) / nullif(DPO1.U_pricelist,0)*100) *0.01,'P') N'ส่วนลดคิดเป็น(%)'
    ,format(iif(DPO1.U_dismaster=0,pdn.U_dismaster,DPO1.U_dismaster)*0.01,'P') N'UD ส่วนลดที่ถูกต้อง master(%)'
    ,format(iif(pdn.PODiscPrcnt=0,porr.DiscPrcnt,pdn.PODiscPrcnt)*0.01,'P') N'ส่วนลดตาม PO(%)'
    ,format((((DPO1.U_pricelist - DPO1.Price) / nullif(DPO1.U_pricelist,0)*100) - DPO1.U_dismaster ) *0.01,'P') N'ผลต่างจากส่วนลดที่ถูกต้อง/หน่วย(%)'
    ,round( DPO1.PriceBefDi*DPO1.Quantity ,2) N'มูลค่าที่สั่งซื้อก่อนลด (ก่อน VAT) ราคาตั้ง ณ เวลานั้น*จำนวน'	--ก่อนลด/ก่อนVat
    ,round( DPO1.GPBefDisc*DPO1.Quantity ,2)  N'มูลค่าที่สั่งซื้อก่อนลด (รวม VAT)'						--ก่อนลด/รวมVat
    ,DPO1.LineTotal N'มูลค่าที่สั่งซื้อหลังลด (ก่อน VAT) ราคาตั้ง ณ เวลานั้น*จำนวน'					--หลังลด/ก่อนVat
    ,DPO1.GTotal N'มูลค่าที่สั่งซื้อหลังลด (รวม VAT)'											--หลังลด/รวมVat
    ,format(DPO1.U_rebate1		* 0.01,'P')	N'(%)ส่วนลดเงินสด Rebate 1'
    ,format(DPO1.U_rebate2		* 0.01,'P')	N'(%)ส่วนลดเงินสด Rebate 2'
    ,format(DPO1.U_rebate1_dis	* 0.01,'P')	N'(%)Rebate 1 หลังหัก'
    ,format(DPO1.U_rebate2_dis	* 0.01,'P')	N'(%)Rebate 2 หลังหัก'
    ,round( (DPO1.U_rebate1*0.01)		* (DPO1.PriceBefDi*DPO1.Quantity) ,2) N'มูลค่าส่วนลดก่อน VAT (Rebate 1)'		--'TotalRebate1_BeforDis_BeforVAT'
    ,round( (DPO1.U_rebate1*0.01)		* (DPO1.GPBefDisc*DPO1.Quantity)  ,2) N'มูลค่าส่วนลดรวม VAT (Rebate 1)'		--'TotalRebate1_BeforDis_AfterVAT'
    ,round( (DPO1.U_rebate2*0.01)		* (DPO1.PriceBefDi*DPO1.Quantity) ,2) N'มูลค่าส่วนลดก่อน VAT (Rebate 2)'		--'TotalRebate2_BeforDis_BeforVAT'
    ,round( (DPO1.U_rebate2*0.01)		* (DPO1.GPBefDisc*DPO1.Quantity)  ,2) N'มูลค่าส่วนลดรวม VAT (Rebate 2)'		--'Totalrebate2_BeforDis_AfterVAT'
    ,round( (DPO1.U_rebate1_dis*0.01)	* DPO1.LineTotal				  ,2) N'มูลค่าส่วนลดหลังหักก่อน VAT (Rebate 1)'--'TotalRebate1_AfterDis_BeforVAT' 
    ,round( (DPO1.U_rebate1_dis*0.01)	* DPO1.GTotal					  ,2) N'มูลค่าส่วนลดหลังหักรวม VAT (Rebate 1)'--'TotalRebate1_AfterDis_AfterVAT' 
    ,round( (DPO1.U_rebate2_dis*0.01)	* DPO1.LineTotal				  ,2) N'มูลค่าส่วนลดหลังหักก่อน VAT (Rebate 2)'--'TotalRebate2_AfterDis_BeforVAT' 
    ,round( (DPO1.U_rebate2_dis*0.01)	* DPO1.GTotal					  ,2) N'มูลค่าส่วนลดหลังหักรวม VAT (Rebate 2)'--'TotalRebate2_AfterDis_AfterVAT' 			
    ,pdn.Linetotal N'มูลค่าสินค้า GRPO',pdn.VatSum N'ภาษี GRPO' ,round( pdn.LineTotal+pdn.VatSum ,2) N'รวมทั้งสิ้น GRPO'
    ,STOCK.TotalStock 'Total Stock'
    ,CASE WHEN STOCK.Supplytype = 'STCK'  THEN STOCK.TotalStock END 'STOCK'	
    ,CASE WHEN STOCK.Supplytype = 'EMER'  THEN STOCK.TotalStock END 'EO'
    ,CASE WHEN STOCK.Supplytype = 'EPOW'  THEN STOCK.TotalStock END 'POW' 
    ,CASE WHEN STOCK.Supplytype = 'SOEM'  THEN STOCK.TotalStock END 'OEM' 
    ,CASE WHEN STOCK.Supplytype = 'IMPT'  THEN STOCK.TotalStock END 'IMPORT'
    ,CASE WHEN STOCK.Supplytype = 'DIRECT'THEN STOCK.TotalStock END 'DIRECT'
    ,round( (isnull(Sale.AVG6,0) + isnull(Sale.AVG3,0)) / 2 ,2) 'sAVG'
    ,round( isnull(Sale.AVG12,0) ,2) 'AVG12'
    ,round( isnull(Sale.AVG6,0) ,2) 'AVG6'
    ,round( isnull(Sale.AVG3,0) ,2) 'AVG3'
    ,round( isnull(STOCK.TotalStock,0) / NULLIF((( round(isnull(Sale.AVG6,0) ,1) + round(isnull(Sale.AVG3,0) ,1) ) / 2),0) ,2) N'M.SALES ทั้งหมด'
    ,round( isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) / NULLIF(((round(isnull(Sale.AVG6,0) ,1) + round(isnull(Sale.AVG3,0) ,1)) / 2),0) ,2) N'M.Sales เฉพาะ IC'
    ,round( isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) ,2) N'Stock ที่เป็น Sales IC เท่านั้น'
    ,round( isnull(STOCK.TotalStock,0) - isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) ,2) N'Stock จอง + EO(Stock Total - IC)'
from xxxx..oDPO
inner join xxxx..DPO1 on oDPO.DocEntry = DPO1.DocEntry
left join  xxxx..DPO5 on DPO1.DocEntry = DPO5.AbsEntry
left join (select * from xxxx..[APFULL_GRPO]
			) PDN on DPO1.BaseType = '20' and DPO1.BaseEntry = pdn.DocEntry and DPO1.ItemCode = pdn.ItemCode and DPO1.BaseLine = PDN.LineNum 
left join (select * from xxxx..[APFULL_PO]
			) PORR on DPO1.BaseType = '22' and DPO1.BaseEntry = porr.DocEntry and DPO1.ItemCode = porr.ItemCode and DPO1.BaseLine = porr.LineNum 
left join xxxx..ORPC on (ODPO.NumAtCard = ORPC.U_Ref_INV) and ORPC.CANCELED = 'N'
left join xxxx..NNM1 nnmrpc on nnmrpc.Series = orpc.Series
left join xxxx..nnm1 on oDPO.Series = nnm1.Series
left join xxxx..oocr oocrr4 on DPO1.OcrCode4 = oocrr4.OcrCode and oocrr4.DimCode = '4'
left join xxxx..oocr oocrr3 on DPO1.OcrCode3 = oocrr3.OcrCode and oocrr3.DimCode = '3'
left join xxxx..oocr oocrr2 on DPO1.OcrCode2 = oocrr2.OcrCode and oocrr2.DimCode = '2'
left join xxxx..ocrd on oDPO.CardCode = ocrd.cardcode
left join xxxx..oitm on DPO1.itemcode = oitm.ItemCode
left join xxxx..oitb on oitm.ItmsGrpCod = oitb.ItmsGrpCod
left join xxxx..[@BRANDS] on OITM.U_brand = [@BRANDS].Code
--Stock (Instock - committed)
left join ( select * from xxxx..[APFULL_Stock]
			) Stock on DPO1.ItemCode = Stock.ItemCode and isnull(DPO1.OcrCode4,'') = isnull(Stock.Supplytype,'') and isnull(DPO1.OcrCode2,'') = isnull(Stock.Sales,'') and DPO1.WhsCode = STOCK.WHS
--sale
left join (select itemcode
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG3,0))) / 3 'AVG3'
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG6,0))) / 6 'AVG6'
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG12,0))) / 12 'AVG12'
			from (select itemcode
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-3,getdate()) and  getdate()) 'AVG3'
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-6,getdate()) and  getdate()) 'AVG6'
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-12,getdate()) and getdate()) 'AVG12'
			from xxxx..[APFULL_SALE]			
			group by itemcode,InvoiceDate 			
			) A	group by itemcode
			) Sale  on OITM.ItemCode = Sale.ItemCode
where ( ODPO.cardcode <> 'AP00015' ) and ODPO.CANCELED = 'N' 
------*****************************************************************************************************************************************************
----ORPC
Union all
select '3CN' as 'GroupType'
    ,CONCAT(NNM1.BeginStr,ORPC.DocNum) N'เลขที่เอกสาร AP Invoice',ORPC.DocDate 'PostingDate AP Invoice',ORPC.TaxDate 'DocumentDate AP Invoice',ORPC.DocDueDate 'DueDate AP Invoice'
    ,RPC1.VisOrder+1 N'จำนวนแถวรายการ'
    ,-RPC1.LineTotal N'มูลค่าตาม AP Invoice ก่อน VAT',-RPC5.WTAmnt 'Withholding Tax',-RPC1.VatSum 'มูลค่า VAT ตาม AP Invoice',-(RPC1.LineTotal + RPC1.VatSum) 'มูลค่าตาม AP Invoice หลัง VAT'
    ,oRPC.CardCode N'รหัสผู้จำหน่าย',oRPC.CardName N'ขื่อผู้จำหน่าย'
    ,isnull(pdn.DocNum,'') N'เลขที่เอกสาร GRPO',pdn.DocDate N'วันที่ทำเอกสาร GRPO'
    ,pdn.TaxDate N'วันที่ใบกำกับภาษี',isnull(oRPC.NumAtCard,pdn.NumAtCard) N'เลขที่ใบกำกับภาษี'
    ,oocrr2.OcrName 'Sales',oocrr3.OcrName 'Status',oocrr4.OcrName 'SupplyType'
    ,isnull(oitm.U_brand,'') N'ยี่ห้อ',OITB.ItmsGrpNam N'ประเภท',RPC1.Itemcode N'หมายเลขอะไหล่',RPC1.Dscription N'รายการอะไหล่'
    ,NULL as N'เลขที่ใบสั่งซื้อ',pdn.WhsCode N'คลัง GRPO'
    ,NULL as N'จำนวนสั่งตามหน้า PO'
    ,NULL as N'จำนวนรับหน้า GRPO'
    ,-RPC1.Quantity N'จำนวนรับหน้า AP' 
    ,NULL as N'ผลต่างจำนวนรับระหว่าง AP กับ GRPO'
    ,NULL as N'จำนวนรับทุก AP ของ PO ใบนี้ (ผลรวมจำนวน AP ที่เคยรับ)'
    ,NULL as N'ผลต่างจำนวนทุก AP กับจำนวน PO'
    ,isnull(pdn.U_remark_temp,RPC1.U_remark_temp) N'หมายเหตุผู้อนุมัติ',isnull(pdn.U_status_temp,RPC1.U_status_temp) N'Field รอ CN หน้า GRPO',NULL as N'เลขที่ CN ในระบบ SAPB1'
    ,NULL as  N'ราคาตั้งของราคาที่ได้รับจริง ณ ช่วงเวลานั้น'
    ,-RPC1.PriceBefDi N'ราคาตั้งใน AP (UnitPrice)'
    ,NULL as  N'ราคาในระบบ GRPO'
    ,NULL as  N'ราคาที่สั่ง PO'
    ,NULL as  N'ราคาที่ได้รับจริง GRPO'
    ,-RPC1.Price N'ราคาที่ได้รับจริง AP'
    ,NULL as N'ผลต่างราคาที่ได้รับจริง (GRPO-AP)'
    ,format(((RPC1.U_pricelist - RPC1.Price) / nullif(RPC1.U_pricelist,0)*100) *0.01,'P') N'ส่วนลดคิดเป็น(%)'
    ,format(iif(RPC1.U_dismaster=0,pdn.U_dismaster,RPC1.U_dismaster)*0.01,'P') N'UD ส่วนลดที่ถูกต้อง master(%)'
    ,format(iif(pdn.PODiscPrcnt=0,porr.DiscPrcnt,pdn.PODiscPrcnt)*0.01,'P') N'ส่วนลดตาม PO(%)'
    ,format((((RPC1.U_pricelist - RPC1.Price) / nullif(RPC1.U_pricelist,0)*100) - RPC1.U_dismaster ) *0.01,'P') N'ผลต่างจากส่วนลดที่ถูกต้อง/หน่วย(%)'
    ,-round( RPC1.PriceBefDi*RPC1.Quantity ,2) N'มูลค่าที่สั่งซื้อก่อนลด (ก่อน VAT) ราคาตั้ง ณ เวลานั้น*จำนวน'	--ก่อนลด/ก่อนVat
    ,-round( RPC1.GPBefDisc*RPC1.Quantity ,2)  N'มูลค่าที่สั่งซื้อก่อนลด (รวม VAT)'						--ก่อนลด/รวมVat
    ,-RPC1.LineTotal N'มูลค่าที่สั่งซื้อหลังลด (ก่อน VAT) ราคาตั้ง ณ เวลานั้น*จำนวน'					--หลังลด/ก่อนVat
    ,-RPC1.GTotal N'มูลค่าที่สั่งซื้อหลังลด (รวม VAT)'											--หลังลด/รวมVat
    ,format(RPC1.U_rebate1		* 0.01,'P')	N'(%)ส่วนลดเงินสด Rebate 1'
    ,format(RPC1.U_rebate2		* 0.01,'P')	N'(%)ส่วนลดเงินสด Rebate 2'
    ,format(RPC1.U_rebate1_dis	* 0.01,'P')	N'(%)Rebate 1 หลังหัก'
    ,format(RPC1.U_rebate2_dis	* 0.01,'P')	N'(%)Rebate 2 หลังหัก'
    ,-round( (RPC1.U_rebate1*0.01)		* (RPC1.PriceBefDi*RPC1.Quantity) ,2) N'มูลค่าส่วนลดก่อน VAT (Rebate 1)'		--'TotalRebate1_BeforDis_BeforVAT'
    ,-round( (RPC1.U_rebate1*0.01)		* (RPC1.GPBefDisc*RPC1.Quantity)  ,2) N'มูลค่าส่วนลดรวม VAT (Rebate 1)'		--'TotalRebate1_BeforDis_AfterVAT'
    ,-round( (RPC1.U_rebate2*0.01)		* (RPC1.PriceBefDi*RPC1.Quantity) ,2) N'มูลค่าส่วนลดก่อน VAT (Rebate 2)'		--'TotalRebate2_BeforDis_BeforVAT'
    ,-round( (RPC1.U_rebate2*0.01)		* (RPC1.GPBefDisc*RPC1.Quantity)  ,2) N'มูลค่าส่วนลดรวม VAT (Rebate 2)'		--'Totalrebate2_BeforDis_AfterVAT'
    ,-round( (RPC1.U_rebate1_dis*0.01)	* RPC1.LineTotal				  ,2) N'มูลค่าส่วนลดหลังหักก่อน VAT (Rebate 1)'--'TotalRebate1_AfterDis_BeforVAT' 
    ,-round( (RPC1.U_rebate1_dis*0.01)	* RPC1.GTotal					  ,2) N'มูลค่าส่วนลดหลังหักรวม VAT (Rebate 1)'--'TotalRebate1_AfterDis_AfterVAT' 
    ,-round( (RPC1.U_rebate2_dis*0.01)	* RPC1.LineTotal				  ,2) N'มูลค่าส่วนลดหลังหักก่อน VAT (Rebate 2)'--'TotalRebate2_AfterDis_BeforVAT' 
    ,-round( (RPC1.U_rebate2_dis*0.01)	* RPC1.GTotal					  ,2) N'มูลค่าส่วนลดหลังหักรวม VAT (Rebate 2)'--'TotalRebate2_AfterDis_AfterVAT' 			
    ,NULL as  N'มูลค่าสินค้า GRPO',NULL as  N'ภาษี GRPO' ,NULL as  N'รวมทั้งสิ้น GRPO'
    ,STOCK.TotalStock 'Total Stock'
    ,CASE WHEN STOCK.Supplytype = 'STCK'  THEN STOCK.TotalStock END 'STOCK'	
    ,CASE WHEN STOCK.Supplytype = 'EMER'  THEN STOCK.TotalStock END 'EO'
    ,CASE WHEN STOCK.Supplytype = 'EPOW'  THEN STOCK.TotalStock END 'POW' 
    ,CASE WHEN STOCK.Supplytype = 'SOEM'  THEN STOCK.TotalStock END 'OEM' 
    ,CASE WHEN STOCK.Supplytype = 'IMPT'  THEN STOCK.TotalStock END 'IMPORT'
    ,CASE WHEN STOCK.Supplytype = 'DIRECT'THEN STOCK.TotalStock END 'DIRECT'
    ,round( (isnull(Sale.AVG6,0) + isnull(Sale.AVG3,0)) / 2 ,2) 'sAVG'
    ,round( isnull(Sale.AVG12,0) ,2) 'AVG12'
    ,round( isnull(Sale.AVG6,0) ,2) 'AVG6'
    ,round( isnull(Sale.AVG3,0) ,2) 'AVG3'
    ,round( isnull(STOCK.TotalStock,0) / NULLIF((( round(isnull(Sale.AVG6,0) ,1) + round(isnull(Sale.AVG3,0) ,1) ) / 2),0) ,2) N'M.SALES ทั้งหมด'
    ,round( isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) / NULLIF(((round(isnull(Sale.AVG6,0) ,1) + round(isnull(Sale.AVG3,0) ,1)) / 2),0) ,2) N'M.Sales เฉพาะ IC'
    ,round( isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) ,2) N'Stock ที่เป็น Sales IC เท่านั้น'
    ,round( isnull(STOCK.TotalStock,0) - isnull((select STOCK.TotalStock where Stock.Sales = 'IC'),0) ,2) N'Stock จอง + EO(Stock Total - IC)'
from xxxx..oRPC
inner join xxxx..RPC1 on oRPC.DocEntry = RPC1.DocEntry
left join  xxxx..RPC5 on RPC1.DocEntry = RPC5.AbsEntry
left join (select * from xxxx..[APFULL_GRPO]
			) PDN on RPC1.BaseType = '20' and RPC1.BaseEntry = pdn.DocEntry and RPC1.ItemCode = pdn.ItemCode and RPC1.BaseLine = PDN.LineNum 
left join (select * from xxxx..[APFULL_PO]
			) PORR on RPC1.BaseType = '22' and RPC1.BaseEntry = porr.DocEntry and RPC1.ItemCode = porr.ItemCode and RPC1.BaseLine = porr.LineNum 
left join xxxx..nnm1 on oRPC.Series = nnm1.Series
left join xxxx..oocr oocrr4 on RPC1.OcrCode4 = oocrr4.OcrCode and oocrr4.DimCode = '4'
left join xxxx..oocr oocrr3 on RPC1.OcrCode3 = oocrr3.OcrCode and oocrr3.DimCode = '3'
left join xxxx..oocr oocrr2 on RPC1.OcrCode2 = oocrr2.OcrCode and oocrr2.DimCode = '2'
left join xxxx..ocrd on oRPC.CardCode = ocrd.cardcode
left join xxxx..oitm on RPC1.itemcode = oitm.ItemCode
left join xxxx..oitb on oitm.ItmsGrpCod = oitb.ItmsGrpCod
left join xxxx..[@BRANDS] on OITM.U_brand = [@BRANDS].Code
--Stock (Instock - committed)
left join ( select * from xxxx..[APFULL_Stock]
			) Stock on RPC1.ItemCode = Stock.ItemCode and isnull(RPC1.OcrCode4,'') = isnull(Stock.Supplytype,'') and isnull(RPC1.OcrCode2,'') = isnull(Stock.Sales,'') and RPC1.WhsCode = STOCK.WHS
--sale
left join (select itemcode
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG3,0))) / 3 'AVG3'
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG6,0))) / 6 'AVG6'
		,CONVERT(DECIMAL(18,2),sum(isnull(AVG12,0))) / 12 'AVG12'
			from (select itemcode
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-3,getdate()) and  getdate()) 'AVG3'
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-6,getdate()) and  getdate()) 'AVG6'
			,(select SUM(Quantity) WHERE InvoiceDate BETWEEN DATEADD(m,-12,getdate()) and getdate()) 'AVG12'
			from xxxx..[APFULL_SALE]			
			group by itemcode,InvoiceDate 			
			) A	group by itemcode
			) Sale  on OITM.ItemCode = Sale.ItemCode
where ( orpc.cardcode <> 'AP00015' ) and ORPC.CANCELED = 'N' 
) A
order by 'GroupType'

------*****************************************************************************************************************************************************
---------------------------------------------
--declare @docdatefrom	nvarchar(20)declare @docdateto  nvarchar(20)
--declare @taxdatefrom	nvarchar(20)declare @taxdateto	nvarchar(20)
--declare @vendorfrom		nvarchar(20)declare @vendorto	nvarchar(20)
--declare @brandfrom		nvarchar(20)declare @brandto	nvarchar(20)
--set @docdatefrom	= '20220601' 
--set @docdateto		= '20220630' 
--set @taxdatefrom	= '01/01/2009'
--set @taxdateto		= '31/12/2099'
--set @vendorfrom		= 'AP00001'
--set @vendorto		= 'AT01167'
--set @brandfrom		= 'ACD'   
--set @brandto		= 'TRW'
---------------------------------------------

select * 
from xxxx..[APFULL_APFULL]
where ([ยี่ห้อ] BETWEEN @brandfrom AND @brandto)
    AND ([รหัสผู้จำหน่าย] BETWEEN @vendorfrom AND @vendorto) 
    AND ((case when @docdateto = '31/12/2099' then [DocumentDate AP Invoice] else [PostingDate AP Invoice] end) 
        between (case when @docdatefrom = '01/01/2009' then @taxdatefrom else @docdatefrom end) 
            and (case when @docdateto = '31/12/2099' then @taxdateto else @docdateto end))
order by 'GroupType'
