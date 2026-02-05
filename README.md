------------------------------------------------------------------------------------------------------
ATELIER FROM IMAGE TO CLUSTER
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : Cet atelier consiste à **industrialiser le cycle de vie d’une application** simple en construisant une **image applicative Nginx** personnalisée avec **Packer**, puis en déployant automatiquement cette application sur un **cluster Kubernetes** léger (K3d) à l’aide d’**Ansible**, le tout dans un environnement reproductible via **GitHub Codespaces**.
L’objectif est de comprendre comment des outils d’Infrastructure as Code permettent de passer d’un artefact applicatif maîtrisé à un déploiement cohérent et automatisé sur une plateforme d’exécution.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
**Faites un Fork de ce projet**. Si besion, voici une vidéo d'accompagnement pour vous aider dans les "Forks" : [Forker ce projet](https://youtu.be/p33-7XQ29zQ) 
  
Ensuite depuis l'onglet [CODE] de votre nouveau Repository, **ouvrez un Codespace Github**.
  
---------------------------------------------------
Séquence 2 : Création du cluster Kubernetes K3d
---------------------------------------------------
Objectif : Créer votre cluster Kubernetes K3d  
Difficulté : Simple (~5 minutes)
---------------------------------------------------
Vous allez dans cette séquence mettre en place un cluster Kubernetes K3d contenant un master et 2 workers.  
Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Création du cluster K3d**  
```
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```
```
k3d cluster create lab \
  --servers 1 \
  --agents 2
```
**vérification du cluster**  
```
kubectl get nodes
```
**Déploiement d'une application (Docker Mario)**  
```
kubectl create deployment mario --image=sevenajay/mario
------------------------------------------------------------------------------------------------------
ATELIER: IMAGE TO CLUSTER — VERSION CONCISE
------------------------------------------------------------------------------------------------------
Objectif : construire une image Nginx (Packer optional), importer l'image dans un cluster K3d et déployer via Ansible.

Prérequis rapides
- Environnement recommandé : Ubuntu / GitHub Codespaces
- Outils : `docker`, `kubectl`, `k3d`, `ansible-playbook` (optionnel : `packer`)

Commandes clés
- Vérifier / installer dépendances :
```bash
make deps
```
- Flow complet (build + import + deploy) :
```bash
make all
```
- Déploiement manuel (sans `make`) :
```bash
docker build -t image_to_cluster/nginx-custom:latest .
k3d image import image_to_cluster/nginx-custom:latest -c lab
ansible-playbook ansible/deploy.yml
```

Vérifications
- Pods running : `kubectl get pods -l app=nginx-custom -o wide`
- Service et accès :
  - `kubectl get svc nginx-custom -o wide`
  - `kubectl port-forward svc/nginx-custom 8080:80` → ouvrir `http://localhost:8080`

Dépannage rapide
- `k3d` ou `ansible-playbook` manquants → `make deps` ou installer manuellement
- `ImagePullBackOff` → vérifier `k3d image import` et `imagePullPolicy: IfNotPresent` dans `k8s/deployment.yaml`

Livrable attendu
- Commandes lancées, sorties `kubectl get pods`/`kubectl get svc` et capture d'écran de l'application.

------------------------------------------------------------------------------------------------------
 Pour cette partie, fournissez une documentation claire et reproductible permettant à un évaluateur (ou à un collègue) de lancer l'ensemble du pipeline depuis un poste propre ou un Codespace. Voici exactement ce qu'il faut inclure et comment le tester.



