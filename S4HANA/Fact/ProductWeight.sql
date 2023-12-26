WITH Weight AS (
--PRD Weight	
    SELECT "GJAHR", "COSTGROUPS","GROUPS", "TYPE",
        MAP(element_number, 
            1, '01', 02, '02', 03, '03', 4, '04', 5, '05', 6, '06', 7, '07', 8, '08', 9, '09', 10, '10', 11, '11', 12, '12') AS  "Month",
        MAP(element_number,
            1, "WTG001", 2,"WTG002", 3, "WTG003", 4, "WTG004", 5, "WTG005", 6, "WTG006", 7, "WTG007", 8, "WTG008", 9, "WTG009", 10, "WTG010", 11, "WTG011", 12, "WTG012" ) AS "Value"
    FROM "SAPHANADB".ZCOXXT106 
    , SERIES_GENERATE_INTEGER(1, 1, 13)
    WHERE MANDT = '900' AND "GROUPS" IN(XXXXXX)
        
        UNION ALL 
--Sale Weight
    SELECT "GJAHR", "COSTGROUPS","GROUPS", "TYPE",
        MAP(element_number, 
            1, '01', 02, '02', 03, '03', 4, '04', 5, '05', 6, '06', 7, '07', 8, '08', 9, '09', 10, '10', 11, '11', 12, '12') AS  "Month",
        MAP(element_number,
            1, "WTG001", 2,"WTG002", 3, "WTG003", 4, "WTG004", 5, "WTG005", 6, "WTG006", 7, "WTG007", 8, "WTG008", 9, "WTG009", 10, "WTG010", 11, "WTG011", 12, "WTG012" ) AS "Value"
    FROM "SAPHANADB".ZCOXXT106 
    , SERIES_GENERATE_INTEGER(1, 1, 13)
    WHERE MANDT = '900' AND "GROUPS" = 'Sale Weight'
) 
    SELECT 
        "GJAHR" || "Month" ||
                CASE 
                    WHEN "TYPE" = 'BUDGET' THEN '1'
                    WHEN "TYPE" = 'ACTUAL' THEN '2'
                END
            ||
                CASE 
                    WHEN "GROUPS" = 'PRD Weight' THEN '5'
                    WHEN "GROUPS" = 'Sale Weight' THEN '6'
                END
            || 
                CASE
                    WHEN "COSTGROUPS" = '' THEN ''
                    ELSE CAST(HASH_MD5(TO_BINARY("COSTGROUPS")) as NVARCHAR(32))
        END  "Weight_Key",
        "GJAHR" AS "Year",
        "Month",
        "Value"			
    FROM Weight
    WHERE "GROUPS" <> XXXXXX
