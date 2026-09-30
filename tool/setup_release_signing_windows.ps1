param(
  [string]$Repo = "riccardopinato/Agenda-per-Anna"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$LegacyWorkflowRef = "6c82412f35334b0b58972f6a1fea32533bfdbfc8"
$LegacyCertificateSha256 = "58280A02078A610D47F9CF910E4BAC97992AB364C7C05A8E18DAF934DA5ACA58"

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

function Decrypt-OpenSslAes256CbcPbkdf2(
  [string]$InputPath,
  [string]$OutputPath,
  [string]$Password
) {
  $payload = [System.IO.File]::ReadAllBytes($InputPath)
  if ($payload.Length -lt 32) {
    throw "Recovery cifrato non valido."
  }

  $header = [System.Text.Encoding]::ASCII.GetString($payload, 0, 8)
  if ($header -ne "Salted__") {
    throw "Formato recovery cifrato non riconosciuto."
  }

  $salt = New-Object byte[] 8
  [Array]::Copy($payload, 8, $salt, 0, 8)

  $ciphertext = New-Object byte[] ($payload.Length - 16)
  [Array]::Copy($payload, 16, $ciphertext, 0, $ciphertext.Length)

  $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
    $Password,
    $salt,
    250000,
    [System.Security.Cryptography.HashAlgorithmName]::SHA256
  )
  try {
    $key = $derive.GetBytes(32)
    $iv = $derive.GetBytes(16)
  } finally {
    $derive.Dispose()
  }

  $aes = [System.Security.Cryptography.Aes]::Create()
  $aes.KeySize = 256
  $aes.BlockSize = 128
  $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
  $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
  $aes.Key = $key
  $aes.IV = $iv

  try {
    $decryptor = $aes.CreateDecryptor()
    try {
      $plain = $decryptor.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)
      [System.IO.File]::WriteAllBytes($OutputPath, $plain)
    } finally {
      $decryptor.Dispose()
    }
  } finally {
    $aes.Dispose()
    [Array]::Clear($key, 0, $key.Length)
    [Array]::Clear($iv, 0, $iv.Length)
  }
}

function Read-LegacySigningMetadata([string]$RepoName) {
  $encodedLines = & gh api "repos/$RepoName/contents/.github/workflows/sideload-arm64.yml?ref=$LegacyWorkflowRef" --jq ".content"
  if ($LASTEXITCODE -ne 0 -or -not $encodedLines) {
    throw "Non riesco a leggere il contratto della vecchia firma."
  }

  $encoded = ($encodedLines -join "")
  $workflowBytes = [Convert]::FromBase64String($encoded)
  $workflow = [System.Text.Encoding]::UTF8.GetString($workflowBytes)

  $storeMatch = [regex]::Match($workflow, "-storepass\s+([^\s\\]+)")
  $keyMatch = [regex]::Match($workflow, "-keypass\s+([^\s\\]+)")
  $aliasMatch = [regex]::Match($workflow, "-alias\s+([^\s\\]+)")

  if (-not $storeMatch.Success -or -not $keyMatch.Success -or -not $aliasMatch.Success) {
    throw "Impossibile ricostruire in modo automatico i metadati della vecchia firma."
  }

  return [PSCustomObject]@{
    StorePassword = $storeMatch.Groups[1].Value
    KeyPassword = $keyMatch.Groups[1].Value
    Alias = $aliasMatch.Groups[1].Value
  }
}

