param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "update", "status", "sync", "enable-auto", "disable-auto", "enable-autoupdate", "disable-autoupdate", "init-project", "help")]
    [string]$Action = "status",

    [Parameter(Position = 1)]
    [string]$TargetPath = ""
)

$ErrorActionPreference = "Stop"

# Dynamic Paths Configuration (Portable across any machine)
$AutoAiRoot       = $PSScriptRoot
$ParentDevRoot    = Split-Path -Path $AutoAiRoot -Parent
$CustomSkillsRoot = Join-Path $AutoAiRoot "custom-skills"
$MasterRuleFile   = Join-Path $AutoAiRoot "rules\auto-orchestrator.md"

# Resolve pstack location dynamically (env -> sibling ../skills/pstack -> ./vendor/pstack)
$SiblingPstack    = Join-Path $ParentDevRoot "skills\pstack"
$VendorPstack     = Join-Path $AutoAiRoot "vendor\pstack"

if ($env:PSTACK_PATH -and (Test-Path $env:PSTACK_PATH)) {
    $PstackRoot = (Resolve-Path $env:PSTACK_PATH).Path
} elseif (Test-Path (Join-Path $SiblingPstack "skills")) {
    $PstackRoot = (Resolve-Path $SiblingPstack).Path
} else {
    $PstackRoot = $VendorPstack
}
$PstackSkillsRoot = Join-Path $PstackRoot "skills"

# IDE Global Directories
$AgyConfigDir     = Join-Path $HOME ".gemini\config"
$AgySkillsDir     = Join-Path $AgyConfigDir "skills"
$AgySkillsJson    = Join-Path $AgyConfigDir "skills.json"
$AgyGeminiMd      = Join-Path $AgyConfigDir "GEMINI.md"
$AgyAgentsMd      = Join-Path $AgyConfigDir "AGENTS.md"

$AgentsDir        = Join-Path $HOME ".agents"
$AgentsSkillsDir  = Join-Path $AgentsDir "skills"
$PstackModelsMd   = Join-Path $AgentsDir "pstack-models.md"

$CursorRulesDir   = Join-Path $HOME ".cursor\rules"
$CursorSkillsDir  = Join-Path $HOME ".cursor\skills"
$CursorAutoRule   = Join-Path $CursorRulesDir "pstack-auto-orchestrator.mdc"
$CursorModelsRule = Join-Path $CursorRulesDir "pstack-models.mdc"

$ClaudeDir        = Join-Path $HOME ".claude"
$ClaudeSkillsDir  = Join-Path $ClaudeDir "skills"
$ClaudeGlobalMd   = Join-Path $ClaudeDir "CLAUDE.md"

$CodexDir         = Join-Path $HOME ".codex"
$CodexSkillsDir   = Join-Path $CodexDir "skills"
$CodexGlobalMd    = Join-Path $CodexDir "AGENTS.md"

$DevRootAgentsMd  = Join-Path $ParentDevRoot "AGENTS.md"
$DevRootClaudeMd  = Join-Path $ParentDevRoot "CLAUDE.md"
$LocalAgentsMd    = Join-Path $AutoAiRoot "AGENTS.md"
$LocalClaudeMd    = Join-Path $AutoAiRoot "CLAUDE.md"
$ScheduledTaskName = "AutoAI_pstack_AutoUpdate"
$StartupDir       = [Environment]::GetFolderPath('Startup')
$StartupVbsFile   = Join-Path $StartupDir "AutoAI_pstack_AutoUpdate.vbs"

