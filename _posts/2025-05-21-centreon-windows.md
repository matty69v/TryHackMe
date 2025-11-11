---
date: 2025-05-21 00:00:00 +0100
title: "Centreon : comment superviser des serveurs Windows Server avec SNMP ??"
author: Matty
categories: [Centreon]
tags: [Linux, supervision, centreon, installation, snmpv3, snmp, windows, windows-server]
render_with_liquid: false
image:
    path: /images/centreon_windows/Centreon-Supervision-Windows-Server-avec-SNMP.jpg.jpeg
---

## I. Présentation

Dans cet article, nous allons apprendre à superviser un serveur Windows Server à l'aide de la solution Centreon et du protocole SNMP.

Les systèmes d'exploitation Windows prennent en charge nativement le protocole SNMP, un protocole de supervision simple, rapide et largement répandu. Néanmoins, il est à noter plusieurs points :

- Seules les versions SNMP v1 et v2c est prise en charge, ce qui implique de se passer des améliorations de SNMP v3, y compris en matière de sécurité. Avec le SNMP v2c, « l'authentification » s'effectue via un nom de communauté et cette information transite en clair sur le réseau.
- Sur Windows Server, SNMP est une fonctionnalité considérée comme obsolète depuis Windows Server 2012, comme le spécifie la documentation de Microsoft. Pour autant, le SNMP est toujours disponible sur Windows Server 2025.

Grâce à SNMP, il est possible de surveiller des indicateurs clés du système tels que l'usage du processeur, de la mémoire, des disques ou encore l'état des interfaces réseau.

Nous verrons comment installer et configurer SNMP sur un serveur Windows en utilisant à la fois l'interface graphique via Server Manager et en ligne de commande PowerShell pour offrir une approche complète et adaptée à tous les environnements. Nous ajusterons aussi les paramètres du pare-feu Windows pour limiter les interactions avec le service SNMP.

En configurant correctement le service SNMP et en connectant votre serveur à Centreon, vous pourrez centraliser et automatiser la surveillance de vos machines Windows.

Suite à la lecture de ce tutoriel, vous serez capable de monitorer vos serveurs Windows avec Centreon.

Avant de commencer, voici, pour rappel, nos précédents tutoriels sur Centreon :

- Centreon : installation de votre serveur de supervision sous Linux
- Sécurisation Centreon : protection des utilisateurs, SELinux, pare-feu, etc.
- Sécurisation Centreon : comment configurer l'accès HTTPS pour l'interface Web ?
- Centreon : comment superviser des serveurs Linux avec SNMPv3 ?

## II. Quelles sont les alternatives à SNMP pour superviser Windows ?

Avant d'évoquer la configuration de SNMP, commençons par quelques mots sur les alternatives à SNMP. Nous avons conscience que la supervision via SNMP ne conviendra pas à tout le monde, mais sous Windows, avec Centreon, il n'est pas aisé de faire autrement.

- Le client NSClient++ avec NRPE, ce qui implique de déployer un agent sur toutes les machines, ainsi qu'un fichier de configuration. Ce dernier est d'ailleurs susceptible de contenir un identifiant et un mot de passe, ce qui n'est pas sans risque. En allant plus loin, il est envisageable de s'appuyer sur un certificat.
- L'utilisation de WMI, un composant natif présent dans Windows, qui est donc agentless. Ceci implique une prise en charge au niveau de la solution de supervision.
- L'utilisation de NCPA (Nagios Cross-Platform Agent) qu'il faut installer et configurer sur chaque machine Windows. À ce jour, NCPA ne fonctionne pas avec Centreon.
- L'Agent de supervision Centreon (Centreon Monitoring Agent), développé directement par Centreon, et qui pourrait représenter une piste très intéressante à l'avenir. Pour le moment, il est en version bêta, et d'après nos tests, et trop instable pour être mis en œuvre en production.

Si vous souhaitez nous faire un retour à ce sujet, vous pouvez commenter cet article.

## III. Supervision de Windows Server

Afin de pouvoir réaliser la supervision de vos serveurs Windows avec Centreon, il est indispensable d'installer et de configurer correctement la fonctionnalité SNMP (Simple Network Management Protocol) sur chacun de vos serveurs.

### A. Installation de SNMP via l'interface graphique

Suivez les étapes ci-dessous pour installer le SNMP via l'interface graphique.

1. Ouvrez le Gestionnaire de serveur (Server Manager).

2. Cliquez sur Gérer → Ajouter des rôles et fonctionnalités

3. Cliquez sur Suivant jusqu'à atteindre l'étape Fonctionnalités.

