// parameter can blank about Date if more than 2 value
// DocDate > DueDate > min/max(date)

IF HasValue({?DocDate}) and HasUpperBound({?DocDate}) then maximum({?DocDate}) else 
IF HasValue({?DueDate}) and HasUpperBound({?DueDate}) then maximum({?DueDate}) else
maximum({Command.INV_Date})
-----------------------------------
IF HasValue({?group@select* from oitb where Locked = 'N'}) 
and HasLowerBound({?group@select* from oitb where Locked = 'N'}) 
then minimum({?group@select* from oitb where Locked = 'N'}) else 
minimum({Command.Item Group})
