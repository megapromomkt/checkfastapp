# ============================================================
# CheckFast — DEPLOY PARA PRODUÇÃO (checkfast.app.br)
# ============================================================
# ⚠️  ATENÇÃO: Isso vai atualizar o site REAL!
# Só execute após aprovação no ambiente de staging.
# ============================================================

$flutter = "C:\Users\Stand Alone\flutter\bin\flutter.bat"
$firebase = "C:\Users\Stand Alone\AppData\Roaming\npm\firebase.cmd"

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "  CheckFast — Deploy para PRODUÇÃO" -ForegroundColor Red
Write-Host "  Site: checkfast.app.br" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  ATENÇÃO: Você está prestes a atualizar o SITE REAL." -ForegroundColor Yellow
Write-Host "Só continue se já aprovou as mudanças no ambiente de staging!" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Digite 'SIM' para confirmar o deploy em produção"

if ($confirm -ne "SIM") {
    Write-Host ""
    Write-Host "Deploy cancelado. Nenhuma alteração foi feita." -ForegroundColor Cyan
    pause
    exit 0
}

# 1. Build Flutter Web
Write-Host ""
Write-Host "[1/3] Compilando o Flutter para Web (produção)..." -ForegroundColor Yellow
& $flutter build web --release --web-renderer html
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO na compilação! Verifique os erros acima." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "[2/3] Build concluído com sucesso!" -ForegroundColor Green

# 2. Deploy para produção
Write-Host ""
Write-Host "[3/3] Enviando para PRODUÇÃO (checkfast.app.br)..." -ForegroundColor Yellow
& $firebase deploy --only hosting:production --project checkfast-28a72

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO no deploy! Tente rodar 'firebase login' antes." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  PRODUÇÃO ATUALIZADA COM SUCESSO!" -ForegroundColor Green
Write-Host "  Acesse: https://checkfast.app.br" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
pause
