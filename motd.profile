# check if there are runonce-scripts scheduled
sched=no
for file in /etc/runonce.d/*.sh; do
	test ! -e "$file" && continue
	sched=yes && break
done

# notify user about it
if [ "$sched" = "yes" ]; then
	echo "Warning: There are run-once jobs scheduled."
	echo "It is advised to reboot as soon as possible to let these jobs complete!"
fi
