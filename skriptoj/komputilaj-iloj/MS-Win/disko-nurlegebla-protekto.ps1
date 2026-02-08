# Vérifier si PowerShell est lancé en admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Write-Host "ERREUR : Lance PowerShell en tant qu'administrateur." -ForegroundColor Red
    exit
}

Write-Host "=== Analyse des disques ===`n"

# Récupérer tous les disques en lecture seule
$readonlyDisks = Get-Disk | Where-Object { $_.IsReadOnly -eq $true }

if ($readonlyDisks.Count -eq 0) {
    Write-Host "Aucun disque n'est en lecture seule." -ForegroundColor Green
    exit
}

foreach ($disk in $readonlyDisks) {

    Write-Host "Disque détecté en lecture seule :" -ForegroundColor Yellow
    $disk | Format-Table Number, FriendlyName, IsReadOnly, OperationalStatus

    # Confirmation utilisateur
    $confirm = Read-Host "Retirer la protection en écriture du disque $($disk.Number) ? (o/n)"

    if ($confirm -ne "o") {
        Write-Host "→ Ignoré." -ForegroundColor Cyan
        continue
    }

    Write-Host "→ Tentative via Set-Disk..." -ForegroundColor White

    try {
        Set-Disk -Number $disk.Number -IsReadOnly $false -ErrorAction Stop
        Write-Host "✓ Protection retirée via Set-Disk." -ForegroundColor Green
    }
    catch {
        Write-Host "Set-Disk a échoué. Tentative via diskpart..." -ForegroundColor Yellow

        $dp = @"
select disk $($disk.Number)
attributes disk clear readonly
exit
"@

        $dp | diskpart | Out-Null
    }

    # Vérification
    $updated = Get-Disk -Number $disk.Number

    if ($updated.IsReadOnly -eq $false) {
        Write-Host "✓ Le disque $($disk.Number) n'est plus en lecture seule." -ForegroundColor Green
    }
    else {
        Write-Host "✗ Échec : le disque $($disk.Number) reste protégé." -ForegroundColor Red
    }

    Write-Host ""
}

Write-Host "=== Traitement terminé ==="
