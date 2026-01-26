# --- CONFIGURATION MISE A JOUR ---
$DOCKER_USER = "warshall"
$VERSION = "v2.0.0"
$IMAGES = @(
    @{ Name = "webmvc";         Path = "Web/Dockerfile" },
    @{ Name = "applicants-api"; Path = "Services/Applicants.Api/Dockerfile" },
    @{ Name = "jobs-api";       Path = "Services/Jobs.Api/Dockerfile" },
    @{ Name = "identity-api";   Path = "Services/Identity.Api/Dockerfile" },
    # CORRECTION ICI : Le dossier s'appelle "Database" sur ton image
    @{ Name = "sql-data";       Path = "Database/Dockerfile" } 
    @{ Name = "kibana";       Path = "logging/kibana/Dockerfile" } 
    @{ Name = "fluent-bit";       Path = "logging/fluent-bit/Dockerfile" } 
    @{ Name = "elasticsearch";       Path = "logging/elasticsearch/Dockerfile" } 
)

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   BUILD & PUSH TOTAL (PSEUDO: WARSHALL)             " -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

docker login

foreach ($Image in $IMAGES) {
    $FullImageName = "$DOCKER_USER/$($Image.Name):$VERSION"
    Write-Host "`n[*] Construction de : $FullImageName" -ForegroundColor Cyan

    # On récupère le dossier où se trouve le Dockerfile (ex: logging/fluent-bit)
    $Directory = Split-Path $Image.Path

    # On build en utilisant le dossier spécifique comme contexte
    docker build -t $FullImageName $Directory

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[+] Build réussi, envoi vers Docker Hub..." -ForegroundColor Green
        docker push $FullImageName
    } else {
        Write-Host "[ERREUR] Échec sur $($Image.Name)." -ForegroundColor Red
    }
}