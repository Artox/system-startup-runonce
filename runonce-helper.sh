#!/bin/sh -e

usage() {
	echo "Usage: $0 <command> [<options>]"
	echo
	echo "Commands:"
	echo "\tadd <name> <exec> [<args>]"
	echo "\t\tschedule <exec> for execution on startup"
	echo "\tremove <name>"
	echo "\t\tremove scheduled job with name <name>"
	echo "\trun"
	echo "\t\texecute all scripts and applications (to be used by service only)"
}

main() {
	if [ $# = 0 ]; then
		usage
		exit 1
	fi
	command=$1
	shift

	case $command in
		add)
			add $@
			;;
		run)
			run $@
			;;
		remove)
			remove $@
			;;
		*)
			echo "Invalid command \"$command\"!"
			usage
			exit 1
			;;
	esac
}

add() {
	# TODO: error-checking
	name="$1"
	exec="$2"

	shift 2
	args="$@"

	# check if name already exists
	if [ -e "/etc/runonce.d/$name.sh" ]; then
		echo "Error: job with name=\"$name\" exists already!"
		return 1
	fi

	# create script
	echo "#!/bin/sh\n\n$exec $args" > "/etc/runonce.d/$name.sh"
	chmod +x "/etc/runonce.d/$name.sh"

	echo "Added job with name=\"$name\"!"
	return 0
}

remove() {
	# TODO: error-checking
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
	# go through all scripts
	for script in /etc/runonce.d/*.sh; do
		s=0
		$SHELL "$script" || s=$?
		# TODO: send output to logfile?
		if [ $s = 0 ]; then
			# all fine, delete script
			rm -f $script
		else
			# script failed, keep it in case it may succeed later, or for debugging
			echo "`basename $script` failed with $s!"
		fi
	done
	return 0
}

main $@
