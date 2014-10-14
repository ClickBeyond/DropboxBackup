# Dropbox Backup

`Dropbox Backup` is a collection of **BASH** scripts for backing up your server with [Dropbox Uploader](https://github.com/andreafabrizi/Dropbox-Uploader/).

## Setup

1. First clone this repo:
```bash
$ cd ~
$ git clone https://github.com/CubicApps/DropboxBackup.git
```

2. Then give the scripts execution permissions if they don't already have them:
```bash
$ cd ~/DropBoxBackup
$ chmod +x dropbox_uploader.sh
$ chmod +x db_backup.sh
$ chmod +x log_backup.sh
```

3. Finally, run the `dropbox_uploader.sh` script and follow the on-screen instructions to connect it to your Dropbox account:
```bash
$ ./dropbox_uploader.sh
```

## Usage

The `Dropbox Backup` syntax for backing up MySQL databases is:

```bash
$ ~/DropboxBackup/db_backup.sh -u dbUsername -p dbPassword -h dbHost -d dbName
```

This script will create a MySQL dump file, which is then compressed into a `.tar.gz` file and then uploaded to your dropbox folder.

## Backup Log File

Every time the `db_backup.sh` script is executed, entries are added to `~/tmp/backup.log`. This log file can be backed up to dropbox by executing the `log_backup.sh` script as follows:

```bash
$ ~/DropboxBackup/log_backup.sh
```

Alternatively, the log file can be backed up manually by doing the following:
```bash
$ cd ~/tmp
$ BKP_LOG_FILE="log-backup-$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"
$ tar -zcf "$BKP_LOG_FILE" "backup.log"
$ ~/DropboxBackup/dropbox_uploader.sh -f ~/.dropbox_uploader upload $BKP_LOG_FILE "/Log_Backups/$BKP_LOG_FILE"
$ rm -f $BKP_LOG_FILE
```

The above commands perform the following:

1. Change to the `tmp` directory.
2. Create a new name for the backup.
3. Compress the existing log file into a `.tar.gz`.
4. Upload the compressed file to dropbox.
5. Delete the archive.

## Scheduled Jobs (cron)

Cron is used on Linux to schedule commands or scripts that need to be executed periodically.

To edit your `crontab` file use:
```bash
$ crontab -e
```

Providing your system is setup to send emails (see [Sending Email using Mandrill](#6)), then add these lines to your `crontab` file to email errors to the `MAILTO` address:
```
MAILTO="<your@email.com>"
@daily ~/DropboxBackup/db_backup.sh -u dbUsername -p dbPassword -h dbHost -d dbName > /dev/null
@weekly ~/DropboxBackup/log_backup.sh > /dev/null
```

To list the cron history use:
```bash
$ grep CRON /var/log/syslog
```

### Crontab Syntax

The syntax for adding a new cron job is:
```
1 2 3 4 5 /path/to/command arg1 arg2
```

Where:

1. = Minute (0-59)
2. = Hours (0-23)
3. = Day (0-31)
4. = Month (0-12 [12 == December])
5. = Day of the week (0-7 [7 or 0 == sunday])

The syntax can also be expressed as this:

```
* * * * * command to be executed
- - - - -
| | | | |
| | | | ----- Day of week (0 - 7) (Sunday == 0 or 7)
| | | ------- Month (1 - 12)
| | --------- Day of month (1 - 31)
| ----------- Hour (0 - 23)
------------- Minute (0 - 59)
```

Alternatively, a special string can be used to specify the first five fields:
```
Special string    Meaning
@reboot           Run once, at start-up
@yearly           Run once a year, "0 0 1 1 *"
@annually         (same as @yearly)
@monthly          Run once a month, "0 0 1 * *"
@weekly           Run once a week, "0 0 * * 0"
@daily            Run once a day, "0 0 * * *"
@midnight         (same as @daily)
@hourly           Run once an hour, "0 * * * *"
```

## Sending Email using Mandrill

Linux can be configured to send email through [Mandrill](https://mandrill.com/) using your SMTP & API credentials. The information in this section is based on [this article from Mandrill.com](http://help.mandrill.com/entries/23060367-Can-I-configure-Postfix-to-send-through-Mandrill-).

1. Install a SASL authentication package, [Postfix](http://www.postfix.org/) and mail utilities:
```bash
$ apt-get install -y libsasl2-modules postfix mailutils
```

	During the Postfix setup select `Internet with smarthost`. Enter your fully qualified domain name (`FQDN`) e.g., `example.com` and the SMTP relay host `[smtp.mandrillapp.com]`.

2. Then open the Postfix configuration file and change/append any lines that don't exist:
```bash
$ sudo nano /etc/postfix/main.cf
# Make sure these settings exist (append any that don't):
myhostname = <your-domain-name> e.g., example.com
relayhost = [smtp.mandrillapp.com]
# enable SASL authentication
smtp_sasl_auth_enable = yes
# tell Postfix where the credentials are stored
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd 
smtp_sasl_security_options = noanonymous
# use STARTTLS for encryption
smtp_use_tls = yes 
```

3. Create an SMTP username and password file:
```bash
$ sudo nano /etc/postfix/sasl_passwd
# Add your Mandrill username and API key
[smtp.mandrillapp.com] USERNAME:API_KEY
```

4. Create the hash db file for Postfix and lock down access to it:
```bash
$ postmap /etc/postfix/sasl_passwd
$ chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```

5. Restart the Postfix service:
```bash
$ service postfix restart
```

6. Finally, test the sending of email through Mandrill:
```bash
$ echo "Test Email." | mail -s "Hello" -a "FROM:YOUR_USERNAME@YOUR_DOMAIN.com" TO_USERNAME@TO_DOMAIN.com
```

7. Check the mail log to make sure that the email has been sent properly:
```bash
$ cat /var/log/mail.log
# Try and find this at the end of the file:
status=sent (250 2.0.0 Ok)
```


# Dropbox Uploader

Dropbox Uploader is a **BASH** script which can be used to upload, download, delete, list files (and more!) from **Dropbox**, an online file sharing, synchronization and backup service. 

It's written in BASH scripting language and only needs **cURL**.

**Why use this script?**

* **Portable:** It's written in BASH scripting and only needs *cURL* (curl is a tool to transfer data from or to a server, available for all operating systems and installed by default in many linux distributions).
* **Secure:** It's not required to provide your username/password to this script, because it uses the official Dropbox API for the authentication process. 

Please refer to the &lt;Wiki&gt;(https://github.com/andreafabrizi/Dropbox-Uploader/wiki) for tips and additional information about this project. The Wiki is also the place where you can share your scripts and examples related to Dropbox Uploader.

## Features

* Cross platform
* Support for the official Dropbox API
* No password required or stored
* Simple step-by-step configuration wizard
* Simple and chunked file upload
* File and recursive directory download
* File and recursive directory upload
* Shell wildcard expansion (only for upload)
* Delete/Move/Rename/Copy/List files
* Create share link

## Getting started

First, clone the repository using git (recommended):

```bash
git clone https://github.com/andreafabrizi/Dropbox-Uploader/
```

or download the script manually using this command:

```bash
curl "https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh" -o dropbox_uploader.sh
```

Then give the execution permission to the script and run it:

```bash
 $chmod +x dropbox_uploader.sh
 $./dropbox_uploader.sh
```

The first time you run `dropbox_uploader`, you'll be guided through a wizard in order to configure access to your Dropbox. This configuration will be stored in `~/.dropbox_uploader`.

### Configuration wizard

The configuration wizard is pretty self-explanatory. One thing to notice is that if you choose "App permission", your uploads will end up on Dropbox under an `App/<your_app_name>` folder. To have them stored in another folder, such as in `/dir/`, you'll need to give Dropbox-Uploader permission to all Dropbox files.

## Usage

The syntax is quite simple:

```
./dropbox_uploader.sh COMMAND [PARAMETERS]...

[%%]: Optional param
<%%>: Required param
```

**Available commands:**

* **upload** &lt;LOCAL_FILE/DIR ...&gt; &lt;REMOTE_FILE/DIR&gt;  
Upload a local file or directory to a remote Dropbox folder.  
If the file is bigger than 150Mb the file is uploaded using small chunks (default 4Mb); 
in this case a . (dot) is printed for every chunk successfully uploaded and a * (star) if an error 
occurs (the upload is retried for a maximum of three times).
Only if the file is smaller than 150Mb, the standard upload API is used, and if the -p option is used
the default curl progress bar is displayed during the upload process.  
The local file/dir parameter supports wildcards expansion.

* **download** &lt;REMOTE_FILE/DIR&gt; [LOCAL_FILE/DIR]  
Download file or directory from Dropbox to a local folder

* **delete** &lt;REMOTE_FILE/DIR&gt;  
Remove a remote file or directory from Dropbox

* **move** &lt;REMOTE_FILE/DIR&gt; &lt;REMOTE_FILE/DIR&gt;  
Move or rename a remote file or directory

* **copy** &lt;REMOTE_FILE/DIR&gt; &lt;REMOTE_FILE/DIR&gt;  
Copy a remote file or directory

* **mkdir** &lt;REMOTE_DIR&gt;  
Create a remote directory on DropBox

* **list** [REMOTE_DIR]  
List the contents of the remote Dropbox folder

* **share** &lt;REMOTE_FILE&gt;  
Get a public share link for the specified file or directory
 
* **info**  
Print some info about your Dropbox account

* **unlink**  
Unlink the script from your Dropbox account


**Optional arguments passed before the command:**  
* **-f &lt;FILENAME&gt;**  
Load the configuration file from a specific file

* **-s**  
Skip already existing files when download/upload. Default: Overwrite

* **-d**  
Enable DEBUG mode

* **-q**  
Quiet mode. Don't show progress meter or messages

* **-p**  
Show cURL progress meter

* **-k**  
Doesn't check for SSL certificates (insecure)


**Examples:**
```bash
    ./dropbox_uploader.sh upload /etc/passwd /myfiles/passwd.old
    ./dropbox_uploader.sh upload *.zip /
    ./dropbox_uploader.sh -p download /backup.zip
    ./dropbox_uploader.sh delete /backup.zip
    ./dropbox_uploader.sh mkdir /myDir/
    ./dropbox_uploader.sh upload "My File.txt" "My File 2.txt"
    ./dropbox_uploader.sh share "My File.txt"
    ./dropbox_uploader.sh list
```

## Tested Environments

* GNU Linux
* FreeBSD 8.3/10.0
* MacOSX
* Windows/Cygwin
* Raspberry Pi
* QNAP
* iOS
* OpenWRT
* Chrome OS
* OpenBSD

If you have successfully tested this script on others systems or platforms please let me know!

## Running as cron job
Dropbox Uploader relies on a different configuration file for each system user. The default configuration file location is HOME_DIRECTORY/.dropbox_uploader. This means that if you do the setup with your user and then you try to run a cron job as root, it won't works.  
So, when running this script using cron, please keep in mind the following:
* Remember to setup the script with the user used to run the cron job
* Use always the -f option to specify the full configuration file path, because sometimes in the cron environment the home folder path is not detected correctly
* My advice is, for security reasons, to not share the same configuration file with different users

## How to setup a proxy

To use a proxy server, just set the **https_proxy** environment variable:

**Linux:**
```bash
    export HTTP_PROXY_USER=XXXX
    export HTTP_PROXY_PASSWORD=YYYY
    export https_proxy=http://192.168.0.1:8080
```

**BSD:**
```bash
    setenv HTTP_PROXY_USER XXXX
    setenv HTTP_PROXY_PASSWORD YYYY
    setenv https_proxy http://192.168.0.1:8080
```
   
## BASH and Curl installation

**Debian & Ubuntu Linux:**
```bash
    sudo apt-get install bash (Probably BASH is already installed on your system)
    sudo apt-get install curl
```

**BSD:**
```bash
    cd /usr/ports/shells/bash && make install clean
    cd /usr/ports/ftp/curl && make install clean
```

**Cygwin:**  
You need to install these packages:  
* curl
* ca-certificates
* dos2unix

Before running the script, you need to convert it using the dos2unix command.


**Build cURL from source:**
* Download the source tarball from http://curl.haxx.se/download.html
* Follow the INSTALL instructions

## DropShell

DropShell is an interactive DropBox shell, based on DropBox Uploader:

```bash
DropShell v0.2
The Intractive Dropbox SHELL
Andrea Fabrizi - andrea.fabrizi@gmail.com

Type help for the list of the available commands.

andrea@Dropbox:/$ ls
 [D] 0       Apps
 [D] 0       Camera Uploads
 [D] 0       Public
 [D] 0       scripts
 [D] 0       Security
 [F] 105843  notes.txt
andrea@DropBox:/ServerBackup$ get notes.txt
```

## Donations

 If you want to support this project, please consider donating:
 * PayPal: andrea.fabrizi@gmail.com
 * BTC: 1JHCGAMpKqUwBjcT3Kno9Wd5z16K6WKPqG
