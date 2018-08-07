FROM nimmis/java-centos:oracle-8-jdk

# Product specific labels
LABEL io.k8s.display-name="TIBCO DataSynapse GridServer Manager"
LABEL Tibco.gridserver.version="6.2.0"
LABEL summary="Provides GridServer Manager base image"

# Obtain the vendor-provided archive from external storage
ARG GS_ARCHIVE_URL=http://athena.grid.datasynapse.com/testing/Releases/internal/Grid_Builds/6.2.0/6.2.0.130326/TIB_gridserver_6.2.0.tar.gz
ARG GS_HF_ARCHIVE_URL=http://athena.grid.datasynapse.com/testing/Releases/internal/Grid_Builds/6.2.0/6.2.0.163493/TIB_gridserver_6.2.0_hotfix13.jar
# ARG GS_DEPLOYMENT=http://lin32vm053.rofa.tibco.com:3000/gists/414/blobs/fc4c53ae5ae34a68770415c14cb8a38227feb9e5/config-and-run.sh

# The maximum heap size, in MB, as specified by the -Xmx<size> java option.
# Default is 1024m
ARG JVM_MAX_HEAP="1024m"

# set JAVA_HOME environment 
ENV JAVA_HOME /usr/java/latest

# Download the archive and extract it without writing the archive file to disk
RUN curl $GS_ARCHIVE_URL | tar xz -C /opt
RUN cd /opt

#RUN hotfix installation here
RUN curl $GS_HF_ARCHIVE_URL > hotfix.jar
RUN java -jar hotfix.jar --batch /opt/datasynapse/manager
RUN cd /opt/datasynapse/manager

# Manager communications (between directors and brokers)
EXPOSE 5635/tcp

# Client & engine communications
EXPOSE 8000/tcp

# Administration Tool (web based)
EXPOSE 8080/tcp

WORKDIR /opt/datasynapse/manager

#ARG CACHE_DATE=1

# Use provided max heap setting
# RUN sed -i "s/# MAX_HEAP=/MAX_HEAP=$JVM_MAX_HEAP/" server.sh

# Generate the manager-data folder
RUN ./server.sh prepare

# OpenShift will run the server using a randomly generated uid
RUN chmod -R a+w /opt/datasynapse/manager-data
RUN curl http://lin32vm053.rofa.tibco.com:3000/gists/415/blobs/ed1a2ef8d99f6e4e54daf51738b98953463f48b4/install.silent > install.silent
RUN ./install.sh install.silent > ./stdout.txt 2> ./stderr.txt

#COPY config-and-run.sh /opt/datasynapse/manager
#RUN /bin/bash -c <(curl -s http://lin32vm053.rofa.tibco.com:3000/gists/414/blobs/6205a116b4d48f4eaf94f011dc887f5f4020b7b2/config-and-run.sh | tr -d '\r')
#RUN curl -fsSL http://lin32vm053.rofa.tibco.com:3000/gists/414/blobs/095ebb6431dc11fa4b4f995b695c680424c5b8c5/config-and-run.sh | tr -d '\r' > config-and-run.sh
#RUN chmod +x config-and-run.sh
#RUN ./config-and-run.sh

CMD cd /opt/datasynapse/manager && ./server.sh start && tail -F /etc/hosts
# CMD cd /opt/datasynapse/YourScriptFolder && ./YourDeplomentScript.sh
# CMD bash
