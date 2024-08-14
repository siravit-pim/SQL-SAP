DROP VIEW "vw_StockOut";
CREATE VIEW "vw_StockOut" as (

with result as (
	with batch as (
	    select batch1."BaseEntry",batch1."ItemCode",batch1."BaseLinNum",batch1."BaseType",
	    	batch1."BatchNum",
	    	batch2."MnfSerial", 
	    	batch2."MnfDate",
	    	batch2."ExpDate",
	    	batch1."Quantity"
	    from ibt1 batch1
	    left join obtn batch2 on batch2."DistNumber" = batch1."BatchNum" and batch1."ItemCode" = batch2."ItemCode"
	    where batch1."BaseType" IN(15,60) and batch1."Direction" = 2
	)
	
	select -- DL
		dln1."WhsCode",
		odln."DocDate",
		dln1."ItemCode",
		odln."CardCode",
		dln1."BaseRef",
		oinv."DocNum",
		dln1."Dscription",
		batch."BatchNum",
		batch."MnfSerial", 
		batch."MnfDate",
		batch."ExpDate", 
		IFNULL(DAYS_BETWEEN(batch."MnfDate", batch."ExpDate"),0) as "ShifLife",
		IFNULL(DAYS_BETWEEN(odln."DocDate", batch."ExpDate"),0) as "ShifLife_B/L",
		IFNULL(CAST(ROUND( ( DAYS_BETWEEN(CURRENT_TIMESTAMP, batch."ExpDate") / DAYS_BETWEEN(batch."MnfDate", batch."ExpDate") ) * 100 ,2 )as DECIMAL(9,2)),0) as "OfShifLife_B/L",
		IFNULL(-batch."Quantity",dln1."Quantity") as "Quantity"
	from odln 
	join dln1 on odln."DocEntry" = dln1."DocEntry"
	left join inv1 on inv1."BaseEntry" = dln1."DocEntry" and inv1."BaseLine" = dln1."LineNum"
	left join oinv on oinv."DocEntry" = inv1."DocEntry" and oinv."CANCELED" = 'N'
	left join batch on batch."BaseType" = 15 and batch."BaseEntry" = dln1."DocEntry" and batch."ItemCode" = dln1."ItemCode" and batch."BaseLinNum" = dln1."LineNum"
	where odln."CANCELED" = 'N' --and odln."DocNum" = '124010010'
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	    UNION ALL --~~~~~~~~~~~~~~~~~~~~~~~~
	select -- GI
		ige1."WhsCode",
		oige."DocDate",
		ige1."ItemCode",
		oige."CardCode",
		ige1."BaseRef",
		oign."DocNum",
		ige1."Dscription",
		batch."BatchNum",
		batch."MnfSerial", 
		batch."MnfDate",
		batch."ExpDate", 
		IFNULL(DAYS_BETWEEN(batch."MnfDate", batch."ExpDate"),0) as "ShifLife",
		IFNULL(DAYS_BETWEEN(oige."DocDate", batch."ExpDate"),0) as "ShifLife_B/L",
		IFNULL(CAST(ROUND( ( DAYS_BETWEEN(CURRENT_TIMESTAMP, batch."ExpDate") / DAYS_BETWEEN(batch."MnfDate", batch."ExpDate") ) * 100 ,2 )as DECIMAL(9,2)),0) as "OfShifLife_B/L",
		IFNULL(-batch."Quantity",ige1."Quantity") as "Quantity"
	from oige 
	join ige1 on oige."DocEntry" = ige1."DocEntry"
	left join ign1 on ign1."BaseEntry" = ige1."DocEntry" and ign1."BaseLine" = ige1."LineNum"
	left join oign on oign."DocEntry" = ign1."DocEntry" and oign."CANCELED" = 'N'
	left join batch on batch."BaseType" = 60 and batch."BaseEntry" = ige1."DocEntry" and batch."ItemCode" = ige1."ItemCode" and batch."BaseLinNum" = ige1."LineNum"
	where oige."CANCELED" = 'N'
)
select result."WhsCode",result."DocDate",
	IFNULL(result."CardCode",'-') as "CardCode", 
	IFNULL(bp."CardName",'-') as "CardName",
	IFNULL(result."BaseRef",'-') as "BaseRef",
	IFNULL(CAST(result."DocNum" as NVARCHAR(99)),'-') as "DocNum",
	result."ItemCode", IFNULL(result."Dscription",'-') as "Dscription",
	IFNULL(result."BatchNum",'-') as "BatchNum",
	IFNULL(result."MnfSerial",'-') as "MnfSerial",
	CAST(result."MnfDate" as DATE) as  "MnfDate", CAST(result."ExpDate" as DATE ) as  "ExpDate" ,
	result."ShifLife", "ShifLife_B/L", result."OfShifLife_B/L", result."Quantity",
	IFNULL(app."AppName",'-') as "Application for Pharma"
from result
left join ocrd bp on bp."CardCode" = result."CardCode"
left join (
		select U1."FldValue" as "AppID", u1."Descr" as "AppName" 
		from  UFD1  U1  
		inner join CUFD C1  on U1."FieldID" =C1."FieldID"  and  U1."TableID" = C1."TableID" 
		where C1."AliasID"= 'PHARMA_APP_CUS'  and  C1."TableID"='OCRD'
	) app on app."AppID" = bp.U_PHARMA_APP_CUS
);
--where "ItemCode" = 'FG000001' --and "BatchNum" IN('2306280025','2306280024')
