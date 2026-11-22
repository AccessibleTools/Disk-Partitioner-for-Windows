using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows;
using DiskPartitioner.Helpers;

namespace DiskPartitioner
{
    public partial class App : Application
    {
        private const string MutexName = @"Global\DiskPartitioner_SingleInstance_Mutex";
        private static Mutex? _mutex;
        private static bool _ownsMutex = false;

        protected override void OnStartup(StartupEventArgs e)
        {
            // Initialize process-level DLL security hardening (Microsoft SDL / CWE-427)
            NativeMethods.InitializeProcessSecurity();

            DispatcherUnhandledException += (s, args) =>
            {
                try
                {
                    string logPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DiskPartitioner_crash.log");
                    File.AppendAllText(logPath, $"[{DateTime.Now}] Dispatcher Exception: {args.Exception}\n");
                }
                catch { }
                args.Handled = true;
            };

            AppDomain.CurrentDomain.UnhandledException += (s, args) =>
            {
                try
                {
                    string logPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DiskPartitioner_crash.log");
                    File.AppendAllText(logPath, $"[{DateTime.Now}] AppDomain Exception: {args.ExceptionObject}\n");
                }
                catch { }
            };

            bool isNewInstance = false;
            try
            {
                _mutex = new Mutex(true, MutexName, out isNewInstance);
                _ownsMutex = isNewInstance;
            }
            catch (AbandonedMutexException)
            {
                _ownsMutex = true;
                isNewInstance = true;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Mutex creation error: {ex.Message}");
                _ownsMutex = false;
            }

            if (!isNewInstance)
            {
                MessageBox.Show("Disk Partitioner for Windows is already running.", "Disk Partitioner for Windows", MessageBoxButton.OK, MessageBoxImage.Information);
                Shutdown();
                return;
            }

            base.OnStartup(e);
        }

        protected override void OnExit(ExitEventArgs e)
        {
            if (_ownsMutex && _mutex != null)
            {
                try
                {
                    _mutex.ReleaseMutex();
                    _mutex.Dispose();
                }
                catch { }
            }
            base.OnExit(e);
        }
    }
}
