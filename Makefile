
templates:
	echo | r2w.py

check:
	rsync --exclude .svn --exclude .git --exclude Makefile --exclude .publish* -ruav `cat .publish_target`/. .
	git status

clean:
	maint/update-templates.pl -d

committed:
	if git diff-files --name-status | grep '.'; then /bin/false; else :; fi

publish: templates committed
	rsync -O --exclude var --exclude .git\* --exclude Makefile --exclude .publish\* -ruv . `cat .publish_target`
	git push

push: templates committed
	maint/push.sh
