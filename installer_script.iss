 ; Musicly - Inno Setup script (CI friendly)
 ; Build first:
 ;   flutter build windows --release
 ;
 ; Compile (local):
 ;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer_script.iss
 
 #define AppName "Musicly"
 #define AppExe "Musicly.exe"
 
 [Setup]
 AppId={{8E2B5C7B-0F2C-4A35-9B0F-9D4C8E9A1A1B}
 AppName={#AppName}
 AppVersion=2.13.3
 AppPublisher=Musicly
 DefaultDirName={localappdata}\{#AppName}
 DefaultGroupName={#AppName}
 DisableProgramGroupPage=yes
 DisableDirPage=yes
 OutputDir=Output
 OutputBaseFilename=Musicly-Setup
 Compression=lzma2
 SolidCompression=yes
 ArchitecturesInstallIn64BitMode=x64
 PrivilegesRequired=lowest
 SetupIconFile=windows\runner\resources\app_icon.ico
 UninstallDisplayIcon={app}\{#AppExe}
 WizardStyle=modern
 CloseApplications=yes
 CloseApplicationsFilter={#AppExe}
 RestartApplications=no
 RestartIfNeededByRun=no
 
 [Files]
 Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
 
 [Icons]
 Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon
 Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
 Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
 
 [Tasks]
 Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: checked
 
 [Run]
 Filename: "{app}\{#AppExe}"; Description: "Launch {#AppName}"; Flags: postinstall nowait skipifsilent unchecked
 
 [UninstallDelete]
 Type: filesandordirs; Name: "{app}"
 Type: filesandordirs; Name: "{userappdata}\{#AppName}"
 Type: filesandordirs; Name: "{localappdata}\{#AppName}"
