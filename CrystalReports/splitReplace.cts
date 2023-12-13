/* split some information */
// split | first method
Split ({INV1.Dscription},"_")[1]
& chr(13) &
Split ({INV1.Dscription},"_")[-1]

// replace | secound method
Replace( {INV1.Dscription},"_" , chr(10) ) // can use chr(13) or chr(10)

// chr(10) | ASCII character code 10 | New Line or NL. ASCII
// chr(13) | ASCII character code 13 | Carriage Return or CR
// ref: https://www.petefreitag.com/blog/ascii-chr-10-chr-13
