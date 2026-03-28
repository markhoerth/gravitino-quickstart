FROM dbeaver/cloudbeaver:latest

# Pre-configure admin credentials and data sources
COPY initial-data.conf /opt/cloudbeaver/conf/initial-data.conf
COPY initial-data-sources.conf /opt/cloudbeaver/conf/initial-data-sources.conf

# Enable anonymous access to shared connections
RUN sed -i 's|grantConnectionsAccessToAnonymousTeam.*|grantConnectionsAccessToAnonymousTeam: true,|' \
    /opt/cloudbeaver/conf/cloudbeaver.conf

