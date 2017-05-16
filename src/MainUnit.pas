unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ComCtrls, Windows, StdCtrls, ExtCtrls, Registry, Utils;

type

  { TMainForm }

  TMainForm = class(TForm)
    chkRunAtStartup: TCheckBox;
    chkRunMinimized: TCheckBox;
    labCurrentVolume: TLabel;
    labVolumeWhenLocked: TLabel;
    memInformation: TMemo;
    Timer1: TTimer;
    TrayIcon1: TTrayIcon;
    trkVolumeCurrent: TTrackBar;
    trkVolumeWhenLocked: TTrackBar;
    procedure chkRunAtStartupChange(Sender: TObject);
    procedure chkRunMinimizedChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure trkVolumeCurrentChange(Sender: TObject);
    procedure trkVolumeWhenLockedChange(Sender: TObject);
  private
    { private declarations }
    lastBeepTime: TDatetime;
    lastWorkstationState: boolean;
    saveSettingsEnabled: boolean;
    hideOnStartup: boolean;
    procedure SaveSettings;
    procedure LoadSettings;
    procedure MinimizeApplication;
    procedure RestoreApplication;
  public
    { public declarations }
  end;

const
  LOCKED = True;
  UNLOCKED = False;

var
  MainForm: TMainForm;

//done: контролировать повторный запуск
//done: свертываться в трей
//done: при попытке закрыть спрашивать - правда хочешь закрыть?
//done: сохранять настройки
//done: прописываться в автозапуске в реестре

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.trkVolumeCurrentChange(Sender: TObject);
var
  volumeLevel: single;
begin
  with trkVolumeCurrent do
    volumeLevel := position / max;
  SetMasterVolume(volumeLevel);
  if (now - lastBeepTime) * secsperday >= 0.5 then
    messagebeep(MB_IconExclamation); {48}
  lastBeepTime := now;
end;

procedure TMainForm.trkVolumeWhenLockedChange(Sender: TObject);
begin
  SaveSettings;
end;

procedure TMainForm.SaveSettings;
var
  R: TRegistry;
begin
  if not saveSettingsEnabled then
    Exit;
  R := TRegistry.Create;
  try
    R.OpenKey('Software\' + Stringreplace(Application.Title, ' ', '_',
      [rfReplaceAll]), True);
    with trkVolumeWhenLocked do
      R.WriteFloat('VolumeWhenLocked', Position / Max);
    with chkRunMinimized do
      R.WriteBool('RunMinimized', Checked);
  finally
    R.CloseKey;
  end;
  try
    R.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);
    with chkRunAtStartup do
      if Checked then
        R.WriteString('MuteWhenLocked', Application.ExeName)
      else
        R.DeleteValue('MuteWhenLocked');
  finally
    R.CloseKey;
  end;
end;

procedure TMainForm.LoadSettings;
var
  R: TRegistry;
begin
  saveSettingsEnabled := False;
  R := TRegistry.Create;
  try
    try
      R.OpenKey('Software\' + Stringreplace(Application.Title, ' ',
        '_', [rfReplaceAll]), True);
      with trkVolumeWhenLocked do
        Position := Round(R.ReadFloat('VolumeWhenLocked') * Max);
      chkRunMinimized.Checked := R.ReadBool('RunMinimized');
    finally
      R.CloseKey;
    end;
    try
      R.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);
      with chkRunAtStartup do
        Checked := R.ValueExists('MuteWhenLocked');
    finally
      R.CloseKey;
    end;

  except
    // mute errors
  end;
  saveSettingsEnabled := True;
end;

procedure TMainForm.MinimizeApplication;
begin
  Application.Minimize;
  MainForm.Hide;
end;

procedure TMainForm.RestoreApplication;
begin
  Application.Restore;
  MainForm.Show;
  ShowWindow(MainForm.Handle, SW_NORMAL);
  Application.BringToFront;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  volumeLevel: single;
begin
  InitVolumeEndpoint();
  LoadSettings;
  TrayIcon1.Show;
  lastWorkstationState := UNLOCKED;
  lastBeepTime := now;
  volumeLevel := GetMasterVolume();
  trkVolumeCurrent.Position := Round(trkVolumeCurrent.Max * volumeLevel);
  hideOnStartup := chkRunMinimized.Checked;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if hideOnStartup then
    MinimizeApplication;
  hideOnStartup := False;
end;

procedure TMainForm.FormWindowStateChange(Sender: TObject);
begin
  if MainForm.WindowState = wsMinimized then
    MinimizeApplication;
end;

procedure TMainForm.chkRunAtStartupChange(Sender: TObject);
begin
  SaveSettings;
end;

procedure TMainForm.chkRunMinimizedChange(Sender: TObject);
begin
  SaveSettings;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := MessageDlg(Application.Title, 'Really want to close me?',
    mtConfirmation, [mbYes, mbNo], '') = mrYes;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  volumeLevel: single;
begin
  if IsWorkstationLocked and (lastWorkstationState = UNLOCKED) then
  begin
    lastWorkstationState := LOCKED;
    with trkVolumeWhenLocked do
      volumeLevel := Position / Max;
    SetMasterVolume(volumeLevel);
  end
  else if (not IsWorkstationLocked) and (lastWorkstationState = LOCKED) then
  begin
    lastWorkstationState := UNLOCKED;
    with trkVolumeCurrent do
      volumeLevel := Position / Max;
    SetMasterVolume(volumeLevel);
  end;
end;

procedure TMainForm.TrayIcon1Click(Sender: TObject);
begin
  if MainForm.Visible then
    MinimizeApplication
  else
    RestoreApplication;
end;

end.
