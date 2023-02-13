// parameter can blank about Date if more than 2 value
// DocDate > DueDate > min/max(date)

IF HasValue({?DocDate}) and HasLowerBound({?DocDate}) then minimum({?DocDate}) else 
IF HasValue({?DueDate}) and HasLowerBound({?DueDate}) then minimum({?DueDate}) else
minimum({Command.INV_Date})
