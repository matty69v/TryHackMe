---
date: 2025-06-14 00:00:00 +0100
title: "Centreon : comment superviser votre firewall PfSense ?"
author: Matty
categories: [Centreon]
tags: [Linux, supervision, centreon, pfsense, snmp]
render_with_liquid: false
image:
    path: /images/centreon_pfsense/Centreon-monitoring-firewall-pfSense.jpg.jpeg
---

## I. Présentation

Dans ce tutoriel, nous allons apprendre à superviser un pare-feu pfSense à l'aide de la solution de supervision Centreon. Cette supervision centralisée permet d'avoir une visibilité en temps réel sur l'état de votre pare-feu, d'anticiper les incidents et donc de garantir la sécurité et la disponibilité de votre réseau.

Grâce au template Centreon Net-FW-Pfsense-SNMP-custom, vous pouvez surveiller des indicateurs essentiels au bon fonctionnement de pfSense, tels que :

- **Short Packets** : paquets considérés comme trop courts ou malformés
- **Bad Offset Packets** : nombre de paquets avec un décalage invalide
- **Blocked Packets Per Interface** : trafic bloqué sur chaque interface réseau
- **Fragment Packets** : paquets fragmentés détectés
- **Match Packets** : paquets ayant matché une règle du pare-feu
- **Memory Dropped Packets** : paquets rejetés par manque de mémoire
- **Normalize Packets** : paquets ayant subi une normalisation par le moteur de filtrage
- **Runtime** : durée de fonctionnement du système (uptime)

Nous verrons aussi comment superviser la charge système de pfSense via Centreon.

Si vous n'avez pas encore de pfSense et souhaitez essayer la supervision de celui-ci, voici un tutoriel d'installation :

- Tutoriel - Installation pfSense

Sans oublier nos tutoriels Centreon déjà disponibles :

- Centreon : installation de votre serveur de supervision sous Linux
- Sécurisation Centreon : protection des utilisateurs, SELinux, pare-feu, etc.
- Sécurisation Centreon : comment configurer l'accès HTTPS pour l'interface Web ?
- Centreon : comment superviser des serveurs Linux avec SNMPv3 ?
- Centreon : comment superviser Windows Server ?
- Centreon : comment importer des hôtes via un fichier CSV et l'API CLAPI ?

## II. Comment activer SNMP sur pfSense ?

Afin de pouvoir utiliser du SNMPv3 sur pfSense, accédez au menu **Services > SNMP**.

![Désactivation du SNMP natif de pfSense]( /images/centreon_pfsense/1.png)

Ensuite, décochez l'option "Activer le démon SNMP et ses contrôles", puis enregistrez. Cela évite tout conflit avec le paquet NET-SNMP que nous allons installer. Si nous allons installer ce paquet, c'est parce que l'implémentation native de SNMP dans pfSense ne supporte pas SNMPv3.

![Désactivation du SNMP natif de pfSense]( /images/centreon_pfsense/2.png)

Pour installer le paquet NET-SNMP sur pfSense, allez dans le menu **System** puis sélectionnez **Package Manager**.

![Accès au gestionnaire de paquets de pfSense]( /images/centreon_pfsense/3.png)

Dans la section **Available Packages** nous allons installer **net-snmp** qui va nous permettre de pouvoir superviser notre pfSense de manière sécurisée avec SNMPv3.

![Installation du paquet NET-SNMP sur pfSense]( /images/centreon_pfsense/4.png)

Le résultat attendu après installation est le suivant :

![Paquet NET-SNMP installé sur pfSense]( /images/centreon_pfsense/5.png)

## III. Configurer SNMPv3 sur pfSense

Désormais, rendez-vous dans **Services -> SNMP (NET-SNMP)** que nous venons d'installer. Attention à ne pas confondre avec l'autre entrée nommée SNMP.

![Configuration SNMPv3 sur pfSense]( /images/centreon_pfsense/6.png)

Dans l'onglet **Général** activez le service snmpd et validez le changement.

![Activation du service SNMP sur pfSense]( /images/centreon_pfsense/7.png)

Afin de configurer notre utilisateur pour le SNMPv3, rendez-vous dans la section **Users**. Pour des raisons de sécurité, nous allons supprimer l'utilisateur par défaut nommé manager. Nous allons ajouter notre propre utilisateur en cliquant sur **Add**.

