unit Service;

interface

uses
  BackgroundThreadUnit,

  System.Classes,
  System.SysUtils,
  System.Win.Registry,

  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.SvcMgr,

  Winapi.Messages,
  Winapi.Windows;

type
  TInterBaseWatchdog = class(TService)
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceExecute(Sender: TService);
    procedure ServiceAfterInstall(Sender: TService);
  private
    FBackgroundThread: TBackgroundThread;
  public
    function GetServiceController: TServiceController; override;
  end;

var
  InterBaseWatchdog: TInterBaseWatchdog;

implementation

{$R *.dfm}


procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  InterBaseWatchdog.Controller(CtrlCode);
end;

function TInterBaseWatchdog.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

// Resume service;
procedure TInterBaseWatchdog.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('SYSTEMCurrentControlSetServices' + name, false) then
    begin
      Reg.WriteString('Description', 'Restart InterBase every 48 hours when InterBase is running.');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TInterBaseWatchdog.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
  FBackgroundThread.Continue;
  Continued := True;
end;

procedure TInterBaseWatchdog.ServiceExecute(Sender: TService);
begin
  while not Terminated do
  begin
    ServiceThread.ProcessRequests(false);
    TThread.Sleep(1000);
  end;
end;

// Pause service
procedure TInterBaseWatchdog.ServicePause(Sender: TService; var Paused: Boolean);
begin
  FBackgroundThread.Pause;
  Paused := True;
end;

// Create and start backgroud thread
procedure TInterBaseWatchdog.ServiceStart(Sender: TService; var Started: Boolean);
begin
  FBackgroundThread := TBackgroundThread.Create(False); // Start directly
  Started := True;
end;

// Stop service and thread
procedure TInterBaseWatchdog.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  FBackgroundThread.Terminate;
  FBackgroundThread.WaitFor;
  FreeAndNil(FBackgroundThread);
  Stopped := True;
end;

end.
