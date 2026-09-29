#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/logs/$SCRIPT_NAME-$TIMESTAMP.log
MYSQLLOG=/tmp/$SCRIPT_NAME-$TIMESTAMP-Mysql.log

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$2 .. $R FAILURE $N"
    else
        echo -e "$2 .. $G SUCCESS $N"
    fi
}
echo "Starting the script: $TIMESTAMP"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]
then
    echo "Need to run the script with super access"
    exit 1
else
    echo "You are super access"
fi 

dnf update -y
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm &>>$LOGFILE
VALIDATE $? "Installing package is success"
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 &>>$LOGFILE
dnf install -y mysql-community-server &>>$LOGFILE
VALIDATE $? "Installing mysql server"
systemctl enable --now mysqld
VALIDATE $? "Enabling mysqld"
systemctl start mysqld

VALIDATE $? "Starting Mysql"
sleep 2
Temporary=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}') &>>$MYSQLLOG
New_Pass="ExpenseApp@1"

sudo mysql_secure_installation <<-EOF
$Temporary
n
$New_Pass
$New_Pass
y
y
y
y
EOF

# Ensure you hit ENTER after the EOF line above so there is a blank line here
