
libs="header.tt footer.tt"

find . -name \*.\*.tt -print | xargs ls -tr | while read fn
do
	dest=`expr "$fn" : '\(.*\).tt'`
	if [ $dest -nt $fn ]
	then
		nt=
		for x in $libs
		do
			[ $dest -ot $x ] && nt="$nt $x"
		done
		[ -z "$nt" ] && continue
	fi
	echo "Processing $fn => $dest"
	if tpage $fn > $dest
	then
		:
	else
		bad="$bad $fn"
	fi
done

if [ -n "$bad" ]
then
	echo "FAILED: $bad"
	exit 1
fi
