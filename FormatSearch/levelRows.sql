/* Can calculate with 2 method and can use decalare in FS, it's STD */
-- first method
SELECT $[$38.234000373.Number] - $[$38.34.Number]

-- second method
Declare @Price1 as Money
Declare @Price2 as Money
SET @Price1 = (SELECT $[$38.U_TEST1.number])
SET @Price2 = (SELECT $[$38.U_TEST2.number])
SELECT @Price1 * @Price2
