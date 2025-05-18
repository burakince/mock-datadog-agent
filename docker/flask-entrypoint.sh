#!/bin/sh

cd /var/code
/root/.venv/bin/python -m flask run --port "${TRACE_PORT}" --host 0.0.0.0
