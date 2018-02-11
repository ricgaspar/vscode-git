' PwdLastSet.vbs
' VBScript program to retrieve password information for a user.
' This includes the date the password was last set, the domain maximum
' password age policy, and whether the user can change their password.
'
' ----------------------------------------------------------------------
' Copyright (c) 2002 Richard L. Mueller
' Hilltop Lab web site - http://www.rlmueller.net
' Version 1.0 - December 5, 2002
' Version 1.1 - March 7, 2003 - Standardize Hungarian notation.
' Version 1.2 - April 27, 2003 - Retrieve pwdLastSet from one DC.
' Version 1.3 - May 9, 2003 - Account for error in IADsLargeInteger
'                             property methods HighPart and LowPart.
' Version 1.4 - December 29, 2009 - Modify function Integer8Date.
'
' You have a royalty-free right to use, modify, reproduce, and
' distribute this script file in any way you find useful, provided that
' you agree that the copyright owner above has no warranty, obligations,
' or liability for such use.

Option Explicit

Dim objUser, strUserDN, objShell, lngBiasKey, lngBias, k
Dim objRootDSE, strDNSDomain, objDomain, objMaxPwdAge, intMaxPwdAge
Dim objDate, dtmPwdLastSet, lngFlag, blnPwdExpire, blnExpired
Dim lngHighAge, lngLowAge

Const ADS_UF_PASSWD_CANT_CHANGE = &H40
Const ADS_UF_DONT_EXPIRE_PASSWD = &H10000

' Hard code user Distinguished Name.
strUserDN = "CN=EYE0001,CN=Users,DC=nedcar,DC=nl"
Set objUser = GetObject("LDAP://" & strUserDN)

' Obtain local time zone bias from machine registry.
' This bias changes with Daylight Savings Time.
Set objShell = CreateObject("Wscript.Shell")
lngBiasKey = objShell.RegRead("HKLM\System\CurrentControlSet\Control\" _
    & "TimeZoneInformation\ActiveTimeBias")
If (UCase(TypeName(lngBiasKey)) = "LONG") Then
    lngBias = lngBiasKey
ElseIf (UCase(TypeName(lngBiasKey)) = "VARIANT()") Then
    lngBias = 0
    For k = 0 To UBound(lngBiasKey)
        lngBias = lngBias + (lngBiasKey(k) * 256^k)
    Next
End If

' Determine domain maximum password age policy in days.
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("DefaultNamingContext")
Set objDomain = GetObject("LDAP://" & strDNSDomain)
Set objMaxPwdAge = objDomain.MaxPwdAge

' Account for bug in IADslargeInteger property methods.
lngHighAge = objMaxPwdAge.HighPart
lngLowAge = objMaxPwdAge.LowPart
If (lngLowAge < 0) Then
    lngHighAge = lngHighAge + 1
End If
intMaxPwdAge = -((lngHighAge * 2^32) _
    + lngLowAge)/(600000000 * 1440)

' Retrieve user password information.
' The pwdLastSet attribute should always have a value assigned,
' but other Integer8 attributes representing dates could be "Null".
If (TypeName(objUser.pwdLastSet) = "Object") Then
    Set objDate = objUser.pwdLastSet
    dtmPwdLastSet = Integer8Date(objDate, lngBias)
Else
    dtmPwdLastSet = #1/1/1601#
End If
lngFlag = objUser.Get("userAccountControl")
blnPwdExpire = True
If ((lngFlag And ADS_UF_PASSWD_CANT_CHANGE) <> 0) Then
    blnPwdExpire = False
End If
If ((lngFlag And ADS_UF_DONT_EXPIRE_PASSWD) <> 0) Then
    blnPwdExpire = False
End If

' Determine if password expired.
blnExpired = False
If (blnPwdExpire = True) Then
    If (DateDiff("d", dtmPwdLastSet, Now()) > intMaxPwdAge) Then
        blnExpired = True
    End If
End If

' Display password information.
Wscript.Echo "User: " & strUserDN & vbCrLf & "Password last set: " _
    & dtmPwdLastSet & vbCrLf & "Maximum password age (days): " _
    & intMaxPwdAge & vbCrLf & "Can password expire? " & blnPwdExpire _
    & vbCrLf & "Password expired? " & blnExpired

Function Integer8Date(ByVal objDate, ByVal lngBias)
    ' Function to convert Integer8 (64-bit) value to a date, adjusted for
    ' local time zone bias.
    Dim lngAdjust, lngDate, lngHigh, lngLow
    lngAdjust = lngBias
    lngHigh = objDate.HighPart
    lngLow = objdate.LowPart
    ' Account for error in IADsLargeInteger property methods.
    If (lngLow < 0) Then
        lngHigh = lngHigh + 1
    End If
    If (lngHigh = 0) And (lngLow = 0) Then
        lngAdjust = 0
    End If
    lngDate = #1/1/1601# + (((lngHigh * (2 ^ 32)) _
        + lngLow) / 600000000 - lngAdjust) / 1440
    ' Trap error if lngDate is ridiculously huge.
    On Error Resume Next
    Integer8Date = CDate(lngDate)
    If (Err.Number <> 0) Then
        On Error GoTo 0
        Integer8Date = #1/1/1601#
    End If
    On Error GoTo 0
End Function

