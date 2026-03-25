FROM dbeaver/cloudbeaver:latest

# Pre-configure admin credentials and data sources
COPY initial-data.conf /opt/cloudbeaver/conf/initial-data.conf
COPY initial-data-sources.conf /opt/cloudbeaver/conf/initial-data-sources.conf

# Enable anonymous access to shared connections
RUN sed -i 's|grantConnectionsAccessToAnonymousTeam.*|grantConnectionsAccessToAnonymousTeam: true,|' \
    /opt/cloudbeaver/conf/cloudbeaver.conf

# Restore pre-configured workspace (includes working Trino connection)
COPY workspace-backup.tar.gz /tmp/workspace-backup.tar.gz
RUN tar -xzf /tmp/workspace-backup.tar.gz -C /opt/cloudbeaver && \
    rm /tmp/workspace-backup.tar.gz
