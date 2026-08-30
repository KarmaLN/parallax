$RepoPath = $PSScriptRoot
$DelaySeconds = 30

Write-Host "========================================"
Write-Host " Git Auto Sync"
Write-Host "========================================"
Write-Host "Repository: $RepoPath"
Write-Host ""

# ============================================================
# Find Git
# ============================================================

$Git = $null

# Normal Git installations
$GitCandidates = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files\Git\bin\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
)

# GitHub Desktop bundled Git
$GitHubDesktopPath = "$env:LOCALAPPDATA\GitHubDesktop"

if (Test-Path -LiteralPath $GitHubDesktopPath) {
    $GitHubGit = Get-ChildItem `
        -LiteralPath $GitHubDesktopPath `
        -Filter "git.exe" `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($GitHubGit) {
        $GitCandidates += $GitHubGit.FullName
    }
}

# Check candidates
foreach ($Candidate in $GitCandidates) {
    if (Test-Path -LiteralPath $Candidate) {
        $Git = $Candidate
        break
    }
}

# Finally check PATH
if (-not $Git) {
    $GitCommand = Get-Command git -ErrorAction SilentlyContinue

    if ($GitCommand) {
        $Git = $GitCommand.Source
    }
}

if (-not $Git) {
    Write-Host ""
    Write-Host "ERROR: Git could not be found." -ForegroundColor Red
    Write-Host ""
    pause
    exit
}

Write-Host "Git found:" -ForegroundColor Green
Write-Host $Git
Write-Host ""

# ============================================================
# Verify repository
# ============================================================

if (-not (Test-Path -LiteralPath "$RepoPath\.git")) {
    Write-Host "ERROR: No .git folder found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected repository:"
    Write-Host $RepoPath
    Write-Host ""
    pause
    exit
}

# IMPORTANT:
# -LiteralPath is required because your path contains [ and ].
Set-Location -LiteralPath $RepoPath

Write-Host "Repository verified." -ForegroundColor Green
Write-Host "Waiting for changes..."
Write-Host ""

# ============================================================
# File watcher
# ============================================================

$watcher = New-Object System.IO.FileSystemWatcher

$watcher.Path = $RepoPath
$watcher.Filter = "*"
$watcher.IncludeSubdirectories = $true

$watcher.NotifyFilter = (
    [System.IO.NotifyFilters]::FileName -bor
    [System.IO.NotifyFilters]::DirectoryName -bor
    [System.IO.NotifyFilters]::LastWrite
)

$global:LastChange = Get-Date

$action = {
    $path = $Event.SourceEventArgs.FullPath

    # Ignore Git's internal files
    if ($path -notlike "$using:RepoPath\.git\*") {
        $global:LastChange = Get-Date
    }
}

Register-ObjectEvent `
    -InputObject $watcher `
    -EventName Changed `
    -Action $action | Out-Null

Register-ObjectEvent `
    -InputObject $watcher `
    -EventName Created `
    -Action $action | Out-Null

Register-ObjectEvent `
    -InputObject $watcher `
    -EventName Deleted `
    -Action $action | Out-Null

Register-ObjectEvent `
    -InputObject $watcher `
    -EventName Renamed `
    -Action $action | Out-Null

$watcher.EnableRaisingEvents = $true

# ============================================================
# Main loop
# ============================================================

while ($true) {

    Start-Sleep -Milliseconds 500

    $elapsed = ((Get-Date) - $global:LastChange).TotalSeconds

    if ($elapsed -ge $DelaySeconds) {

        $changes = & $Git -C $RepoPath status --porcelain

        if ($changes) {

            $global:LastChange = Get-Date

            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host " Changes detected" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan

            Write-Host ""
            Write-Host "Adding changes..." -ForegroundColor Yellow

            & $Git -C $RepoPath add .

            if ($LASTEXITCODE -ne 0) {
                Write-Host "git add failed." -ForegroundColor Red
                continue
            }

            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $commitMessage = "Auto-sync: $timestamp"

            Write-Host "Creating commit..." -ForegroundColor Yellow

            & $Git -C $RepoPath commit -m $commitMessage

            if ($LASTEXITCODE -eq 0) {

                Write-Host "Commit successful." -ForegroundColor Green

                Write-Host ""
                Write-Host "Pushing to GitHub..." -ForegroundColor Yellow

                & $Git -C $RepoPath push

                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Host "Successfully pushed to GitHub!" -ForegroundColor Green
                }
                else {
                    Write-Host ""
                    Write-Host "Push failed." -ForegroundColor Red
                }

            }
            else {
                Write-Host "Commit failed." -ForegroundColor Red
            }

            Write-Host ""
            Write-Host "Waiting for changes..."
        }
    }
}