# Quick Setup Script for GitHub-based NATS Deployment
# This script helps you initialize the GitHub repository

param(
    [Parameter(Mandatory=$true)]
    [string]$GithubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "nats-server"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "NATS Server - GitHub Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if git is initialized
if (-not (Test-Path ".git")) {
    Write-Host "`n[1/4] Initializing Git repository..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial NATS server configuration"
    Write-Host "✓ Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "`n[1/4] Git repository already initialized" -ForegroundColor Green
}

# Instructions for GitHub
Write-Host "`n[2/4] Create GitHub Repository" -ForegroundColor Yellow
Write-Host "Please create a new repository on GitHub:" -ForegroundColor White
Write-Host "  1. Go to: https://github.com/new" -ForegroundColor Cyan
Write-Host "  2. Repository name: $RepoName" -ForegroundColor Cyan
Write-Host "  3. Make it PUBLIC (important!)" -ForegroundColor Cyan
Write-Host "  4. DO NOT initialize with README" -ForegroundColor Cyan
Write-Host ""

$continue = Read-Host "Have you created the repository? (y/n)"
if ($continue -ne 'y') {
    Write-Host "Please create the repository first, then run this script again." -ForegroundColor Yellow
    exit
}

# Add remote and push
Write-Host "`n[3/4] Pushing to GitHub..." -ForegroundColor Yellow
$repoUrl = "https://github.com/${GithubUsername}/${RepoName}.git"

try {
    git remote add origin $repoUrl 2>$null
} catch {
    Write-Host "Remote already exists, updating..." -ForegroundColor Yellow
    git remote set-url origin $repoUrl
}

git branch -M main
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Code pushed to GitHub" -ForegroundColor Green
    
    Write-Host "`n[4/4] Next Steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Wait for GitHub Actions to complete (~1-2 minutes)" -ForegroundColor White
    Write-Host "   Check status: https://github.com/${GithubUsername}/${RepoName}/actions" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Make the container image public:" -ForegroundColor White
    Write-Host "   a. Go to: https://github.com/${GithubUsername}?tab=packages" -ForegroundColor Cyan
    Write-Host "   b. Click on 'nats-server'" -ForegroundColor Cyan
    Write-Host "   c. Click 'Package settings'" -ForegroundColor Cyan
    Write-Host "   d. Scroll to 'Danger Zone' → 'Change visibility' → 'Public'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Deploy to Azure:" -ForegroundColor White
    Write-Host "   .\deploy-from-github.ps1 -GithubUsername '$GithubUsername'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Setup Complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to push to GitHub" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  - Repository exists at: $repoUrl" -ForegroundColor White
    Write-Host "  - You have push permissions" -ForegroundColor White
    Write-Host "  - Git credentials are configured" -ForegroundColor White
}
