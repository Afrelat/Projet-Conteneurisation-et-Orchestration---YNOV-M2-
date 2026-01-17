# --- CONFIGURATION DES CHEMINS ---
$NAMESPACE = "projet-apps"
$ELK_PATH        = "k8s/elk/elk-stack.yaml"
$SQL_PATH        = "k8s/sql/sql-deployment.yaml"
$REDIS_PATH      = "k8s/redis/redis-deployment.yaml"
$RABBIT_PATH     = "k8s/rabbitmq/rabbitmq-deployment.yaml"
$IDENTITY_PATH   = "k8s/identity/identity-deployment.yaml"
$JOBS_PATH       = "k8s/jobs/jobs-deployment.yaml"
$APPLICANTS_PATH = "k8s/applicant/applicants-deployment.yaml"
$WEB_PATH        = "k8s/web/web-deployment.yaml"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   DÉPLOIEMENT : ELK PRIORITAIRE PUIS MICROSERVICES    " -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# 1. PRÉPARATION DU NAMESPACE
Write-Host "[1/5] Vérification du Namespace..." -ForegroundColor Yellow
if (!(kubectl get ns $NAMESPACE --ignore-not-found)) {
    kubectl create ns $NAMESPACE
    Write-Host "Namespace '$NAMESPACE' créé." -ForegroundColor Green
}

# 2. PRIORITÉ ABSOLUE : LA STACK ELK
Write-Host "`n[2/5] Déploiement de la stack ELK (Collecteur de logs)..." -ForegroundColor Yellow
kubectl apply -f $ELK_PATH -n $NAMESPACE

Write-Host "Attente du démarrage complet de ELK (Elasticsearch/Logstash)..." -ForegroundColor Gray
kubectl wait --for=condition=ready pod -l app=elasticsearch -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=logstash -n $NAMESPACE --timeout=120s

# INITIALISATION DE L'INDEX AVANT LE RESTE
Write-Host "[*] Initialisation du flux de logs..." -ForegroundColor Cyan
kubectl run init-elk-flux --image=busybox -n $NAMESPACE --rm -i --restart=Never -- /bin/sh -c 'echo "{\"message\": \"ELK PREPRET - READY FOR LOGS\", \"app\": \"system-monitor\"}" | nc -w 1 logstash 5044'
Write-Host "ELK est maintenant prêt à recevoir les logs des microservices." -ForegroundColor Green

# 3. INFRASTRUCTURES DE DONNÉES
Write-Host "`n[3/5] Déploiement des bases de données et bus..." -ForegroundColor Yellow
kubectl apply -f $SQL_PATH -n $NAMESPACE
kubectl apply -f $REDIS_PATH -n $NAMESPACE
kubectl apply -f $RABBIT_PATH -n $NAMESPACE

Write-Host "Attente de la disponibilité de SQL et RabbitMQ..." -ForegroundColor Gray
kubectl wait --for=condition=ready pod -l app=sql -n $NAMESPACE --timeout=90s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n $NAMESPACE --timeout=90s

# 4. MICROSERVICES ET WEB (Ils pourront logger dès le démarrage)
Write-Host "`n[4/5] Déploiement des microservices API et Frontend..." -ForegroundColor Yellow
kubectl apply -f $IDENTITY_PATH -n $NAMESPACE
kubectl apply -f $JOBS_PATH -n $NAMESPACE
kubectl apply -f $APPLICANTS_PATH -n $NAMESPACE
if (Test-Path $WEB_PATH) { kubectl apply -f $WEB_PATH -n $NAMESPACE }

Write-Host "Finalisation du démarrage des applications..." -ForegroundColor Gray
kubectl wait --for=condition=ready pod -l app=applicants-api -n $NAMESPACE --timeout=120s
kubectl wait --for=condition=ready pod -l app=webmvc -n $NAMESPACE --timeout=120s

# 5. TUNNELS (Ports corrigés selon les standards de service)
Write-Host "`n[5/5] Ouverture des tunnels d'accès..." -ForegroundColor Yellow

# On mappe le port 80 du service web vers le 8080 local
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/webmvc 8080:80 -n $NAMESPACE"

# On mappe le port 5601 de Kibana
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/kibana 5601:5601 -n $NAMESPACE"

# On mappe le port 80 du service API vers le 8081 local (Vérifiez si votre service API est sur le port 80 ou 8080)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/applicants-api 8081:80 -n $NAMESPACE"

Write-Host "`n[SUCCÈS] ELK a été déployé en premier. Tout est opérationnel." -ForegroundColor Green
kubectl get pods -n $NAMESPACE