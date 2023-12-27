# WSUS Management Tasks
PowerShell script that handles automating WSUS management and optimization tasks.
## Project Goals
- Decline updates that are not needed.
  Still working on a way to better define what to decline vs just the current configuration of x86 and ARM64
- Clear synchronizations reports - keeping a set number of days with a default predetermined.
  Working on a way to determine SQL vs WID databases and make the connection as needed to clean the table that stores the sync records.
