# --- CONFIGURATION DES CHEMINS ---
$NAMESPACE = "projet-apps"

# Chemins des manifestes par dossiers
$SQL_PATH        = "k8s/sql/sql-deployment.yaml"
$REDIS_PATH      = "k8s/redis/redis-deployment.yaml"
$RABBIT_PATH     = "k8s/rabbitmq/rabbitmq-deployment.yaml"
$IDENTITY_PATH   = "k8s/identity/identity-deployment.yaml"
$JOBS_PATH       = "k8s/jobs/jobs-deployment.yaml"
$APPLICANTS_PATH = "k8s/applicant/applicants-deployment.yaml"
$WEB_PATH        = "k8s/web/web-deployment.yaml"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   DÉPLOIEMENT COMPLET DE L'ARCHITECTURE KUBERNETES   " -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan


# 1. PRÉPARATION DU NAMESPACE
Write-Host "[1/4] Vérification du Namespace..." -ForegroundColor Yellow
# Utilisation de 2>$null pour ignorer l'erreur si le namespace n'existe pas
$nsExists = kubectl get ns $NAMESPACE --ignore-not-found
if (!$nsExists) {
    kubectl create ns $NAMESPACE
    Write-Host "Namespace '$NAMESPACE' créé." -ForegroundColor Green
} else {
    Write-Host "Namespace '$NAMESPACE' déjà présent." -ForegroundColor Gray
}

# 2. FONDATIONS (Infrastructures de données)
Write-Host "`n[2/4] Déploiement des infrastructures (Bases de données & Bus)..." -ForegroundColor Yellow
kubectl apply -f $SQL_PATH -n $NAMESPACE
kubectl apply -f $REDIS_PATH -n $NAMESPACE
kubectl apply -f $RABBIT_PATH -n $NAMESPACE

Write-Host "Attente du statut 'Ready' pour les fondations..." -ForegroundColor Gray
kubectl wait --for=condition=ready pod -l app=sql -n $NAMESPACE --timeout=90s
kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=60s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n $NAMESPACE --timeout=90s

# 3. COUCHE API (Logique métier)
Write-Host "`n[3/4] Déploiement des microservices API..." -ForegroundColor Yellow
kubectl apply -f $IDENTITY_PATH -n $NAMESPACE
kubectl apply -f $JOBS_PATH -n $NAMESPACE
kubectl apply -f $APPLICANTS_PATH -n $NAMESPACE

# 4. COUCHE WEB (Interface utilisateur)
Write-Host "`n[4/4] Déploiement de l'application Web Frontend..." -ForegroundColor Yellow
if (Test-Path $WEB_PATH) {
    kubectl apply -f $WEB_PATH -n $NAMESPACE
} else {
    Write-Warning "Fichier $WEB_PATH introuvable."
}

# 5. OUVERTURE DES ACCÈS (Port-Forwarding automatique)
Write-Host "`n[5/5] Ouverture des tunnels d'accès..." -ForegroundColor Yellow

# On attend 10 secondes que les derniers Pods (Web/API) finissent de s'initialiser
Write-Host "Attente de l'initialisation réseau (10s)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Utilisation de -NoExit pour garder la fenêtre ouverte en cas d'erreur
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/webmvc 8080:80 -n $NAMESPACE"
Write-Host " -> Web accessible sur : http://localhost:8080" -ForegroundColor Cyan

Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward pod/rabbitmq-0 15672:15672 -n $NAMESPACE"
Write-Host " -> RabbitMQ accessible sur : http://localhost:15672" -ForegroundColor Cyan

# Attention : vérifiez bien que le nom du service est applicants-api dans votre YAML
# Syntaxe : [Port_Local]:[Port_Pod] 
# On bypass le port du Service pour taper directement sur le port 8080 du conteneur
# On tape directement dans le Deployment (le conteneur)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward deployment/applicants-api 8081:8080 -n $NAMESPACE"
Write-Host "`n[INFO] Gardez les fenêtres secondaires ouvertes pour maintenir l'accès." -ForegroundColor DarkYellow


# VÉRIFICATION FINALE
Write-Host "`n--- Résumé des ressources déployées ---" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE -o wide

Write-Host "`n[SUCCÈS] L'architecture est opérationnelle." -ForegroundColor Green
Write-Host "Prochaine étape suggérée : Configuration de l'Ingress ou du HPA." -ForegroundColor Gray