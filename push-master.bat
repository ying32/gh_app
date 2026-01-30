@echo off

echo 推送本地中...

git push --thin --progress "origin" master

:retry

echo 推送github中...

git push --thin --progress "github" master

if %errorlevel% NEQ 0 (
  goto retry
)
pause