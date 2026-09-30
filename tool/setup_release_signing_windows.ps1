param(
  [string]$Repo = "riccardopinato/Agenda-per-Anna"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Require-Command([string]$Name, [string]$InstallHint) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name non trovato. $InstallHint"
  }
}

function New-RandomSecret([int]$ByteCount = 36) {
  $buffer = New-Object byte[] $ByteCount
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try {
    $rng.GetBytes($buffer)
  } finally {
    $rng.Dispose()
  }
  return ([Convert]::ToBase64String($buffer)).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

Require-Command "keytool" "Installa un JDK recente e riapri PowerShell."
Require-Command "gh" "Installa GitHub CLI da https://cli.github.com/ e riapri PowerShell."

& gh auth status | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "GitHub CLI non autenticato. Esegui: gh auth login"
}

$BackupDir = Join-Path $HOME ".annas-diary-signing"
$KeystorePath = Join-Path $BackupDir "agenda-release.jks"
$RecoveryPath = Join-Path $BackupDir "SIGNING-RECOVERY.json"

$HasKeystore = Test-Path $KeystorePath
$HasRecovery = Test-Path $RecoveryPath

if ($HasKeystore -xor $HasRecovery) {
  throw "Backup signing incompleto in $BackupDir. Non genero una nuova chiave: ripristina prima la cartella completa."
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

if ($HasKeystore -and $HasRecovery) {
  Write-Host "Riutilizzo la keystore release stabile esistente..."
  $Recovery = Get-Content -Raw -Path $RecoveryPath | ConvertFrom-Json
  $Alias = [string]$Recovery.alias
  $StorePassword = [string]$Recovery.keystorePassword
  $KeyPassword = [string]$Recovery.keyPassword

  if ([string]::IsNullOrWhiteSpace($Alias) -or
      [string]::IsNullOrWhiteSpace($StorePassword) -or
      [string]::IsNullOrWhiteSpace($KeyPassword)) {
    throw "SIGNING-RECOVERY.json non contiene i dati necessari."
  }
} else {
  $StorePassword = New-RandomSecret
  $KeyPassword = New-RandomSecret
  $Alias = "annas-diary-release"

  Write-Host "Genero la keystore release stabile..."
  & keytool -genkeypair -storetype JKS -keystore $KeystorePath -storepass $StorePassword -keypass $KeyPassword -alias $Alias -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Annas Diary, OU=Mobile, O=Riccardo Pinato, C=IT" -noprompt
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $KeystorePath)) {
    throw "Creazione keystore fallita."
  }

  $Recovery = [ordered]@{
    repository = $Repo
    createdAtUtc = [DateTime]::UtcNow.ToString("o")
    keystoreFile = "agenda-release.jks"
    alias = $Alias
    keystorePassword = $StorePassword
    keyPassword = $KeyPassword
    note = "BACKUP CRITICO: senza questa keystore non puoi firmare aggiornamenti con la stessa identita."
  }
  $Recovery | ConvertTo-Json -Depth 3 | Set-Content -Path $RecoveryPath -Encoding UTF8
}

& keytool -list -keystore $KeystorePath -storepass $StorePassword -alias $Alias | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "La keystore release non supera la verifica locale."
}

$KeystoreBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($KeystorePath))

try {
  & icacls $BackupDir /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" | Out-Null
} catch {
  Write-Warning "Proteggi manualmente la cartella di signing: non sono riuscito a restringere automaticamente i permessi NTFS."
}

Write-Host "Registro i quattro GitHub Actions Secrets senza stamparne il contenuto..."
$Secrets = [ordered]@{
  ANDROID_KEYSTORE_BASE64 = $KeystoreBase64
  ANDROID_KEYSTORE_PASSWORD = $StorePassword
  ANDROID_KEY_ALIAS = $Alias
  ANDROID_KEY_PASSWORD = $KeyPassword
}

foreach ($entry in $Secrets.GetEnumerator()) {
  & gh secret set $entry.Key --repo $Repo --body $entry.Value
  if ($LASTEXITCODE -ne 0) {
    throw "Impossibile impostare il secret $($entry.Key)."
  }
}

Write-Host "Verifico che GitHub esponga tutti i nomi dei secret..."
$SecretNames = & gh secret list --repo $Repo --json name --jq ".[].name"
foreach ($name in $Secrets.Keys) {
  if ($SecretNames -notcontains $name) {
    throw "Il secret $name non risulta registrato."
  }
}

Write-Host "Avvio Signing Doctor..."
& gh workflow run signing-doctor.yml --repo $Repo --ref main
if ($LASTEXITCODE -ne 0) {
  throw "Impossibile avviare Signing Doctor."
}

Start-Sleep -Seconds 4
$DoctorRun = & gh run list --repo $Repo --workflow signing-doctor.yml --limit 1 --json databaseId --jq ".[0].databaseId"
if (-not $DoctorRun) {
  throw "Non riesco a trovare il run di Signing Doctor."
}

& gh run watch $DoctorRun --repo $Repo --exit-status
if ($LASTEXITCODE -ne 0) {
  throw "Signing Doctor fallito. Non avvio la build APK."
}

Write-Host "Signing Doctor OK. Avvio la build ARM64 stabile..."
& gh workflow run sideload-arm64.yml --repo $Repo --ref main
if ($LASTEXITCODE -ne 0) {
  throw "Impossibile avviare il workflow ARM64."
}

Start-Sleep -Seconds 4
$BuildRun = & gh run list --repo $Repo --workflow sideload-arm64.yml --limit 1 --json databaseId --jq ".[0].databaseId"
if (-not $BuildRun) {
  throw "Non riesco a trovare il run ARM64."
}

& gh run watch $BuildRun --repo $Repo --exit-status
if ($LASTEXITCODE -ne 0) {
  throw "La firma e configurata, ma la build ARM64 ha rilevato un altro problema."
}

Write-Host ""
Write-Host "FIRMA ANDROID CONFIGURATA E VERIFICATA."
Write-Host "Backup locale: $BackupDir"
Write-Host "Copia l intera cartella in almeno un secondo supporto sicuro e offline."
Write-Host "Non condividere mai SIGNING-RECOVERY.json o agenda-release.jks."
