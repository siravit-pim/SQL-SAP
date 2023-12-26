SELECT 
    CAST(CALENDARDATE AS DATE) AS "Date", CALENDARYEAR AS "Year", CALENDARQUARTER AS "Quarter",
    CALENDARMONTH AS "Month", CALENDARWEEK AS "Week", CALENDARDAY AS "Day", WEEKDAY AS "WeekDay",
    YEARQUARTER AS "YearQuarter", YEARMONTH AS "YearMonth", YEARWEEK AS "YearWeek",
    CASE 
        WHEN CALENDARMONTH = '01' THEN 'January'
        WHEN CALENDARMONTH = '02' THEN 'February'
        WHEN CALENDARMONTH = '03' THEN 'March'
        WHEN CALENDARMONTH = '04' THEN 'April'
        WHEN CALENDARMONTH = '05' THEN 'May'
        WHEN CALENDARMONTH = '06' THEN 'June'
        WHEN CALENDARMONTH = '07' THEN 'July'
        WHEN CALENDARMONTH = '08' THEN 'August'
        WHEN CALENDARMONTH = '09' THEN 'September'
        WHEN CALENDARMONTH = '10' THEN 'October'
        WHEN CALENDARMONTH = '11' THEN 'November'
        WHEN CALENDARMONTH = '12' THEN 'December'
    END "MonthName_EN",
    CASE 
        WHEN CALENDARMONTH = '01' THEN N'มกราคม'
        WHEN CALENDARMONTH = '02' THEN N'กุมภาพันธ์'
        WHEN CALENDARMONTH = '03' THEN N'มีนาคม'
        WHEN CALENDARMONTH = '04' THEN N'เมษายน'
        WHEN CALENDARMONTH = '05' THEN N'พฤษภาคม'
        WHEN CALENDARMONTH = '06' THEN N'มิถุนายน'
        WHEN CALENDARMONTH = '07' THEN N'กรกฎาคม'
        WHEN CALENDARMONTH = '08' THEN N'สิงหาคม'
        WHEN CALENDARMONTH = '09' THEN N'กันยายน'
        WHEN CALENDARMONTH = '10' THEN N'ตุลาคม'
        WHEN CALENDARMONTH = '11' THEN N'พฤศจิกายน'
        WHEN CALENDARMONTH = '12' THEN N'ธันวาคม'
    END "MonthName_TH",
    CASE 
        WHEN WEEKDAY = '1' THEN 'Monday'
        WHEN WEEKDAY = '2' THEN 'Tuesday'
        WHEN WEEKDAY = '3' THEN 'Wednesday'
        WHEN WEEKDAY = '4' THEN 'Thursday'
        WHEN WEEKDAY = '5' THEN 'Friday'
        WHEN WEEKDAY = '6' THEN 'Saturday'
        WHEN WEEKDAY = '7' THEN 'Sunday'
    END "WeekDayName_EN",
    CASE 
        WHEN WEEKDAY = '1' THEN N'จันทร์'
        WHEN WEEKDAY = '2' THEN N'อังคาร'
        WHEN WEEKDAY = '3' THEN N'พุธ'
        WHEN WEEKDAY = '4' THEN N'พฤหัสบดี'
        WHEN WEEKDAY = '5' THEN N'ศุกร์'
        WHEN WEEKDAY = '6' THEN N'เสาร์'
        WHEN WEEKDAY = '7' THEN N'อาทิตย์'
    END "WeekDayName_TH"
FROM "SAPHANADB".SCAL_TT_DATE
WHERE CALENDARYEAR >= 2010 and CALENDARYEAR <= YEAR(CURRENT_TIMESTAMP)
