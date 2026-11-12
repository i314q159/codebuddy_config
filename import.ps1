param(
    [string] $Code = 'buddycn',
    [string] $UserDir = "$env:APPDATA\CodeBuddy CN\User",
    [ValidateSet('All', 'Extensions', 'Settings')]
    [string] $Only = 'All'
)

if ($Only -in @('All', 'Extensions')) {
    $extFile = "$PSScriptRoot\extensions.txt"
    if (Test-Path $extFile) {
        $exts = @(Get-Content $extFile | Where-Object { $_.Trim() })
        $failed = @()
        $i = 0
        foreach ($e in $exts) {
            $i++
            Write-Host "[$i/$($exts.Count)] $e"
            & $Code --install-extension $e.Trim() | Out-Null
            if ($LASTEXITCODE -ne 0) { $failed += $e.Trim() }
        }
        Write-Host "Extensions: $($exts.Count) processed, $($failed.Count) failed"
        if ($failed.Count) { $failed | ForEach-Object { Write-Warning "Failed: $_" } }

        # Uninstall extensions installed but not present in extensions.txt
        $desired = @($exts | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
        $installed = @(& $Code --list-extensions | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
        $extra = @($installed | Where-Object { $desired -notcontains $_.ToLower() })
        if ($extra.Count) {
            $rmFailed = @()
            foreach ($e in $extra) {
                Write-Host "Uninstalling extra: $e"
                & $Code --uninstall-extension $e | Out-Null
                if ($LASTEXITCODE -ne 0) { $rmFailed += $e }
            }
            Write-Host "Extras: $($extra.Count) found, $($rmFailed.Count) failed"
            if ($rmFailed.Count) { $rmFailed | ForEach-Object { Write-Warning "Failed to uninstall: $_" } }
        }
        else { Write-Host 'Extras: 0 found, nothing to uninstall' }
    }
    else { Write-Warning 'extensions.txt not found, skipping extensions.' }
}

if ($Only -in @('All', 'Settings')) {
    $src = "$PSScriptRoot\codebuddy-user"
    if (Test-Path $src) {
        $existing = Join-Path $UserDir 'settings.json'
        if (Test-Path $existing) { Copy-Item $existing "$existing.bak" -Force }
        $files = @(Get-ChildItem $src -Recurse -File -Include *.json, *.code-snippets)
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($src.TrimEnd('\').Length).TrimStart('\')
            $target = Join-Path $UserDir $rel
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item $f.FullName $target -Force
        }
        Write-Host "Copied $($files.Count) config files -> $UserDir"
    }
    else { Write-Warning 'codebuddy-user directory not found, skipping settings.' }
}
