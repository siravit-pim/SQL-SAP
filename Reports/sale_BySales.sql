select
    DocEntry,
    docnum,
    DocDate,
    SlpCode,
    SlpName,
    cardcode,
    cardname,
    sum(net) 'Net'
from (
        select
            oinv.docnum,
            oinv.DocEntry,
            oinv.CardCode,
            oinv.CardName,
            oslp.SlpCode,
            oslp.SlpName,
            OINV.DocDate,
            (INV.Total - OINV.DiscSum) 'net'
        from oinv
            left join OSLP on oinv.SlpCode = oslp.SlpCode
            INNER JOIN (
                select
                    Docentry,
                    sum(linetotal) 'Total'
                FROM INV1
                GROUP BY Docentry
            ) INV ON OINV.DocEntry = INV.DocEntry
        where oinv.CANCELED = 'N'
        union all
        select
            orin.docnum,
            orin.DocEntry,
            orin.CardCode,
            orin.CardName,
            oslp.SlpCode,
            OSLP.SlpName,
            orin.DocDate,
            (- RIN.Total + ORIN.DiscSum) 'net'
        from orin
            left join OSLP on orin.SlpCode = oslp.SlpCode
            INNER JOIN (
                select
                    Docentry,
                    BaseType,
                    sum(linetotal) 'Total'
                FROM RIN1
                GROUP BY Docentry, BaseType
            ) RIN ON ORIN.DocEntry = RIN.DocEntry
            AND RIN.BaseType <> '203'
        where ORIN.CANCELED = 'N'
    ) a
where a.DocDate BETWEEN { ? DateFrom } and { ? DateTo }
group by DocEntry, docnum, DocDate, SlpCode, SlpName, cardcode, cardname
