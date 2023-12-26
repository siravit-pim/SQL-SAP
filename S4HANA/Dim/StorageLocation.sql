WITH incremental AS (
    SELECT 
        WERKS "Plant",
        LGORT "StorageLocation",
        LGOBE "StorageLocationDesc"
    FROM SAPHANADB.T001L 
    WHERE MANDT = 900 
)
SELECT *,
    TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
    TO_DATE('9999-12-31') AS END_DATE,
    1 AS ACTIVE,
    CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
        IFNULL("Plant",'') || 
        IFNULL("StorageLocation",'')
    )))) as NVARCHAR(32)) AS HASH_KEY,
    CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
        IFNULL("Plant",'') || 
        IFNULL("StorageLocation",'') ||
        IFNULL("StorageLocationDesc",'')
    )))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