4. Recherchez et cochez SNMP Service.

**Important :** cochez également Fournisseur WMI SNMP (SNMP WMI Provider) pour pouvoir configurer correctement votre communauté SNMP via les outils standards ou PowerShell.

5. Cliquez sur Suivant, puis Installer.

Une fois l'installation achevée, ouvrez la console Services (services.msc) et localisez le service nommé SNMP Service (ou « Service SNMP »). Faites un clic droit dessus, sélectionnez Propriétés, puis rendez-vous dans l'onglet Sécurité.

C'est ici que vous allez configurer la communauté SNMP ainsi que définir le serveur de supervision autorisé à recevoir les données SNMP.

Dans notre cas, nous renseignons l'adresse IP de notre serveur Centreon, qui est 10.30.111.64.

Indiquez le nom de la communauté que vous souhaitez utiliser, ici, ce sera « IT-Connect ». Cela permettra à votre serveur Centreon de connaître la communauté sur laquelle il devra écouter. N'oubliez pas également d'ajouter l'adresse IP de votre serveur Centreon dans la liste des hôtes autorisés.

### B. Installation de SNMP en PowerShell

Une autre manière d'installer le service SNMP ainsi que le SNMP WMI Provider est d'utiliser PowerShell en ligne de commande.

Pour installer SNMP et le SNMP WMI Provider via PowerShell, ouvrez une fenêtre PowerShell en tant qu'administrateur et exécutez la commande suivante :

```powershell
Install-WindowsFeature -Name SNMP-Service, SNMP-WMI-Provider
```

Une fois l'installation terminée, il est également possible de configurer directement la communauté SNMP et d'ajouter l'adresse IP autorisée via PowerShell en modifiant la base de registre Windows.

Pour créer une nouvelle communauté SNMP, par exemple « IT-Connect », avec un accès en lecture seule, vous pouvez utiliser la commande suivante :

```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities" -Name " IT-Connect " -PropertyType DWord -Value 4
```

Dans cette commande :

- IT-Connect est le nom de la communauté SNMP que votre serveur Centreon ciblera.
- La valeur 4 correspond à une autorisation en Lecture seule (Read-Only).
- Si vous souhaitez donner un accès en Lecture/Écriture, vous devrez mettre la valeur 8 à la place.

Ensuite, pour ajouter l'adresse IP autorisée à interroger le serveur via SNMP (10.30.111.64) pour notre serveur Centreon), il faut ajouter cette adresse dans la clé de registre des PermittedManagers :

```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers" -Name "1" -PropertyType String -Value "10.30.111.64"
```

Ici :

- 1 est un numéro d'ordre. Si vous devez ajouter plusieurs IPs, vous utiliserez 2, 3, etc.
- 10.30.111.64 est l'adresse IP du serveur autorisé à recevoir les informations SNMP.

Après avoir effectué ces modifications, il est nécessaire de redémarrer le service SNMP pour que la configuration soit prise en compte :

```powershell
Restart-Service SNMP
```

**Attention :** Si vous n'installez pas le SNMP WMI Provider en même temps que SNMP Service, certaines options, notamment la configuration avancée des communautés et des managers autorisés via PowerShell ou l'interface graphique, pourraient ne pas être disponibles.

### C. Limiter l'accès à SNMP avec le pare-feu Windows

Pour sécuriser le service SNMP et limiter son accès uniquement à notre serveur de supervision, voici comment configurer une règle dans le pare-feu Windows.

Commencez par ouvrir le Pare-feu Windows avec fonctions avancées de sécurité. Pour cela, appuyez sur les touches Windows + R, tapez wf.msc et validez avec Entrée. Une fois la console ouverte, regardez dans le menu à gauche et cliquez sur Règles de trafic entrant.

Dans la partie droite de la fenêtre, cliquez ensuite sur Nouvelle règle.

Une fenêtre s'ouvre : choisissez l'option Port puis cliquez sur Suivant.

Pour autoriser seulement le SNMP, nous devons sélectionner UDP et indiquer le port 161, qui est utilisé par SNMP. Cliquez de nouveau sur Suivant.

À l'étape « Action », choisissez Autoriser la connexion, puis continuez en cliquant sur Suivant.

Vous arriverez sur la sélection des profils réseau (Domaine, Privé, Public). Cochez uniquement les profils qui correspondent à votre environnement, par exemple Domaine et Privé, puis cliquez sur Suivant.

Il vous reste maintenant à donner un nom à votre règle. Par exemple, tapez SNMP - Supervision, puis cliquez sur Terminer pour créer la règle.

