#!/bin/bash
# ---------------------------------------------------------------------------
# generator - helps in jekyll partial builds generation and other features

# Copyright 2016, Sid Vishnoi  
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Revision history:
# 2016-10-14
# ---------------------------------------------------------------------------

PROGNAME=${0##*/}
VERSION="0.1"

KRED=`tput setaf 1`
KGRN=`tput setaf 2`
KYEL=`tput setaf 3`
KBLU=`tput setaf 4`
KMAG=`tput setaf 5`
KCYN=`tput setaf 6`
KRST=`tput sgr0`
KINV="\e[7m"


#####################################################
# set your absolute path to project source directory here 
# projectSource=~/path/to/project-folder/source/
projectSource=~/Github/jekyll-helper-script/sample-project/source
# name that will be used in your posts with -n parameter
yourName=""
# your default text editor ## subl/gedit
text_editor="subl"
#####################################################

if [[ $projectSource == "" ]]; then
	echo "${KRED}set project source directory first${KRST}"
	exit 1
fi
cd $projectSource



echo -e "${KCYN}in project directory:"
pwd
echo "${KRST}"

# move everthing to tmp folder, and work there if anything goes wrong during builds (as a safety measure)
rm -rf ../.tmp
mkdir -p ../.tmp
cp -rf . ../.tmp 
cd ../.tmp/

clear_public(){
	echo -e "${KINV}clearing the public folder${KRST}" 
	rm -rf ../public/*
	echo -e "${KGRN}cleared${KRST}"
	return
}

create_new_post(){
	echo "${yellow}you're about to create a new post :D ${reset}"
	directory=$1

	if [[ $directory == "" ]]; then
		printf "Enter post directory: "
		read -r directory
	fi

	mkdir -p ../content/$directory

	printf "Enter post title: "
	read -r TITLE
	postname=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
	FILE=`date +%Y-%m-%d`-${postname// /-}.md

echo "---
layout: news
title: $TITLE
date: $(date +%Y-%m-%dT%H:%M:%S%z)
author: $yourName
categories: [$directory]
modified_time: $(date +%Y-%m-%dT%H:%M:%S%z)
permalink: /$directory/${postname// /-}/
---

start writing something great" >> ../content/$directory/$FILE

	${text_editor} ../content/$directory/$FILE

	return
}

create_category(){
	path=$1

	if [[ $path == "" ]]; then
		echo "${KRED}path not specified! skipping to next argument.${KRST}"
		return
	fi
	if [ ! -d "../content/$path" ]; then
		echo -e "${KRED}directory doesn't exist in content directory. skipping to next argument.${KRST}"
		return
	fi

	echo -e "${KINV}Generating '${path}' directory...${KRST}" >&2;
	rm -rf _posts/*
	rm -rf _site/*
	cp -rf ../content/${path}/* _posts/
	cp -rf _posts/pages/ pages/ # pages from current category
	mv pages/index.html index.html
	cp _config/_config.yml _temp.yml
	sed -i "s|paginate_path: 'page\/:num'|paginate_path: '${path}/page\/:num'|g" _temp.yml # set correct paginate path
	sed -i "s|  path: '\/feed.xml'|  path: '\/${path}\/feed.xml'|g" _temp.yml # set correct feed path
	bundle exec jekyll build --config _temp.yml

	mv _site/index.html _site/${path} # move generated index page and sitemap to category folder
	mv _site/sitemap.xml _site/${path}

	rsync -a _site/* ../public/
	rm _temp.yml
	rm -rf _posts/*
	rm -rf _site/*
	rm -rf pages/
	echo -e "${KGRN}Generated '${path}' in public directory.${KRST}"
	return
}

create_static(){
	echo -e "${KINV}building static assets...${KRST}"
	rm -rf _site/
	rm -rf index.html

	bundle exec jekyll build --config _config/_config_static.yml 

	rm _site/feed.xml
	printf "built:"
	ls _site
	rsync -a _site/* ../public/
	echo -e "${KGRN}generated static assets.${KRST}"
	return
}

create_page(){
	path=$1
	if [[ $path == "" ]]; then
		echo "${KRED}path not specified! skipping to next argument.${KRST}"
		return
	fi
	if [ ! -f "../content/$path" ]; then
		echo -e "${KRED}file doesn't exist at given path. skipping to next argument.${KRST}"
		return
	fi

	echo -e "${KINV}Generating page: '${path}'${KRST}" >&2;
	mkdir -p pages
	rm -rf _posts/*
	cp ../content/$path pages/
	bundle exec jekyll build --config _config/_config_page.yml
	rm _site/feed.xml # remove feed and other auto generated files
	rsync -a _site/* ../public/
	rm -rf pages
	echo -e "${KGRN}generated ${path}.${KRST}"
	return
}

create_main(){
	echo -e "${KINV}building main home page...${KRST}"
	cp -rf ../content/index.html .
	bundle exec jekyll build --config _config/_config_home.yml 
	rsync _site/index.html ../public/
	echo -e "${KGRN}generated home page.${KRST}"
	return
}

create_all(){
	echo "build all!!"
	cats=( $(find  ../content/ -maxdepth 1 -type d -not -path "*pages*" -not -path "*_drafts*" -printf '%P\n') ) 
	for dir in "${cats[@]}"; do
		create_category $dir
	done

	create_static
	create_main

	opages=( $(find  ../content/pages/ -maxdepth 1 -type f -printf '%P\n') )
	for page in "${opages[@]}"; do
		create_page pages/$page
	done

	cd $projectSource 

	rm -rf ../.tmp
	mkdir -p ../.tmp
	cp -rf . ../.tmp # move everthing to tmp folder, as a backup if anything goes wrong during builds
	cd ../.tmp/
	return
}

serve_local(){
	port=4000
	echo -e "${KINV}serving to local host on port :$port${KRST}" 
	pushd ../public/
	python -m SimpleHTTPServer $port & disown
	popd
	PID=`ps -ef |grep SimpleHTTPServer |grep $port |awk '{print $2}'`			
	echo "server PID = $PID"
	echo "${KYEL}to kill server type k OR ::::: $ kill -9 $PID${KRST}"
	read -p "" response
	if [[ $response =~ ^(k|K)$ ]]; then
		kill -9 $PID
		echo "${KGRN}local server killed.${KRST}"
	fi
	return
}

deploy(){
	echo -e "${KINV}deploy the public folder${KRST}"
	echo -e "${KRED}create a deployment method first in generator file in function deploy(){KRST}"
	return
}

error_exit() {
	echo -e "${KRED}${PROGNAME}: ${1:-"Unknown Error"}${KRST}" >&2
	cd $projectSource
	cd ..
	rm -rf .tmp
	exit 1
}

graceful_exit() {
	echo -e "${KYEL}${KINV}final clean up...${KRST}"
	cd $projectSource
	cd ..
	rm -rf .tmp
	echo -e "${KGRN}ALL DONE. EXITING..${KRST}"
	exit
}

signal_exit() { # Handle trapped signals
	case $1 in
		INT)
			error_exit "${KYEL}Program interrupted by user${KRST}" ;;
		TERM)
			echo -e "${KYEL}\n$PROGNAME: Program terminated${KRST}" >&2
			graceful_exit 
			;;
		*)
			error_exit "${KRED}$PROGNAME: Terminating on unknown signal${KRST}" ;;
	esac
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Parse command-line
while [[ -n $1 ]]; do
	case $1 in
		-h | --help)
			echo -e "$(<_jekyll-helper/helper-manual.txt)"
			exit 0
			;;
		-n | --new)
			shift; directory="$1"
			create_new_post $directory
			;;
		-f | --fresh)
			clear_public
			;;
		-c | --cat)
			shift; path="$1" 
			create_category $path
			;;
		-p | --page)
			shift; path="$1"
			create_page $path
			;;
		-s | --static)
			create_static
			;;
		-m | --main)
			create_main
			;;
		-a | --all)
			create_all
			;;
		-l | --local)
			serve_local
			;;
		-d | --deploy)
			deploy
			;;
		-* | --*)
			error_exit "Unknown option $1" 
			;;
		*)
			echo "Argument $1 to process..." 
			;;
	esac
	shift
done

graceful_exit
