using System; 
using System.Collections.Generic; 
using System.Text; 
using System.Runtime.InteropServices; 
public class ProfileAPI{ 
     
    [DllImport("kernel32.dll")] 
    public static extern bool WriteProfileSection( 
        string lpAppName,  
        string lpString); 
     
    [DllImport("kernel32.dll")] 
    public static extern bool WriteProfileString( 
        string lpAppName, 
        string lpKeyName, 
        string lpString); 
     
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] 
    [return: MarshalAs(UnmanagedType.Bool)] 
    public static extern bool WritePrivateProfileString( 
        string lpAppName, 
        string lpKeyName,  
        string lpString,  
        string lpFileName); 
     
    [DllImport("kernel32.dll")] 
    public static extern uint GetPrivateProfileSectionNames( 
        long lpReturnBuffer, 
        uint nSize,  
        string lpFileName); 
     
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] 
    public static extern uint GetPrivateProfileString(  
        string lpAppName,  
        string lpKeyName,  
        string lpDefault,  
        StringBuilder lpReturnedString,  
        uint nSize,  
        string lpFileName);  
         
} 