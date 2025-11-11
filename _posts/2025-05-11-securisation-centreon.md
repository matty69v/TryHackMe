---
date: 2025-05-11 00:00:00 +0100
title: "Sécurisation Centreon : protection des utilisateurs, SELinux, pare-feu, etc."
author: Matty
categories: [Centreon]
tags: [Linux, supervision, centreon, installation, securisation, selinux, firewall]
render_with_liquid: false
image:
    path: /images/centreon_securisation/Securisation-de-base-Centreon.jpg.jpeg
---

## I. Présentation

Dans ce tutoriel, nous allons passer en revue plusieurs bonnes pratiques pour sécuriser votre plateforme Centreon, en activant SELinux, en configurant firewalld, en sécurisant les fichiers de configuration et en appliquant les bonnes pratiques sur les comptes utilisateurs.

Dans l'article précédent, nous avons vu comment installer Centreon, la plateforme de supervision open source qui permet de garder un œil sur l'ensemble de votre infrastructure IT. Maintenant que l'outil est opérationnel, il est temps d'aborder un aspect tout aussi essentiel : la sécurisation du serveur Centreon.

Comme tout système connecté et exposé à un réseau, un serveur de supervision peut devenir une cible privilégiée. Protéger Centreon, c'est non seulement sécuriser l'accès à l'interface, mais aussi renforcer la sécurité des comptes utilisateurs, protéger les fichiers sensibles et s'assurer que seuls les services autorisés peuvent accéder à votre serveur.

Centreon : installation de votre serveur de supervision sous Linux

## II. Étapes de sécurisation de Centreon

Dans cette partie, nous allons renforcer la sécurité de notre serveur Centreon en mettant en place plusieurs mesures clés : sécurisation des comptes utilisateurs, activation de SELinux, installation des modules Centreon adaptés, protection des fichiers de configuration, et enfin, configuration du pare-feu avec firewalld.

### A. Protéger les comptes utilisateurs

Lors de l'installation de Centreon, plusieurs comptes système sont créés automatiquement (root, centreon, centreon-engine, centreon-broker, centreon-gorgone). Ces comptes ont des rôles précis :

- **root** → administrateur du système
- **centreon** → gestion de la plateforme web
- **centreon-engine** → moteur de supervision
- **centreon-broker** → transport des données de supervision
- **centreon-gorgone** → exécution des actions à distance

Si on garde les mots de passe par défaut, n'importe qui connaissant Centreon peut essayer de se connecter et prendre le contrôle du serveur. Modifier les mots de passe est donc la première étape de protection.

```bash
passwd <nom_compte>
```

Pour l'utilisateur apache, qui sert à exécuter les pages web, il est normal qu'il ne puisse pas ouvrir une session ou utiliser un terminal. On vérifie ça avec la commande suivante :

```bash
cat /etc/passwd | grep apache
```

Vous devez avoir la valeur `/sbin/nologin` pour le compte apache. Cela signifie que même si quelqu'un vole le compte apache, il ne pourra pas l'utiliser pour ouvrir une session shell.

```
apache:x:48:48:Apache:/usr/share/httpd:/sbin/nologin
```

### B. Activer SELinux

SELinux est un mécanisme de sécurité qui fonctionne en complément des permissions classiques. Même si un pirate arrive à exploiter une faille dans Apache, SELinux limite les actions qu'il peut faire. Par exemple, il l'empêchera d'accéder à des fichiers système ou de modifier certains processus.

Pour plus d'informations à propos de SELinux, visitez la documentation Red Hat.

On vérifie d'abord qu'aucune alerte n'est présente :

```bash
cat /var/log/audit/audit.log | grep -i denied
```

Si des erreurs apparaissent, vous devez les analyser et décider si ces erreurs sont régulières et doivent être ajoutées des règles SELinux par défaut de Centreon. Pour ce faire, utilisez la commande suivante pour transformer l'erreur en règles SELinux :

```bash
audit2allow -a
```

Pour réactiver SELinux, éditez le fichier `/etc/selinux/config` et changez la valeur avec les options suivantes :

