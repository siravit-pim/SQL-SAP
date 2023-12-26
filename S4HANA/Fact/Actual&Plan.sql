WITH Summarized AS (
    WITH CostPlan AS (
        SELECT '1' as "CostType_Key", 'Plan' AS "CostType",
            CAST(A."GJAHR" AS NVARCHAR(4)) AS "FiscalYear",
            CAST(MAP(element_number, 
                1, '01', 02, '02', 03, '03', 4, '04', 5, '05', 6, '06', 7, '07', 8, '08', 9, '09', 10, '10', 11, '11', 12, '12') AS NVARCHAR(2)) AS  "Month",
             MAP(element_number,
                1, A."WTG001", 2, A."WTG002", 3, A."WTG003", 4, A."WTG004", 5, A."WTG005", 6, A."WTG006", 7, A."WTG007", 8, A."WTG008", 9, A."WTG009", 10, A."WTG010", 11, A."WTG011", 12, A."WTG012" ) AS "Value",
            SUBSTRING(A."KSTAR", 3, 99) AS "GLAccountCode",
            (SELECT MAX(SUBSTRING(COSS.USPOB,7,10)) FROM SAPHANADB.COSS WHERE A.OBJNR = COSS.OBJNR AND A.GJAHR = COSS.GJAHR ) AS "CostCenterCode",
            C."PlantCode",
            C."Department&Plant",
            C."Department_Key",
            CASE 
                WHEN SUBSTRING(A."OBJNR",10,1) = '5' THEN '5' --'Conversion'
                WHEN SUBSTRING(A."OBJNR",10,1) = '6' THEN '6' --'SG&A'
                ELSE NULL 
            END "Conversion/SG&A_Key" ,
            NULL AS "DocNum" ,NULL AS "Text", NULL AS "LineNum"
        FROM "SAPHANADB"."COSP" A
        INNER JOIN XXXXX."DimCostElement" B on SUBSTRING(A."KSTAR", 3, 99) = B."CostElement" AND IFNULL(B."CostElementGroup", '') <> '' AND IFNULL(B."FC/VC", '') <> ''
        LEFT JOIN XXXXX."DimCostCenter" C ON SUBSTRING(A."OBJNR", 7, 99) = C."CostCenter"
        , SERIES_GENERATE_INTEGER(1, 1, 13)			--Generate Pivot
        WHERE A."VERSN" = '000'						--Version
                and A."WRTTP" = '01'				--ValueType = Plan
                and SUBSTRING(A."OBJNR",0,2) = 'KS' --Object for costCenter
                
    ), CostActual2 as (
        WITH CostActual as (
            SELECT
                "GJAHR" AS "FiscalYear",
                "Month",
                "HSL" as "Value",
                "GL_ACCOUNT" as "GLAccountCode",	
                "COSTCENTER_FAGLL03" as "CostCenterCode" ,
                IFNULL("DOCNR",'') AS "DocNum", "Text",ROW_NUMBER() OVER (PARTITION BY "COSTCENTER_FAGLL03", "GL_ACCOUNT", "DOCNR", "GJAHR", "Month" ORDER BY "COSTCENTER_FAGLL03", "GL_ACCOUNT", "DOCNR", "GJAHR", "Month") AS "LineNum"
            FROM XXXXX
            WHERE ( (IFNULL("Costcenter_Desc", '') <> '')  AND ("Costcenter_Desc" NOT LIKE '%SUMMARY%') )
                AND (IFNULL("DOCUMENT_DATE", '' ) <> '')
                AND (IFNULL("COSTCENTER_FAGLL03", '') <> '')
                AND "HSL" <> 0
    
        ) SELECT 
                '2' AS "CostType_Key", 'Actual' AS "CostType",
                "FiscalYear", "Month",
                A."Value",
                A."GLAccountCode",
                A."CostCenterCode",
                C."PlantCode",
                C."Department&Plant",
                C."Department_Key",
                CASE 
                    WHEN SUBSTRING(A."CostCenterCode",4,1) = '5' THEN '5'--'Conversion'
                    WHEN SUBSTRING(A."CostCenterCode",4,1) = '6' THEN '6'--'SG&A'
                    ELSE NULL 
                END "Conversion/SG&A_Key",
                "DocNum","Text","LineNum"
            from CostActual A
            INNER JOIN XXXXX."DimCostElement" B on A."GLAccountCode" = B."CostElement" AND IFNULL(B."CostElementGroup", '') <> '' AND IFNULL(B."FC/VC", '') <> ''
            LEFT JOIN XXXXX."DimCostCenter" C on A."CostCenterCode" = C."CostCenter"	
    )
        SELECT *
        FROM CostPlan
        WHERE "Value" <> 0
            UNION ALL
        SELECT *
        FROM CostActual2
        WHERE "Value" <> 0
        
)  SELECT
        CASE 
            WHEN "CostType_Key" = '1' THEN CAST(
                                                HASH_MD5(
                                                    TO_BINARY(
                                                        UPPER(
                                                            TRIM('' FROM "CostCenterCode" || "GLAccountCode"
                                                            )
                                                        )
                                                    )
                                                ) AS NVARCHAR(32)
                                            )
            ELSE CAST(
                    HASH_MD5(
                        TO_BINARY( 
                            UPPER(
                                TRIM('' FROM "CostCenterCode" || "GLAccountCode" || "DocNum" || "FiscalYear" || "Month" || "LineNum"
                                ) 
                            )
                        ) 
                    ) AS NVARCHAR(32)
                ) 
        END "WorkCenter_Key",
        "Value",
        "CostType_Key",
        "FiscalYear", "Month",
        "PlantCode",
        "CostCenterCode",
        "GLAccountCode", --,"DocNum","Text""LineNum"
        "Department&Plant",
        "FiscalYear" || "Month"|| "CostType_Key" || "Conversion/SG&A_Key" ||
        CASE
            XXXXX
        END AS "Weight_Key"
    FROM Summarized A 
