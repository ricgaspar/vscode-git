function ConvertTo-KMSStatus
{
	[cmdletbinding()]
	Param(
		[Parameter(mandatory=$true)]
		[int]$StatusCode
	)
	switch -exact ($StatusCode)
	{
		0		{"Unlicensed"}
		1		{"Licensed"}
		2		{"OOBGrace"}
		3		{"OOTGrace"}
		4		{"NonGenuineGrace"}
		5		{"Notification"}
		6		{"ExtendedGrace"}
		default {"Unknown"}
	}
}