object InterBaseWatchdog: TInterBaseWatchdog
  DisplayName = 'InterBase Watchdog'
  AfterInstall = ServiceAfterInstall
  OnContinue = ServiceContinue
  OnExecute = ServiceExecute
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 480
  Width = 640
end
