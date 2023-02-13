// wanna split some information
// split
Split ({INV1.Dscription},"_")[1]
& chr(13) &
Split ({INV1.Dscription},"_")[-1]

// -------------------------------
// replace
//chr(13) or chr(10) like enter
Replace( {INV1.Dscription},"_" , chr(10) )
