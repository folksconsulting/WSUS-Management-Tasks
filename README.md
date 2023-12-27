# WSUS Management Tasks
PowerShell script that handles automating WSUS management and optimization tasks to be ran as a scheduled task or manually on your WSUS server.
## Project Goals
- Decline updates that are not needed.
    - Still need to work out a way to easily identify and add what updates to decline.
    - Currently set to decline **x86** and **ARM64**.
- Clear synchronizations reports - keeping a set number of days with a default predetermined.
    - Need to determine best way to handle SQL Server vs WID databases.
## References
Please refer to the [FOLKS Consulting DevOps Guidelines](https://github.com/folksconsulting) for reporting issues, contributing, code of conduct, and etc.
