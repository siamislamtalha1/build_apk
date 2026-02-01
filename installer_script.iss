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
 AppName=Musicly
 AppVersion=1.0
 AppPublisher=Your Name
 DefaultDirName={localappdata}\Musicly
 DefaultGroupName=Musicly
 DisableProgramGroupPage=yes
 OutputDir=Output
 OutputBaseFilename=Musicly-Setup
 Compression=lzma2
 SolidCompression=yes
 ArchitecturesInstallIn64BitMode=x64
 PrivilegesRequired=lowest
 SetupIconFile=windows\runner\resources\app_icon.ico
 UninstallDisplayIcon={app}\musicly.exe
 WizardStyle=modern
 CloseApplications=yes
 CloseApplicationsFilter={#AppExe}
 RestartApplications=no
 RestartIfNeededByRun=no
 
 [Files]
 Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
 
 [Icons]
 Name: "{autodesktop}\Musicly"; Filename: "{app}\musicly.exe"; Tasks: desktopicon
 Name: "{group}\Musicly"; Filename: "{app}\musicly.exe"
 Name: "{group}\Uninstall Musicly"; Filename: "{uninstallexe}"
 
 [Tasks]
 Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"
 
 [Run]
 Filename: "{app}\musicly.exe"; Description: "Launch Musicly"; Flags: postinstall nowait skipifsilent unchecked
 
 [UninstallDelete]
 Type: filesandordirs; Name: "{app}"
 Type: filesandordirs; Name: "{userappdata}\Musicly"
 Type: filesandordirs; Name: "{localappdata}\Musicly"
