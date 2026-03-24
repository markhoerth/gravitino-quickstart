FROM python:3.11-slim

RUN apt-get update && \
    apt-get install -y curl postgresql-client && \
    rm -rf /var/lib/apt/lists/*

RUN pip install requests pyarrow psycopg2-binary

COPY init.sh /init.sh
COPY register_catalogs.py /register_catalogs.py
COPY load_data.py /load_data.py

RUN chmod +x /init.sh

CMD ["/init.sh"]
