[Setup]
AppName=Countdown Timer
AppVersion=1.0.0
DefaultDirName={autopf}\Countdown Timer
DefaultGroupName=Countdown Timer
OutputDir=build\installer
OutputBaseFilename=CountdownTimer-Setup
Compression=lzma2
SolidCompression=yes
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\countdown_timer.exe
WizardStyle=modern

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Countdown Timer"; Filename: "{app}\countdown_timer.exe"
Name: "{commondesktop}\Countdown Timer"; Filename: "{app}\countdown_timer.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\countdown_timer.exe"; Description: "Launch Countdown Timer"; Flags: nowait postinstall skipifsilent
