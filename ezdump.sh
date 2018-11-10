#!/bin/bash

# Set up default variables
HOST="hostname"
USER="username"
PASSSWORD="password"
DEST="~/path/to/destination/"

DB="databaseName"
ARCH="archiveName"

if [ $1 -eq "" ]; then
	echo "Please add parameters of: \
		ezdump hostname username password destination databaseName archiveName"
fi

if [ $1 -ne "" ]; then
	$HOST=$1
fi

if [ $2 -ne "" ]; then
	$USER=$2
fi

if [ $3 -ne "" ]; then
	$PASSWORD=$3
fi

if [ $4 -ne "" ]; then
	$DEST=$4
fi

if [ $5 -ne "" ]; then
	$DB=$5
fi

if [ $6 -ne "" ]; then
	$ARCH=$6
fi

DEFAULTDIR=~/.ezdump/
SSHDIR=~/.ezdump/.ssh/
MYCNF=~/.ezdump/.my.cnf

# Generate a working directory
mkdir $DEFAULTDIR
mkdir $SSHDIR

# Setup a function to pass in MySQL configuration information
function MyCnf() {
	echo '\
	[mysqldump-setup]
	host=$1
	user=$2
	password=$3
	'
}

# Generate information for the mysqldump
function DumpLiner() {
	DATE=$1
	ARCHIVE_FILE=${DATE}.$2.sql.gz
	MYSQL_CONFIG=$3
	DB=$4
	KEY=$5
	mysqldump --defaults-extra-file=$MYSQL_CONFIG} ${DB} --single-transaction --routines --events --triggers \
  | gzip -c \
  | openssl smime -encrypt -binary -text -aes256 -out ${ARCHIVE_FILE} -outform DER ${KEY}
}

# Generate openssl key
cd $SSHDIR
openssl req -x509 -nodes -newkey rsa:2048 -keyout ezdump.priv.pem -out ezdump.pub.pem
cd -

# Generate MySQL configuration file
touch $MYCNF
chown whoami:whoami $MYCNF
chmod 660 $MYCNF

# Input configurations into MySQL configuration file
cat $(MyCnf($HOST, $USER, $PASSWORD)) > $MYCNF

# Generate dump
echo "Generating MySQL Database Dump..."
DATE=DATE=`date +%Y-%m-%d-%H-%M-%S`
PUB_KEY=${SSHDIR} + "ezdump.pub.pem"
cd $DEST
DumperLiner($DATE, $ARCH, $DB, $PUB_KEY)
echo "Done!"






