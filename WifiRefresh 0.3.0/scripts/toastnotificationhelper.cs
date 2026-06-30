using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using Windows.Data.Xml.Dom;
using Windows.UI.Notifications;

class ToastNotificationHelper
{
    private static readonly PropertyKey AppUserModelIdPropertyKey = new PropertyKey(
        new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
        5);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int SetCurrentProcessExplicitAppUserModelID(string appID);

    static void Main(string[] args)
    {
        if (args.Length < 2)
        {
            Console.WriteLine("Usage: ToastNotificationHelper.exe <title> <message> [aumid]");
            return;
        }

        string title = args[0];
        string message = args[1];
        string aumid = args.Length > 2 ? args[2] : "WifiRefresh.Tool";

        try
        {
            EnsureStartMenuShortcut(aumid);
            SetCurrentProcessExplicitAppUserModelID(aumid);

            string toastXml = $@"
<toast>
    <visual>
        <binding template=""ToastText02"">
            <text id=""1"">{EscapeXml(title)}</text>
            <text id=""2"">{EscapeXml(message)}</text>
        </binding>
    </visual>
    <audio src=""ms-winsoundevent:Notification.Default"" />
</toast>";

            XmlDocument doc = new XmlDocument();
            doc.LoadXml(toastXml);

            ToastNotification toast = new ToastNotification(doc);
            ToastNotificationManager.CreateToastNotifier(aumid).Show(toast);

            Console.WriteLine("Toast displayed successfully");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            Environment.Exit(1);
        }
    }

    static void EnsureStartMenuShortcut(string appId)
    {
        try
        {
            string shortcutName = "WifiRefresh Toast Notification Helper.lnk";
            string startMenu = Environment.GetFolderPath(Environment.SpecialFolder.StartMenu);
            string programs = Path.Combine(startMenu, "Programs");
            Directory.CreateDirectory(programs);

            string executablePath = Assembly.GetExecutingAssembly().Location;
            string shortcutPath = Path.Combine(programs, shortcutName);

            Type shellLinkType = Type.GetTypeFromCLSID(new Guid("00021401-0000-0000-C000-000000000046"))
                ?? throw new InvalidOperationException("Shell link COM class is not available.");

            object shellLink = Activator.CreateInstance(shellLinkType)
                ?? throw new InvalidOperationException("Failed to create Shell link instance.");

            IShellLinkW shellLinkInterface = (IShellLinkW)shellLink;
            shellLinkInterface.SetPath(executablePath);
            shellLinkInterface.SetWorkingDirectory(Path.GetDirectoryName(executablePath) ?? string.Empty);
            shellLinkInterface.SetDescription("WifiRefresh toast notification helper");
            shellLinkInterface.SetArguments(string.Empty);
            shellLinkInterface.SetIconLocation(executablePath, 0);
            shellLinkInterface.SetShowCmd(1);

            IPersistFile persistFile = (IPersistFile)shellLink;
            persistFile.Save(shortcutPath, true);

            IPropertyStore propertyStore = (IPropertyStore)shellLink;
            PropertyKey propertyKey = AppUserModelIdPropertyKey;
            PropVariant propertyValue = new PropVariant(appId);
            propertyStore.SetValue(ref propertyKey, ref propertyValue);
            propertyStore.Commit();
            persistFile.Save(shortcutPath, true);
            propertyValue.Dispose();
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Shortcut registration failed: {ex.Message}");
        }
    }

    static string EscapeXml(string text)
    {
        return text
            .Replace("&", "&amp;")
            .Replace("<", "&lt;")
            .Replace(">", "&gt;")
            .Replace("\"", "&quot;")
            .Replace("'", "&apos;");
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PropertyKey
    {
        public Guid FormatId;
        public int PropertyId;

        public PropertyKey(Guid formatId, int propertyId)
        {
            FormatId = formatId;
            PropertyId = propertyId;
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PropVariant : IDisposable
    {
        public short ValueType;
        public short Reserved1;
        public short Reserved2;
        public short Reserved3;
        public IntPtr PointerValue;

        public PropVariant(string value)
        {
            ValueType = (short)VarEnum.VT_LPWSTR;
            Reserved1 = 0;
            Reserved2 = 0;
            Reserved3 = 0;
            PointerValue = Marshal.StringToCoTaskMemUni(value);
        }

        public void Dispose()
        {
            if (PointerValue != IntPtr.Zero)
            {
                Marshal.FreeCoTaskMem(PointerValue);
                PointerValue = IntPtr.Zero;
            }
        }
    }

    [ComImport]
    [Guid("000214F9-0000-0000-C000-000000000046")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IShellLinkW
    {
        int GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cch, IntPtr pfd, int fFlags);
        int GetIDList(out IntPtr ppidl);
        int SetIDList(IntPtr pidl);
        int GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cch);
        int SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        int GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cch);
        int SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
        int GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cch);
        int SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
        int GetHotkey(out short pwHotkey);
        int SetHotkey(short wHotkey);
        int GetShowCmd(out int piShowCmd);
        int SetShowCmd(int iShowCmd);
        int GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cch, out int piIcon);
        int SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
        int SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, int dwReserved);
        int Resolve(IntPtr hwnd, int fFlags);
        int SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
    }

    [ComImport]
    [Guid("0000010B-0000-0000-C000-000000000046")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPersistFile
    {
        [PreserveSig]
        int GetCurFile([Out, MarshalAs(UnmanagedType.LPWStr)] out string pszFile);
        [PreserveSig]
        int IsDirty();
        [PreserveSig]
        int Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, uint dwMode);
        [PreserveSig]
        int Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, [MarshalAs(UnmanagedType.Bool)] bool fRemember);
        [PreserveSig]
        int SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
    }

    [ComImport]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPropertyStore
    {
        [PreserveSig]
        int GetCount(out uint propertyCount);
        [PreserveSig]
        int GetAt(uint propertyIndex, out PropertyKey propertyKey);
        [PreserveSig]
        int GetValue(ref PropertyKey key, out PropVariant value);
        [PreserveSig]
        int SetValue(ref PropertyKey key, ref PropVariant value);
        [PreserveSig]
        int Commit();
    }
}