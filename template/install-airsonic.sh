sudo apt-get update && sudo apt-get upgrade -y
#sudo apt install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user
sudo apt install -y default-jdk unzip wget
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat

wget https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.84/bin/apache-tomcat-8.5.84.zip
unzip apache-tomcat-*.zip
sudo mkdir -p /opt/tomcat
sudo mv apache-tomcat-8.5.84 /opt/tomcat/
sudo ln -s /opt/tomcat/apache-tomcat-8.5.84 /opt/tomcat/latest
sudo chown -R tomcat: /opt/tomcat
sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'

echo -e '[Unit]\nDescription=Tomcat servlet container\nAfter=network.target\n[Service]\nType=forking\nUser=tomcat\nGroup=tomcat\nEnvironment="JAVA_HOME=/usr/lib/jvm/default-java"\nEnvironment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"\nEnvironment="CATALINA_BASE=/opt/tomcat/latest"\nEnvironment="CATALINA_HOME=/opt/tomcat/latest"\nEnvironment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"\nEnvironment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"\nExecStart=/opt/tomcat/latest/bin/startup.sh\nExecStop=/opt/tomcat/latest/bin/shutdown.sh\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/tomcat.service
sudo systemctl daemon-reload
sudo systemctl enable tomcat

wget https://github.com/airsonic/airsonic/releases/download/v10.6.2/airsonic.war
gpg --keyserver keyserver.ubuntu.com --recv 0A3F5E91F8364EDF
wget https://github.com/airsonic/airsonic/releases/download/v10.6.2/artifacts-checksums.sha.asc
gpg --verify artifacts-checksums.sha.asc
sha256sum -c artifacts-checksums.sha.asc

sudo mkdir /var/airsonic/
sudo chown -R tomcat:tomcat /var/airsonic/
sudo mkdir /var/music/
sudo mkdir /var/music/Podcast
sudo chown -R tomcat:tomcat /var/music/

# add user to tomcat group so I can do the migration later
sudo usermod -a -G tomcat $(whoami)

# sudo rm /var/lib/tomcat8/webapps/airsonic.war
# sudo rm -R /var/lib/tomcat8/webapps/airsonic/
# sudo rm -R /var/lib/tomcat8/work/*

sudo mv airsonic.war /opt/tomcat/latest/webapps/airsonic.war
sudo chown tomcat:tomcat /opt/tomcat/latest/webapps/airsonic.war

#sudo mkdir -p /opt/tomcat/latest/webapps/airsonic/META-INF

sudo mkdir /etc/systemd/system/tomcat.service.d
echo -e "[Service]\nReadWritePaths=/var/airsonic/\nReadWritePaths=/var/music/" | sudo tee /etc/systemd/system/tomcat.service.d/airsonic.conf
sudo systemctl daemon-reload
sudo systemctl start tomcat.service

echo "waiting 60 seconds for airsonic to start"
sleep 60
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<Context><Resource name="jdbc/airsonicDB" auth="Container" type="javax.sql.DataSource" maxActive="20" maxIdle="30" maxWait="10000" username="mysqladmin" password="SuperS3kretPasSw0rd" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://airsonicmysql.mysql.database.azure.com/airsonic?sessionVariables=sql_mode=ANSI_QUOTES"/></Context>' \
| sudo tee /opt/tomcat/latest/webapps/airsonic/META-INF/context.xml

echo -e 'DatabaseMysqlMaxlength=512\nDatabaseConfigType=JNDI\nDatabaseConfigJNDIName=jdbc/airsonicDB\nDatabaseUsertableQuote=' | sudo tee /var/airsonic/airsonic.properties

# restart tomcat
sudo systemctl start tomcat.service

echo "change the db: alter table podcast_episode modify column description varchar(4096) null;"