```
SELINUX=enforcing  # Ppour que la politique de sécurité SELinux soit appliquée en mode strict.
```

Puis, redémarrez votre serveur afin que les modifications prennent effet.

```bash
shutdown -r now
```

Enfin, comme Centreon a besoin de règles spécifiques pour bien fonctionner avec SELinux, on installe les modules adaptés :

```bash
dnf install centreon-common-selinux \
centreon-web-selinux \
centreon-broker-selinux \
centreon-engine-selinux \
centreon-gorgoned-selinux \
centreon-plugins-selinux
```

### C. Sécurisation des fichiers de configuration

Les fichiers comme `/etc/centreon/conf.pm` et `/etc/centreon/centreon.conf.php` contiennent des informations sensibles :

- Identifiants de base de données
- Chemins système
- Clés internes

Si ces fichiers sont mal protégés, un utilisateur malveillant pourrait les lire et compromettre tout le système. On réduit donc les droits d'accès uniquement à l'utilisateur et au groupe concernés avec les commandes suivantes :

```bash
chown centreon:centreon /etc/centreon/conf.pm
chmod 660 /etc/centreon/conf.pm
chown apache:apache /etc/centreon/centreon.conf.php
chmod 660 /etc/centreon/centreon.conf.php
```

### D. Activation de Firewalld

Ces commandes activent et démarrent le service firewalld, qui gère les règles de filtrage des connexions réseau, permettant de contrôler les accès entrants et sortants sur le serveur.

Ensuite, pour sécuriser le serveur, nous allons ajouter des règles à firewalld afin de restreindre l'accès aux services nécessaires, tout en bloquant les connexions non autorisées. Cela permet de limiter les risques d'intrusion en n'ouvrant que les ports indispensables pour notre utilisation de Centreon.

```bash
systemctl enable firewalld
systemctl start firewalld
```

Exécutez les commandes suivantes afin d'ajouter vos règles firewall sur le serveur Centreon (changez les numéros de port si vous avez personnalisé ceux-ci) :

```bash
# Protocoles par défaut (SSH, HTTP, HTTPS, SNMP) 
firewall-cmd --zone=public --add-service=ssh --permanent 
firewall-cmd --zone=public --add-service=http --permanent 
firewall-cmd --zone=public --add-service=https --permanent 
firewall-cmd --zone=public --add-service=snmp --permanent 
firewall-cmd --zone=public --add-service=snmptrap --permanent 
# Centreon Gorgone 
firewall-cmd --zone=public --add-port=5556/tcp --permanent 
# Centreon Broker 
firewall-cmd --zone=public --add-port=5669/tcp –permanent
```

> **Note :** pour renforcer la sécurité de l'accès SSH, envisagez de modifier le port par défaut (22) utilisé par ce service. Il conviendra alors d'adapter la règle de firewall pour cibler le bon port.

Une fois les règles ajoutées, rechargez firewalld :

```bash
firewall-cmd –reload
```

Pour vérifier que la configuration a été correctement appliquée, utilisez la commande suivante pour lister toutes les règles actives :

```bash
firewall-cmd --list-all
```

Par exemple, voici le résultat attendu :

```
public (active)
target: default
icmp-block-inversion: no
interfaces: eth0
sources:
services: http snmp snmptrap ssh
ports: 5556/tcp 5669/tcp
protocols:
forward: no
masquerade: no
forward-ports:
source-ports:
icmp-blocks:
rich rules:
```

Ce qui donne :

![IMAGE](/images/centreon_securisation/Configuration-Firewall-sur-serveur-Centreon.png)

## III. Conclusion

En suivant ces étapes, vous avez renforcé la sécurité de votre serveur Centreon en configurant le pare-feu et en restreignant l'accès réseau. Cela constitue une première ligne de défense pour protéger vos données et garantir la stabilité de votre infrastructure.

Dans les prochains articles, nous irons plus loin dans la sécurisation de Centreon avec la mise en place de Fail2ban pour protéger davantage votre serveur contre les attaques par brute-force, ainsi que l'activation du HTTPS pour sécuriser les échanges entre les utilisateurs et l'interface web de Centreon (HTTPS).