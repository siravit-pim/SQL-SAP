--information Batch with Qty
select
    T0.Itemcode,
    T0.ItemName,
    OBTQ.Quantity,
    OBTQ.WhsCode,
    T0.MnfDate,
    T0.ExpDate,
    T0.DistNumber,
    T0.MnfSerial,
    OITM.InvntryUom
from obtn T0
    join OBTQ on (OBTQ.Quantity > 0) and T0.Itemcode = OBTQ.ItemCode
        and (
            T0.SysNumber = OBTQ.SysNumber and T0.AbsEntry = OBTQ.MdAbsEntry
        )
    left join OITM on T0.ItemCode = OITM.ItemCode
order by 1, DistNumber, MnfSerial
