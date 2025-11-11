---
date: 2025-06-01 00:00:00 +0100
title: "Centreon : supervision d'un serveur VMware ESXi avec le connecteur de Centreon"
author: Matty
categories: [Centreon]
tags: [Linux, supervision, centreon, esxi, snmp]
render_with_liquid: false
image:
    path: /images/centreon_esxi/Centreon-superviser-ESXi-avec-SNMP.jpg.jpeg
---

## I. Présentation

Dans cet article, nous allons découvrir comment superviser efficacement vos ESXi VMware à l'aide du connecteur intégré de Centreon. Depuis la version 24.10, Centreon propose un connecteur VMware natif, qui simplifie grandement la supervision en évitant de recourir à des scripts ou à des méthodes complexes. Cette approche vous permet de centraliser facilement la surveillance de vos hyperviseurs et de gagner un temps précieux. Dans un prochain article, nous verrons comment appliquer la même méthode pour superviser un serveur VMware vCenter.

Grâce à cette configuration, vous serez en mesure de surveiller les principaux indicateurs de performance de vos hôtes ESXi, notamment l'usage CPU, la mémoire (RAM), l'espace de stockage, l'état des datastores, la latence d'accès disque, l'uptime... Le connecteur permet aussi de détecter la présence d'alarmes ESXi, de vérifier si l'hôte est en mode maintenance, de superviser l'état de certains services internes, ou encore de remonter le nombre total de machines virtuelles actives.

En revanche, ce connecteur ne permet pas (actuellement) d'obtenir des informations détaillées sur chaque VM (nom, IP, état, consommation de ressources individuelle, etc.). Pour cela, une supervision via vCenter sera nécessaire ce point sera abordé dans un prochain article.

Avant de commencer, voici, pour rappel, nos précédents tutoriels sur Centreon :

- Centreon : installation de votre serveur de supervision sous Linux
- Sécurisation Centreon : protection des utilisateurs, SELinux, pare-feu, etc.
- Sécurisation Centreon : comment configurer l'accès HTTPS pour l'interface Web ?
- Centreon : comment superviser des serveurs Linux avec SNMPv3 ?
- Centreon : comment superviser Windows Server ?
- Centreon : comment importer des hôtes via un fichier CSV et l'API CLAPI ?

## II. Supervision VMware ESXi

### A. Création de l'hôte dans Centreon

La première étape afin de pouvoir débuter la supervision de votre ESXi est de rajouter votre hôte sur votre plateforme en y renseignant les informations nécessaires comme vu dans les précédents tutoriels et d'installer le connecteur de supervision associé VMware ESX en vous rendant dans **Configuration -> Monitoring Connector Manager** :

![Installation du connecteur VMWare dans Centreon]( /images/centreon_esxi/1.png)

Désormais, vous pouvez créer votre hôte en y ajoutant le template **Virt-VMWare2-ESX-custom** :

![Ajout du template VMWare ESXi dans Centreon]( /images/centreon_esxi/2.png)

### B. Ajout d'un utilisateur sur votre ESXi

Afin de pouvoir utiliser le connecteur Centreon il est nécessaire de créer un utilisateur en Lecture Seule sur votre ESXi rendez-vous sur l'interface WEB et dans **Gérer -> Sécurité et utilisateurs -> Utilisateurs -> Utilisateurs -> Ajouter un utilisateur**.

Dans ce cas, nous allons procéder à la création d'un utilisateur nommé `centreon`. Cet utilisateur sera configuré spécifiquement pour des besoins d'accès à une application ou un service, sans nécessiter un accès direct au shell du système. Vous pouvez aussi utiliser un nom avec une partie aléatoire pour rendre plus difficile la découverte.

