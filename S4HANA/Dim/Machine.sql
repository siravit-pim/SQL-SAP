WITH incremental AS (
	SELECT
	    A."OBJID" AS "ObjCode",
	    B."ARBPL" AS "MachineCode",
		A."KTEXT" AS "MachineDesc",
		B."WERKS" AS "PlantCode"
	FROM "SAPHANADB".CRTX A
	JOIN "SAPHANADB".CRHD B ON A."OBJID" = B."OBJID" AND A."OBJTY" = B."OBJTY"
	WHERE A."MANDT"= '900' and A."SPRAS" = 'E'
)
SELECT *,
	TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
	TO_DATE('9999-12-31') AS END_DATE,
	1 AS ACTIVE,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
	    IFNULL("ObjCode",'')
	)))) as NVARCHAR(32)) AS HASH_KEY,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("ObjCode",'') ||
		IFNULL("MachineCode",'') ||
		IFNULL("MachineDesc",'') ||
		IFNULL("PlantCode",'')
	)))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
