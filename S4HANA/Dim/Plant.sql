WITH incremental As (
    SELECT 
	    "WERKS" AS "PlantCode",
        "NAME1" AS "PlantName",
        "REGIO" AS "PlantRegion",
        "ORT01" AS "PlantDistrict"
    FROM "SAPHANADB".T001W
    WHERE "MANDT" = 900 AND "KUNNR" != ''
)
SELECT *,
    TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
	TO_DATE('9999-12-31') AS END_DATE,
	1 AS ACTIVE,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM 	
	    IFNULL("PlantCode",'')
	)))) as NVARCHAR(32)) AS HASH_KEY,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM 
    	IFNULL("PlantCode",'')||
    	IFNULL("PlantName",'')||
    	IFNULL("PlantRegion",'')||
    	IFNULL("PlantDistrict",'')
	)))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
