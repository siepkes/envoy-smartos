#!/bin/sh
#
# SMF refresh method of envoy.xml to hot restart Envoy. Install as /opt/envoy/smf/envoy-refresh.sh.
#
# hot-restarter.py kills *all* Envoy processes when a new epoch exits with an error. So this script
# only hot restart when the configuration is valid and the previous hot restart has finished.
# Requires the Envoy admin interface on ADMIN, curl and jq.
#
. /lib/svc/share/smf_include.sh

ADMIN=http://127.0.0.1:9901
WAIT_ATTEMPTS=60

# Prints "<restart epoch> <hot restart initializing>" of the Envoy serving the admin interface,
# eg. "3 false", or nothing if the admin interface doesn't answer.
admin_epoch() {
    curl -sf --max-time 1 "${ADMIN}/server_info" 2>/dev/null |
        jq -r '"\(.command_line_options.restart_epoch) \(.hot_restart_initializing)"' 2>/dev/null
}

# Waits until Envoy epoch $1 serves the admin interface and has finished initializing.
wait_for_epoch() {
    attempt=0
    while [ "${attempt}" -lt "${WAIT_ATTEMPTS}" ]; do
        if [ "$(admin_epoch)" = "$1 false" ]; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    return 1
}

current=$(admin_epoch)
if [ -z "${current}" ]; then
    echo "envoy-refresh: admin interface ${ADMIN} is not answering, not hot restarting" >&2
    exit $SMF_EXIT_OK
fi
epoch=${current%% *}

if ! wait_for_epoch "${epoch}"; then
    echo "envoy-refresh: epoch ${epoch} is still initializing, not hot restarting" >&2
    exit $SMF_EXIT_OK
fi

if ! /opt/envoy/smf/envoy-start.sh --mode validate; then
    echo "envoy-refresh: configuration is invalid, not hot restarting" >&2
    exit $SMF_EXIT_OK
fi

# Only signal hot-restarter.py Otherwise Envoy processes that are still starting up would be
# killed by SIGHUP.
ctid=$(svcs -H -o ctid "${SMF_FMRI}" | tr -d ' ')
if ! pkill -HUP -c "${ctid}" -f 'hot-restarter\.py'; then
    echo "envoy-refresh: hot-restarter.py is not running in contract ${ctid}" >&2
    exit $SMF_EXIT_ERR_FATAL
fi

next=$((epoch + 1))
if wait_for_epoch "${next}"; then
    echo "envoy-refresh: hot restarted into epoch ${next}"
else
    echo "envoy-refresh: epoch ${next} did not take over within ${WAIT_ATTEMPTS} attempts" >&2
fi
exit $SMF_EXIT_OK