![Création d'un utilisateur sur ESXi]( /images/centreon_esxi/3.png)

Désormais, notre utilisateur est créé ! Nous devons alors lui mettre les autorisations « Lecture Seule ».

Rendez-vous dans votre page d'accueil de votre ESXi, puis allez dans **Actions -> Autorisations -> Ajouter un utilisateur**.

![Ajout des autorisations sur ESXi]( /images/centreon_esxi/4.png)

Une fois cette page atteinte, nous allons définir l'utilisateur auquel nous souhaitons modifier les autorisations dans notre cas `centreon` que nous mettons en « Lecture Seule ».

Une fois cette procédure faite, aucune autre modification n'est nécessaire sur votre ESXi, nous allons désormais paramétrer dans Centreon les éléments nécessaires à sa supervision.

### C. Connecteur VMWare dans Centreon

Avant de débuter la supervision VMWare, Centreon utilise un daemon pour se connecter et requêter l'ESXi.

Installez le daemon sur tous les collecteurs avec la commande suivante :

```bash
dnf install centreon-plugin-Virtualization-VMWare-daemon
```

Pour démarrer le daemon et l'activer au démarrage :

```bash
systemctl start centreon_vmware 
systemctl enable centreon_vmware
```

**Note :** vous pouvez vérifier que votre configuration est fonctionnelle en consultant les logs dans `/var/log/centreon/centreon_vmware.log`.

Afin de pouvoir utiliser le connecteur VMWare dans votre Centreon rendez-vous dans **Configuration -> Connectors -> Additional Configurations**, puis cliquez sur la touche « + Add ».

Une fenêtre va s'ouvrir et nous allons renseigner les informations nécessaires pour le que connecteur puisse utiliser les données de notre ESXi.

Commencez par saisir le **Name**, c'est-à-dire le nom que vous souhaitez donner à cet hôte supervisé, par exemple : `ESXI1`. Ce nom doit être clair et explicite pour pouvoir l'identifier facilement dans Centreon. Dans le champ **Description**, indiquez une courte phrase décrivant ce que vous supervisez, par exemple : « Supervision de l'esxi1 ». Ce champ est informatif et vous aidera à documenter votre configuration.

Ensuite, sélectionnez le **Type** correspondant à la version de votre ESXi, ici : `VMware 6/7`. Choisissez ensuite le **Poller**, c'est-à-dire le serveur Centreon qui collectera les données, dans notre cas : `Central`.

Dans la section **Parameters**, indiquez le **vCenter name**, qui correspond au nom affiché pour votre ESXi, par exemple : `ESXI1`. Pour le champ **URL**, saisissez l'adresse d'accès à l'API VMware SDK, dans notre cas : `https://10.30.103.12/sdk`. Veillez à remplacer l'adresse IP par celle de votre propre hôte ESXi et assurez-vous que l'URL est correcte.

Renseignez ensuite les **Username** et **Password**, précédemment configurés, dans notre cas, c'est l'utilisateur `centreon`.

Enfin, dans la section **Port**, indiquez le port de communication, par défaut : `5700`.

Vérifiez que ce port est bien ouvert entre Centreon et votre hôte ESXi pour garantir la communication.

![Configuration du connecteur VMWare dans Centreon]( /images/centreon_esxi/5.png)

Désormais, dans notre hôte, nous pouvons renseigner les informations ci-contre avec `ESX1`, le nom que nous avons renseigné dans "vCenter Name" précédemment :

![Ajout du connecteur VMWare à l'hôte dans Centreon]( /images/centreon_esxi/6.png)

Une erreur est commune depuis la version 24.10, toujours pas réglée par Centreon. Si lors de l'export du poller, vous avez l'erreur ci-contre dans `/var/log/centreon/centreon-web.log` :

```
Could not write to VMWare's configuration file 'watchdog.json' for monitoring server 'Central'.
Please add writing permissions for the webserver's user.
```

La manière de résoudre ce souci est d'exécuter cette commande :

```bash
chmod 666 /etc/centreon/centreon_vmware.json
```

Vous pouvez désormais vous rendre dans vos services afin de pouvoir voir le statut de votre ESXi et surveiller par exemple :

- ESX-Alarms
- Esx-Cpu
- Esx-Datastores-Latency
- Esx-Health
- Esx-Memory
- Esx-Service
- Esx-Status
- Esx-Storage
- Esx-Swap
- Esx-Time
- Esx-Traffic
- Esx-Uptime
- Esx-Vm-Count
- Esx-is-Maintenance

## III. Conclusion

Vous êtes désormais à même de superviser efficacement vos hôtes ESXi VMware grâce à l'intégration du connecteur VMware dans Centreon. Cette méthode simplifie grandement la gestion de vos infrastructures virtualisées en permettant une surveillance centralisée des ressources essentielles telles que l'état du processeur, de la mémoire, du stockage, et des services.

Dans un prochain article, nous approfondirons la supervision d'une infrastructure avec l'ajout du VMWare vCenter, ce qui vous permettra d'étendre cette méthode à une gestion plus large de votre environnement VMware avec Centreon.

Pour aller plus loin dès maintenant, vous pouvez consulter la [documentation officielle de Centreon](https://docs.centreon.com/).