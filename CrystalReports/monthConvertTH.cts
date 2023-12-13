switch (
    month({PWHT.TaxDate})=1 ,"ม.ค.",
    month({PWHT.TaxDate})=2 ,"ก.พ.",
    month({PWHT.TaxDate})=3 ,"มี.ค.",
    month({PWHT.TaxDate})=4 ,"เม.ย.",
    month({PWHT.TaxDate})=5 ,"พ.ค.",
    month({PWHT.TaxDate})=6 ,"มิ.ย.",
    month({PWHT.TaxDate})=7 ,"ก.ค.",
    month({PWHT.TaxDate})=8 ,"ส.ค.",
    month({PWHT.TaxDate})=9 ,"ก.ย.",
    month({PWHT.TaxDate})=10 ,"ต.ค.",
    month({PWHT.TaxDate})=11 ,"พ.ย.",
    month({PWHT.TaxDate})=12 ,"ธ.ค."
    )
    -------------
    Year({PWHT.TaxDate})+543
