# ==============================================
# Git 历史全面清理脚本（自动拉取并创建所有本地分支）
# ==============================================

Write-Host "=== Git 历史邮箱清理脚本 ===" -ForegroundColor Cyan
Write-Host ""

$targetName  = git config user.name
$targetEmail = git config user.email

if (-not $targetName -or -not $targetEmail) {
    Write-Host "错误：未配置 git user.name 或 user.email" -ForegroundColor Red
    Read-Host "按任意键退出..."
    exit 1
}

Write-Host "目标身份：$targetName <$targetEmail>" -ForegroundColor Yellow
Write-Host ""

# 自动安装 git-filter-repo
if (-not (Get-Command git-filter-repo -ErrorAction SilentlyContinue)) {
    Write-Host "正在安装 git-filter-repo..." -ForegroundColor Yellow
    pip install git-filter-repo
}

# ==================== 关键改进：拉取所有远程分支并创建本地分支 ====================
Write-Host "正在拉取所有远程分支..." -ForegroundColor Yellow
git fetch --all --prune

Write-Host "正在为远程分支创建本地跟踪分支..." -ForegroundColor Yellow

git branch -r | ForEach-Object {
    $remoteBranch = $_.Trim()
    if ($remoteBranch -match "^origin/(.+)$" -and $remoteBranch -notmatch "HEAD$") {
        $localBranch = $matches[1]
        # 如果本地不存在这个分支，则创建跟踪分支
        if (-not (git branch --list $localBranch)) {
            git branch --track $localBranch $remoteBranch 2>$null
            Write-Host "  已创建本地分支: $localBranch" -ForegroundColor Green
        }
    }
}

# ==================== 开始重写历史 ====================
Write-Host ""
Write-Host "警告：即将重写所有本地分支的历史！" -ForegroundColor Red
$confirm = Read-Host "是否继续？(yes/no)"

if ($confirm -ne "yes") {
    Write-Host "已取消" -ForegroundColor Yellow
    Read-Host "按任意键退出..."
    exit 0
}

$branches = git for-each-ref --format='%(refname)' refs/heads/ | ForEach-Object { $_.Trim() }

git filter-repo --force `
    --commit-callback "
        commit.author_name = b'$targetName'
        commit.author_email = b'$targetEmail'
        commit.committer_name = b'$targetName'
        commit.committer_email = b'$targetEmail'
    " `
    --refs $branches

Write-Host ""
Write-Host "历史重写完成！" -ForegroundColor Green

# 强制推送
Write-Host ""
$pushConfirm = Read-Host "是否立即强制推送所有分支？(yes/no)"

if ($pushConfirm -eq "yes") {
    Write-Host "正在强制推送所有分支..." -ForegroundColor Yellow
    git push origin --all --force
    Write-Host "推送完成。" -ForegroundColor Green
} else {
    Write-Host "已跳过推送，可手动执行：git push origin --all --force" -ForegroundColor Cyan
}

Write-Host ""
Read-Host "按任意键退出..."
