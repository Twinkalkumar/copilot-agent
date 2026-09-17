param(
    [string[]]$LogPaths = @(
        "C:\Logs",
        "C:\inetpub\logs\LogFiles",
        "C:\Windows\System32\LogFiles"
    ),

    [int]$RetentionDays = 30,

    [switch]$Delete
)

$cutoff = (Get-Date).AddDays(-$RetentionDays)

foreach ($logPath in $LogPaths) {
    if (-not (Test-Path -LiteralPath $logPath)) {
        Write-Warning "Path does not exist: $logPath"
        continue
    }

    Get-ChildItem -LiteralPath $logPath -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.LastWriteTime -lt $cutoff
        } |
        ForEach-Object {
            if ($Delete) {
                try {
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                    Write-Host "Deleted: $($_.FullName)"
                }
                catch {
                    Write-Warning "Could not delete $($_.FullName): $($_.Exception.Message)"
                }
            }
            else {
                Write-Host "[DRY RUN] Would delete: $($_.FullName)"
            }
        }
}
