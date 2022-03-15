# vps-server-install

Instructions pour préparer un server VPS Ubuntu.
Cette configuration fonctionne également avec un server standard (non VPS)

La fin de cette préparation sera pour la mise en place d'une application nodeJS.

## Configuration Système

Beaucoup de packages sont déjà préinstallés et ne necéssiteront donc pas d'installation préalable.

### Changer le mot de pass admin

Même si nous ne désirons pa utiliser ce compte il est préférable de changer son mot de pass.
Le mot de pass fourni par le système n'est probablement pas à votre goût.

```bash
$ passwd
```

Et Suivez les instructions: Vous allez rentrez le mot de passe actuel suivi du nouveau mot de passe 2 fois.

### Création d'un utilisateur avec les droits sudo

Si vous venez d'installer votre Ubuntu, vous devez être connecté avec l'utilisateur `root` ou `ubuntu`.
Je vous conseille de créer votre propre utilisateur avec les droits sudo avant de commencer.

```bash
$ adduser YOUR_USER_NAME
$ adduser YOUR_USER_NAME sudo
```

Vous pouvez ensuite vous déconnecter et vous connecter avec votre propre utilisateur.

### Passer en mode root (ou sudo)

Des fois il est necessaire de passer en mode root ou sudo pour exécuter certaines commandes.

Il existe plusieurs méthodes :

- `$ sudo -i`
- `$ sudo su -`
- `$ sudo <commande>` Pour exécuter une commande en mode sudo

### Mise à jour des paquets

```bash
$ apt-get update
$ apt-get upgrade
```

`update` va mettre à jour la liste des paquets.

`upgrade` va mettre à jour tous les paquets.

## Security install

Il est préférable de passer en mode sudo pour effectuer ces actions

### Configurer ssh

