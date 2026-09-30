#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
MYSQLLOG=/tmp/$SCRIPT_NAME-$TIMESTAMP-Mysql.log

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$2 .. $R FAILURE $N"
        exit 1
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

dnf update -y &>>$LOGFILE
VALIDATE $? "Latest packages updated"
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm &>>$LOGFILE
VALIDATE $? "Installing package"
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 &>>$LOGFILE
dnf install -y mysql-community-server &>>$LOGFILE
VALIDATE $? "Installing mysql server"

systemctl enable --now mysqld
VALIDATE $? "Enabling mysqld"
systemctl start mysqld
VALIDATE $? "Starting Mysql"
sleep 2
Temporary=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}') &>>$MYSQLLOG
echo "Temp password: $Temporary"

New_Pass="ExpenseApp@1"
echo "New Password: $New_Pass" 
sleep 5
mysql -u root -p${New_Pass} << EOF
exit
EOF
if [ $? -ne 0 ]
then
    sudo mysql --connect-expired-password -u root -p"$Temporary" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${New_Pass}';" &>>MYSQLLOG
    VALIDATE $? "Root Password Setup"
else
    echo -e "Mysql Root Password is already setup.. $Y SKIPPING $N"
    mysql -u root -p${New_Pass} <<-EOF
     CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'ExpenseApp@1';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF  

fi