WITH incremental AS (
	WITH Finised AS (
		WITH GroupCCGL2 AS (
			WITH GroupCCGL AS (
				WITH B AS ( -- every GL must have CostCenter
					SELECT DISTINCT 
                        OBJNR, GJAHR, SUBSTRING(USPOB,7,10) AS "CostCenter" 
					FROM SAPHANADB.COSS
					WHERE MANDT = '900' AND VERSN = '000'
				)
		----------------------------------
				SELECT DISTINCT '2' AS "Type",
					"COSTCENTER_FAGLL03" as "CostCenter", "GL_ACCOUNT" as "CostElement",
					"GJAHR" AS "FiscalYear","Month" AS "Month",
					IFNULL("DOCNR",'') AS "DocNum","Text",
					ROW_NUMBER() OVER (
                            PARTITION BY "COSTCENTER_FAGLL03", "GL_ACCOUNT", "DOCNR", "GJAHR", "Month" ORDER BY "COSTCENTER_FAGLL03", "GL_ACCOUNT", "DOCNR", "GJAHR", "Month"
					    ) AS "LineNum"
				FROM "_SYS_BIC"."CEO_DASHBOARD/ZP_FI_FBL3N_GL_LINE_ITEM"
				WHERE IFNULL("COSTCENTER_FAGLL03", '') <> '' AND IFNULL("GL_ACCOUNT", '') <> '' AND HSL <> 0
		----------------------------------
					UNION
				SELECT DISTINCT '1' AS "Type",
					B."CostCenter", SUBSTRING(A.KSTAR,3,99) as "CostElement",
					A.GJAHR AS "FiscalYear",'0' AS "Month",
					NULL AS "DocNum",NULL AS "Text",NULL AS "LineNum"
				FROM SAPHANADB.COSP A
				JOIN B ON A.OBJNR = B.OBJNR AND A.GJAHR = B.GJAHR
					, SERIES_GENERATE_INTEGER(1, 1, 13)	--Generate Pivot
				WHERE A.MANDT = '900' AND A.VERSN = '000' AND A.WRTTP = '01' AND SUBSTRING(A."OBJNR",0,2) = 'KS'
			)
			SELECT DISTINCT *,
				CASE 
					WHEN "Type" = '1' THEN CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM IFNULL("CostCenter",'') || IFNULL("CostElement",'') )))) AS NVARCHAR(32))						
					ELSE CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM IFNULL("CostCenter",'') || IFNULL("CostElement",'') || IFNULL("DocNum",'') || IFNULL("FiscalYear",'') || IFNULL("Month",'') || IFNULL("LineNum",0) )))) AS NVARCHAR(32)) 
				END "WorkCenter_Key"
			FROM GroupCCGL
			WHERE IFNULL("CostCenter", '') <> '' AND IFNULL("CostElement", '') <> ''
		)
		SELECT DISTINCT 
			A."WorkCenter_Key",
			C."PlantCode", P."PlantShortName",  P."PlantName",
			C."Department_Key",C."Department" AS "DepartmentName",C."Department&Plant",
			A."CostCenter" as "CostCenterCode", C."CostCenterName",
			M."MachineCode", M."MachineDesc",M."MachineGroup", M."ProcessGroup", M."Process", 
			A."CostElement" AS "CostElementCode", B."CostElementName",
            B."FC/VC",
            B."CostElementGroup",
			SUBSTRING(C."CostCenter", 4, 1),
			"Text",
            "DocNum"
		FROM GroupCCGL2 A 
		LEFT JOIN "BIITPL01"."DimCostElement" B ON A."CostElement" = B."CostElement"
		LEFT JOIN "BIITPL01"."DimCostCenter" C ON A."CostCenter" = C."CostCenter"
		LEFT JOIN "BIITPL01"."DimMachine" M ON C."MachineCode" = M."MachineCode" AND C."PlantCode" = M."PlantCode"
		LEFT JOIN "BIITPL01"."DimPlant" P ON C."PlantCode" = P."PlantCode" OR M."PlantCode" = P."PlantCode" 	
	) 
	SELECT 
		*,
		CASE 
			WHEN "Conversion/SG&A" = 'Conversion' THEN '5' WHEN "Conversion/SG&A" = 'SG&A' THEN '6' 
		END "Conversion/SG&A_Key"
	FROM Finised
)
SELECT *,
	TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
	TO_DATE('9999-12-31') AS END_DATE,
	1 AS ACTIVE,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("WorkCenter_Key",'')
	)))) as NVARCHAR(32)) AS HASH_KEY,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("WorkCenter_Key",'') ||
		IFNULL("PlantCode",'') ||
		IFNULL("PlantShortName",'') ||
		IFNULL("PlantName",'') ||
		IFNULL("Department_Key",'') ||
		IFNULL("CostCenterName",'') ||
		IFNULL("MachineCode",'') ||
		IFNULL("MachineDesc",'') ||
		IFNULL("MachineGroup",'') ||
		IFNULL("ProcessGroup",'') ||
		IFNULL("Process",'') ||
		IFNULL("CostElementName",'') ||
		IFNULL("FC/VC",'') ||
		IFNULL("CostElementGroup",'') ||
		IFNULL("Text",'')
	)))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
