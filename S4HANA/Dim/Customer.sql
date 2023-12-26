WITH incremental AS (
	WITH main AS (
		SELECT
		    A.LAND1 AS "Country",  
		    C.VTWEG AS "DistChannelCode", C9.VTEXT AS "DistChannel",
			TRIM(LEADING '0' FROM A.KUNNR) AS "CusCode",
			A.NAME1 || ' ' || A.NAME2 AS "CusName",
			A.KTOKD AS "CusTypeCode",
			A.REGIO AS "ProvinceCode",
			B.BEZEI AS "Province",
			A.ORT01 AS "District",
			A.ORT02 AS "SubDistrict",
			A.PSTLZ AS "PostCode",
			C.KDGRP AS "CusGroupCode", CC.KTEXT AS "CusGroup", --typeBP
		    C.kvgr1 as "CusGroup1Code", C1.bezei AS "CusGroup1", --typeBP1
    		C.kvgr2 as "CusGroup2Code", C2.bezei AS "CusGroup2", --typeBP2
			C.kvgr3 as "CusGroup3Code", C3.bezei AS "CusGroup3", --Focus
            C.kvgr4 as "CusGroup4Code", C4.bezei AS "CusGroup4", --grade
            C.kvgr5 as "CusGroup5Code", C5.bezei AS "CusGroup5", --commision
            C.vkbur as "SalesOfficeCode", S9.bezei AS "SalesOffice",
			C.BZIRK as "SalesDistrictCode",	S3.BZTXT AS "SalesDistrict",
			C.VKGRP as "SalesGroupCode", S2.BEZEI AS "SalesGroup",
			CAST(A.ERDAT as DATE) as "CusCreateDate",
			LTRIM(EMP.LIFNR,'0') AS "EmpCode",
			EMP.NAME1 || ' ' || EMP.NAME2 AS "EmpName",
			CAST(EMP.ERDAT as DATE) as "EmpCreateDate"
		FROM "SAPHANADB".KNA1 A
		INNER JOIN "SAPHANADB".KNVV C ON C.KUNNR = A.KUNNR AND (C."MANDT" = 900 and C."SPART" = '00' and C."VTWEG" ='10' and C."VKORG" ='1000')
		INNER JOIN "SAPHANADB".KNVP D ON D.KUNNR = A.KUNNR AND C.VKORG = D.VKORG AND C.VTWEG = D.VTWEG AND C.SPART = D.SPART AND (D.MANDT= 900 AND D.PARVW='Z1' AND D.PARZA='000')
		INNER JOIN "SAPHANADB".T005U B ON B.LAND1 = A.LAND1 AND B.BLAND = A.REGIO AND ( B.SPRAS = 'E' AND B.MANDT = 900)
		LEFT JOIN "SAPHANADB".LFA1 EMP ON EMP.LIFNR = D.LIFNR AND (EMP."MANDT" = 900 AND EMP."KTOKK" = 'Z004')
		LEFT JOIN "SAPHANADB".T151T CC ON C.KDGRP = CC.KDGRP AND (CC.SPRAS = 'E' AND CC."MANDT" = 900)
		LEFT JOIN "SAPHANADB".TVV1T C1 ON C.KVGR1 = C1.KVGR1 AND (C1.SPRAS = 'E' AND C1."MANDT" = 900)
		LEFT JOIN "SAPHANADB".TVV2T C2 ON C.KVGR2 = C2.KVGR2 AND (C2.SPRAS = 'E' AND C2."MANDT" = 900)
		LEFT JOIN "SAPHANADB".TVV3T C3 ON C.KVGR3 = C3.KVGR3 AND (C3.SPRAS = 'E' AND C3."MANDT" = 900)
		LEFT JOIN "SAPHANADB".TVV4T C4 ON C.KVGR4 = C4.KVGR4 AND (C4.SPRAS = 'E' AND C4."MANDT" = 900)
		LEFT JOIN "SAPHANADB".TVV5T C5 ON C.KVGR5 = C5.KVGR5 AND (C5.SPRAS = 'E' AND C5."MANDT" = 900)
		LEFT JOIN "SAPHANADB".TVGRT S2 ON C.VKGRP = S2.VKGRP AND (S2.SPRAS = 'E' AND S2."MANDT" = 900)
		LEFT JOIN "SAPHANADB".T171T S3 ON C.BZIRK = S3.BZIRK AND (S3.SPRAS = 'E' AND S3."MANDT" = 900)
		LEFT JOIN "SAPHANADB".TVTWT C9 ON C.VTWEG = C9.VTWEG AND C9.SPRAS = 'E'
		LEFT JOIN "SAPHANADB".TVKBT S9 ON C.vkbur = S9.vkbur AND S9.spras = 'E'
		WHERE A.MANDT = 900 AND A.KTOKD != 'Z008'
	) 
	select DISTINCT -- dup cause `Divisions`
	    * 
	from main
)
SELECT *,
	TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
	TO_DATE('9999-12-31') AS END_DATE,
	1 AS ACTIVE,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("CusCode",'')
	)))) as NVARCHAR(32)) AS HASH_KEY,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("Country",'') ||
		IFNULL("DistChannelCode",'') ||
		IFNULL("DistChannel",'') ||
		IFNULL("CusCode",'') ||
		IFNULL("CusName",'') ||
		IFNULL("CusTypeCode",'') ||
		IFNULL("ProvinceCode",'') ||
		IFNULL("Province",'') ||
		IFNULL("District",'') ||
		IFNULL("SubDistrict",'') ||
		IFNULL("PostCode",'') ||
		IFNULL("CusGroupCode",'') ||
		IFNULL("CusGroup",'') ||
		IFNULL("CusGroup1Code",'') ||
		IFNULL("CusGroup1",'') ||
		IFNULL("CusGroup2Code",'') ||
		IFNULL("CusGroup2",'') ||
		IFNULL("CusGroup3Code",'') ||
		IFNULL("CusGroup3",'') ||
		IFNULL("CusGroup4Code",'') ||
		IFNULL("CusGroup4",'') ||
		IFNULL("CusGroup5Code",'') ||
		IFNULL("CusGroup5",'') ||
		IFNULL("SalesOfficeCode",'') ||
		IFNULL("SalesOffice",'') ||
		IFNULL("SalesDistrictCode",'') ||
		IFNULL("SalesDistrict",'') ||
		IFNULL("SalesGroupCode",'') ||
		IFNULL("SalesGroup",'') ||
		IFNULL("CusCreateDate",'') ||
		IFNULL("EmpCode",'') ||
		IFNULL("EmpName",'') ||
		IFNULL("EmpCreateDate",'')
	)))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental 
