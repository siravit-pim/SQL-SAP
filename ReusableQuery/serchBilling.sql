-- Search billing by specify document number
select
    [@Bill].DocNum 'BillNo',
    [@Bill1].U_RefDocNum 'DucumentNo',
    case
        when [@Bill1].U_RefDocType = '13' then 'Inv'
        when [@Bill1].U_RefDocType = '12' then 'DP'
        when [@Bill1].U_RefDocType = '14' then 'CN'
    END 'DocType',
    orct.DocNum 'IncomingNo'
from [@Bill1]
    left join [@Bill] on [@Bill].DocEntry = [@Bill1].DocEntry
    LEFT JOIN (
        SELECT
            DocEntry,
            ObjType,
            DocNum
        FROM OINV   
        where  OINV.canceled = 'N'
    		UNION ALL
        SELECT
            DocEntry,
            ObjType,
            DocNum
        FROM ORIN
        where ORIN.canceled = 'N'
    		UNION ALL
        SELECT
            DocEntry,
            ObjType,
            DocNum
        FROM ODPI
        where ODPI.canceled = 'N'
    ) Doc ON [@Bill1].U_RefDocType = Doc.ObjType AND [@Bill1].U_RefDocNum = Doc.DocNum
    left join rct2 on rct2.DocEntry = Doc.DocEntry and rct2.InvType = [@Bill1].U_RefDocType
    left join orct on rct2.DocNum = orct.DocEntry
where [@Bill].Canceled = 'N' 
	--specify clearly :
    --and Doc.DocNum		= '641001743' --'Inv/Down/CN'
    --and [@Bill].DocNum	= '122030003' --'Bill'
    --and orct.DocNum		= '122030034' --'Incoming'
