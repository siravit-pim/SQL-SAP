-- When stock > 0 and only group can't change
if @object_Type = '4'
and @transaction_type = 'U' begin if Exists (
    SELECT
        OITM.itemcode,
        OITM.OnHand
    FROM OITM
        join (
            select
                A.itemcode,
                A.ItmsGrpCod,
                A.LogInstanc
            from AITM A
                right join (
                    select
                        itemcode,
                        max(LogInstanc) 'Logg'
                    from AITM
                    group by
                        itemcode
                ) lastGroup on lastGroup.logg = A.LogInstanc
                and lastGroup.itemcode = A.itemcode
        ) A on A.ItemCode = OITM.ItemCode
    WHERE
        OITM.OnHand > 0
        and OITM.ItmsGrpCod <> A.ItmsGrpCod
        AND OITM.ItemCode = @list_of_cols_val_tab_del
) BEGIN
SET
    @ERROR = '2'
SET
    @ERROR_MESSAGE = 'You can not update of item group if there is a stock '
END
END
