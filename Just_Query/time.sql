-- Time ex. 00:00
CASE WHEN T4.TrsfrTime = 0 THEN '' 
ELSE CASE WHEN T4.TrsfrTime <= 999 THEN '0'+LEFT(T4.TrsfrTime,1)+':'+RIGHT(T4.TrsfrTime,2)
		ELSE LEFT(T4.TrsfrTime,2)+':'+RIGHT(T4.TrsfrTime,2) 
	END 
END 'TransferTime'
