unit Utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows;

function IsWorkstationLocked: boolean;
function GetMasterVolume: single;
procedure SetMasterVolume(const Value: single);
procedure InitVolumeEndpoint;


implementation

uses
  MMDevAPI, ActiveX;

var
  endpointVolume: IAudioEndpointVolume;

function IsWorkstationLocked: boolean;
var
  hDesktop: HDESK;
begin
  Result := False;
  hDesktop := OpenDesktop('default', 0, False, DESKTOP_SWITCHDESKTOP);
  try
    if hDesktop <> 0 then
      Result := not SwitchDesktop(hDesktop);
  finally
    CloseDesktop(hDesktop);
  end;
end;

function GetMasterVolume: single;
begin
  endpointVolume.GetMasterVolumeLevelScaler(Result);
end;

procedure SetMasterVolume(const Value: single);
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

end.
