using System;
using System.Windows;
using System.Windows.Controls;
using DiskPartitioner.Models;

namespace DiskPartitioner.Views
{
    public partial class WipeConfirmationDialog : Window
    {
        public bool Confirmed { get; private set; }

        public WipeConfirmationDialog(PhysicalDiskItem disk)
        {
            InitializeComponent();
            txtDiskInfo.Text = $"Target: Disk {disk.DiskIndex} - {disk.Model} ({disk.FormattedSize}, {disk.PartitionsCount} partitions)";

            Loaded += (s, e) => txtConfirmation.Focus();

            KeyDown += (s, e) =>
            {
                if (e.Key == System.Windows.Input.Key.Escape)
                {
                    e.Handled = true;
                    BtnCancel_Click(btnCancel, new RoutedEventArgs());
                }
                else if (e.Key == System.Windows.Input.Key.Enter)
                {
                    if (System.Windows.Input.Keyboard.FocusedElement is System.Windows.Controls.Button)
                    {
                        return;
                    }
                    if (btnClean.IsEnabled)
                    {
                        e.Handled = true;
                        BtnClean_Click(btnClean, new RoutedEventArgs());
                    }
                }
            };
        }

        private void TxtConfirmation_TextChanged(object sender, TextChangedEventArgs e)
        {
            btnClean.IsEnabled = string.Equals(txtConfirmation.Text.Trim(), "CONFIRM", StringComparison.OrdinalIgnoreCase);
        }

        private void BtnClean_Click(object sender, RoutedEventArgs e)
        {
            if (string.Equals(txtConfirmation.Text.Trim(), "CONFIRM", StringComparison.OrdinalIgnoreCase))
            {
                Confirmed = true;
                DialogResult = true;
                Close();
            }
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            Confirmed = false;
            DialogResult = false;
            Close();
        }
    }
}
