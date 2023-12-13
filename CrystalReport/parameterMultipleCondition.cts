/* parameter multiple condition */
// parameter can be blank about Date if more than 2 value, so make this method
// logic statement : DocDate > DueDate > min/max(date)

IF HasValue({?DocDate}) AND HasUpperBound({?DocDate}) THEN 
    maximum({?DocDate}) 
ELSE 
    IF HasValue({?DueDate}) AND HasUpperBound({?DueDate}) THEN 
        maximum({?DueDate}) 
    ELSE
        maximum({Command.INV_Date});
    


