#!/bin/bash -e

usage() {
	printf "Usage: %s <command> [<options>]" "$0"
	printf "\n"
	printf "Commands:"
	printf "\tadd <name> <exec> [<args>]"
	printf "\t\tschedule <exec> for execution on startup"
	printf "\tremove <name>"
	printf "\t\tremove scheduled job with name <name>"
	printf "\trun"
	printf "\t\texecute all scripts and applications (to be used by service only)"
}

main() {
	if [ $# = 0 ]; then
		usage
		exit 1
	fi
	command="$1"
	shift

	s=0
	case $command in
		add)
			add $* || s=$?
			;;
		run)
			run $* || s=$?
			;;
		remove)
			remove $* || s=$?
			;;
		*)
			echo "Invalid command \"$command\"!"
			usage
			s=1
			;;
	esac
	exit $s
}

add() {
	# TODO: error-checking
	name="$1"
	exec="$2"

	shift 2
	args="$*"

	# check if name already exists
	if [ -e "/etc/runonce.d/$name.sh" ]; then
		echo "Error: job with name=\"$name\" exists already!"
		return 1
	fi

	# create script
	printf "#!/bin/sh\n%s %s\nexit \$?" $exec "$args" > "/etc/runonce.d/$name.sh"
	chmod +x "/etc/runonce.d/$name.sh"

	echo "Added job with name=\"$name\"!"
	return 0
}

remove() {
	if [ $# != 1 ]; then
		echo "$0: invalid number of arguments!"
		usage
		return 1
	fi
	name="$1"

	if [ ! -e "/etc/runonce.d/$name.sh" ]; then
		echo "Error: job with name=\"$name\" does not exists!"
		return 1
	fi

	rm -f "/etc/runonce.d/$name.sh"

	echo "Removed job with name=\"$name\"!"
	return 0
}

run() {
	if [ $# != 0 ]; then
		echo "Encountered illegal arguments: $*"
		return 1
	fi

	# collect all scripts
	scripts=
	i=0
	for script in /etc/runonce.d/*.sh; do
		test ! -e "$script" && continue
		((i=i+1))
		scripts[$i]="$script"
	done
	count=$i

	# run all scripts
	for i in $(seq 1 $count); do
		script="${scripts[$i]}"

		# execute it
		echo $script
		s=0
		$SHELL "$script" || s=$?
		# TODO: send output to logfile?
		if [ $s = 0 ]; then
			# all fine, delete script
			rm -f "$script"
			echo "$(basename \"$script\") succeeded!"
		else
			# script failed, keep it in case it may succeed later, or for debugging
			echo "$(basename \"$script\") failed with $s!"
		fi
	done
	return 0
}

main $*