Pour finir, vous allez restreindre l'accès à une adresse IP spécifique. Double-cliquez sur la règle que vous venez de créer, puis allez dans l'onglet Etendue. Dans la section Adresses IP distantes, sélectionnez Ces adresses IP et ajoutez l'adresse IP de votre serveur de supervision. Validez en cliquant sur OK.

**Note :** Lorsque vous ajoutez l'adresse IP distante (par exemple 10.30.111.26), vous remarquerez qu'elle est affichée sous la forme 10.30.111.26/32. Cette notation /32 signifie que la règle s'applique uniquement à cette adresse IP précise. Sans ce suffixe, ou en utilisant un masque plus large (par exemple /24), vous risqueriez d'autoriser tout un sous-réseau au lieu d'une seule machine. Le /32 est donc essentiel pour restreindre l'accès exclusivement au serveur de supervision et éviter qu'un autre appareil du réseau puisse interroger SNMP.

Voilà, vous avez sécurisé votre service SNMP : désormais, seul le serveur spécifié pourra interroger la machine via SNMP, ce qui réduit considérablement les risques d'accès non autorisé.

### D. Ajouter un hôte Windows dans Centreon

Afin de pouvoir collecter les différentes métriques de notre serveur Windows, nous devons créer un hôte dans Centreon, en spécifiant la même adresse IP que celle du serveur Windows à superviser.

Dans un premier temps, nous devons installer la Template de notre hôte afin que le collecteur de Centreon connaisse les données à superviser. Pour cela, rendez-vous dans Configuration -> Monitoring Connector Manager.

Dans « Keyword » rentrez la valeur « Windows » et choisissez la template « Windows SNMP » :

Une fois installé, rendez-vous dans Configuration -> Hosts -> Hosts afin d'ajouter notre serveur Windows.

Dès que nous sommes sur cette page, ajoutons notre serveur Windows et renseignons toutes les informations nécessaires à la supervision de notre hôte.

Il va falloir donner un nom à notre serveur afin qu'il soit reconnaissable sous votre interface, lui attribuer l'adresse IP de la machine supervisée (ici 10.30.111.21).

Ensuite, sélectionnez la version du protocole SNMP à utiliser. Dans notre cas, il s'agit de SNMP version 2c. Il est maintenant nécessaire d'indiquer quel serveur de supervision va interroger notre hôte. Ici, on sélectionne "Central", qui représente l'instance principale de Centreon.

On passe ensuite au choix du template, le modèle de supervision préconfiguré. Dans notre exemple, nous sélectionnons le template personnalisé OS-Windows-SNMP-Custom, installé précédemment. Ce template contient les commandes de supervision nécessaires pour récupérer des informations telles que la charge CPU, la mémoire, etc.

Il est important de cocher l'option "Create Services linked to the Template too" afin que les services définis dans ce template soient automatiquement créés pour l'hôte.

### E. Appliquer la nouvelle configuration

Après avoir ajouté ou modifié un hôte, il faut exporter la configuration vers le poller pour que les changements soient pris en compte.

Dans le menu "Pollers", on clique sur "Export configuration", puis sur "Export & reload".

Cela applique les modifications et recharge la supervision sur toute la plateforme. Sans cette étape, Centreon ne prendra pas en compte les nouveaux paramètres.

**Note :** pour rappel, il est indispensable d'exporter la configuration après chaque modification (ajout, suppression ou mise à jour d'un hôte, d'un service ou d'un poller). Sans cette étape, les changements ne seront pas pris en compte par le moteur de supervision, ce qui pourrait entraîner un décalage entre ce qui est configuré et ce qui est réellement surveillé.

Une fois l'opération réalisée, rendez-vous dans vos services afin d'observer les métriques collectées pour votre serveur Windows :

Nous pouvons constater que notre modèle effectue, par défaut, plusieurs vérifications : SWAP, mémoire RAM, CPU, réponse au ping.

## IV. Conclusion

En suivant ces étapes, vous devriez être en mesure d'installer et configurer le service SNMP sur un serveur Windows pour l'intégrer à notre plateforme de supervision Centreon. Nous avons également abordé les paramètres essentiels pour garantir une supervision fiable et efficace.

N'oubliez pas d'exporter la configuration après chaque modification dans Centreon, afin que les changements soient correctement pris en compte par le moteur de supervision.

Dans les prochains articles, nous continuerons à explorer la configuration de Centreon pour superviser une infrastructure.

Pour aller plus loin dès maintenant, vous pouvez consulter la documentation officielle de Centreon.