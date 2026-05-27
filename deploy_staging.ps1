# ============================================================
# CheckFast — DEPLOY PARA STAGING (AMBIENTE DE TESTES)
# ============================================================
# Uso: Clique com botão direito > "Executar com PowerShell"
#      OU abra o terminal e execute:  .\deploy_staging.ps1
# ============================================================

$flutter = "C:\Users\Stand Alone\flutter\bin\flutter.bat"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$firebase = "firebase"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CheckFast — Deploy para STAGING" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 0. Firebase Login (abre o navegador para autenticar)
Write-Host "[0/3] Verificando autenticação no Firebase..." -ForegroundColor Yellow
& $firebase login --no-localhost
& $flutter build web --release --web-renderer html
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO na compilação! Verifique os erros acima." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "[2/3] Build concluído com sucesso!" -ForegroundColor Green

# 2. Deploy para staging (Preview Channel de 7 dias)
Write-Host ""
Write-Host "[3/3] Enviando para o ambiente de STAGING..." -ForegroundColor Yellow
& $firebase hosting:channel:deploy staging --expires 7d --project checkfast-28a72

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO no deploy! Tente rodar 'firebase login' antes." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  STAGING PUBLICADO COM SUCESSO!" -ForegroundColor Green
Write-Host "  Acesse o link gerado acima para testar." -ForegroundColor Green
Write-Host "  O ambiente expira em 7 dias." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
pause
