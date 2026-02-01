; Musicly Inno Setup Installer
; Build Windows first:
;   flutter clean
;   flutter pub get
;   flutter build windows --release
;
; Then compile this script with Inno Setup to produce a single:
;   Musicly-Setup.exe

#define MyAppName "Musicly"
#define MyAppExeName "Musicly.exe"
#define MyAppPublisher "Musicly"
#define MyAppURL "https://musiclyco.com"

; IMPORTANT:
; This points at Flutter's Windows release output folder.
#define BuildDir "..\\build\\windows\\x64\\runner\\Release"

[Setup]
AppId={{8E2B5C7B-0F2C-4A35-9B0F-9D4C8E9A1A1B}
AppName={#MyAppName}
AppVersion=2.13.3
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\{#MyAppName}
DisableDirPage=yes
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=Musicly-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardStyle=modern
PrivilegesRequired=lowest
; Prevent "file in use" issues: close the running app during install/uninstall.
CloseApplications=yes
CloseApplicationsFilter={#MyAppExeName}
RestartApplications=no
RestartIfNeededByRun=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Copy the entire Flutter Windows release output (EXE + DLLs + data folder)
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{autoprograms}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove install folder even if the app created extra files there.
Type: filesandordirs; Name: "{app}"

; Also remove common per-user data folders created by many Windows apps.
; NOTE: This will delete Musicly settings/cache stored in AppData.
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}"
