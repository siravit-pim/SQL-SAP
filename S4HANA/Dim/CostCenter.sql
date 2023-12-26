WITH incremental AS (
	WITH Machine AS (
		SELECT DISTINCT
			A.KOSTL, B.ARBPL, B.WERKS
		FROM "SAPHANADB".CRCO A
		JOIN "SAPHANADB".CRHD B ON A."OBJID" = B."OBJID"
		WHERE A."MANDT"= '900' AND LEFT(B.ARBPL,2) != 'M-'
	) 
    SELECT 
		A."KOSTL" AS "CostCenter",
		A."LTEXT" AS "CostCenterName",
		CAST(HASH_MD5(TO_BINARY(DPM.PLANT)) as NVARCHAR(32)) AS "Department_Key",
		CAST(SUBSTRING_REGEXPR( '[^_]+' IN DPM.PLANT FROM 1 OCCURRENCE 1 ) as NVARCHAR(40)) AS "Department",
		DPM.PLANT "Department&Plant",
		Machine.ARBPL AS "MachineCode",
		IFNULL(Machine.WERKS, Plant."PlantCode") AS "PlantCode"
	FROM "SAPHANADB".CSKT A
	LEFT JOIN Machine ON A."KOSTL" = Machine.KOSTL
	LEFT JOIN "XXXXX"."DimPlant" Plant ON Plant."PlantShortName" = SUBSTRING_REGEXPR('[^-]+' IN A."LTEXT" FROM 1 OCCURRENCE 1)
	JOIN "SAPHANADB".ZCOXXT103 DPM ON A."KOSTL" = DPM.KOSTL AND DPM.MANDT = 900 AND DPM.PLANT NOT LIKE '%SUMMARY%'
	WHERE A."MANDT"=900 and A."SPRAS" = 'E'
)
SELECT *,
    TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
    TO_DATE('9999-12-31') AS END_DATE,
    1 AS ACTIVE,
    CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
        IFNULL("CostCenter",'')
    )))) as NVARCHAR(32)) AS HASH_KEY,
    CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
        IFNULL("CostCenter",'') ||
        IFNULL("CostCenterName",'') ||
        IFNULL("Department_Key",'') ||
        IFNULL("Department",'') ||
        IFNULL("Department&Plant",'') ||
        IFNULL("MachineCode",'') ||
        IFNULL("PlantCode" ,'')
    )))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
