# Projet M2Cloud – Déploiement Kubernetes d’une application microservices

## Description

Ce projet consiste à déployer une application composée de plusieurs microservices sur un cluster Kubernetes (AKS ou local). L’objectif est de mettre en place une architecture cloud complète avec conteneurs, scalabilité, monitoring, sécurité et gestion des logs.

L’application se compose des services suivants :

* **web** : Application web consommant les services `applicants.api` et `jobs.api`.
* **applicants.api** : API REST fournissant des données sur les candidats.
* **jobs.api** : API REST fournissant des informations sur les offres d’emploi.
* **identity.api** : API REST gérant l’authentification.
* **sql.data** : Base de données SQL Server pour les données des APIs.
* **rabbitmq** : Service de messagerie pour la communication entre services.

Les dépendances et les variables d’environnement sont définies dans le fichier `docker-compose` du projet.

---

## Objectifs techniques

1. **Conteneurisation**

   * Création d’images Docker pour chaque service.
   * Publication des images dans un registre privé (Docker Hub ou Azure Container Registry).

2. **Déploiement Kubernetes**

   * Déploiement de tous les services sous forme de pods, deployments et StatefulSet pour SQL.
   * Services internes et ingress pour l’accès externe sécurisé via HTTPS.
   * Affinité des pods pour optimiser les performances et communication entre services.
   * Limites et demandes de ressources CPU/Mémoire définies pour chaque service.

3. **Scalabilité**

   * Mise en place d’un **Horizontal Pod Autoscaler** (HPA) basé sur l’utilisation CPU.
   * Démonstration de l’augmentation des replicas sous charge.

4. **Santé et monitoring**

   * Sondes de liveness et readiness configurées pour chaque pod.
   * Installation de Metrics Server, kube-state-metrics et Prometheus pour surveiller le cluster et les pods.

5. **Sécurité**

   * Accès externe via HTTPS avec certificat TLS auto-signé.
   * ServiceAccount dédié avec RBAC restreint.
   * NetworkPolicy pour limiter les communications inter-services.

6. **Gestion des logs**

   * Mise en place d’une stack EFK (Elasticsearch / FluentBit / Kibana) pour centraliser et analyser les logs.
   * Dashboard et recherche filtrée pour détecter les erreurs d’un service.

7. **Automatisation du déploiement**

   * Création d’un **Helm chart** pour automatiser la création des déploiements, services, ingress, HPA, NetworkPolicy et RBAC.
   * CI/CD avec GitHub Actions pour build et push des images Docker.

---

## Ressources par service

| Service        | CPU Requests | CPU Limits | Mem Requests | Mem Limits | Affinité                 |
| -------------- | ------------ | ---------- | ------------ | ---------- | ------------------------ |
| web            | 4m           | 1          | 900Mi        | 2000Mi     | applicants.api, jobs.api |
| applicants.api | 0.5          | 1          | 500Mi        | 1500Mi     | sql.data                 |
| jobs.api       | 0.5          | 1          | 500Mi        | 1500Mi     | sql.data                 |
| identity.api   | 0.5          | 1          | 500Mi        | 1500Mi     | sql.data                 |
| sql.data       | 4m           | 1          | 500Mi        | 1500Mi     | —                        |

---

## Démonstration

Le projet permet de :

* Déployer une architecture microservices complète sur Kubernetes.
* Monitorer l’état des pods, nodes et du cluster via Prometheus.
* Observer le scaling automatique via HPA.
* Consulter et analyser les logs centralisés dans Kibana/OpenSearch Dashboards.
* Assurer la sécurité via TLS, RBAC et NetworkPolicy.
