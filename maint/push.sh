#!/bin/sh

git fetch
if [ -n "$(git rev-list -1 refs/heads/gh-pages..refs/remotes/origin/master)" ]
then
	git update-ref refs/heads/gh-pages refs/remotes/origin/master
fi
old=$(git symbolic-ref HEAD)
git symbolic-ref HEAD refs/heads/gh-pages
git checkout HEAD .gitignore
git add .
git update-ref refs/heads/gh-pages $(echo "autopublish html" | git commit-tree `git write-tree` -p HEAD -p $old)
git push origin HEAD:master
git symbolic-ref HEAD $old
git read-tree HEAD
git checkout HEAD .gitignore
git update-index --refresh