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

dnf install -y nodejs20 &>>$LOGFILE
VALIDATE $? "Installing nodejs"

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "User Creation"

else
    echo -e "User is already created.. $Y SKIPPING $N"
fi
cd /app &>>$LOGFILE
# mkdir -p /app --> without error
if [ $? -ne 0 ]
then
    mkdir /app &>>$LOGFILE
    VALIDATE $? "Dir creation"
    cd /app

else
    echo -e "Directory already created.. $Y SKIPPING $N"
    
fi
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE

rm -rf /app/* &>>$LOGFILE
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Code is Unzip"
npm install &>>$LOGFILE
cp /home/ec2-user/ExpenseProject-Shell/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Copying the backend service file to system config"

systemctl daemon-reload
VALIDATE $? "Reload Daemon"

systemctl start backend &>>$LOGFILE
VALIDATE $? "start backend"

systemctl enable backend
VALIDATE $? "Enable backend"

#echo "Install MysqlClient to use mysqlDB"
New_Pass="ExpenseApp@1"
mysql -u root -p{$New_Pass} <<EOF &>>$LOGFILE
exit
EOF

if [ $? -ne 0 ]
then
     echo "Mysql is not installed to connect DB"
     dnf install mariadb105 -y &>>$LOGFILE
     VALIDATE $? "Install Mysql Client"
else
    echo -e "Mysql is already installed ... $Y SKIPPING $N"
fi

sleep 3
echo "Creating database using schema.."
mysql -h 172.31.18.69 -uroot -pExpenseApp@1 < schema/backend.sql
VALIDATE $? "Schema installed"

systemctl restart backend
VALIDATE $? "Restarting backend"