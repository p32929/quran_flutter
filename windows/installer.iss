; Inno Setup script for the Quran Windows installer.
; Invoked by CI as:  ISCC.exe /DMyAppVersion=<version> windows\installer.iss
; SourceDir is set to the repo root so the build output path resolves correctly.

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#define MyAppName "Al Quran"
#define MyAppPublisher "Quran"
#define MyAppExeName "quran_flutter_v2.exe"

[Setup]
; NOTE: keep this AppId stable across releases so upgrades replace the old install.
AppId={{8F2A9C14-3B6E-4D7A-9E1F-2C5B8A0D4E63}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
DisableProgramGroupPage=yes
; Resolve everything relative to the repo root (this script lives in windows\)
SourceDir={#SourcePath}\..
OutputDir=installer_output
OutputBaseFilename=quran-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
