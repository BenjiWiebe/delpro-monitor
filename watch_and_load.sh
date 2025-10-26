#!/usr/bin/bash
while inotifywait --quiet --event modify,close_write view.php ||true; do
	if php view.php >view.html.tmp; then
		mv view.html.tmp view.html
	else
		tput bel
		clear
		php view.php
	fi
done