function Try-RecoverLegacySigning(
  [string]$RepoName,
  [string]$KeystorePath,
  [string]$RecoveryPath
) {
  $migrationPassphrase = New-RandomSecret 48
  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("anna-signing-recovery-" + [Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $temporarySecretCreated = $false
  try {
    Write-Host "Cerco la firma sideload storica nella GitHub Actions cache..."

    & gh secret set SIGNING_MIGRATION_PASSPHRASE --repo $RepoName --body $migrationPassphrase | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Impossibile creare il secret temporaneo di migrazione."
    }
    $temporarySecretCreated = $true

    & gh workflow run legacy-signing-recovery.yml --repo $RepoName --ref main | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Impossibile avviare il recupero della firma storica."
    }

    Start-Sleep -Seconds 4
    $runId = & gh run list --repo $RepoName --workflow legacy-signing-recovery.yml --limit 1 --json databaseId --jq ".[0].databaseId"
    if (-not $runId) {
      throw "Non riesco a trovare il run di recupero della firma storica."
    }

    $watchOutput = & gh run watch $runId --repo $RepoName --exit-status 2>&1
    $watchOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
      throw "Il workflow di recupero della firma storica e fallito."
    }

    & gh run download $runId --repo $RepoName --name annas-diary-legacy-signing-recovery --dir $tempRoot | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Impossibile scaricare il risultato cifrato del recupero."
    }

    $encrypted = Get-ChildItem -Path $tempRoot -Recurse -Filter "legacy-sideload.jks.enc" | Select-Object -First 1
    if (-not $encrypted) {
      Write-Warning "La vecchia cache di firma non e piu disponibile. Verra creata una nuova identita stabile."
      return $null
    }

    $env:SIGNING_MIGRATION_PASSPHRASE_LOCAL = $migrationPassphrase
    Decrypt-OpenSslAes256CbcPbkdf2 -InputPath $encrypted.FullName -OutputPath $KeystorePath -Password $env:SIGNING_MIGRATION_PASSPHRASE_LOCAL
    Remove-Item Env:SIGNING_MIGRATION_PASSPHRASE_LOCAL -ErrorAction SilentlyContinue

    $legacy = Read-LegacySigningMetadata -RepoName $RepoName

    & keytool -list -keystore $KeystorePath -storepass $legacy.StorePassword -alias $legacy.Alias | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "La JKS storica recuperata non supera la verifica."
    }

    $certPath = Join-Path $tempRoot "legacy-cert.der"
    & keytool -exportcert -keystore $KeystorePath -storepass $legacy.StorePassword -alias $legacy.Alias -file $certPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Impossibile verificare il certificato della JKS storica."
    }

    $fingerprint = (Get-FileHash -Algorithm SHA256 -Path $certPath).Hash.ToUpperInvariant()
    if ($fingerprint -ne $LegacyCertificateSha256) {
      throw "La JKS recuperata non corrisponde al certificato sideload storico atteso."
    }

    $recovery = [ordered]@{
      repository = $RepoName
      createdAtUtc = [DateTime]::UtcNow.ToString("o")
      source = "legacy-actions-cache"
      keystoreFile = "agenda-release.jks"
      certificateSha256 = $fingerprint
      alias = $legacy.Alias
      keystorePassword = $legacy.StorePassword
      keyPassword = $legacy.KeyPassword
      note = "BACKUP CRITICO: questa e la firma storica usata dagli APK sideload precedenti."
    }
    $recovery | ConvertTo-Json -Depth 3 | Set-Content -Path $RecoveryPath -Encoding UTF8

    Write-Host "Firma sideload storica recuperata e verificata."
    return [PSCustomObject]@{
      StorePassword = $legacy.StorePassword
      KeyPassword = $legacy.KeyPassword
      Alias = $legacy.Alias
      Source = "legacy-actions-cache"
    }
  } finally {
    Remove-Item Env:SIGNING_MIGRATION_PASSPHRASE_LOCAL -ErrorAction SilentlyContinue
    if ($temporarySecretCreated) {
      & gh secret delete SIGNING_MIGRATION_PASSPHRASE --repo $RepoName 2>$null | Out-Null
    }
    Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
  }
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
  $legacy = Try-RecoverLegacySigning -RepoName $Repo -KeystorePath $KeystorePath -RecoveryPath $RecoveryPath

  if ($legacy) {
    $StorePassword = $legacy.StorePassword
    $KeyPassword = $legacy.KeyPassword
    $Alias = $legacy.Alias
  } else {
    $StorePassword = New-RandomSecret
    $KeyPassword = New-RandomSecret
    $Alias = "annas-diary-release"

    Write-Host "Genero la prima keystore release permanente..."
    & keytool -genkeypair -storetype JKS -keystore $KeystorePath -storepass $StorePassword -keypass $KeyPassword -alias $Alias -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Annas Diary, OU=Mobile, O=Riccardo Pinato, C=IT" -noprompt
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $KeystorePath)) {
      throw "Creazione keystore fallita."
    }

    $Recovery = [ordered]@{
      repository = $Repo
      createdAtUtc = [DateTime]::UtcNow.ToString("o")
      source = "new-permanent-key"
      keystoreFile = "agenda-release.jks"
      alias = $Alias
      keystorePassword = $StorePassword
      keyPassword = $KeyPassword
      note = "BACKUP CRITICO: senza questa keystore non puoi firmare aggiornamenti con la stessa identita."
    }
    $Recovery | ConvertTo-Json -Depth 3 | Set-Content -Path $RecoveryPath -Encoding UTF8
  }
}

& keytool -list -keystore $KeystorePath -storepass $StorePassword -alias $Alias | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "La keystore release non supera la verifica locale."
}

$KeystoreBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($KeystorePath))

try {
  $aclTarget = ("{0}:(OI)(CI)F" -f $env:USERNAME)
  & icacls $BackupDir /inheritance:r /grant:r $aclTarget | Out-Null
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
  & gh secret set $entry.Key --repo $Repo --body $entry.Value | Out-Null
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
& gh workflow run signing-doctor.yml --repo $Repo --ref main | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Impossibile avviare Signing Doctor."
}

Start-Sleep -Seconds 4
$DoctorRun = & gh run list --repo $Repo --workflow signing-doctor.yml --limit 1 --json databaseId --jq ".[0].databaseId"
if (-not $DoctorRun) {
  throw "Non riesco a trovare il run di Signing Doctor."
}

$doctorOutput = & gh run watch $DoctorRun --repo $Repo --exit-status 2>&1
$doctorOutput | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
  throw "Signing Doctor fallito. Non avvio la build APK."
}

Write-Host "Signing Doctor OK. Avvio la build ARM64 stabile..."
& gh workflow run sideload-arm64.yml --repo $Repo --ref main | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Impossibile avviare il workflow ARM64."
}

Start-Sleep -Seconds 4
$BuildRun = & gh run list --repo $Repo --workflow sideload-arm64.yml --limit 1 --json databaseId --jq ".[0].databaseId"
if (-not $BuildRun) {
  throw "Non riesco a trovare il run ARM64."
}

$buildOutput = & gh run watch $BuildRun --repo $Repo --exit-status 2>&1
$buildOutput | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
  throw "La firma e configurata, ma la build ARM64 ha rilevato un altro problema."
}

Write-Host ""
Write-Host "FIRMA ANDROID CONFIGURATA E VERIFICATA."
Write-Host "Backup locale: $BackupDir"
Write-Host "Copia l intera cartella in almeno un secondo supporto sicuro e offline."
Write-Host "Non condividere mai SIGNING-RECOVERY.json o agenda-release.jks."
