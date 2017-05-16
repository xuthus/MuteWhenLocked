program lockmute;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Windows,
  SysUtils,
  Interfaces, // this includes the LCL widgetset
  Forms,
  MainUnit,
  Utils;

  function CheckAlreadyRun: boolean;
  begin
    if CreateMutex(nil, True, '839D3799-2302-40E0-A45C-F052D25AD65Da') = 0 then
      RaiseLastOSError;
    Result := GetLastError = ERROR_ALREADY_EXISTS;
  end;

{$R *.res}

begin
  if CheckAlreadyRun then
    exit;
  Application.Title := 'Mute When Locked';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.



