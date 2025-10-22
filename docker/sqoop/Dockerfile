FROM apache/hadoop:2.10.2 AS hg-sqoop

USER root

# export http_proxy=http://alan1:xe&UvMTrrEOiPhA7@10.5.33.2:6777
# export https_proxy=http://alan1:xe&UvMTrrEOiPhA7@10.5.33.2:6777

# Install Sqoop
RUN wget https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    tar -xvzf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -C /opt && \
    mv /opt/sqoop-1.4.7.bin__hadoop-2.6.0 /opt/sqoop && \
    rm sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz

ENV SQOOP_HOME=/opt/sqoop
ENV PATH=$SQOOP_HOME/bin:$PATH

# Install JDK 8
RUN wget -O openjdk8.tar.gz https://download.java.net/openjdk/jdk8u41/ri/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz && \
    tar -xvzf openjdk8.tar.gz -C /opt && \
    mv /opt/java-se-8u41-ri /opt/java-8 && \
    rm -f openjdk8.tar.gz

ENV JAVA_HOME=/opt/java-8
ENV PATH=$JAVA_HOME/bin:$PATH

ENV http_proxy=""
ENV https_proxy=""

# Setup Hadoop Paths
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_YARN_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV SQOOP_HOME=/opt/sqoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Copy the same Hadoop config to connect to Hadoop cluster
COPY ./conf/* /opt/hadoop/etc/hadoop/

# Copy JDBC drivers (for Postgres/MySQL/etc.)
COPY ./drivers/* $SQOOP_HOME/lib/
