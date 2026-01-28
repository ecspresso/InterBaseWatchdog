unit ServiceUtils;

interface

uses
  Winapi.Windows,
  Winapi.WinSvc,
  System.SysUtils,
  System.DateUtils;

type
  TServiceUtils = class
  private
    FServiceName: string;
    FProcessId: Int64;
    function GetService(const ADesiredAccess: DWORD; out hSCM: THandle): THandle;
    function GetProcessId: Int64;

    // class procedure ErrorCheck(const AHandle: THandle);
    // class function ErrorCodeToString(const AErrorCode: DWORD): string;
    class function FileTimeToDateTime(const AFileTime: TFileTime): TDateTime;
  public
    constructor Create(const AServiceName: string);
    function ServiceUptime: Int64;
    procedure RestartService;
  end;

implementation


{ TServiceUtils }

constructor TServiceUtils.Create(const AServiceName: string);
begin
  FServiceName := AServiceName;
end;

class function TServiceUtils.FileTimeToDateTime(const AFileTime: TFileTime): TDateTime;
var
  LSystemTime: TSystemTime;
begin
  FileTimeToSystemTime(AFileTime, LSystemTime);
  Result := SystemTimeToDateTime(LSystemTime);
end;

function TServiceUtils.GetService(const ADesiredAccess: DWORD; out hSCM: THandle): THandle;
begin
  hSCM := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  Win32Check(hSCM <> 0);

  Result := OpenService(hSCM, PChar(FServiceName), ADesiredAccess);
  Win32Check(Result <> 0);
end;

function TServiceUtils.GetProcessId: Int64;
var
  LhSCM, LhService: THandle;
  LService: SERVICE_STATUS_PROCESS;
  LBytes: DWORD;
begin
  LhService := GetService(SERVICE_QUERY_STATUS, LhSCM);
  try
    // Get service info
    Win32Check(QueryServiceStatusEx(LhService, SC_STATUS_PROCESS_INFO, @LService, SizeOf(LService), LBytes));

    if (LService.dwCurrentState = SERVICE_STOPPED) or (LService.dwCurrentState = SERVICE_STOP_PENDING) then
      Result := -1
    else
      Result := LService.dwProcessId;
  finally
    Win32Check(CloseServiceHandle(LhService));
    Win32Check(CloseServiceHandle(LhSCM));
  end;
end;

procedure TServiceUtils.RestartService;
var
  LhSCM, LhService: THandle;
  LStatus: SERVICE_STATUS;
  s: PWideChar;
begin
  LhService := GetService(SERVICE_STOP or SERVICE_START or SERVICE_QUERY_STATUS, LhSCM);

  try
    // Stop
    Win32Check(ControlService(LhService, SERVICE_CONTROL_STOP, LStatus));

    // Wait until restart
    while QueryServiceStatus(LhService, LStatus) and (LStatus.dwCurrentState <> SERVICE_STOPPED) do
      Sleep(250);

    // Start
    Win32Check(StartService(LhService, 0, s));
  finally
    Win32Check(CloseHandle(LhService));
    Win32Check(CloseHandle(LhSCM));
  end;
end;

function TServiceUtils.ServiceUptime: Int64;
var
  LProcessHandle: THandle;
  LCreationTime, LExitTime, LKernelTime, LUserTime: TFileTime;
  LNowFT: TFileTime;
  LNow, LStart: TDateTime;

  LStartUTC, LNowUTC: TDateTime;
  LStartSt, LNowSt: TSystemTime;
begin
  try
    FProcessId := GetProcessId;
    if FProcessId <= 0 then
      Exit(-1);

    LProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION, False, FProcessId);
    Win32Check(GetProcessTimes(LProcessHandle, LCreationTime, LExitTime, LKernelTime, LUserTime));

    // Start time (UTC)
    LStartUTC := FileTimeToDateTime(LCreationTime);

    // Now (UTC)
    GetSystemTimeAsFileTime(LNowFT);
    LNowUTC := FileTimeToDateTime(LNowFT);

    // antal sekunder sen start
    Result := SecondsBetween(LStartUTC, LNowUTC);
  finally
    Win32Check(CloseHandle(LProcessHandle));
  end;
end;

end.