function Ensure-PstackInstalled {
    if (-not (Test-Path $PstackSkillsRoot)) {
        Write-Host "`n[0/3] pstack not found locally. Cloning backnotprop/pstack into $VendorPstack..." -ForegroundColor Yellow
        $vendorParent = Split-Path -Path $VendorPstack -Parent
        if (-not (Test-Path $vendorParent)) {
            New-Item -ItemType Directory -Path $vendorParent -Force | Out-Null
        }
        git clone https://github.com/backnotprop/pstack.git "$VendorPstack"
        $script:PstackRoot = (Resolve-Path $VendorPstack).Path
        $script:PstackSkillsRoot = Join-Path $script:PstackRoot "skills"
    }

    # Ensure default ~/.agents/pstack-models.md exists for new users
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $defaultModelsBody = @"
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# Strictly uses only Gemini models (`pro` = Gemini Pro / Argon, `flash` = Gemini Flash). Do NOT use Claude models.
# budget: large (xhigh)
feature, refactoring: flash
bug-fix: flash
perf-issue: pro
hillclimb: flash
judgment and prose: pro
hardest tasks: pro
how explorer: flash
how explainer: pro
why investigators: flash
why synthesizer: pro
reflect tooling: flash
reflect judgment, divergent, synthesizer: pro
arena runners: pro, flash
arena cross-judge pool: pro, flash
swarm workers: flash
architect runners: pro, flash
interrogate reviewers: pro, flash
"@
    if (-not (Test-Path $AgentsDir)) {
        New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
    }
    if (-not (Test-Path $PstackModelsMd)) {
        [System.IO.File]::WriteAllText($PstackModelsMd, $defaultModelsBody, $utf8NoBom)
        Write-Host "  -> Created default model config at $PstackModelsMd" -ForegroundColor Green
    }
    if (-not (Test-Path $CursorRulesDir)) {
        New-Item -ItemType Directory -Path $CursorRulesDir -Force | Out-Null
    }
    if (-not (Test-Path $CursorModelsRule)) {
        $cursorModelsContent = @"
---
description: pstack per-role model choices (overrides skill defaults)
alwaysApply: true
---
$defaultModelsBody
"@
        [System.IO.File]::WriteAllText($CursorModelsRule, $cursorModelsContent, $utf8NoBom)
    }
}

