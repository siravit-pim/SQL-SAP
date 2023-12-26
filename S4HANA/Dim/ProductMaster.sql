WITH incremental AS (
	WITH Sorting AS (
		WITH Cal4 AS (	
			WITH Cal3 AS (
				WITH Cal2 AS (	
					WITH Cal AS (
						SELECT 
							LTRIM(A.MATNR,'0') "MaterialCode", A3.MAKTX AS "MaterialDesc",
							A.MTART	"MaterialType", A1.MTBEZ AS "MaterialTypeDesc",
							A.MATKL	"MaterialGroup", A2.WGBEZ AS "MaterialGroupDesc",
							C.MFRGR "MaterialGroupSize",
							D.ATFLV	"MaterialLength", -- value's a non-sense
							A.BRGEW	"GrossWeight",
							A.NTGEW	"NetWeight",
							A.GEWEI	"WeightUnit",
							A.MEINS	"BaseUoM",
							A.LABOR	"Turnover",
							B.KONDM "MachineGroup", B6.VTEXT AS "MachineGroupDesc",
							---------------------------
							--A.PRDHA	"ProductHierarchy",
							LEFT(A.PRDHA, 8) "RMTypeKey",
							SUBSTRING(A.PRDHA, 8,1) "RMType",
							--LEFT(A.PRDHA, 12) "BrandKey",
							SUBSTRING(A.PRDHA, 11,2) "BrandCode", --A4.VTEXT "BrandDesc",
							(SELECT z.VTEXT FROM SAPHANADB.T179T z WHERE z.PRODH = LEFT(A.PRDHA, 12) 
							    AND z.SPRAS= 'E' AND z.MANDT= '900' AND z.VTEXT != 'Dummy'
							) "BrandDesc",
							--LEFT(A.PRDHA, 14) "CoatingKey",
							SUBSTRING(A.PRDHA, 13,2) "CoatingCode",-- A44.VTEXT "Coating",
							(SELECT z.VTEXT FROM SAPHANADB.T179T z WHERE z.PRODH = LEFT(A.PRDHA, 14) 
							    AND z.SPRAS= 'E' AND z.MANDT= '900' AND z.VTEXT != 'Dummy'
							) "Coating",
							---------------------------
							B.MVGR1 "ODCode", B1.BEZEI "ODDesc",
							B.MVGR2 "WallTHKCode", CASE WHEN B2.desConvert = 999 THEN NULL ELSE B2.desConvert END "WallTHKDesc(mm.)",
							B.MVGR3 "RealTHKCode", CASE WHEN B3.desConvert = 999 THEN NULL ELSE B3.desConvert END "RealTHKDesc(mm.)",
							B.MVGR4 "StandardCode",B4.BEZEI "StandardDesc",
							B.MVGR5 "ProductPurposeCode", B5.BEZEI "ProductPurposeDesc",
							---------------------------
							CASE
								XXX
							END "GroupTHK",
							CASE
								XXX
							END "TypePM",
							CASE
								XXX
							END "SizePM",
							CASE 
								XXX
							END "MovementType",
							CASE
								XXX
							END "ProductView",
							CASE 
                                XXX
							END "SupplyType",
							CASE
								XXX
							END "SizeForSales",
                            CASE 
                                XXX
                            END "MatType"
						FROM SAPHANADB.MARA A --mat
						JOIN SAPHANADB.MAKT A3 ON A.MATNR = A3.MATNR AND A3.SPRAS= 'E' AND A3.MANDT= '900' AND (A3.MAKTX NOT LIKE('%Cancel%') AND A3.MAKTX NOT LIKE(N'%ยกเลิก%'))
						LEFT JOIN SAPHANADB.MVKE B ON A.MATNR = B.MATNR AND B.MANDT = 900 AND B.VKORG = '1000' AND B.VTWEG = '10' -- alot of key for join
						LEFT JOIN SAPHANADB.MARC C ON A.MATNR = C.MATNR AND C.MANDT = 900 AND C.WERKS = 1000 -- FOR NOT Ducpicate
						LEFT JOIN SAPHANADB.AUSP D ON A.MATNR = D.OBJEK AND D.MANDT = 900 AND D.ATINN = '0000000174' AND  D.KLART = '001'
						--------------------------------------------------
						LEFT JOIN SAPHANADB.T134T A1 ON A.MTART = A1.MTART AND A1.SPRAS= 'E' AND A1.MANDT= '900'
						LEFT JOIN SAPHANADB.T023T A2 ON A.MATKL = A2.MATKL AND A2.SPRAS= 'E' AND A2.MANDT= '900'
						--LEFT JOIN SAPHANADB.T179T A4 ON LEFT(A.PRDHA, 12) = A4.PRODH AND A4.SPRAS= 'E' AND A4.MANDT= '900' AND A4.VTEXT != 'Dummy' --Brand
						--LEFT JOIN SAPHANADB.T179T A44 ON LEFT(A.PRDHA, 14) = A4.PRODH AND A4.SPRAS= 'E' AND A4.MANDT= '900' AND A4.VTEXT != 'Dummy' --Coating
						LEFT JOIN SAPHANADB.TVM1T B1 ON B.MVGR1 = B1.MVGR1 AND B1.SPRAS = 'E' AND B1.MANDT= '900' AND B1.BEZEI != 'Dummy'
						LEFT JOIN ( SELECT MVGR2, CAST( CASE 
											WHEN BEZEI IN('', NULL, 'Dummy') OR BEZEI LIKE '%x%' THEN '999'
											ELSE SUBSTRING_REGEXPR('[^ ]+' IN BEZEI OCCURRENCE 1)
										END AS DECIMAL(5,2) ) desConvert
									FROM SAPHANADB.TVM2T
									WHERE SPRAS = 'E' AND MANDT= '900'
								) B2 ON B.MVGR2 = B2.MVGR2
						LEFT JOIN ( SELECT MVGR3, CAST( CASE 
											WHEN BEZEI IN('', NULL, 'Dummy') OR BEZEI LIKE '%x%' THEN '999'
											ELSE SUBSTRING_REGEXPR('[^ ]+' IN BEZEI OCCURRENCE 1)
										END AS DECIMAL(5,2) ) desConvert
									FROM SAPHANADB.TVM3T
									WHERE SPRAS = 'E' AND MANDT= '900'
								) B3 ON B.MVGR3 = B3.MVGR3				
						LEFT JOIN SAPHANADB.TVM4T B4 ON B.MVGR4 = B4.MVGR4 AND B4.SPRAS = 'E' AND B4.MANDT= '900' AND B4.BEZEI != 'Dummy'
						LEFT JOIN SAPHANADB.TVM5T B5 ON B.MVGR5 = B5.MVGR5 AND B5.SPRAS = 'E' AND B5.MANDT= '900' AND B5.BEZEI != 'Not specific'
						LEFT JOIN SAPHANADB.T178T B6 ON B.KONDM = B6.KONDM AND B6.SPRAS = 'E' AND B6.MANDT= '900' --Machine
						---------------------------
						WHERE A.MANDT = 900
					) 
					SELECT *,
						CASE
							XXX
						END "SurfacePM",
						CASE 
							XXX
						END "MovementType1",
						CASE
							XXX
						END	"XXX",
						CASE
							XXX
						END "ProductType1",
						CASE
							XXX
						END "BrandProduct"
					FROM Cal
				) 
				SELECT *,
					CASE
						XXX
					END "SurfaceType",
					CASE
						XXX
					END "ProductType",
					CASE
					    XXX
					END "Brand"
				FROM Cal2
			)
			SELECT *,
				CASE
					XXX
				END "SurfaceType1",
				CASE
					XXX
				END "BrandGroup"
			FROM Cal3
		)
		SELECT *,
			CASE
				XXX
			END "ApplicationSales",
			CASE
				XXX
			END "CoatingTrans"
			
		FROM Cal4
	)
	---------------------------------------------------------------
	SELECT --"MatType",
		"ProductType" AS "ProductType_FI",
		CAST("ProductType1" as NVARCHAR(16)) AS "ProductType_PD", -- diff view
        "MaterialTypeDesc" as "ProductTypeDesc",
		CAST("ProductView" as NVARCHAR(16)) AS "ProductGroup_FI", -- diff view
        "MaterialGroupDesc" as "ProductGroup_PD",
		"SurfaceType1" AS "ProductSurface",
		"CoatingTrans" as "Coating",
		"SizePM" AS "ProductSize",
		"ODDesc" AS "ProductOD",
		"MaterialCode" AS "ProductCode",
		"MaterialDesc" as "ProductName",
		"ApplicationSales" AS "Application",
		"BrandGroup" AS "BrandGroup",
		"Brand",
		"StandardDesc" AS "Standard",
		"Turnover",
		"MovementType",
		"ProductPurposeDesc" as "ProductPurpose"
	FROM Sorting
)
SELECT *,
	TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
	TO_DATE('9999-12-31') AS END_DATE,
	1 AS ACTIVE,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("ProductCode",'')
	)))) as NVARCHAR(32)) AS HASH_KEY,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("ProductType_FI",'') ||
		IFNULL("ProductType_PD",'') ||
		IFNULL("ProductTypeDesc",'') ||
		IFNULL("ProductGroup_FI",'') ||
		IFNULL("ProductGroup_PD",'') ||
		IFNULL("ProductSurface",'') ||
		IFNULL("Coating",'') ||
		IFNULL("ProductSize",'') ||
		IFNULL("ProductOD",'') ||
		IFNULL("ProductCode",'') ||
		IFNULL("ProductName",'') ||
		IFNULL("Application",'') ||
		IFNULL("BrandGroup",'') ||
		IFNULL("Brand",'') ||
		IFNULL("Standard",'') ||
		IFNULL("Turnover",'') ||
		IFNULL("MovementType",'') ||
		IFNULL("ProductPurpose",'')
	)))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
