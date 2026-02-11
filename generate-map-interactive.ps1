# PB: Generate Interactive Leska Map HTML
# Usage: .\generate-map-interactive.ps1

# Set console encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$leska = Get-Content .\leska.json -Encoding UTF8 | ConvertFrom-Json

$stageIcons = @{
    done = "[OK]"
    active = "[>>]"
    pending = "[ ]"
}

# Generate Mermaid diagram code
$mermaidCode = "flowchart LR`n"

for ($i = 0; $i -lt $leska.stages.Count; $i++) {
    $stage = $leska.stages[$i]
    $icon = $stageIcons[$stage.status]
    $nodeId = "S$($stage.id)"
    $label = "$icon $($stage.name)"
    
    $style = if ($stage.status -eq "active") { ":::active" } else { "" }
    
    # Add click event
    $mermaidCode += "    $nodeId[`"$label`"]$style`n"
    $mermaidCode += "    click $nodeId call showStage($($stage.id))`n"
    
    if ($i -lt $leska.stages.Count - 1) {
        $nextId = "S$($leska.stages[$i + 1].id)"
        $mermaidCode += "    $nodeId --> $nextId`n"
    }
}

$mermaidCode += "`n    classDef active fill:#264f78,stroke:#007acc,stroke-width:3px`n"

# Generate stage panels HTML
$stagePanelsHtml = ""

foreach ($stage in $leska.stages) {
    $statusClass = $stage.status
    $icon = $stageIcons[$stage.status]
    
    $tasksHtml = ""
    if ($stage.tasks -and $stage.tasks.Count -gt 0) {
        $tasksHtml = "<div class='stage-section'><h4>Tasks:</h4><ul>"
        foreach ($task in $stage.tasks) {
            $checkIcon = if ($task.done) { "[X]" } else { "[ ]" }
            $taskClass = if ($task.done) { "done" } else { "" }
            $tasksHtml += "<li class='$taskClass'>$checkIcon $($task.text)</li>"
        }
        $tasksHtml += "</ul></div>"
    }
    
    $criteriaHtml = ""
    if ($stage.criteria -and $stage.criteria.Count -gt 0) {
        $criteriaHtml = "<div class='stage-section'><h4>Success Criteria:</h4><ul>"
        foreach ($criterion in $stage.criteria) {
            $criteriaHtml += "<li>$criterion</li>"
        }
        $criteriaHtml += "</ul></div>"
    }
    
    $stagePanelsHtml += @"
<div class='stage-panel' id='stage-$($stage.id)' data-stage='$($stage.id)'>
    <div class='stage-header $statusClass'>
        <h3>$icon Stage $($stage.id): $($stage.name)</h3>
        <span class='status-badge $statusClass'>$($stage.status)</span>
    </div>
    <div class='stage-body'>
        <p class='stage-description'>$($stage.description)</p>
        $criteriaHtml
        $tasksHtml
    </div>
</div>
"@
}

