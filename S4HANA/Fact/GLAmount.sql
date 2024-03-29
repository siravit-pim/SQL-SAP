SELECT A.HRYID,
    B.FISCALYEAR "Year",
    B.CALENDARYEARMONTH AS "YearMonth",
    B.CALENDARQUARTER "Quarter",
    B.CALENDARMONTH "Month",
    a."GLAccount" as "GLAccountCode",
    SUM(b.AMOUNT) AS "Amount"
FROM "xxxxx"."DimGLAccountMaster" A
LEFT JOIN SAPHANADB.ZPAMTGL B ON A."GLAccount" = LTRIM(B.GLACCOUNT, '0')
GROUP BY A.HRYID,B.FISCALYEAR, B.CALENDARYEARMONTH, B.CALENDARQUARTER, B.CALENDARMONTH, a."GLAccount" 
