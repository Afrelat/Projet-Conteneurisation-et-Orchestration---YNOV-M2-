# --- CONFIGURATION MISE A JOUR ---
$DOCKER_USER = "warshall"
$VERSION = "v1.0.0"
$IMAGES = @(
    @{ Name = "webmvc";         Path = "Web/Dockerfile" },
    @{ Name = "applicants-api"; Path = "Services/Applicants.Api/Dockerfile" },
    @{ Name = "jobs-api";       Path = "Services/Jobs.Api/Dockerfile" },
    @{ Name = "identity-api";   Path = "Services/Identity.Api/Dockerfile" },
    # CORRECTION ICI : Le dossier s'appelle "Database" sur ton image
    @{ Name = "sql-data";       Path = "Database/Dockerfile" } 
)

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   BUILD & PUSH TOTAL (PSEUDO: WARSHALL)             " -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

docker login

foreach ($Image in $IMAGES) {
    $FullImageName = "$DOCKER_USER/$($Image.Name):$VERSION"
    Write-Host "`n[*] Construction de : $FullImageName" -ForegroundColor Cyan
    
    # On reste a la racine (.) pour que Docker voit le dossier Database
    docker build -t $FullImageName -f $($Image.Path) .

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Reussi. Push en cours..." -ForegroundColor Green
        docker push $FullImageName
    } else {
        Write-Host "[ERREUR] Echec sur $($Image.Name)." -ForegroundColor Red
        break
    }
}