![Ajout d'un utilisateur SNMPv3 sur pfSense]( /images/centreon_pfsense/8.png)

Pour configurer un utilisateur SNMPv3, commencez par définir un nom d'utilisateur, ici par exemple **itconnect**, et sélectionnez le type d'entrée **User Entry (USM)**. Vous pouvez aussi ajouter une description pour mieux identifier ce compte.

Ensuite, dans la partie **SNMPv3 Access Control**, spécifiez les permissions d'accès. Dans ce cas, l'utilisateur dispose uniquement des droits de lecture (**Read Only**), ce qui lui permet d'effectuer des requêtes de type GET et GETNEXT. Laisser le champ **Base OID** vide donne à cet utilisateur un accès à l'ensemble des objets SNMP disponibles.

![Configuration de l'utilisateur SNMPv3 sur pfSense]( /images/centreon_pfsense/9.png)

Dans la configuration SNMPv3 de pfSense, la section **USM User Configuration** permet de définir les paramètres de sécurité pour les utilisateurs SNMP.

- **Type d'authentification** : sélectionnez un algorithme, ici SHA, reconnu pour sa robustesse.
- **Mot de passe** : renseignez un mot de passe d'au moins 8 caractères pour sécuriser l'accès.
- **Protocole de confidentialité** : choisissez un protocole de chiffrement, comme AES, pour protéger les données échangées.
- **Phrase de passe** : définissez une passphrase utilisée avec le chiffrement ; si elle n'est pas fournie, le mot de passe sera utilisé à la place.
- **Niveau minimal de sécurité USM** : assurez-vous que l'utilisateur ne peut se connecter qu'avec un niveau de sécurité élevé, ici Privé, ce qui signifie que l'authentification et le chiffrement sont tous deux requis.

![Configuration de la sécurité SNMPv3 sur pfSense]( /images/centreon_pfsense/10.png)

## IV. Règle de pare-feu SNMP

Par défaut, le pare-feu pfSense ne permet pas les connexions SNMP externes sur l'interface WAN. Dans le cas où votre serveur de supervision est distant vis-à-vis de votre firewall, vous devez autoriser le flux sur votre pare-feu. Si vous contactez le pfSense depuis l'interface LAN, ce n'est pas nécessaire.

Dans notre exemple, nous allons créer une règle de pare-feu pour autoriser la communication SNMP. Accédez au menu **Firewall** de pfSense, puis sélectionnez l'option **Rules** et ajoutez une règle de filtrage sur le WAN.

![Création d'une règle de pare-feu SNMP sur pfSense]( /images/centreon_pfsense/11.png)
![Création d'une règle de pare-feu SNMP sur pfSense]( /images/centreon_pfsense/12.png)

À l'écran de création de la règle de pare-feu, effectuez la configuration suivante :

- **Action** : Passer (Pass)
- **Interface** : WAN
- **Famille d'adresses** : IPV4
- **Protocole** : UDP

Règle de pare-feu SNMP sur pfSense

À l'écran de configuration de la source, vous devez définir l'adresse IP qui sera autorisée à effectuer des communications SNMP avec le pare-feu pfSense. Dans notre exemple, n'importe quel ordinateur est autorisé à communiquer en SNMP avec le pare-feu. Pour des raisons de sécurité, il est recommandé de restreindre la source.

À l'étape de destination du pare-feu, effectuez la configuration suivante :

- **Destination** : Adresse WAN
- **Plage de ports de destination** : de SNMP 161 à SNMP 161

![Configuration de la destination de la règle de pare-feu SNMP sur pfSense]( /images/centreon_pfsense/13.png)

## V. Création de l'hôte pfSense dans Centreon

La dernière étape consiste à créer notre firewall dans la configuration de Centreon. Cette solution de supervision propose un template d'hôte pfSense que nous allons installer via : **Configuration -> Connectors -> Monitoring Connectors**. Ce connecteur se nomme simplement **pfSense**.

![Installation du connecteur pfSense dans Centreon]( /images/centreon_pfsense/14.png)

Comme observé dans les tutoriels précédents, créez votre hôte pfSense avec les informations nécessaires. Dans notre cas, il faut utiliser la template **NET-FW-Pfsense-SNMP-Custom**.

Dans les customs macros, nous allons devoir renseigner les informations précédemment définies de notre utilisateur SNMPv3 dans notre cas dans **SNMPEXTRAOPTIONS** nous allons renseigner cette valeur : `--snmp-username=itconnect --authprotocol=SHA --authpassphrase=123456789+Aze --privprotocol=AES --privpassphrase=123456789+Aze`.

Cette commande permet d'indiquer les informations d'authentification et de chiffrement utilisées lors des échanges SNMP. L'option `--snmp-username` spécifie le nom de l'utilisateur SNMPv3, ici itconnect. Le paramètre `--authprotocol=SHA` définit le protocole d'authentification utilisé, à savoir SHA (Secure Hash Algorithm), tandis que `--authpassphrase` fournit le mot de passe associé.

Le paramètre `--privprotocol=AES` précise le protocole de chiffrement des données SNMP, ici AES (Advanced Encryption Standard). Enfin, `--privpassphrase` indique le mot de passe utilisé pour le chiffrement.

> **Attention** : Veillez à utiliser des mots de passes différents et sécurisés, ces mots de passes sont utilisés à des fins de démonstrations.

![Configuration de l'hôte pfSense dans Centreon]( /images/centreon_pfsense/15.png)

> **Note** : pour rappel, il est indispensable d'exporter la configuration après chaque modification (ajout, suppression ou mise à jour d'un hôte, d'un service ou d'un poller). Sans cette étape, les changements ne seront pas pris en compte par le moteur de supervision, ce qui pourrait entraîner un décalage entre ce qui est configuré et ce qui est réellement surveillé.

Dans notre cas voici le résultat attendu pour un de nos services de notre pfSense :

![Résultats de la supervision pfSense dans Centreon]( /images/centreon_pfsense/16.png)

Si vous rencontrez des erreurs sur le plugin, rendez-vous dans la documentation officielle de Centreon dans la section Troubleshooting :

- Troubleshooting Centreon

## VI. Supervision de la charge CPU de pfSense

Par défaut, le template standard fourni par Centreon ne permet pas de superviser directement l'état du CPU d'un hôte via SNMP. Cela peut poser un problème lorsque l'on souhaite monitorer la charge système sur des équipements qui ne disposent pas de plugin personnalisé ou d'agents spécifiques.

Heureusement, il est possible d'exploiter les données fournies par le protocole SNMP pour obtenir ces informations, en se basant sur les MIBs disponibles sur le système supervisé.

En effectuant une requête SNMP de type snmpwalk, on peut interroger l'OID suivant : `.1.3.6.1.4.1.2021.10`, qui fait partie de la MIB UCD-SNMP-MIB. Cette MIB est souvent disponible sur les systèmes Unix/Linux équipés de Net-SNMP.

> **Remarque** : en identifiant d'autres OID, vous pouvez cibler d'autres composants du site, dont la RAM. Ceci peut vous permettre d'adapter la supervision de votre firewall selon vos besoins.

Cette section de la MIB expose les informations relatives à la charge moyenne du système sur différentes périodes (1, 5 et 15 minutes). Voici un exemple de retour typique d'une commande snmpwalk sur cet OID :

```
UCD-SNMP-MIB::laIndex.1 = INTEGER: 1
UCD-SNMP-MIB::laIndex.2 = INTEGER: 2
UCD-SNMP-MIB::laIndex.3 = INTEGER: 3
UCD-SNMP-MIB::laNames.1 = STRING: Load-1
UCD-SNMP-MIB::laNames.2 = STRING: Load-5
UCD-SNMP-MIB::laNames.3 = STRING: Load-15
UCD-SNMP-MIB::laLoad.1 = STRING: 1.17
UCD-SNMP-MIB::laLoad.2 = STRING: 1.08
UCD-SNMP-MIB::laLoad.3 = STRING: 0.87
```

Ces valeurs représentent la charge moyenne du système sur les 1, 5 et 15 dernières minutes :

- **laLoad.1** : Charge moyenne sur 1 minute (ici 1.17)
- **laLoad.2** : Charge moyenne sur 5 minutes (ici 1.08)
- **laLoad.3** : Charge moyenne sur 15 minutes (ici 0.87)

Ces indicateurs peuvent être très utiles pour évaluer l'utilisation du CPU dans le temps, même si cela ne correspond pas exactement à une métrique de "CPU usage" en pourcentage. Néanmoins, ils donnent une bonne indication de la charge du système et permettent d'anticiper les pics d'activité.

Pour intégrer cette surveillance dans Centreon, il est possible de créer un service personnalisé SNMP en utilisant ces OID. Il suffit de configurer une supervision SNMP générique et de cibler les OID `.1.3.6.1.4.1.2021.10.1.3.X` (où X est l'index 1, 2 ou 3 selon la période de charge souhaitée).

Pour superviser un hôte à partir d'un OID spécifique, il est nécessaire de créer un service personnalisé dans Centreon. Pour cela, on utilise le connecteur "Generic SNMP", accessible depuis le menu suivant : **Configuration → Connectors → Monitoring Connectors**.

Ce connecteur permet de définir des requêtes SNMP ciblées, en renseignant directement les OID que l'on souhaite interroger. C'est une méthode efficace lorsque l'on connaît précisément les identifiants SNMP des informations à superviser, sans passer par un template préconfiguré.

![Création d'un service SNMP personnalisé dans Centreon]( /images/centreon_pfsense/17.png)

Pour créer notre service personnalisé, nous devons nous rendre dans le menu : **Configuration → Services → Services by Host**.

![Création d'un service SNMP personnalisé dans Centreon]( /images/centreon_pfsense/18.png)

Nous allons configurer un service SNMP personnalisé pour interroger l'OID `.1.3.6.1.4.1.2021.10.1.3.1`, qui correspond à la valeur laLoad.1 de la MIB UCD-SNMP-MIB. Cette valeur représente la charge moyenne du CPU sur une période d'une minute.

Dans Centreon, nous avons créé un service nommé « CPU 1 min Load average » afin d'identifier clairement la période de charge supervisée. L'équipement ciblé par cette supervision est notre pfSense, mais cela peut tout aussi bien être un serveur ou tout autre équipement compatible SNMP. Pour ce service, nous utilisons le template « App-Protocol-SNMP-String-Value-custom », qui permet de définir une requête SNMP personnalisée basée sur une chaîne de caractères. La commande de vérification choisie est « App-Protocol-SNMP-Oid-String-Value », qui interroge une valeur spécifique à partir de l'OID renseigné.

Plusieurs champs personnalisés ont été renseignés pour paramétrer la vérification. Les formats de message sont définis pour les différents états : OK, warning, critical et unknown, avec des messages adaptés en fonction des seuils atteints ou d'éventuelles erreurs. Les seuils d'alerte ont été fixés ici à 1.00 pour warning et 2.00 pour critical, à titre d'exemple. Enfin, le champ « EXTRAOPTIONS » reste vide sauf en cas de besoin spécifique.

Il est important de comprendre que sur une machine mono-cœur, une charge CPU à 1.00 signifie que le cœur est utilisé à 100 %, donc une charge supérieure à cette valeur indique une surcharge. En revanche, sur un système multi-cœurs, les seuils doivent être adaptés en fonction du nombre de cœurs disponibles pour refléter correctement la charge réelle du processeur.

![Configuration du service SNMP personnalisé dans Centreon]( /images/centreon_pfsense/19.png)

Dans notre cas, voici le résultat attendu après création de notre service :

![Résultats de la supervision CPU pfSense dans Centreon]( /images/centreon_pfsense/20.png)

## VII. Conclusion

Vous savez maintenant comment superviser efficacement un pare-feu pfSense avec Centreon en utilisant SNMPv3. Nous venons d'effectuer les actions suivantes : activation et configuration de SNMP sur pfSense, installation du bon paquet (net-snmp), création d'un utilisateur sécurisé avec les bons droits et niveaux de chiffrement, mise en place d'une règle de pare-feu pour autoriser le trafic SNMP (bien que facultatif), et enfin, intégration dans Centreon avec le bon template.

Ce type de supervision vous permettra de garder un œil en temps réel sur l'état de votre pare-feu et d'anticiper les problèmes ! Vous avez maintenant toutes les infos à portée de clic via l'interface de Centreon.

Pensez bien à sécuriser vos mots de passe SNMPv3 et à limiter l'accès aux IPs autorisées dans vos règles pfSense. La supervision, c'est puissant, mais seulement si c'est bien protégé ! N'hésitez pas à adapter les commandes ou configurations à votre environnement.
