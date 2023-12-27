# WSUS Management Tasks
PowerShell script that handles automating WSUS management and optimization tasks to be ran as a scheduled task or manually on your WSUS server.
## Project Goals
- Log file management - _**Implemented - Open for Improvements**_
    - Create log file (timestamped events), rotate log file based on size, remove log files older than x (default 7) number days.
    - Calculate time each management task takes.
- Decline updates that are not needed - _**Implemented - Activily working on Improvements**_
    - Still need to work out a way to easily identify and add what updates to decline.
    - Currently set to decline **x86** and **ARM64**.
- Perform WSUS Server Cleanup tasks and log results - _**Implemented - Open for Improvements**_
- Clear synchronizations reports - keeping a set number of days with a default predetermined - _**In Progress**_
    - Need to determine best way to handle SQL Server vs WID databases.
## TODO (see active issues as well)
1. Clear synchronizations reports implementation.
    - Need to determine best approach for working with SQL Server and WID depending on WSUS configuration.
2. Decline updates
    - Want the ability to easily identify which updates to decline vs hard coding the title and doing a foreach and $title -like "example" for the decline loop.
3. Validation and sanitization of user provided values.
    - Validate that directory paths are valid directories.
    - Validate that filenames are valid names and using valid extensions.
4. Improve error handling and processing
    - On line 196, 215, and 237 work in a solution to prevent those errors with the UpdateServices module is not installed/imported.
        - Thought process: conditional statement that checks if UpdateServices was imported/available. If not bypass the WMT class and output error or statement to the logfile.
## References
Please refer to the [FOLKS Consulting DevOps Guidelines](https://github.com/folksconsulting) for reporting issues, contributing, code of conduct, and etc.
## License
We want to create a resource that can be used by anyone for any project regardless if personal or commercial.

We believe in the spirit of sharing and helping our fellow IT professionals!

MIT License
Copyright © 2023 FOLKS Consulting, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
