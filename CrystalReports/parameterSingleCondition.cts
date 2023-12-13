// parameter single condition
// ex.1
if HasValue({?Docnum}) THEN
    {Command.DocNum}={?Docnum}
else
    TRUE

// ex.2
----------------------------------
if HasValue({?group@select* from oitb where Locked = 'N'}) AND HasLowerBound({?group@select* from oitb where Locked = 'N'}) THEN 
    minimum({?group@select* from oitb where Locked = 'N'}) 
else 
    minimum({Command.Item_Group})
