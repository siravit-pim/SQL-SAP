DO
BEGIN
	--for loop variable declarations
	DECLARE i INT := 1;
    DECLARE currentYear INT := 2019;
    DECLARE currentQuarter INT := 4;
    DECLARE currentMonth INT := 12;
	--column value variable declarations
    DECLARE currentYearQuarter NVARCHAR(6);
    DECLARE currentYearMonth NVARCHAR(6);
    DECLARE Revenue Decimal(19,4);
	DECLARE COGS Decimal(19,4);
	DECLARE MarkToMarketLoss Decimal(19,4);
	DECLARE NetProfit Decimal(19,4);
	DECLARE TotalAssets Decimal(19,4);
	DECLARE TotalLiabilities Decimal(19,4); 
	DECLARE TotalEquities Decimal(19,4);
	DECLARE AssetCurrent Decimal(19,4);
	DECLARE LiabilityCurrent Decimal(19,4);
	DECLARE Inventories Decimal(19,4);
	DECLARE Inventories_LastQ Decimal(19,4);
	DECLARE Inventories_LastYearQ4 Decimal(19,4);
	DECLARE AR Decimal(19,4);
	DECLARE AR_LastQ Decimal(19,4);
	DECLARE AR_LastYearQ4 Decimal(19,4);
	DECLARE AP Decimal(19,4);
	DECLARE AP_LastQ Decimal(19,4);
	DECLARE AP_LastYearQ4 Decimal(19,4);
	DECLARE ST_Debt Decimal(19,4);
	DECLARE ST_Debt_LastQ Decimal(19,4);
	DECLARE ST_Debt_LastYearQ4 Decimal(19,4);
    -- Create a temporary table to store the results
   CREATE LOCAL TEMPORARY COLUMN TABLE #TempFactRatio (
        "YearQuarter" NVARCHAR(6),
        "YearMonth" NVARCHAR(6),
        "Revenue" Decimal(19,4),
		"COGS" Decimal(19,4),
		"MarkToMarketLoss" Decimal(19,4),
		"NetProfit" Decimal(19,4),
		"TotalAssets" Decimal(19,4),
		"TotalLiabilities" Decimal(19,4),
		"TotalEquities" Decimal(19,4),
		"AssetCurrent" Decimal(19,4),
		"LiabilityCurrent" Decimal(19,4),
		"Inventories" Decimal(19,4),
		"Inventories_LastQ" Decimal(19,4),
		"Inventories_LastYearQ4" Decimal(19,4),
		"AR" Decimal(19,4),
		"AR_LastQ" Decimal(19,4),
		"AR_LastYearQ4" Decimal(19,4),
		"AP" Decimal(19,4),
		"AP_LastQ" Decimal(19,4),
		"AP_LastYearQ4" Decimal(19,4),
		"ST_Debt" Decimal(19,4),
		"ST_Debt_LastQ" Decimal(19,4),
		"ST_Debt_LastYearQ4" Decimal(19,4)
    );

    -- Loop through quarters
    FOR i IN 1..9999 DO 

	-- Defind / representation of the year and quarter.
    currentYearQuarter := TO_NVARCHAR(currentYear) || '-' || TO_NVARCHAR(currentQuarter);
    currentYearMonth := TO_NVARCHAR(currentYear) || CASE WHEN currentMonth < 10 THEN '0' || TO_NVARCHAR(currentMonth) ELSE TO_NVARCHAR(currentMonth) END  ;
    
    
	-------------------------
    IF currentMonth = 12 THEN
        currentMonth := 1;
        currentYear := currentYear + 1;
    ELSE
        currentMonth := currentMonth + 1;
    END IF;
    -------------------------
        IF currentMonth >= 1 AND currentMonth <= 3 THEN currentQuarter := 1;
        ELSEIF currentMonth >= 4 AND currentMonth <= 6 THEN currentQuarter := 2;
        ELSEIF currentMonth >= 7 AND currentMonth <= 9 THEN currentQuarter := 3;
        ELSEIF currentMonth >= 10 AND currentMonth <= 12 THEN currentQuarter := 4;
        END IF;
        -------------------------
        IF currentYear = LEFT(QUARTER(CURRENT_DATE, 10), 4) + 1 
           AND currentMonth = MONTH(ADD_MONTHS(CURRENT_DATE, 2))
        THEN
            BREAK; -- Exits if year is more than 1 from now and month is ahead
        END IF;

	-------------------------
    -- Statement logic
		WITH Summarize AS ( -- PL
			WITH Calculation1 AS (
				WITH ProvideGroup AS (	
					SELECT a.HRYID, B.CALENDARMONTH AS "Month",
						B.FISCALYEAR || '-' || B.CALENDARQUARTER AS "Date", --a."GLAccount", a."GLAccountName", 
						CASE 
							WHEN a.Hlevel = 1 THEN NULL
							WHEN a.Hlevel = 2 THEN a.Level1
							WHEN a.Hlevel = 3 THEN a.Level2
							WHEN a.Hlevel = 4 THEN a.Level3
							WHEN a.Hlevel = 5 THEN a.Level4
							WHEN a.Hlevel = 6 THEN a.Level5
							WHEN a.Hlevel = 7 THEN a.Level6
							WHEN a.Hlevel = 8 THEN a.Level7
						END "GLGroup"
						,SUM(b.AMOUNT) AS "Amount"
					FROM "XXXXX"."DimGLAccountMaster" A
					LEFT JOIN SAPHANADB.ZPAMTGL B ON A."GLAccount" = LTRIM(B.GLACCOUNT, '0')
					WHERE A.HRYID = '1200' AND B.Amount <> 0 AND (B.FISCALYEAR || '-' || B.CALENDARQUARTER) = :currentYearQuarter and B.FISCALYEAR || B.CALENDARMONTH = :currentYearMonth
					GROUP BY a.HRYID,B.FISCALYEAR || '-' || B.CALENDARQUARTER, B.CALENDARMONTH ,
						CASE WHEN a.Hlevel = 1 THEN NULL	WHEN a.Hlevel = 2 THEN a.Level1	WHEN a.Hlevel = 3 THEN a.Level2	WHEN a.Hlevel = 4 THEN a.Level3	WHEN a.Hlevel = 5 THEN a.Level4	WHEN a.Hlevel = 6 THEN a.Level5	WHEN a.Hlevel = 7 THEN a.Level6	WHEN a.Hlevel = 8 THEN a.Level7 END
				
				) SELECT HRYID,"Date", "Month",
					CASE WHEN "GLGroup" IN('Sale Revenue','Service Revenue') THEN -"Amount" 
						END "Revenue",
					CASE WHEN "GLGroup" IN('Cost of Goods Sold','Cost of Service','Depreciation (Group Cost)') THEN "Amount" 
						END "COGS",
					CASE WHEN "GLGroup" IN('Loss from diminution in value of inventories') THEN "Amount"
						END "Mark to Market Loss (Reverse)",
					CASE WHEN HRYID = '1200' THEN -"Amount" 
						END "NetProfit"
				FROM ProvideGroup
			) 	
				SELECT HRYID,"Date",  "Month",
					SUM("Revenue") AS "Revenue",
					SUM("COGS") AS "COGS",
					SUM("Mark to Market Loss (Reverse)") AS "Mark to Market Loss (Reverse)",
					SUM("NetProfit") AS "NetProfit"		
				FROM Calculation1 
				GROUP BY HRYID, "Date",  "Month"
		-----------------------------------
		), --BS
		GroupBS AS (
				WITH ProvideGroup AS (	
					SELECT a.HRYID, B.CALENDARMONTH AS "Month",
					    B.FISCALYEAR || '-' || B.CALENDARQUARTER AS "Date",
						CASE 
							WHEN a.Hlevel = 1 THEN NULL
							WHEN a.Hlevel = 2 THEN NULL
							WHEN a.Hlevel = 3 THEN NULL
							WHEN a.Hlevel = 4 THEN a.Level1
							WHEN a.Hlevel = 5 THEN a.Level2
							WHEN a.Hlevel = 6 THEN a.Level3
							WHEN a.Hlevel = 7 THEN a.Level4
							WHEN a.Hlevel = 8 THEN a.Level5
						END "GLGroupRoot",
						CASE 
							WHEN a.Hlevel = 1 THEN NULL
							WHEN a.Hlevel = 2 THEN NULL
							WHEN a.Hlevel = 3 THEN a.Level1
							WHEN a.Hlevel = 4 THEN a.Level2
							WHEN a.Hlevel = 5 THEN a.Level3
							WHEN a.Hlevel = 6 THEN a.Level4
							WHEN a.Hlevel = 7 THEN a.Level5
							WHEN a.Hlevel = 8 THEN a.Level6
						END "GLGroupParent",
						CASE 
							WHEN a.Hlevel = 1 THEN NULL
							WHEN a.Hlevel = 2 THEN a.Level1
							WHEN a.Hlevel = 3 THEN a.Level2
							WHEN a.Hlevel = 4 THEN a.Level3
							WHEN a.Hlevel = 5 THEN a.Level4
							WHEN a.Hlevel = 6 THEN a.Level5
							WHEN a.Hlevel = 7 THEN a.Level6
							WHEN a.Hlevel = 8 THEN a.Level7
						END "GLGroup",
						SUM(b.AMOUNT) AS "Amount"
					FROM "XXXXX"."DimGLAccountMaster" A
					LEFT JOIN SAPHANADB.ZPAMTGL B ON A."GLAccount" = LTRIM(B.GLACCOUNT, '0')
					WHERE A.HRYID = '1100' AND B.Amount <> 0 AND (B.FISCALYEAR || '-' || B.CALENDARQUARTER) <= :currentYearQuarter and B.FISCALYEAR || B.CALENDARMONTH <= :currentYearMonth
					GROUP BY a.HRYID,B.FISCALYEAR || '-' || B.CALENDARQUARTER, B.CALENDARMONTH 
						,CASE WHEN a.Hlevel = 1 THEN NULL WHEN a.Hlevel = 2 THEN a.Level1 WHEN a.Hlevel = 3 THEN a.Level2	WHEN a.Hlevel = 4 THEN a.Level3	WHEN a.Hlevel = 5 THEN a.Level4	WHEN a.Hlevel = 6 THEN a.Level5	WHEN a.Hlevel = 7 THEN a.Level6	WHEN a.Hlevel = 8 THEN a.Level7 END
						,CASE WHEN a.Hlevel = 1 THEN NULL WHEN a.Hlevel = 2 THEN NULL WHEN a.Hlevel = 3 THEN a.Level1	WHEN a.Hlevel = 4 THEN a.Level2 WHEN a.Hlevel = 5 THEN a.Level3	WHEN a.Hlevel = 6 THEN a.Level4 WHEN a.Hlevel = 7 THEN a.Level5	WHEN a.Hlevel = 8 THEN a.Level6	END
						,CASE WHEN a.Hlevel = 1 THEN NULL WHEN a.Hlevel = 2 THEN NULL WHEN a.Hlevel = 3 THEN NULL	WHEN a.Hlevel = 4 THEN a.Level1	WHEN a.Hlevel = 5 THEN a.Level2 WHEN a.Hlevel = 6 THEN a.Level3 WHEN a.Hlevel = 7 THEN a.Level4	WHEN a.Hlevel = 8 THEN a.Level5	END
				) 
				SELECT HRYID,"Date", "Month",
					CASE
						WHEN "GLGroupRoot" IN('Asset','Current Asset','Non Current Asset') THEN "Amount"
					END "TotalAssets",
					CASE
						WHEN "GLGroupRoot" IN('Liabilities','Current Liabilities') THEN -"Amount"
					END "TotalLiabilities",
					CASE
						WHEN "GLGroupRoot" IN('Retail Earnings','Shareholder''s Equities','Liabilities and Shareholder''s Equity') THEN -"Amount"
					END "TotalEquities",
					CASE
						WHEN "GLGroupRoot" IN('Asset','Current Asset') THEN "Amount"
					END "AssetCurrent",
					CASE
						WHEN "GLGroupRoot" IN('Current Liabilities') THEN -"Amount"
					END "LiabilityCurrent",
					CASE
						WHEN "GLGroup" IN('Inventory (Net)') THEN "Amount"
					END "Inventories",
					CASE
						WHEN "GLGroup" IN('Inventory (Net)') THEN (SELECT "Amount" FROM DUMMY WHERE "Date" <> :currentYearQuarter)
					END "Inventories_LastQ",
					CASE
						WHEN "GLGroup" IN('Inventory (Net)') THEN (SELECT "Amount" FROM DUMMY WHERE LEFT("Date",4) <> TO_NVARCHAR(:currentYear))
					END "Inventories_LastYearQ4",
					CASE
						WHEN "GLGroupParent" IN('Account receivable & Other-net') THEN "Amount"
					END "AR",
					CASE
						WHEN "GLGroupParent" IN('Account receivable & Other-net') THEN (SELECT "Amount" FROM DUMMY WHERE "Date" <> :currentYearQuarter)
					END "AR_LastQ",
					CASE
						WHEN "GLGroupParent" IN('Account receivable & Other-net') THEN (SELECT "Amount" FROM DUMMY WHERE LEFT("Date",4) <> TO_NVARCHAR(:currentYear))
					END "AR_LastYearQ4",
					CASE
						WHEN "GLGroupParent" IN('Trade and other  payables') THEN -"Amount"
					END "AP",
					CASE
						WHEN "GLGroupParent" IN('Trade and other  payables') THEN (SELECT -"Amount" FROM DUMMY WHERE "Date" <> :currentYearQuarter)
					END "AP_LastQ",
					CASE
						WHEN "GLGroupParent" IN('Trade and other  payables') THEN (SELECT -"Amount" FROM DUMMY WHERE LEFT("Date",4) <> TO_NVARCHAR(:currentYear))
					END "AP_LastYearQ4",
					CASE
						WHEN "GLGroupParent" IN('Short-term loans from financial institutions') THEN -"Amount"
					END "ST_Debt",
					CASE
						WHEN "GLGroupParent" IN('Short-term loans from financial institutions') THEN (SELECT -"Amount" FROM DUMMY WHERE "Date" <> :currentYearQuarter)
					END "ST_Debt_LastQ",
					CASE
						WHEN "GLGroupParent" IN('Short-term loans from financial institutions') THEN (SELECT -"Amount" FROM DUMMY WHERE LEFT("Date",4) <> TO_NVARCHAR(:currentYear))
					END "ST_Debt_LastYearQ4"
				FROM ProvideGroup
			)
			SELECT currentYearQuarter AS "YearQuarter",
			    currentYearMonth AS "YearMonth",
				IFNULL(PL."Revenue",0) "Revenue",
				IFNULL(PL."COGS",0) "COGS",
				IFNULL(PL."Mark to Market Loss (Reverse)",0) "MarkToMarketLoss",
				IFNULL(PL."NetProfit",0) "NetProfit",
				IFNULL(SUM(BS."TotalAssets"),0) "TotalAssets",
				IFNULL(SUM(BS."TotalLiabilities"),0) "TotalLiabilities",
				IFNULL(SUM(BS."TotalEquities"),0) "TotalEquities",
				IFNULL(SUM(BS."AssetCurrent"),0) "AssetCurrent",
				IFNULL(SUM(BS."LiabilityCurrent"),0) "LiabilityCurrent",
				IFNULL(SUM(BS."Inventories"),0) "Inventories",
				IFNULL(SUM(BS."Inventories_LastQ"),0) "Inventories_LastQ",
				IFNULL(SUM(BS."Inventories_LastYearQ4"),0) "Inventories_LastYearQ4",
				IFNULL(SUM(BS."AR"),0) "AR",
				IFNULL(SUM(BS."AR_LastQ"),0) "AR_LastQ",
				IFNULL(SUM(BS."AR_LastYearQ4"),0) "AR_LastYearQ4",
				IFNULL(SUM(BS."AP"),0) "AP",
				IFNULL(SUM(BS."AP_LastQ"),0) "AP_LastQ",
				IFNULL(SUM(BS."AP_LastYearQ4"),0) "AP_LastYearQ4",
				IFNULL(SUM(BS."ST_Debt"),0) "ST_Debt",
				IFNULL(SUM(BS."ST_Debt_LastQ"),0) "ST_Debt_LastQ",
				IFNULL(SUM(BS."ST_Debt_LastYearQ4"),0) "ST_Debt_LastYearQ4"
				INTO -- Variables storing calculated metrics
					currentYearQuarter,
				    currentYearMonth,
					Revenue,
					COGS,
					MarkToMarketLoss,
					NetProfit,
					TotalAssets,
					TotalLiabilities, 
					TotalEquities,
					AssetCurrent,
					LiabilityCurrent,
					Inventories,
					Inventories_LastQ,
					Inventories_LastYearQ4,
					AR,
					AR_LastQ,
					AR_LastYearQ4,
					AP,
					AP_LastQ,
					AP_LastYearQ4,
					ST_Debt,
					ST_Debt_LastQ,
					ST_Debt_LastYearQ4
			FROM GroupBS BS, Summarize PL
			GROUP BY IFNULL(PL."Revenue",0),IFNULL(PL."COGS",0),IFNULL(PL."Mark to Market Loss (Reverse)",0),IFNULL(PL."NetProfit",0) 
	--------------------------------------------------------------------
	;
	INSERT INTO #TempFactRatio VALUES (
			:currentYearQuarter,
		    :currentYearMonth,
			Revenue,
			COGS,
			MarkToMarketLoss,
			NetProfit,
			TotalAssets,
			TotalLiabilities, 
			TotalEquities,
			AssetCurrent,
			LiabilityCurrent,
			Inventories,
			Inventories_LastQ,
			Inventories_LastYearQ4,
			AR,
			AR_LastQ,
			AR_LastYearQ4,
			AP,
			AP_LastQ,
			AP_LastYearQ4,
			ST_Debt,
			ST_Debt_LastQ,
			ST_Debt_LastYearQ4
		); 
	
	END FOR; -- ************************************

    -----------------------------------------------
     --Create table instead temp table and drop it
	 CREATE TABLE "XXXXX"."FI.FactRatio" AS (
		SELECT * FROM #TempFactRatio
	)
	;
		DROP TABLE #TempFactRatio;
END;
