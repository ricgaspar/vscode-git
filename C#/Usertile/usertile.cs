using System;
using System.Runtime.InteropServices;
 
namespace FejesJoco
{
    class Program
    {
        [DllImport("shell32.dll", EntryPoint = "#262", CharSet = CharSet.Unicode, PreserveSig = false)]
        public static extern void SetUserTile(string username, int whatever, string picpath);
 
        [STAThread]
        static void Main(string[] args)
        {
            SetUserTile(args[0], 0, args[1]);
        }
    }
}