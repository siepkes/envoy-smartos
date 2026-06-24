#!/bin/sh
#
# Starts Envoy. Run by hot-restarter.py (see envoy.xml) for every hot restart epoch, which it passes
# in RESTART_EPOCH, and by envoy-refresh.sh with "--mode validate" to check the configuration before
# a hot restart. Install as /opt/envoy/smf/envoy-start.sh.
#
exec /opt/envoy/bin/envoy-static \
    --config-path /opt/envoy/etc/envoy.yaml \
    --restart-epoch "${RESTART_EPOCH:-0}" \
    "$@"
