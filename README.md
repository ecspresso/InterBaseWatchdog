# InterBaseWatchdog

Lightweight Windows service that monitors InterBase server service (IBG_gds_db) and automatically restarts the InterBase server service when the process has been alive for 48 hours.

## Installation
1. Download `InterBaseWatchdogService.exe`.
2. Open a terminal windows as admin and navigate to the exe file.
3. Execute with `InterBaseWatchdogService.exe /install`.

## Development

Built with RAD Studio. Two projects:

 - InterBaseWatchdogService.dproj - Service executable
 - Debug.dproj - Development testing
