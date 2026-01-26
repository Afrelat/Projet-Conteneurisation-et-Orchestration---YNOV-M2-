# --- CONFIGURATION DES CHEMINS ---
$NAMESPACE = "projet-apps"
$EFK_PATH        = "k8s/efk/efk-stack.yaml" # Nom mis à jour pour EFK
$SQL_PATH        = "k8s/sql/sql-deployment.yaml"
$REDIS_PATH      = "k8s/redis/redis-deployment.yaml"
$RABBIT_PATH     = "k8s/rabbitmq/rabbitmq-deployment.yaml"
$IDENTITY_PATH   = "k8s/identity/identity-deployment.yaml"
$JOBS_PATH       = "k8s/jobs/jobs-deployment.yaml"
$APPLICANTS_PATH = "k8s/applicant/applicants-deployment.yaml"
$WEB_PATH        = "k8s/web/web-deployment.yaml"
$METRICS_PATH    = "k8s/metrics_server/component.yaml"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   DÉPLOIEMENT : ORCHESTRATION EFK + MICROSERVICES     " -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# 1. NAMESPACE
if (!(kubectl get ns $NAMESPACE --ignore-not-found)) { kubectl create ns $NAMESPACE }

# 2. INFRASTRUCTURE PRIORITAIRE
Write-Host "[1/4] Déploiement de l'Infrastructure (EFK, SQL, Redis, Rabbit)..." -ForegroundColor Yellow
kubectl apply -f $METRICS_PATH
kubectl apply -f $EFK_PATH -n $NAMESPACE
kubectl apply -f $SQL_PATH -n $NAMESPACE
kubectl apply -f $REDIS_PATH -n $NAMESPACE
kubectl apply -f $RABBIT_PATH -n $NAMESPACE


Write-Host "Attente de l'infrastructure..." -ForegroundColor Gray
kubectl wait --for=condition=ready pod -l app=elasticsearch -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=fluent-bit -n $NAMESPACE --timeout=120s # Changé : logstash -> fluent-bit
kubectl wait --for=condition=ready pod -l app=sql-data -n $NAMESPACE --timeout=180s

# Pause de sécurité pour laisser SQL Server démarrer ses bases internes
Write-Host "Initialisation de SQL Server (20s)..." -ForegroundColor Gray
Start-Sleep -Seconds 20

# 3. MICROSERVICES (APIs)
Write-Host "`n[2/4] Déploiement des APIs..." -ForegroundColor Yellow
kubectl apply -f $IDENTITY_PATH -n $NAMESPACE
kubectl apply -f $JOBS_PATH -n $NAMESPACE
kubectl apply -f $APPLICANTS_PATH -n $NAMESPACE

Write-Host "Attente des APIs..." -ForegroundColor Gray
kubectl wait --for=condition=ready pod -l app=identity-api -n $NAMESPACE --timeout=120s
kubectl wait --for=condition=ready pod -l app=jobs-api -n $NAMESPACE --timeout=120s
kubectl wait --for=condition=ready pod -l app=applicants-api -n $NAMESPACE --timeout=120s

# 4. FRONTEND
Write-Host "`n[3/4] Déploiement du Frontend Web..." -ForegroundColor Yellow
if (Test-Path $WEB_PATH) { 
    kubectl apply -f $WEB_PATH -n $NAMESPACE 
    kubectl wait --for=condition=ready pod -l app=webmvc -n $NAMESPACE --timeout=120s
}

# 5. ACCÈS RÉSEAU (CORRIGÉ POUR KIBANA PORT 5601)
Write-Host "`n[4/4] Ouverture des accès..." -ForegroundColor Green
# On sépare les ports K8S car Kibana n'est pas sur le port 80
$standardApps = @{ "webmvc"=8080; "identity-api"=8081; "jobs-api"=8082; "applicants-api"=8083 }
foreach ($app in $standardApps.Keys) {
    $portLocal = $standardApps[$app]
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/$app ${portLocal}:80 -n $NAMESPACE"
}
# Ligne spécifique pour Kibana (TargetPort 5601)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/kibana 5601:5601 -n $NAMESPACE"

# 6. TESTS DE CONNECTIVITÉ (CORRIGÉ POUR LES RESTARTS)
Write-Host "`nAnalyse de la stabilité..." -ForegroundColor Yellow
$pods = kubectl get pods -n $NAMESPACE -o json | ConvertFrom-Json
foreach ($pod in $pods.items) {
    $podName = $pod.metadata.name
    # Protection contre les pods sans containerStatuses (ex: Pending)
    $restarts = if ($pod.status.containerStatuses) { $pod.status.containerStatuses[0].restartCount } else { 0 }
    $status = $pod.status.phase

    if ($restarts -gt 0) { Write-Host "ATTENTION : $podName a redémarré $restarts fois." -ForegroundColor Yellow }
    if ($status -eq "Running") { Write-Host "Pod $podName : [OK]" -ForegroundColor Green } 
    else { Write-Host "Pod $podName : [$status]" -ForegroundColor Red }
}