---- address JDT1 that connection
SELECT 		Concat( Concat( Concat( Concat( Concat( Concat(Concat(Concat(Concat(Concat( Concat(
				CASE 
					WHEN IFNULL($[JDT1.U_BUILDING.0], '') = '' THEN '' 
					ELSE Concat(N' อาคาร',$[JDT1.U_BUILDING.0])
				END
				,CASE 
					WHEN IFNULL($[JDT1.U_VILLAGE.0], '') = '' THEN '' 
					ELSE Concat(N' หมู่บ้าน', $[JDT1.U_VILLAGE.0])
				END) 
				,CASE 
					WHEN IFNULL($[JDT1.U_ROOMNO.0], '') = '' THEN '' 
					ELSE Concat(N' ห้องเลขที่ ', $[JDT1.U_ROOMNO.0])
				END) 
				,CASE 
					WHEN IFNULL($[JDT1.U_FLOORNO.0], '') = '' THEN '' 
					ELSE Concat(N' ชั้นที่ ', $[JDT1.U_FLOORNO.0])
				END)
				,CASE WHEN IFNULL($[JDT1.U_HOMENO.0], '') = '' THEN '' 
					ELSE Concat(N' เลขที่ ', $[JDT1.U_HOMENO.0])
				END) 
				,CASE 
					WHEN IFNULL($[JDT1.U_BLOCK.0], '') = '' THEN '' 
					ELSE Concat(N' หมู่ที่ ', $[JDT1.U_BLOCK.0])
				END)
				,CASE 
					WHEN IFNULL($[JDT1.U_SUBSTREET.0], '') = '' THEN '' 
					ELSE Concat(N' ซอย ', $[JDT1.U_SUBSTREET.0])
				END)
				,CASE
					WHEN IFNULL($[JDT1.U_STREET.0], '') = '' THEN '' 
					ELSE Concat(N' ถนน', $[JDT1.U_STREET.0]) 
				END)
				------------------
					,CASE 						WHEN IFNULL($[JDT1.U_City.0], '') = '' THEN '' 						ELSE ' ' || $[JDT1.U_City.0]					END)
					,CASE 						WHEN IFNULL($[JDT1.U_County.0], '') = '' THEN '' 						ELSE ' ' || $[JDT1.U_County.0]
					END)
										,CASE						WHEN IFNULL($[JDT1.U_State.0], '') = '' THEN '' 						WHEN left(IFNULL($[JDT1.U_STATE.0], ''),7) = N'กรุงเทพ' THEN ' ' || N'กรุงเทพ'
						WHEN left(IFNULL($[JDT1.U_STATE.0], ''),3) = N'กทม' THEN ' ' || N'กรุงเทพ'
						WHEN left(IFNULL($[JDT1.U_STATE.0], ''),3) = N'BKK' THEN ' ' || N'กรุงเทพ'						ELSE  Concat(N' จังหวัด',$[JDT1.U_State.0])					END)					,CASE 						WHEN IFNULL($[JDT1.U_ZipCode.0], '') = '' THEN '' 						ELSE ' ' || $[JDT1.U_ZipCode.0]					END)
				---------------------
			
FROM 			DUMMY
