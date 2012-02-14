
templates:
	r2w

check:
	rsync --exclude .svn --exclude .git --exclude Makefile --exclude .publish* -ruav `cat .publish_target`/. .
	git status

clean:
	find . -name \*.txt -print | sed 's/.txt$$/.html/' | while read fn; do [ -f "$$fn" ] && rm "$$fn"; done

committed:
	if git diff-files --name-status | grep '.'; then false; else :; fi

publish: templates committed
	rsync -O --exclude var --exclude .git\* --exclude Makefile --exclude .publish\* -ruv . `cat .publish_target`
	git push

push: templates committed
	maint/push.sh
	git push origin website
