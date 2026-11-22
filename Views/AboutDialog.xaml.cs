using System.Reflection;
using System.Windows;
using DiskPartitioner.Helpers;

namespace DiskPartitioner.Views
{
    public partial class AboutDialog : Window
    {
        public AboutDialog()
        {
            InitializeComponent();

            var ver = typeof(AboutDialog).Assembly.GetName().Version;
            string versionStr = ver != null ? $"{ver.Major}.{ver.Minor}.{ver.Build}" : "1.0.3";
            string storeSuffix = PackageHelper.IsStorePackage() ? " (Microsoft Store)" : "";
            txtVersion.Text = $"Version {versionStr}{storeSuffix} by Accessible Tools";

            Loaded += (s, e) => btnClose.Focus();

            KeyDown += (s, e) =>
            {
                if (e.Key == System.Windows.Input.Key.Escape || e.Key == System.Windows.Input.Key.Enter)
                {
                    e.Handled = true;
                    Close();
                }
            };
        }

        private void BtnClose_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}
