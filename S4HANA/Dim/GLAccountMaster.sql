WITH incremental AS (	
	WITH GroupGL AS (
		WITH Hry AS (
			SELECT *
			FROM HIERARCHY (
				SOURCE (
						SELECT HRYID, CONCAT(HRYID, HRYNODE) "NODE_ID" ,CONCAT(HRYID, PARNODE) "PARENT_ID", REPLACE(NODETXT,'_',' ') AS NODETXT
						FROM  SAPHANADB.hrrp_nodet 
						WHERE MANDT = '900' AND SPRAS = 'E' AND HRYID IN ('1100','1200') AND HRYVALTO = '99991231'
					)
					start where HRYNODE IN('01100','01200')
					sibling order by NODE_ID
					multiparent   
					orphan root  
					cycle breakup
				)
		) SELECT a.HRYID, gl."GLAccount", gl."GLAccountName",gl.HLevel, 	
				CASE
					WHEN gl.HLevel = '1' THEN gl."GLAccountName"
					ELSE substr_before(a.hry_structure,'~')
				END Level1,
				CASE
					WHEN gl.HLevel = '2' THEN gl."GLAccountName"
					ELSE SUBSTRING_REGEXPR('[^~]+' IN a.hry_structure OCCURRENCE 2)
				END Level2,
				CASE
					WHEN gl.HLevel = '3' THEN gl."GLAccountName"
					ELSE SUBSTRING_REGEXPR('[^~]+' IN a.hry_structure OCCURRENCE 3)
				END Level3,
				CASE
					WHEN gl.HLevel = '4' THEN gl."GLAccountName"
					ELSE SUBSTRING_REGEXPR('[^~]+' IN a.hry_structure OCCURRENCE 4)
				END Level4,
				CASE
					WHEN gl.HLevel = '5' THEN gl."GLAccountName"
					ELSE SUBSTRING_REGEXPR('[^~]+' IN a.hry_structure OCCURRENCE 5)
				END Level5,
				CASE
					WHEN gl.HLevel = '6' THEN gl."GLAccountName"
					ELSE SUBSTRING_REGEXPR('[^~]+' IN a.hry_structure OCCURRENCE 6)
				END Level6,
				CASE
					WHEN gl.HLevel = '7' THEN gl."GLAccountName"
					ELSE SUBSTRING_REGEXPR('[^~]+' IN a.hry_structure OCCURRENCE 7)
				END Level7,
				CASE
					WHEN gl.HLevel = '8' THEN gl."GLAccountName"
					ELSE SUBSTRING_REGEXPR('[^~]+' IN a.hry_structure OCCURRENCE 8)
				END Level8
			FROM (
					SELECT HRYID, node_id, hry_structure, HIERARCHY_LEVEL
				  	FROM hierarchy_ancestors_aggregate 
			  	(
			  		SOURCE Hry
					measures (
				     		string_agg(NODETXT, '~') as hry_structure
				     	) 
			) WHERE hierarchy_tree_size = 1  
		) a LEFT JOIN (
				SELECT CONCAT(node.HRYID, node.PARNODE) "parent", gl.TXT50 AS "GLAccountName",
					TRIM(LEADING '0' FROM gl.SAKNR) AS "GLAccount",
					TRIM(LEADING '0' FROM node.HRYLEVEL) AS HLevel
				FROM SAPHANADB.hrrp_node node
				JOIN SAPHANADB.SKAT gl ON node.NODEVALUE = gl.SAKNR and gl.KTOPL = '1000' AND gl.MANDT = '900' AND gl.SPRAS = 'E'
				WHERE node.MANDT = '900' AND node.HRYID IN ('1100','1200') AND node.HRYVALTO = '99991231' AND node.PARNODE <> '00NOTASSGND' AND node.NODETYPE = 'L'
			) gl ON gl."parent" = a.node_id
	) 
	SELECT *,
		-- provide the prefix-number for sort of group GL in BI, ** pls ask BI DEV first for change it
		CASE
			WHEN Level2 = 'Asset' THEN '1 Asset'
			WHEN Level2 = 'Liabilities and Shareholder''s Equity' THEN '2 Liabilities and Shareholder''s Equity'
			ELSE Level2
		END GroupReportLevel2,
		CASE
			WHEN Level3 = 'Current Asset' THEN '1 Current Asset'
			WHEN Level3 = 'Non Current Asset' THEN '2 Non-Current Asset'
			WHEN Level3 = 'Liabilities' THEN '1 Liabilities'
			WHEN Level3 = 'Shareholder''s Equities' THEN '2 Shareholder''s Equities'
			WHEN Level3 = 'Reveune' THEN '1 Reveune'
			WHEN Level3 = 'Expense' THEN '2 Expense'
			WHEN Level3 = 'Finance Cost' THEN '3 Finance Cost'
			WHEN Level3 = 'Corporate Income Tax' THEN '4 Corporate Income Tax'
			ELSE Level3
		END GroupReportLevel3,
		CASE
			WHEN Level4 = 'Sale Revenue' THEN '1 Sale Revenue'
			WHEN Level4 = 'Other Income' THEN '2 Other Income'
			WHEN Level4 = 'Unrealize Gain Loss on Exchange Rate' THEN '3 Unrealize Gain Loss on Exchange Rate'
			WHEN Level4 = 'Service Revenue' THEN '4 Service Revenue'
			WHEN Level4 = 'Cost of Goods Sold' THEN '1 Cost of Goods Sold'
			WHEN Level4 = 'Administrative Expense' THEN '2 Administrative Expense'
			WHEN Level4 = 'Selling Expense' THEN '3 Selling Expense'
			WHEN Level4 = 'Interest expenses-Trust Receipt' THEN '1 Interest expenses-Trust Receipt'
			WHEN Level4 = 'Interest expenses-Promissory Notes' THEN '2 Interest expenses-Promissory Notes'
			WHEN Level4 = 'Interest exp-Lease' THEN '3 Interest exp-Lease'
			WHEN Level4 = 'Bank Charges' THEN '4 Bank Charges'
			WHEN Level4 = 'Letter of Guarantee FEE' THEN '5 Letter of Guarantee FEE'
			WHEN Level4 = 'Deferred tax expense' THEN '1 Deferred tax expense'
			WHEN Level4 = 'Corporate Income Tax' THEN '2 Corporate Income Tax'
			ELSE Level4
		END GroupReportLevel4
	FROM GroupGL
	WHERE  "GLAccount" is not null
)
SELECT *,
	TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
	TO_DATE('9999-12-31') AS END_DATE,
	1 AS ACTIVE,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL(HRYID,'') ||
		IFNULL("GLAccount",'')
	)))) as NVARCHAR(32)) AS HASH_KEY,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
	    IFNULL(HRYID,'') ||
	    IFNULL("GLAccount",'') ||
		IFNULL("GLAccountName",'') ||
		IFNULL(HLevel,'') ||
		IFNULL(Level1,'') ||
		IFNULL(Level2,'') ||
		IFNULL(Level3,'') ||
		IFNULL(Level4,'') ||
		IFNULL(Level5,'') ||
		IFNULL(Level6,'') ||
		IFNULL(Level7,'') ||
		IFNULL(Level8,'')
	)))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
