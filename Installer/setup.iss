; Inno Setup 6 Script for Disk Partitioner for Windows
; Accessible Tools Suite - https://github.com/AccessibleTools/Disk-Partitioner-for-Windows
#define MyAppName "Disk Partitioner for Windows"
#define MyAppVersion "1.0.3"
#define MyAppPublisher "Accessible Tools"
#define MyAppURL "https://github.com/AccessibleTools/Disk-Partitioner-for-Windows"
#define MyAppExeName "DiskPartitioner.exe"

[Setup]
; Unique GUID for Disk Partitioner for Windows
AppId={{8B84F074-686E-4547-8B52-327A79D20EF1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Disk Partitioner for Windows
UsePreviousAppDir=no
DirExistsWarning=no
DefaultGroupName=Accessible Tools\{#MyAppName}
DisableProgramGroupPage=yes
DisableReadyPage=yes
OutputDir=Output
OutputBaseFilename=DiskPartitioner_Setup_v1.0.3
SetupIconFile=..\Resources\app.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
CloseApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
UninstallDisplayNameMark=%1
UninstallDisplayNameMarks=%1

[Files]
Source: "..\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
Type: files; Name: "{commondesktop}\{#MyAppName}.lnk"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Check: ShouldCreateDesktopIcon

[Registry]
; Daily auto-update check setting configured from installer
Root: HKCU; Subkey: "Software\AccessibleTools\DiskPartitioner"; ValueType: dword; ValueName: "AutoCheckUpdates"; ValueData: 1; Check: ShouldAutoUpdate; Flags: uninsdeletevalue
; Unconditionally delete all registry keys and values for Disk Partitioner on uninstall without asking
Root: HKCU; Subkey: "Software\AccessibleTools\DiskPartitioner"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\AccessibleTools"; Flags: uninsdeletekeyifempty

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent shellexec

[UninstallDelete]
Type: files; Name: "{commondesktop}\{#MyAppName}.lnk"
Type: files; Name: "{localappdata}\DiskPartitioner_crash.log"
Type: filesandordirs; Name: "{app}"

[Code]
var
  DesktopIconCheck: TNewCheckBox;
  AutoUpdateCheck: TNewCheckBox;
  PrivacyPolicyBtn: TNewButton;

procedure PrivacyPolicyClick(Sender: TObject);
var
  ResultCode: Integer;
begin
  ShellExec('open', 'https://gist.github.com/AakanshNahadiya/4d4f4abe3878de9c43ff9d9b3b7c9ee3', '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
end;

function ShouldCreateDesktopIcon(): Boolean;
begin
  Result := (DesktopIconCheck <> nil) and DesktopIconCheck.Checked;
end;

function ShouldAutoUpdate(): Boolean;
begin
  Result := (AutoUpdateCheck <> nil) and AutoUpdateCheck.Checked;
end;

procedure InitializeWizard();
begin
  // Embed desktop shortcut option directly on the destination directory selection page
  DesktopIconCheck := TNewCheckBox.Create(WizardForm);
  DesktopIconCheck.Parent := WizardForm.SelectDirPage;
  DesktopIconCheck.Left := WizardForm.DirEdit.Left;
  DesktopIconCheck.Top := WizardForm.DiskSpaceLabel.Top + WizardForm.DiskSpaceLabel.Height + ScaleY(12);
  DesktopIconCheck.Width := WizardForm.DirEdit.Width;
  DesktopIconCheck.Height := ScaleY(24);
  DesktopIconCheck.Caption := 'Create a &desktop shortcut';
  DesktopIconCheck.Checked := True;

  // Embed daily update check option (Default unchecked for user privacy)
  AutoUpdateCheck := TNewCheckBox.Create(WizardForm);
  AutoUpdateCheck.Parent := WizardForm.SelectDirPage;
  AutoUpdateCheck.Left := WizardForm.DirEdit.Left;
  AutoUpdateCheck.Top := DesktopIconCheck.Top + DesktopIconCheck.Height + ScaleY(4);
  AutoUpdateCheck.Width := WizardForm.DirEdit.Width;
  AutoUpdateCheck.Height := ScaleY(22);
  AutoUpdateCheck.Caption := 'Check for updates automatically &once per day';
  AutoUpdateCheck.Checked := False;

  // Embed Privacy Policy button
  PrivacyPolicyBtn := TNewButton.Create(WizardForm);
  PrivacyPolicyBtn.Parent := WizardForm.SelectDirPage;
  PrivacyPolicyBtn.Left := WizardForm.DirEdit.Left;
  PrivacyPolicyBtn.Top := AutoUpdateCheck.Top + AutoUpdateCheck.Height + ScaleY(8);
  PrivacyPolicyBtn.Width := ScaleX(145);
  PrivacyPolicyBtn.Height := ScaleY(26);
  PrivacyPolicyBtn.Caption := 'View &Privacy Policy';
  PrivacyPolicyBtn.OnClick := @PrivacyPolicyClick;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  // On the single options page, present the button directly as "Install"
  if CurPageID = wpSelectDir then
  begin
    WizardForm.NextButton.Caption := SetupMessage(msgButtonInstall);
  end;
end;

function KillRunningApp(): Boolean;
var
  ResultCode: Integer;
  i: Integer;
begin
  Result := True;
  
  // Only attempt termination if an active instance is currently running
  if CheckForMutexes('Global\DiskPartitioner_SingleInstance_Mutex,DiskPartitioner_SingleInstance_Mutex') then
  begin
    // Terminate running instance directly (installer runs elevated as Administrator)
    Exec('taskkill.exe', '/F /T /IM DiskPartitioner.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // Poll for up to 500ms until mutex is completely released
    for i := 1 to 10 do
    begin
      if not CheckForMutexes('Global\DiskPartitioner_SingleInstance_Mutex,DiskPartitioner_SingleInstance_Mutex') then
        Break;
      Sleep(50);
    end;
    Sleep(100);
  end;
end;

function InitializeSetup(): Boolean;
begin
  // Terminate any running instance immediately on setup launch
  KillRunningApp();
  Result := True;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  // Terminate any running instance when user clicks "Install" button right before extracting files
  KillRunningApp();
  Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    // Double-ensure app is terminated immediately prior to file operations
    KillRunningApp();
  end;
end;

function InitializeUninstall(): Boolean;
begin
  // Terminate running instance immediately when uninstaller launches
  KillRunningApp();
  Result := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    // Double-ensure app is terminated before file deletion step
    KillRunningApp();
  end;
end;
