@echo off
setlocal EnableExtensions
REM Safe source commit/push for Lo-lo78/LReaParams.
REM The ReaPack workflow commits index.xml to main after a published release;
REM always fetch and preserve the *remote generated index*, even if replacing
REM the source folder accidentally removed the file locally.
if "%~1"=="" (
  echo Usage: Tools\push_lreaparams.cmd "Commit message"
  exit /b 2
)
pushd "%~dp0.." || exit /b 1
git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
  echo ERROR: This directory is not a Git working tree.
  popd
  exit /b 1
)
git fetch origin main
if errorlevel 1 goto :failed
REM Only index.xml is recovered from the remote: it is a generated file.
git cat-file -e origin/main:index.xml >nul 2>nul
if not errorlevel 1 (
  git restore --source=origin/main --staged --worktree -- index.xml
  if errorlevel 1 goto :failed
)
git add .
if errorlevel 1 goto :failed
git diff --cached --quiet
if not errorlevel 1 (
  echo No source changes to commit. Nothing pushed.
  popd
  exit /b 0
)
git commit -m "%~1"
if errorlevel 1 goto :failed
REM Rebase the newly created local commit over the automatic ReaPack commit.
git pull --rebase origin main
if errorlevel 1 (
  echo ERROR: Rebase needs attention. Do not force push or reset --hard.
  goto :failed
)
git push origin main
if errorlevel 1 goto :failed
popd
exit /b 0
:failed
echo ERROR: Stopped safely. Read the Git message above.
popd
exit /b 1
