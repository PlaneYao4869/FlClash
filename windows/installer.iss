[Setup]
AppName=PlaneClash
AppVersion=1.0.0
AppPublisher=PlaneYao
DefaultDirName={autopf}\PlaneClash
DefaultGroupName=PlaneClash
OutputDir=..\installer_output
OutputBaseFilename=PlaneClash_Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\PlaneClash.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"
Name: "startmenu"; Description: "创建开始菜单快捷方式"; GroupDescription: "附加图标:"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\PlaneClash"; Filename: "{app}\PlaneClash.exe"
Name: "{group}\卸载 PlaneClash"; Filename: "{uninstallexe}"
Name: "{autodesktop}\PlaneClash"; Filename: "{app}\PlaneClash.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\PlaneClash.exe"; Description: "启动 PlaneClash"; Flags: nowait postinstall skipifsilent
