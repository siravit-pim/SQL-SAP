/* parameter multiple condition */
// parameter can be blank about Date if more than 2 value, so make this method
// logic statement : DocDate > DueDate > min/max(date)

if HasValue({?DocDate}) AND HasUpperBound({?DocDate}) THEN 
    maximum({?DocDate}) 
else 
    if HasValue({?DueDate}) AND HasUpperBound({?DueDate}) THEN 
        maximum({?DueDate}) 
    else
        maximum({Command.INV_Date});
    


