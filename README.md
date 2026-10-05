This script runs on Windows RV Players.  The Windows task scheduler is used to periodically run the script. When the script is run, it fetches data such as: disk space,
rv process ID's with handles being used, memory being used, CPU being used and the last playback entry.  This should be used for testing new RV builds on pc players to
track long term player data to detect memory/handle leaks.
