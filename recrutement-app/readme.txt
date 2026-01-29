helm lint .

helm template recrutement-app .

helm install recrutement-app . -n projet-apps --create-namespace

helm upgrade recrutement-app . -n projet-apps

helm uninstall recrutement-app -n projet-apps