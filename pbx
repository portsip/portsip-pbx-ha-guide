#!/bin/sh

. ${OCF_ROOT}/lib/heartbeat/ocf-shellfuncs

metadata_template()
{
    local ra_name=$1
    local ra_version=$2
    local svr_name=$3
    cat <<END
<?xml version="1.0"?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">
<resource-agent name="$ra_name">
<version>$ra_version</version>

<longdesc lang="en">
Resource script for $svr_name server. It manages a $svr_name instance as a HA resource.
</longdesc>
<shortdesc lang="en">Manages a $svr_name instance</shortdesc>

<parameters>
</parameters>

<actions>
<action name="start" timeout="10s" />
<action name="stop" timeout="30s" />
<action name="status" timeout="10s" />
<action name="monitor" depth="0" timeout="10s" interval="10s" />
<action name="meta-data" timeout="5s" />
<action name="validate-all"  timeout="5s"/>
</actions>
</resource-agent>
END
}

usage_template()
{
    local prog=$1
    cat <<-EOF
usage: $prog action

action:
        start   start Server
        stop    stop Server
        status  return the status of Server, up or down
        monitor  return TRUE if Server appears to be working.
        meta-data       show meta data message
        validate-all    validate the instance parameters
EOF
}

isalive_service()
{
	local is_pbx_container_started=$(docker container ls | grep ${SERVICE_NAME}|wc -l)
	if [ $is_pbx_container_started -eq 1 ];then
		ocf_log debug "[$SERVICE_NAME]: alive"
		return $OCF_SUCCESS
	fi
	ocf_log error "[$SERVICE_NAME]: dead"
	return $OCF_NOT_RUNNING
}

monitor_service()
{
	isalive_service || return $OCF_NOT_RUNNING
	return $OCF_SUCCESS
}

start_service()
{
	validate_all_service || exit $?

	#judge already started
	monitor_service
	if [ $? -eq $OCF_SUCCESS ]; then
		return $OCF_SUCCESS
	fi

	# start container pbx
	echo "`date "+%Y/%m/%d %T"`: start ==========================="
	docker start ${SERVICE_NAME}
	while true; do
		monitor_service
		if [ $? -eq $OCF_SUCCESS ]; then
			break
		fi
		ocf_log debug "start_service[$SERVICE_NAME]: retry"
		sleep 3
	#todo only try three times?
	done

	return $OCF_SUCCESS
}

stop_service()
{
	# stop pbx container
	docker stop -t 1 ${SERVICE_NAME}

	return $OCF_SUCCESS
}

validate_all_service()
{
	return $OCF_SUCCESS
}

# RA environment variables
COMMAND=$1
SERVICE_NAME="pbx"
SERVICE_RA_NAME="pbx"
SERVICE_RA_VERSION="1.0"

# the main script
case "$COMMAND" in
	start)
		ocf_log debug  "[$SERVICE_NAME] Enter start"
		start_service
		func_status=$?
		ocf_log debug  "[$SERVICE_NAME] Leave start $func_status"
		exit $func_status
		;;
	stop)
		ocf_log debug  "[$SERVICE_NAME] Enter stop"
		stop_service
		func_status=$?
		ocf_log debug  "[$SERVICE_NAME] Leave stop $func_status"
		exit $func_status
		;;
	status)
		if monitor_service; then
			echo "[$SERVICE_NAME] service is running"
			exit $OCF_SUCCESS
		else
			echo "[$SERVICE_NAME] service is stopped"
			exit $OCF_NOT_RUNNING
		fi
		exit $?
		;;
	monitor)
		ocf_log debug  "[$SERVICE_NAME] Enter monitor"
		monitor_service
		func_status=$?
		ocf_log debug  "[$SERVICE_NAME] Leave monitor $func_status"
		exit $func_status
		;;
	meta-data)
		metadata_template ${SERVICE_RA_NAME} ${SERVICE_RA_VERSION} ${SERVICE_NAME}
		exit $OCF_SUCCESS
		;;
	validate-all)
		validate_all_service
		exit $?
		;;
	usage|help)
		usage_template $0
		exit $OCF_SUCCESS
		;;
	*)
		usage_template $0
		exit $OCF_ERR_UNIMPLEMENTED
		;;
esac
