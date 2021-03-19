git add .

msg="update at $(date '+%Y%m%d-%H:%M:%S')"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

git push
