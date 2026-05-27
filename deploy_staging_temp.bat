@echo off
set PATH=%PATH%;C:\Program Files\nodejs
"C:\Users\Stand Alone\AppData\Roaming\npm\firebase.cmd" hosting:channel:deploy staging --expires 7d
