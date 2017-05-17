unit Utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows;

function IsWorkstationLocked: Boolean;
function GetMasterVolume: Single;
procedure SetMasterVolume(const Value: Single);
procedure InitVolumeEndpoint;
function IsWindows10orHigher: Boolean;


implementation

uses
  MMDevAPI, ActiveX, JwaWinBase, JwaWtsApi32, JwaLmServer, JwaLmApiBuf;

var
  endpointVolume: IAudioEndpointVolume;
  isWindows10: Boolean;

function IsSessionLocked(): Boolean;
const
  WTS_CURRENT_SERVER_HANDLE = 0;
  WTSSessionInfoEx = 25;
  WTS_SESSIONSTATE_LOCK = $00000000;
  WTS_SESSIONSTATE_UNLOCK = $00000001;
  WTS_SESSIONSTATE_UNKNOWN = $FFFFFFFF;
type
  WTSINFOEX = packed record
    Level: DWORD;
    SessionID: Int64;
    ConnectSessionState: DWORD;
    SessionFlags: Int32;
  end;
  PWTSINFOEX = ^WTSINFOEX;

var
  processId: DWORD;
  sessionId: DWORD;
  sessionInfo: PWTSINFOEX;
  res: BOOL;
  bytesReturned: DWORD;
begin
  Result := False;
  processId := GetCurrentProcessId;
  if ProcessIdToSessionId(processId, sessionId) then
  begin
    try
      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE,
        sessionId, WTS_INFO_CLASS(WTSSessionInfoEx), sessionInfo, bytesReturned) then
        Result := sessionInfo^.SessionFlags = WTS_SESSIONSTATE_LOCK;
    finally
      WTSFreeMemory(sessionInfo);
    end;
  end;
end;

function IsWorkstationLocked: Boolean;
var
  hDesktop: HDESK;
begin
  Result := False;
  if isWindows10 then
    Result := IsSessionLocked()
  else
  begin
    hDesktop := OpenInputDesktop(0, False, DESKTOP_SWITCHDESKTOP);
    try
      if hDesktop <> 0 then
        Result := not SwitchDesktop(hDesktop);
    finally
      CloseDesktop(hDesktop);
    end;
  end;
end;

function IsWindows10orHigher: Boolean;
var
  Buffer: PServerInfo101;
begin
  Result := False;
  Buffer := nil;
  if NetServerGetInfo(nil, 101, Pointer(Buffer)) = NO_ERROR then
    try
      Result := Buffer^.sv101_version_major >= 10;
    finally
      NetApiBufferFree(Buffer);
    end;
end;

function GetMasterVolume: Single;
begin
  endpointVolume.GetMasterVolumeLevelScaler(Result);
end;

procedure SetMasterVolume(const Value: Single);
begin
  endpointVolume.SetMasterVolumeLevelScalar(Value, nil);
end;

procedure InitVolumeEndpoint;
var
  deviceEnumerator: IMMDeviceEnumerator;
  defaultDevice: IMMDevice;
begin
  endpointVolume := nil;
  CoCreateInstance(CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER,
    IID_IMMDeviceEnumerator, deviceEnumerator);
  deviceEnumerator.GetDefaultAudioEndpoint(eRender, eConsole, defaultDevice);
  defaultDevice.Activate(IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER,
    nil, endpointVolume);
end;

initialization
  isWindows10 := IsWindows10orHigher();
end.