Il est plus sécuritaire de changer le port SSH (Cela permettra d'éviter la plupart des attaques de robot)

Nous allons également supprimer l'accès root par SSH

```bash
$ vi /etc/ssh/sshd_config
```

/!\ Pensez à bien décommenté chaque ligne où nous allons faire une modification en enlevant le # devant

- Changer la valeur du `Port` (par example 2222)

```bash
Port 2222
```

- Changer des valeurs de sécurité pour éviter les essaies multiples de mot de passe et protéger contre les tentatives de brute-force.

```bash
LoginGraceTime 5m
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 3
```

```bash
PasswordAuthentication yes
PermitEmptyPasswords no
```

```bash
ChallengeResponseAuthentication no
```

```bash
UsePAM yes
```

- Restart sshd et vérifier qu'il est bien actif.

```bash
$ systemctl restart sshd
$ systemctl status sshd
$ systemctl enable sshd
```

À partir de maintenant vous devez préciser le port lors de vos connections SSH

```bash
$ ssh mon_identifiant@mon_ip -p 2222
```

### Configuration du Firewall

Nous allons utiliser iptables qui est déjà préinstallé.

Logiquement ce n'est pas necéssaire mais vous pouvez réinstaller iptables pour être sur d'avoir la dernière version.

```bash
$ apt-get install iptables
```

Pour que les modifications faites soit conservés et réappliqué après chaque redemarrage, il vous faudra installer iptables-persistent.
Sinon les règles seront sauvegardées mais pas réappliqué si il y a un reboot.

```bash
$ apt-get install iptables-persistent
```

- Ouvrez un nouveau fichier firewall

```bash
$ vi /etc/init.d/firewall
```

- Copiez le contenu de `firewall.sh` dans le fichier

  Par défaut nous fermons tous les ports et réouvrons uniquement les necessaires.

  **/!\\/!\ Pensez à changer le port SSH dans le fichier pour celui que vous avez choisi dans l'étape précédant.**

- Rendre le fichier executable

```bash
$ chmod +x /etc/init.d/firewall
```

- Executez le

```bash
$ /etc/init.d/firewall
```

Le script sauvegarde les règles une fois appliquées `sudo /sbin/iptables-save`

Si vous effectuez cette configuration sur un serveur distant via SSH, vous risquez d'être déconnecté.
Ne vous inquietez pas, le script continuera.

Veuillez juste vous reconnecter.

Pour vérifier la configuration faite

```bash
$ sudo iptables -L
```

### Bloquer ports scanning avec portsentry

**/!\ NE PAS UTILISER SI VOUS VOUS CONNECTEZ AVEC UNE IP VARIABLE !**

**_Pensez à mettre une IP fixe_**

Installons Portsentry

```bash
$ apt-get install portsentry
```

- Modifiez `/etc/portsentry/portsentry.ignore` et ajoutez votre IP local (si non, vous serez bloquez !)
- Modifiez `/etc/default/portsentry` et mettez ce contenu

```
TCP_MODE="atcp"
UDP_MODE="audp"
```

- Modifiez le fichier `/etc/portsentry/portsentry.conf`
  - Modifiez ``IGNORE OPTION` par (valeur par défaut : 0)
  ```
  BLOCK_UDP="1"
  BLOCK_TCP="1"
  ```
  - Commentez les lignes `KILL_HOSTS_DENY`
  - Comme nous utilisons iptables, commentez toutes les lignes commençant par `KILL_ROUTE”` SAUF `KILL_ROUTE="/sbin/iptables -I INPUT -s $TARGET$ -j DROP"`
- Redemarrez le service

```bash
$ service portsentry restart
```

### Installer un Firewall Network

Je préfère l'idée d'installer un Firewall en ligne sur il est proposé par votre hébergeur.
Voici la tutoriel de celui de OVH <https://docs.ovh.com/fr/dedicated/firewall-network/>

Cela permet de définir une liste blanche d'IP pouvant se connecter à votre VPS.

Si votre IP change ou si vous devez utiliser un autre oridinateur vous pourriez être bloqué hors de votre VPS mais avec une configuration en ligne vous pourrez ajouter cette nouvelle IP en ligne. Si vous liste blanche est embarquée sur le VPS cela sera beaucoup plus compliqué.

### Install fail2ban

Le but de Fail2ban est de bloquer les adresses IP inconnues qui tentent de pénétrer dans votre système. il permet de se prémunir contre toute attaque brutale contre vos services.

- Commençons par installer le package

```bash
$ apt-get install fail2ban
```

- Il faut modifier le fichier de configuration adapter à votre utilisation. Pensez d'abord à sauvegarder le fichier de configuration

```bash
$ cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.backup
```

- Modifications le fichier à votre convenance

```bash
$ vi /etc/fail2ban/jail.conf
```

- Redémarrez le service

```bash
$ /etc/init.d/fail2ban restart
```

### Autorisez uniquement votre utilisateur à se connecter ?

TODO

## Clef SSH

### Create the SSH Key

Generation de la clef SSH

```bash
$ ssh-keygen
```

Vous pouvez garder les valeurs par défaut.

```bash
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/emmap1/.ssh/id_rsa):
Created directory '/home/<username>/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/emmap1/.ssh/id_rsa.
Your public key has been saved in /Users/emmap1/.ssh/id_rsa.pub.
The key fingerprint is:
4c:80:61:2c:00:3f:9d:dc:08:41:2e:c0:cf:b9:17:69 emmap1@myhost.local
The key's randomart image is:
+--[ RSA 2048]----+
|*o+ooo.          |
|.+.=o+ .         |
|. *.* o .        |
| . = E o         |
|    o . S        |
|   . .           |
|     .           |
|                 |
|                 |
+-----------------+
```

Vous pouvez vérifier la liste des clefs

```bash
$ ls ~/.ssh
id_rsa  id_rsa.pub
```

Vous devriez avoir deux fichiers, un pour la clef publique `id_rsa.pub` et un pour la clef privée `id_rsa`

### Ajouter la clef au ssh-agent

Si vous ne voulez pas entrer votre mot de passe à chaque fois que vous utilisez votre clef SSH, vous devez l'ajouter au ssh-agent.

- Demarrez l'agent

```bash
$ eval `ssh-agent`
Agent pid 9700
```

Ajouter le ssh agent

```bash
$ ssh-add ~/.ssh/id_rsa
```

### Ajouter la clef à votre compte GitHub ou Bitbucket ou autre

- Afficher votre clef

```bash
cat ~/.ssh/id_rsa.pub
```

Copiez la clef et collez la dans la section SSH Key de votre système de repos.

Vous pouvez ensuite tester votre configuration.

Par example sur Bitbucket

```bash
$ ssh -T git@bitbucket.org
```

Vous devriez avoir ce message

```bash
You can use git or hg to connect to Bitbucket. Shell access is disabled.
```

### Installation Git

```bash
$ sudo apt-get install git
```

## Installation NodeJS

### Installation NodeJS

```bash
$ apt-get install nodejs
```

Si vos packages ont bien été mis à jour avec `apt-get update` et `apt-get upgrade` vous devriez avoir la dernière version de Node.

Vérifions

```bash
$ node -v
v16.14.0
$ npm -v
8.3.1
```

Pour être sur d'avoir la dernière version de npm reinstallé la dernière version via npm lui-même et revérifiez.

```bash
$ npm install -g npm@latest
```

```bash
$ npm -v
8.5.4
```

## Installer et configurer Nginx pour rediriger vos applications

Nginx est une bonne solution pour rediriger tous vos port HTTP

### Installer nginx

```bash
$ sudo apt-get install nginx
```

### Ajouter un proxy pour rediriger le port 80 vers votre app

- Ajouter le fichier my-nginx.conf du repo dans votre dossier `/etc/nginx/site-available`, et ajouter un lien symbolique dans le dossier `/etc/nginx/site-enabled`.

```bash
$ sudo ln -s /etc/nginx/sites-available/my-nginx.conf /etc/nginx/sites-enabled
```

Changez le nom de domaine.

Si vous avez plusieurs app copiez et collez la section `server` et changez le nom de domaine (vous pouvez mettre des sous domaines, exemple _sous-domaine.mon-domaine.com_) et le port.

- Supprimez la config par défaut

```bash
$ sudo rm /etc/nginx/sites-enabled/default
```

- Redémarrez Nginx

```bash
$ sudo service nginx reload
```

### Https consideration

to do

## Installation pm2, pour lancer votre app Node

### Installation pm2

```bash
$ npm install -g pm2
```

### Ajout pm2 au boot script

```bash
$ pm2 startup
```

Et execute le script affiché (avec un utilisateur sudo)

### (Optionel) Utilisation de keymetrics

Allez sur [Keymetrics](https://app.keymetrics.io/), créer un compte, et dans votre server, tape la commande fourni pour donner accès à votre server.

Tu peux maintenant installer plein de plugins ! Par exemple logrotate, server monitoring et mongo modules.

Vous pouvez les installer directement par lignes de commandes sur votre server ou en cliquant sur le site keymetrics.

/!\ Vous devez avoir le bon port ouvert, vérifiez les recommandations keymetrics et configurez votre firewall (c'est déjà configuré dans mon fichier de configuration iptables mais le port pourrait être différent).
