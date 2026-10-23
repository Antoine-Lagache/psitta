#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif

[Setup]
AppId={{C3CC9F34-91EE-4C45-923E-C498E6039ED9}
AppName=Psitta
AppVersion={#AppVersion}
AppPublisher=Antoine Lagache
AppPublisherURL=https://psitta.net
DefaultDirName={localappdata}\Programs\Psitta
DefaultGroupName=Psitta
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=Psitta-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\psitta.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Psitta"; Filename: "{app}\psitta.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Psitta"; Filename: "{app}\psitta.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\psitta.exe"; Description: "{cm:LaunchProgram,Psitta}"; Flags: nowait postinstall skipifsilent
