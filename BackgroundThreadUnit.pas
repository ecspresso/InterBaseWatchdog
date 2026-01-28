unit BackgroundThreadUnit;

interface

uses
  ServiceUtils,

  System.Classes,
  System.IOUtils,
  System.SysUtils;

type
  TBackgroundThread = class(TThread)
  private const
    MAX_PROCESS_UP_TIME_SECONDS = 172800;
  private
    FPaused: Boolean;
    FTerminated: Boolean;
    FServiceUtils: TServiceUtils;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
    procedure Pause;
    procedure Continue;
  end;

implementation

procedure TBackgroundThread.Continue;
begin
  FPaused := False;
end;

constructor TBackgroundThread.Create(CreateSuspended: Boolean);
begin
  inherited;
  FServiceUtils := nil;
end;

destructor TBackgroundThread.Destroy;
begin
  FreeAndNil(FServiceUtils);
  inherited;
end;

procedure TBackgroundThread.Execute;
var
  LUptime: Int64;
begin
  FServiceUtils := TServiceUtils.Create('IBG_gds_db');

  FPaused := False;

  while not Terminated do
  begin
    if not FPaused then
      if FServiceUtils.ServiceUptime >= MAX_PROCESS_UP_TIME_SECONDS then
        FServiceUtils.RestartService;
    TThread.Sleep(60000);
  end;
end;

procedure TBackgroundThread.Pause;
begin
  FPaused := True;
end;

end.
