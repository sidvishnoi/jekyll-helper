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

# Usage: generator [-h|--help] [-n|--new location] [-f|--fresh] [-c|--cat category path] [-p|--post path] [-s|--static] [-m|--main] [-a|--all] [-l|--local] [-d|--deploy]

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

projectDir=~/Github/jekyll-partial-builds/source/ # set your project source directory here >>  projectDir=~/path/to/project-folder/source/

if [[ $projectDir == "" ]]; then
	echo "${KRED}set project directory first${KRST}"
	exit 1
fi

cd $projectDir # set your project source directory here
echo "${KCYN}in project directory:"
pwd
echo "${KRST}"

rm -rf ../.tmp
mkdir -p ../.tmp
cp -rf . ../.tmp # move everthing to tmp folder, as a backup if anything goes wrong during builds
cd ../.tmp/

clean_up() { # Perform pre-exit housekeeping
	echo "${KYEL}final clean up...${KRST}"
	cd $projectDir
	cd ..
	rm -rf .tmp
	return
}

error_exit() {
	echo -e "${KRED}${PROGNAME}: ${1:-"Unknown Error"}${KRST}" >&2
	clean_up
	exit 1
}

graceful_exit() {
	clean_up
	echo -e "${KGRN}ALL DONE. EXITING..${KRST}"
	exit
}

signal_exit() { # Handle trapped signals
	case $1 in
		INT)
			error_exit "${KYEL}Program interrupted by user${KRST}" ;;
		TERM)
			echo -e "${KYEL}\n$PROGNAME: Program terminated${KRST}" >&2
			graceful_exit ;;
		*)
			error_exit "${KRED}$PROGNAME: Terminating on unknown signal${KRST}" ;;
	esac
}

usage() {
	echo -e "Usage: $PROGNAME [-h|--help] [-n|--new location] [-f|--fresh] [-c|--cat category path] [-p|--post path] [-s|--static] [-m|--main] [-a|--all] [-l|--local port] [-d|--deploy]"
}

help_message() {
	cat <<- _EOF_
	$PROGNAME ver. $VERSION
	helps in jekyll partial builds generation and other features

	$(usage)

	Options:
	-h, --help  Display this help message and exit.
	-n, --new location  create a new file along with a folder if required
		Where 'location' is the enter location where to create file.
	-f, --fresh  clear the public folder
	-c, --cat path  build a category
		Where 'category path' is the path of category.
	-p, --post path  build a specific post
		Where 'path' is the path of post, relative to content dir.
	-s, --static  build static files
	-m, --main  build main home page
	-a, --all  build all
	-l, --local port  serve to local host
		Where 'port' is port where to serve.
	-d, --deploy  deploy the public folder

_EOF_
	return
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT



# Parse command-line
while [[ -n $1 ]]; do
	case $1 in
		-h | --help)
			help_message; graceful_exit ;;
		-n | --new)
			echo "create a new file along with a folder if required"; shift; location="$1" 
			;;
		-f | --fresh)
			echo -e "\t${KMAG}clearing the public folder${KRST}" 
			rm -rf ../public/*
			echo -e "\t${KGRN}cleared${KRST}"
			;;
		-c | --cat)
			shift; path="$1" 
			if [[ $path == "" ]]; then
				echo "${KRED}path not specified! skipping to next argument.${KRST}"
				continue
			fi
			if [ ! -d "../content/$path" ]; then
				echo -e "\t${KRED}directory doesn't exist in content directory. skipping to next argument.${KRST}"
				continue
			fi
				echo -e "\t${KMAG}Generating '${path}' directory...${KRST}" >&2;
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
				echo -e "\t${KGRN}Generated '${path}' in public directory.${KRST}"
			;;
		-p | --post)
			shift; path="$1"
			if [[ $path == "" ]]; then
				echo "${KRED}path not specified! skipping to next argument.${KRST}"
				continue
			fi
			if [ ! -f "../content/$path" ]; then
				echo -e "\t${KRED}file doesn't exist at given path. skipping to next argument.${KRST}"
				continue
			fi
			echo -e "\t${KMAG}Generating page: '${path}'${KRST}" >&2;
			pwd
			du -h ../content/$path
			rsync -a ../content/$path pages/
			bundle exec jekyll build --config _config/_config_post.yml
			rm _site/feed.xml # remove feed and other auto generated files
			rsync -a _site/* ../public/
			echo -e "\t${KGRN}generated ${path}.${KRST}"
			;;
		-s | --static)
			echo -e "\t${KMAG}building static assets.${KRST}"
			rm -rf _site/
			rm -rf index.html

			bundle exec jekyll build --config _config/_config_static.yml 

			rm _site/feed.xml
			printf "built:"
			ls _site
			rsync -a _site/* ../public/
			echo -e "\t${KGRN}generated static assets.${KRST}"
			;;
		-m | --main)
			echo -e "\t${KMAG}building main home page.${KRST}"
			cp -rf ../content/index.html .
			bundle exec jekyll build --config _config/_config_home.yml 
			rsync _site/index.html ../public/
			echo -e "\t${KGRN}generated home page."
			;;
		-a | --all)
			echo "build all!!"
			dirs=( $(find  ../content/ -maxdepth 1 -type d -not -path "*pages*" -not -path "*_drafts*" -printf '%P\n') ) 
			cats=""
			for dir in "${dirs[@]}"; do
    			cats+="-c $dir "
			done
			./"${0##*/}" -m $cats -s  ## call cats in end - IDK its causing some problem as cleanup as occured on this call
cd $projectDir # set your project source directory here
echo "${KCYN}in project directory:"
pwd
echo "${KRST}"

rm -rf ../.tmp
mkdir -p ../.tmp
cp -rf . ../.tmp # move everthing to tmp folder, as a backup if anything goes wrong during builds
cd ../.tmp/
echo "continuing to next user arguments.."
			;;
		-l | --local)
			shift; port="$1" 
			if [[ $port == "" ]]; then
				port=4000
			fi
			echo -e "\t${KMAG}serving to local host on port :$port${KRST}" 
			pushd ../public/
			python -m SimpleHTTPServer $port &
			popd
			PID=`ps -ef |grep SimpleHTTPServer |grep $port |awk '{print $2}'`			
			echo "server PID = $PID"
			echo "${KYEL}to kill server type k OR ::::: $ kill $PID${KRST}"
			read -p "" response
			if [[ $response =~ ^(k|K)$ ]]; then
				kill $PID
				echo "${KGRN}local server killed.${KRST}"
			fi
			;;
		-d | --deploy)
			echo "deploy the public folder" 
			;;
		-* | --*)
			usage
			error_exit "Unknown option $1" 
			;;
		*)
			echo "Argument $1 to process..." 
			;;
	esac
	shift
done

# Main logic

graceful_exit

