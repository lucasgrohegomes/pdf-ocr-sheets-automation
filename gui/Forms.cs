using System;
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;

namespace OcrRunner
{
    public class MainForm : Form
    {
        private TextBox txtFolder = new TextBox { Left = 12, Top = 12, Width = 360 };
        private Button btnBrowse = new Button { Left = 380, Top = 10, Width = 80, Text = "Buscar..." };
        private Button btnRun = new Button { Left = 12, Top = 42, Width = 448, Height = 30, Text = "Iniciar Processo" };
        private TextBox txtLog = new TextBox { 
            Left = 12, Top = 80, Width = 448, Height = 260, 
            Multiline = true, ScrollBars = ScrollBars.Vertical, ReadOnly = true, 
            BackColor = Color.Black, ForeColor = Color.LightGreen, Font = new Font("Consolas", 9.0f) 
        };

        public MainForm()
        {
            Text = "Executor OCR";
            Size = new Size(488, 385);
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;

            Controls.AddRange(new Control[] { txtFolder, btnBrowse, btnRun, txtLog });

            btnBrowse.Click += (s, e) => {
                using (var fbd = new FolderBrowserDialog())
                    if (fbd.ShowDialog() == DialogResult.OK) txtFolder.Text = fbd.SelectedPath;
            };

            btnRun.Click += (s, e) => RunScript();
        }

        private void RunScript()
        {
            if (string.IsNullOrWhiteSpace(txtFolder.Text))
            {
                MessageBox.Show("Selecione uma pasta válida.", "Aviso", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            btnRun.Enabled = false;
            txtLog.Clear();

            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = string.Format("-ExecutionPolicy Bypass -File \"..\\scripts\\Main.ps1\" -DirPath \"{0}\"", txtFolder.Text),
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            var proc = new Process { StartInfo = psi, EnableRaisingEvents = true };
            
            proc.OutputDataReceived += (s, e) => AppendLog(e.Data);
            proc.ErrorDataReceived += (s, e) => AppendLog(e.Data);
            
            proc.Exited += (s, e) => {
                AppendLog("\n=== PROCESSO FINALIZADO ===");
                Invoke(new Action(() => btnRun.Enabled = true));
                proc.Dispose();
            };

            proc.Start();
            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();
        }

        private void AppendLog(string message)
        {
            if (message == null) return;
            if (InvokeRequired) { Invoke(new Action(() => AppendLog(message))); return; }
            txtLog.AppendText(message + Environment.NewLine);
        }

        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.Run(new MainForm());
        }
    }
}