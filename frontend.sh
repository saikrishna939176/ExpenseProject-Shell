#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

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

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enable Nginx"
systemctl start nginx
VALIDATE $? "Start Nginx"

rm -rf /usr/share/nginx/html/*

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGFILE
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Code is Unzip"

cp /home/ec2-user/ExpenseProject-Shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copying the backend service file to system config"

systemctl restart nginx
VALIDATE $? "Restarting Nginx"