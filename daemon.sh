#!/usr/bin/bash
set -e

_count_sessions() {
    loginctl -j list-sessions | jq '[.[] | select(.class != "manager")] | length'
}

_watch_sessions() {
    gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1
}

_set_cpu_epp() {
    local pref=$1
    find /sys/devices/system/cpu/ -mindepth 1 -maxdepth 1 -type d -name "cpu[0-9]*" -exec \
        sh -c 'echo '"$1"' > {}/cpufreq/energy_performance_preference' \;
}

_set_cpu_online() {
    local state=$1
    find /sys/devices/system/cpu/ -mindepth 1 -maxdepth 1 -type d -name "cpu[2-9]*" -exec \
        sh -c 'echo '"$1"' > {}/online' \;
}

_action0 () {
        _set_cpu_epp power
        _set_cpu_online 0
}

_action1() {
        _set_cpu_online 1
        _set_cpu_epp balance_performance
}

_previous=$(_count_sessions)

while read -r; do
    _current=$(_count_sessions)
    if [ $_current -ne $_previous ]; then
        _previous=$_current
        if [ $_current -eq 0 ]; then
            echo "No active sessions"
            _action0
        else
            echo "Active sessions: $_current"
            _action1
        fi
    fi
done < <(_watch_sessions)