function Get-RenderedRuleBody {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $rawRule = [System.IO.File]::ReadAllText($MasterRuleFile, $utf8NoBom)

    $pstackForward = $PstackRoot.Replace('\', '/')
    $modelsForward = $PstackModelsMd.Replace('\', '/')

    $rendered = $rawRule `
        -replace '\{\{PSTACK_ROOT_URI\}\}', "file:///$pstackForward" `
        -replace '\{\{PSTACK_ROOT_PATH\}\}', $pstackForward `
        -replace '\{\{MODELS_CONFIG_URI\}\}', "file:///$modelsForward" `
        -replace '\{\{MODELS_CONFIG_PATH\}\}', $modelsForward

    return $rendered
}

function Sync-SkillLinks {
    Ensure-PstackInstalled
    Write-Host "`n[1/3] Syncing pstack & custom skill junctions..." -ForegroundColor Cyan

    foreach ($destRoot in @($AgySkillsDir, $AgentsSkillsDir, $CursorSkillsDir, $ClaudeSkillsDir, $CodexSkillsDir)) {
        if (Test-Path $destRoot) {
            $rootItem = Get-Item $destRoot -Force
            if ($rootItem.LinkType) {
                cmd /c rmdir "$destRoot" 2>$null
            }
        }
        if (-not (Test-Path $destRoot)) {
            New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
        }

        # Clean up broken links first
        Get-ChildItem -Path $destRoot -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.LinkType -and (-not (Test-Path $_.FullName))) {
                cmd /c rmdir "$($_.FullName)" 2>$null
            }
        }

        # Link pstack skills
        if (Test-Path $PstackSkillsRoot) {
            Get-ChildItem -Path $PstackSkillsRoot -Directory | ForEach-Object {
                $linkPath = Join-Path $destRoot $_.Name
                $target   = $_.FullName
                if (Test-Path $linkPath) {
                    $item = Get-Item $linkPath -Force
                    if ($item.LinkType -and ($item.Target -notcontains $target)) {
                        cmd /c rmdir "$linkPath" 2>$null
                    }
                }
                if (-not (Test-Path $linkPath)) {
                    New-Item -ItemType Junction -Path $linkPath -Target $target | Out-Null
                }
            }
        }

        # Link custom skills
        if (Test-Path $CustomSkillsRoot) {
            Get-ChildItem -Path $CustomSkillsRoot -Directory | ForEach-Object {
                $skillFile = Join-Path $_.FullName "SKILL.md"
                if (Test-Path $skillFile) {
                    $linkPath = Join-Path $destRoot $_.Name
                    $target   = $_.FullName
                    if (-not (Test-Path $linkPath)) {
                        New-Item -ItemType Junction -Path $linkPath -Target $target | Out-Null
                    }
                }
            }
        }
    }

    # Update Antigravity skills.json with dynamic paths
    $pstackSkillsForward = "/" + $PstackSkillsRoot.Replace('\', '/')
    $customSkillsForward = "/" + $CustomSkillsRoot.Replace('\', '/')
    $skillsJsonContent = @{
        entries = @(
            @{ path = $pstackSkillsForward },
            @{ path = $customSkillsForward }
        )
    } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($AgySkillsJson, $skillsJsonContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  -> Linked all pstack & custom skills to Antigravity, Cursor, Claude Code, and Codex" -ForegroundColor Green
}

function Sync-AutoRules {
    Write-Host "[2/3] Syncing Always-On Auto-Orchestrator rules to IDEs..." -ForegroundColor Cyan

    if (-not (Test-Path $MasterRuleFile)) {
        Write-Warning "Master rule file not found at $MasterRuleFile"
        return
    }

    $ruleBody  = Get-RenderedRuleBody
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)

    # 1. Antigravity Global & Workspace Hierarchy Rules
    if (-not (Test-Path $AgyConfigDir)) {
        New-Item -ItemType Directory -Path $AgyConfigDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($LocalAgentsMd, $ruleBody, $utf8NoBom)
    [System.IO.File]::WriteAllText($DevRootAgentsMd, $ruleBody, $utf8NoBom)
    [System.IO.File]::WriteAllText($AgyGeminiMd, $ruleBody, $utf8NoBom)
    [System.IO.File]::WriteAllText($AgyAgentsMd, $ruleBody, $utf8NoBom)

    # 2. Cursor Always-Apply Rule (.mdc)
    if (-not (Test-Path $CursorRulesDir)) {
        New-Item -ItemType Directory -Path $CursorRulesDir -Force | Out-Null
    }
    $cursorContent = @"
---
description: Autonomous AI Coding Agent + pstack Auto-Orchestrator (always active)
alwaysApply: true
---
$ruleBody
"@
    [System.IO.File]::WriteAllText($CursorAutoRule, $cursorContent, $utf8NoBom)

    # 3. Claude Code Global & Workspace Rules (CLAUDE.md)
    if (-not (Test-Path $ClaudeDir)) {
        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($ClaudeGlobalMd, $ruleBody, $utf8NoBom)
    [System.IO.File]::WriteAllText($DevRootClaudeMd, $ruleBody, $utf8NoBom)
    [System.IO.File]::WriteAllText($LocalClaudeMd, $ruleBody, $utf8NoBom)

    # 4. Codex Global Rule (~/.codex/AGENTS.md)
    if (-not (Test-Path $CodexDir)) {
        New-Item -ItemType Directory -Path $CodexDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($CodexGlobalMd, $ruleBody, $utf8NoBom)

    Write-Host "  -> Updated Antigravity rules ($DevRootAgentsMd, ~/.gemini/config/GEMINI.md)" -ForegroundColor Green
    Write-Host "  -> Updated Cursor rule (~/.cursor/rules/pstack-auto-orchestrator.mdc)" -ForegroundColor Green
    Write-Host "  -> Updated Claude Code rules (~/.claude/CLAUDE.md, $DevRootClaudeMd)" -ForegroundColor Green
    Write-Host "  -> Updated Codex rules (~/.codex/AGENTS.md)" -ForegroundColor Green
}

function Set-ModelInvocation {
    param([bool]$EnableAuto)

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $skillFiles = Get-ChildItem -Path $PstackSkillsRoot -Filter "SKILL.md" -Recurse

    $modifiedCount = 0
    foreach ($file in $skillFiles) {
        $skillName = $file.Directory.Name
        if ($skillName -eq "setup-pstack") { continue }

        $content = [System.IO.File]::ReadAllText($file.FullName, $utf8NoBom)
        if ($EnableAuto) {
            if ($content -match "(?m)^disable-model-invocation:\s*true\r?\n") {
                $newContent = $content -replace "(?m)^disable-model-invocation:\s*true\r?\n", ""
                [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
                $modifiedCount++
            }
        } else {
            if ($content -notmatch "(?m)^disable-model-invocation:") {
                $newContent = $content -replace "(?m)(^description:.*\r?\n)", "`$1disable-model-invocation: true`r`n"
                [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
                $modifiedCount++
            }
        }
    }

    if ($EnableAuto) {
        Write-Host "[3/3] Unlocked model auto-invocation on pstack skills ($modifiedCount updated)." -ForegroundColor Green
    } else {
        Write-Host "[3/3] Locked model auto-invocation on pstack skills ($modifiedCount updated to manual-only)." -ForegroundColor Yellow
    }
}

function Show-Status {
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  Autonomous AI Coding Agent + pstack Control Center Status" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    Write-Host ("`n[0] pstack Source Location   : {0}" -f $PstackRoot) -ForegroundColor $(if (Test-Path $PstackSkillsRoot) { "Green" } else { "Yellow" })

    # 1. Check Symlinks in Antigravity
    $links = Get-ChildItem -Path $AgySkillsDir -Force -ErrorAction SilentlyContinue
    $validLinks = 0
    $brokenLinks = 0
    foreach ($l in $links) {
        if (Test-Path $l.FullName) { $validLinks++ } else { $brokenLinks++ }
    }
    Write-Host ("[1] Antigravity Skills Links : {0} valid, {1} broken" -f $validLinks, $brokenLinks) -ForegroundColor $(if ($brokenLinks -eq 0 -and $validLinks -gt 0) { "Green" } else { "Red" })

    # 2. Check Auto-Invocation unlock status
    $lockedSkills = @(Select-String -Path "$PstackSkillsRoot\*\SKILL.md" -Pattern "^disable-model-invocation:\s*true" -ErrorAction SilentlyContinue)
    $totalSkills  = @(Get-ChildItem -Path $PstackSkillsRoot -Directory -ErrorAction SilentlyContinue).Count
    $autoModeStatus = if ($totalSkills -gt 0 -and $lockedSkills.Count -eq 0) { "ENABLED (AI can invoke all $totalSkills pstack skills automatically)" } else { "MANUAL / LOCKED ($($lockedSkills.Count) skills locked)" }
    Write-Host ("[2] Skill Auto-Invocation    : {0}" -f $autoModeStatus) -ForegroundColor $(if ($totalSkills -gt 0 -and $lockedSkills.Count -eq 0) { "Green" } else { "Yellow" })

    # 3. Check Always-On Rules
    $agyRuleActive    = (Test-Path $DevRootAgentsMd) -and (Test-Path $AgyGeminiMd)
    $cursorRuleActive = Test-Path $CursorAutoRule
    $claudeRuleActive = (Test-Path $ClaudeGlobalMd) -and (Test-Path $ClaudeSkillsDir)
    $codexRuleActive  = (Test-Path $CodexGlobalMd) -and (Test-Path $CodexSkillsDir)
    Write-Host ("[3] Antigravity Auto-Rule    : {0}" -f $(if ($agyRuleActive) { "ACTIVE (~/.gemini/config/GEMINI.md)" } else { "INACTIVE" })) -ForegroundColor $(if ($agyRuleActive) { "Green" } else { "Yellow" })
    Write-Host ("[4] Cursor Auto-Rule         : {0}" -f $(if ($cursorRuleActive) { "ACTIVE (~/.cursor/rules/pstack-auto-orchestrator.mdc)" } else { "INACTIVE" })) -ForegroundColor $(if ($cursorRuleActive) { "Green" } else { "Yellow" })
    Write-Host ("[5] Claude Code Auto-Rule    : {0}" -f $(if ($claudeRuleActive) { "ACTIVE (~/.claude/CLAUDE.md & ~/.claude/skills)" } else { "INACTIVE" })) -ForegroundColor $(if ($claudeRuleActive) { "Green" } else { "Yellow" })
    Write-Host ("[6] Codex Auto-Rule          : {0}" -f $(if ($codexRuleActive) { "ACTIVE (~/.codex/AGENTS.md & ~/.codex/skills)" } else { "INACTIVE" })) -ForegroundColor $(if ($codexRuleActive) { "Green" } else { "Yellow" })

    # 4. Check Model Budget
    if (Test-Path $PstackModelsMd) {
        $budgetLine = Select-String -Path $PstackModelsMd -Pattern "^# budget:" | Select-Object -First 1
        $budgetText = if ($budgetLine) { $budgetLine.Line.Replace("# budget:", "").Trim() } else { "Custom" }
        Write-Host ("[7] pstack Model Config      : Configured (Budget: {0}) -> {1}" -f $budgetText, $PstackModelsMd) -ForegroundColor Green
    } else {
        Write-Host "[7] pstack Model Config      : Default (Run /setup-pstack to customize)" -ForegroundColor Yellow
    }

    # 5. Check Auto-Update Scheduled Task / Startup Hook
    $taskExists = ($null -ne (Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue)) -or (Test-Path $StartupVbsFile)
    Write-Host ("[8] Auto-Update Scheduler    : {0}" -f $(if ($taskExists) { "ACTIVE (Background update daily & at logon)" } else { "INACTIVE" })) -ForegroundColor $(if ($taskExists) { "Green" } else { "Yellow" })

    Write-Host "`nQuick Commands:" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 install                 # First-time setup (clones pstack, enables auto-mode & auto-update)" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 update                  # Pull latest upstream pstack updates & re-sync now" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 enable-autoupdate       # Enable background automatic pstack updates" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 disable-autoupdate      # Disable background automatic pstack updates" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 status                  # Check system status" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 sync                    # Sync rules & repair skill links across IDEs" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 enable-auto             # Enable automatic pstack orchestration" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 disable-auto            # Switch back to manual /poteto-mode only" -ForegroundColor Gray
    Write-Host "  .\pstack-ctl.ps1 init-project <Path>     # Install AGENTS.md, CLAUDE.md & Copilot rules to a project`n" -ForegroundColor Gray
}

function Register-AutoUpdateTask {
    $scriptPath = Join-Path $AutoAiRoot "pstack-ctl.ps1"
    $actionArgs = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" update"

    # 1. Daily Scheduled Task (User-level, no Admin required)
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $actionArgs
    $triggerDaily = New-ScheduledTaskTrigger -Daily -At 10:00AM
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    Register-ScheduledTask -TaskName $ScheduledTaskName -Action $taskAction -Trigger $triggerDaily -Settings $settings -Description "Automatically pulls latest upstream pstack skills and syncs IDE rules." -Force | Out-Null

    # 2. User Startup hidden runner (runs silently at Windows logon without needing Admin privileges)
    $vbsContent = "CreateObject(`"WScript.Shell`").Run `"powershell.exe $actionArgs`", 0, False"
    [System.IO.File]::WriteAllText($StartupVbsFile, $vbsContent, [System.Text.UTF8Encoding]::new($false))

    Write-Host "  -> Enabled background Auto-Update (Daily at 10:00 AM + Windows Logon)" -ForegroundColor Green
}

function Unregister-AutoUpdateTask {
    if (Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
    }
    if (Test-Path $StartupVbsFile) {
        Remove-Item $StartupVbsFile -Force
    }
    Write-Host "  -> Disabled background Auto-Update" -ForegroundColor Yellow
}

function Update-PstackUpstream {
    Ensure-PstackInstalled
    Write-Host "`n[Update] Checking upstream pstack at $PstackRoot..." -ForegroundColor Cyan

    $lockedBefore = @(Select-String -Path "$PstackSkillsRoot\*\SKILL.md" -Pattern "^disable-model-invocation:\s*true" -ErrorAction SilentlyContinue)
    $wasAutoEnabled = ($lockedBefore.Count -eq 0)

    Push-Location $PstackRoot
    try {
        # Fetch first to verify network connectivity before resetting local working tree
        git fetch origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            git checkout -- skills/ 2>$null
            git merge --ff-only 2>$null
        } else {
            Write-Warning "Network unreachable or git fetch failed; keeping existing pstack files."
        }
    } finally {
        Pop-Location
        Sync-SkillLinks
        Sync-AutoRules
        if ($wasAutoEnabled) {
            Set-ModelInvocation -EnableAuto $true
        }
    }
    Write-Host "  -> Upstream pstack check & sync complete!" -ForegroundColor Green
}

switch ($Action) {
    "status" {
        Show-Status
    }
    "update" {
        Update-PstackUpstream
        Show-Status
    }
    "enable-autoupdate" {
        Register-AutoUpdateTask
        Show-Status
    }
    "disable-autoupdate" {
        Unregister-AutoUpdateTask
        Show-Status
    }
    "sync" {
        Sync-SkillLinks
        Sync-AutoRules
        Show-Status
    }
    "install" {
        Sync-SkillLinks
        Sync-AutoRules
        Set-ModelInvocation -EnableAuto $true
        Register-AutoUpdateTask
        Show-Status
    }
    "enable-auto" {
        Sync-SkillLinks
        Sync-AutoRules
        Set-ModelInvocation -EnableAuto $true
        Register-AutoUpdateTask
        Show-Status
    }
    "disable-auto" {
        Set-ModelInvocation -EnableAuto $false
        Unregister-AutoUpdateTask
        foreach ($f in @($DevRootAgentsMd, $DevRootClaudeMd, $AgyGeminiMd, $AgyAgentsMd, $CursorAutoRule, $ClaudeGlobalMd, $CodexGlobalMd)) {
            if (Test-Path $f) { Remove-Item $f -Force }
        }
        Write-Host "Removed global auto-orchestrator rules and auto-update scheduler. You can still invoke /poteto-mode manually." -ForegroundColor Yellow
        Show-Status
    }
    "init-project" {
        if ([string]::IsNullOrWhiteSpace($TargetPath)) {
            Write-Error "Please provide a target project path. Example: .\pstack-ctl.ps1 init-project E:\Dev\my-app"
        }
        if (-not (Test-Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        $ruleBody  = Get-RenderedRuleBody

        $projAgentsMd = Join-Path $TargetPath "AGENTS.md"
        $projClaudeMd = Join-Path $TargetPath "CLAUDE.md"
        [System.IO.File]::WriteAllText($projAgentsMd, $ruleBody, $utf8NoBom)
        [System.IO.File]::WriteAllText($projClaudeMd, $ruleBody, $utf8NoBom)

        $githubDir = Join-Path $TargetPath ".github"
        if (-not (Test-Path $githubDir)) {
            New-Item -ItemType Directory -Path $githubDir -Force | Out-Null
        }
        $copilotMd = Join-Path $githubDir "copilot-instructions.md"
        [System.IO.File]::WriteAllText($copilotMd, $ruleBody, $utf8NoBom)

        Write-Host "Installed AGENTS.md (Antigravity/Cursor/Codex), CLAUDE.md (Claude Code), and .github/copilot-instructions.md (VS Code) to $TargetPath" -ForegroundColor Green
    }
    "help" {
        Show-Status
    }
}