# Generate full HTML
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Leska Map - $($leska.project)</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
        mermaid.initialize({ 
            startOnLoad: true,
            theme: 'dark',
            flowchart: {
                curve: 'linear',
                padding: 15
            },
            securityLevel: 'loose'
        });
    </script>
    <style>
        * { box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #1e1e1e;
            color: #d4d4d4;
            margin: 0;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        h1 {
            color: #4ec9b0;
            margin-bottom: 10px;
        }
        
        .goal {
            color: #9cdcfe;
            font-size: 1.1em;
            margin-bottom: 30px;
        }
        
        .mermaid {
            background: #252526;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        
        .stage-panels {
            margin-top: 30px;
        }
        
        .stage-panel {
            background: #252526;
            border-radius: 8px;
            margin-bottom: 15px;
            overflow: hidden;
            border: 2px solid transparent;
            transition: all 0.3s ease;
        }
        
        .stage-panel.selected {
            border-color: #007acc;
            box-shadow: 0 0 10px rgba(0, 122, 204, 0.3);
        }
        
        .stage-header {
            padding: 15px 20px;
            background: #2d2d30;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            user-select: none;
        }
        
        .stage-header:hover {
            background: #3e3e42;
        }
        
        .stage-header h3 {
            margin: 0;
            color: #d4d4d4;
            font-size: 1.1em;
        }
        
        .stage-header.done h3 { color: #4ec9b0; }
        .stage-header.active h3 { color: #007acc; }
        
        .status-badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.85em;
            font-weight: 600;
        }
        
        .status-badge.done {
            background: #4ec9b0;
            color: #1e1e1e;
        }
        
        .status-badge.active {
            background: #007acc;
            color: #ffffff;
        }
        
        .status-badge.pending {
            background: #3e3e42;
            color: #858585;
        }
        
        .stage-body {
            padding: 20px;
            display: none;
        }
        
        .stage-panel.expanded .stage-body {
            display: block;
        }
        
        .stage-description {
            color: #9cdcfe;
            margin-bottom: 15px;
            font-style: italic;
        }
        
        .stage-section {
            margin-bottom: 15px;
        }
        
        .stage-section h4 {
            color: #4ec9b0;
            margin: 0 0 10px 0;
            font-size: 0.95em;
        }
        
        .stage-section ul {
            margin: 0;
            padding-left: 20px;
        }
        
        .stage-section li {
            margin: 5px 0;
            color: #cccccc;
        }
        
        .stage-section li.done {
            color: #4ec9b0;
            text-decoration: line-through;
            opacity: 0.7;
        }
        
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #3e3e42;
            color: #858585;
            font-size: 0.9em;
        }
        
        .refresh-note {
            background: #3e3e42;
            padding: 10px;
            border-radius: 4px;
            margin-top: 20px;
            font-size: 0.9em;
            color: #ce9178;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$($leska.project)</h1>
        <div class="goal">Goal: $($leska.goal)</div>
        
        <div class="mermaid">
$mermaidCode
        </div>
        
        <div class="stage-panels">
$stagePanelsHtml
        </div>
        
        <div class="footer">Folder: $($leska.folder)</div>
        
        <div class="refresh-note">
            Note: To update map after changing leska.json, run: <code>.\generate-map-interactive.ps1</code>
        </div>
    </div>

    <script>
        function showStage(stageId) {
            // Remove selection from all panels
            document.querySelectorAll('.stage-panel').forEach(panel => {
                panel.classList.remove('selected');
                panel.classList.remove('expanded');
            });
            
            // Select and expand clicked stage
            const panel = document.getElementById('stage-' + stageId);
            if (panel) {
                panel.classList.add('selected');
                panel.classList.add('expanded');
                
                // Scroll to panel
                panel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }
        }
        
        // Toggle panel on header click
        document.addEventListener('DOMContentLoaded', () => {
            document.querySelectorAll('.stage-header').forEach(header => {
                header.addEventListener('click', (e) => {
                    const panel = e.target.closest('.stage-panel');
                    const wasExpanded = panel.classList.contains('expanded');
                    
                    // Close all panels
                    document.querySelectorAll('.stage-panel').forEach(p => {
                        p.classList.remove('expanded');
                        p.classList.remove('selected');
                    });
                    
                    // Toggle current panel
                    if (!wasExpanded) {
                        panel.classList.add('expanded');
                        panel.classList.add('selected');
                    }
                });
            });
            
            // Auto-expand active stage
            const activePanel = document.querySelector('.stage-panel .stage-header.active');
            if (activePanel) {
                activePanel.click();
            }
        });
    </script>
</body>
</html>
"@

# Save HTML with proper UTF-8 encoding (with BOM for better browser compatibility)
$outputPath = Join-Path $PWD "leska-view.html"
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
$writer = [System.IO.StreamWriter]::new($outputPath, $false, $utf8WithBom)
$writer.Write($html)
$writer.Close()

Write-Host "`nInteractive HTML created: leska-view.html" -ForegroundColor Green
Write-Host "Opening in browser..." -ForegroundColor Cyan

# Open in default browser
Start-Process ".\leska-view.html"
