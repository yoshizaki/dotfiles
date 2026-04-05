# ---------------------------------------------------------------
# 定数
# ---------------------------------------------------------------
Set-Variable -Name ESC           -Value ([char]0x1b) -Option Constant
Set-Variable -Name EXIT_CTRL_C   -Value (-1073741510) -Option Constant  # 0xC000013A

# 予測入力（インテリセンス）を有効化：履歴から提案
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView  # リスト形式で見やすく（好みでInlineに変更可）

# 上下キーで履歴を「前方一致検索」できるようにする
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward


function prompt {
    # 一番最初に直前のコマンドの結果を保存
    $lastSuccess = $? 
    $lastExitCode = $LASTEXITCODE
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $cwd = $ExecutionContext.SessionState.Path.CurrentLocation
    
    # 成功・失敗の判定ロジックを修正
    # $lastCommandSuccess が True なら緑の✔、False なら赤の✘
    # Ctrl+C による中断は「失敗」扱いしない
    $isCtrlC = ($lastExitCode -eq $EXIT_CTRL_C)

    if ($lastSuccess -or $isCtrlC) {
        $statusSymbol = "${ESC}[32m✔${ESC}[0m"
    } else {
        $statusSymbol = "${ESC}[31m✘${ESC}[0m"
    }

    # 失敗時のみ、カッコ内にエラーコードを表示（外部コマンドの場合）
    $codeDisplay = if (-not $lastSuccess -and -not $isCtrlC `
                       -and $null -ne $lastExitCode -and $lastExitCode -ne 0) {
        " ($lastExitCode)"
    } else {
        ""
    }

    Write-Host "" # 視認性のための改行
    Write-Host "[$timestamp] " -ForegroundColor DarkGray -NoNewline
    Write-Host "$env:USERNAME@$env:COMPUTERNAME" -ForegroundColor Green -NoNewline
    Write-Host ":" -NoNewline
    Write-Host "$cwd" -ForegroundColor Blue
    
    return "$statusSymbol$codeDisplay `$ "
}

# -------------------------------------------------------
# トランスクリプト
# -------------------------------------------------------
$transcriptDir = "C:\work\powershellLog"
if (-not (Test-Path $transcriptDir)) { New-Item -ItemType Directory -Path $transcriptDir | Out-Null }

$transcriptPath = Join-Path $transcriptDir "Transcript_$(Get-Date -Format 'yyyy_MM_dd_HH-mm-ss').log"
Start-Transcript -Path $transcriptPath -Append

# -------------------------------------------------------
# ユーティリティ関数
# -------------------------------------------------------
function Get-PureContent {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path
    )
    Get-Content $Path | Where-Object { $_ -notmatch '^\s*(#|;|$)' }
}

# 短い名前で呼び出せるようにエイリアスを設定
Set-Alias nocom Get-PureContent
