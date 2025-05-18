FROM python:3.13.3-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /root/.venv
ENV PATH="/root/.venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir setuptools

COPY requirements.txt /var/code/requirements.txt
RUN pip install --no-cache-dir --requirement /var/code/requirements.txt

FROM python:3.13.3-slim AS runner

COPY src/python/app.py \
     src/python/counter.py \
     src/python/parse_datagram.py \
     src/python/pretty_json.py \
     src/python/udp_server.py \
     src/python/uds_server.py \
     /var/code/

COPY --from=builder /root/.venv /root/.venv

ENV VIRTUAL_ENV="/root/.venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV METRICS_PORT=8125
ENV TRACE_PORT=8126
ENV UDS_PATH=/var/run/datadog/dsd.socket
ENV PYTHONUNBUFFERED=true
ENV FLASK_APP=app
ENV FLASK_ENV=development

COPY docker/flask-entrypoint.sh \
     src/supervisor/stop-supervisor.sh \
     /usr/local/bin/
COPY src/supervisor/supervisord.conf /var/conf/

EXPOSE "${METRICS_PORT}/udp"
EXPOSE "${TRACE_PORT}/tcp"

ENTRYPOINT ["supervisord", "--configuration", "/var/conf/supervisord.conf"]
