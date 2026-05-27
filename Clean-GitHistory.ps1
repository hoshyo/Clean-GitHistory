# ==============================================
# Git 历史全面清理脚本（推送所有分支 + 不自动退出）
# ==============================================

Write-Host "=== Git 历史邮箱清理脚本 ===" -ForegroundColor Cyan
Write-Host ""

# 获取当前项目的 git 配置
$targetName  = git config user.name
$targetEmail = git config user.email

if (-not $targetName -or -not $targetEmail) {
    Write-Host "错误：当前目录未配置 git user.name 或 user.email" -ForegroundColor Red
    Read-Host "按任意键退出..."
    exit 1
}

Write-Host "当前将使用的身份：" -ForegroundColor Yellow
Write-Host "  Name : $targetName"
Write-Host "  Email: $targetEmail"
Write-Host ""

# 自动安装 git-filter-repo
function Install-GitFilterRepo {
    Write-Host "未检测到 git-filter-repo，正在尝试自动安装..." -ForegroundColor Yellow

    $pip = Get-Command pip -ErrorAction SilentlyContinue
    if (-not $pip) {
        Write-Host "未检测到 pip，请先安装 Python 后再运行。" -ForegroundColor Red
        Read-Host "按任意键退出..."
        exit 1
    }

    pip install git-filter-repo
    if ($LASTEXITCODE -ne 0) {
        Write-Host "安装失败，请手动执行：pip install git-filter-repo" -ForegroundColor Red
        Read-Host "按任意键退出..."
        exit 1
    }
    Write-Host "git-filter-repo 安装成功！" -ForegroundColor Green
}

$filterRepo = Get-Command git-filter-repo -ErrorAction SilentlyContinue
if (-not $filterRepo) {
    Install-GitFilterRepo
}

# 第一次确认
Write-Host "警告：此操作将永久重写所有本地分支的提交历史！" -ForegroundColor Red
$confirm1 = Read-Host "是否继续重写历史？(yes/no)"

if ($confirm1 -ne "yes") {
    Write-Host "已取消操作" -ForegroundColor Yellow
    Read-Host "按任意键退出..."
    exit 0
}

Write-Host ""
Write-Host "开始重写历史..." -ForegroundColor Green

# 获取所有本地分支
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

# 第二次确认：是否强制推送（所有分支）
Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "警告：即将执行强制推送（推送所有分支）！" -ForegroundColor Red
Write-Host "这会覆盖远程仓库的所有分支历史，请谨慎操作。" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red

$confirmPush = Read-Host "是否立即执行强制推送所有分支？(yes/no)"

if ($confirmPush -eq "yes") {
    Write-Host ""
    Write-Host "正在强制推送所有分支..." -ForegroundColor Yellow
    
    git push origin --all --force

    if ($LASTEXITCODE -eq 0) {
        Write-Host "所有分支强制推送成功！" -ForegroundColor Green
    } else {
        Write-Host "推送失败，请手动检查。" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "已跳过强制推送。" -ForegroundColor Yellow
    Write-Host "稍后可手动执行：git push origin --all --force" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "脚本执行完毕。" -ForegroundColor Green
Read-Host "按任意键退出窗口..."
