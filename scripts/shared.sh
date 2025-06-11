#!/usr/bin/env bash


get_tmux_option() {
	local option=$1
	local default_value=$2
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

set_tmux_option() {
	local option="$1"
	local value="$2"
	tmux set-option -gq "$option" "$value"
}

tailscale_bin(){
    for op in "$@"; do
        if command -v "$op" > /dev/null 2>&1; then
            echo "$op"
            return 0
        fi
    done
    loc=$(which tailscale)
    if [ $? -eq 0 ]; then
        echo $loc
        return 0
    fi
    return 1
}

current_status(){
    local ts=$(tailscale_bin /usr/local/bin/tailscale $HOME/go/bin/tailscale /Applications/Tailscale.app/Contents/MacOS/Tailscale)
    "$ts" status --json | jq -r 'if .BackendState == "Running" then if .Self.Online then "Online" else "Offline" end else .BackendState end'
}

current_tailnet(){
    local ts=$(tailscale_bin /usr/local/bin/tailscale $HOME/go/bin/tailscale /Applications/Tailscale.app/Contents/MacOS/Tailscale)
    "$ts" status --json | jq -r '.CurrentTailnet.Name'
}

print_icon(){
    icon="$(get_tmux_option @tailscale_icon 󱗼)"
    echo "$icon"
}

exit_node(){
    local ts=$(tailscale_bin /usr/local/bin/tailscale $HOME/go/bin/tailscale /Applications/Tailscale.app/Contents/MacOS/Tailscale)
    status=$("$ts" status --json)
    id=$(echo "$status" | jq -r '.ExitNodeStatus.ID')
    online=$(echo "$status" | jq -r '.ExitNodeStatus.Online')
    if [[ "$online" == "true" ]]; then
        node=$(echo $status | jq -r ".Peer | to_entries | map(.value | select(.ID == \"$id\"))[0].HostName")
        echo "[$node]"
        return 0
    fi
    echo ""
}

print_status_icon(){
    local status=""
    if [ "$#" == 0 ]; then
        status=$(current_status)
    else
        status=$1
    fi
    if [[ $status == "Online" ]]; then
        icon="$(get_tmux_option @tailscale_online_icon ✅)"
    elif [[ $status == "Offline" ]]; then
        icon="$(get_tmux_option @tailscale_offline_icon ⛔️)"
    elif [[ $status == "Stopped" ]]; then
        icon="$(get_tmux_option @tailscale_stopped_icon 🛑)"
    elif [[ $status == "Starting" ]]; then
        icon="$(get_tmux_option @tailscale_starting_icon 🔄)"
    else
        icon="$(get_tmux_option @tailscale_unknown_icon ❓)"
    fi
    echo "$icon"
}

print_status(){
    local status=$(current_status)
    local icon=$(print_status_icon $status)
}
