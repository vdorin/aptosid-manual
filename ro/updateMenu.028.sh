#!/bin/bash
# (C) 2007 Florian Schneider <ffw_schneider@web.de>
# (C) 2008-2011 Trevor Walkley <trevor_walkley@aptenodytes.org>
# 2008 updated the cut for new head by altering to read second line of head -- Trevor Walkley <trevor_walkley@aptenodytes.org>
#2011-03-01 added to help examples of paths when outside of an actual dir , thank you Stefan Fuchs aka fixl -- Trevor Walkley <trevor_walkley@aptenodytes.org>)

version="0.28"
newMenuFile=
newMenu=
newHeadFile=
newHead=
backup=0
directory=""
globalDir=`pwd`
date=`date +%Y%m%d`"_"`date +%H%M%S`
verbose=1

init(){
	echo
	echo "updateMenu version " $version " by Florian Schneider <ffw_schneider@web.de> aka hathe"
	echo
	echo " I will do the following tasks:"
	numHtmFiles=`ls $directory | grep -c .htm`
	if [[ $newHead != "" ]]
	then
		echo "- replace <head> section with content of" $directory$newHeadFile " for $numHtmFiles files"
	fi
	if [[ $newMenu != "" ]]
	then
		echo "- replace <div id=menu> section with content of" $directory$newMenuFile " for $numHtmFiles files"
	fi
	echo "in" $directory
	if [[ $backup != 0 ]]
	then
		echo " I will create backup files of all *.htm? files in that directory"
	else
		echo "!!! I won't do a backup !!!"
	fi
	echo "verbose level is " $verbose
	echo
	echo "Press ENTER key to continue or CTRL+C to exit this script"
	read response
}

vEcho(){
	#echo "\$1 = " $1
	#echo "\$2 = " $2
	if [[ $2 < $verbose || $2 = $verbose ]]
	then
		echo $1
	fi
}

showHelp (){
	echo "updateMenu version " $version
	echo "usage:"
	#echo "./updateMenu -f <file> [-b | -d] | -r | -h"
	echo "./ updateMenu [-mf <file>]  [-hf <file>] [-d <directory>] [-b | -r] [-h]"
	echo
	echo "This script removes the <div id=\"menu\"> ... <\\div> block from"
	echo "every *.htm? file in given directory (-d) and replace that block with "
	echo "the content of a file (-mf)"
	echo "AND/OR"
	echo "This script removes the second to the last but one line of the <head> section"
	echo "assuming the first one is the head tag, second the title tag, third the "
	echo "meta tag and the last line the closing head tag which will be untouched."
	echo "So the head input file (-hf) must not contain the head and/or title tags!"
	echo
	echo "-mf,  --menufile	input file with new menu structure "
	echo "-hf,  --headfile	inputfile with new head structure"
	echo "-d,   --directory	working directory. As an example if outside the working dir ./updateMenu.027.sh -mf aptosid-manual-02.10.2011-REPO/en/menu-en -d aptosid-manual-02.10.2011-REPO/en/ ,or, ./updateMenu.027.sh -d aptosid-manual-02.10.2011-REPO/en/ -mf aptosid-manual-02.10.2011-REPO/en/menu-en"
	echo "-b,   --backup		creates a backup of every *.htm? file before edit"
	echo "-r,   --remove		removes all backup files in current directory"
	echo "			this option can only be used with -d as option BEFORE -r"
	echo "-v,   --verbose		0: nothing, 1: a bit (standard), 2: more, eg line numbers"
	echo "-h,   --help 		display this help"
	exit 0
}

removeBackupFiles (){
	echo "I will remove" `ls $directory*.htm*.* | wc -l` "files in" $directory
	echo "press ENTER to continue or CTRL-C to exit"
	read
	echo "Remove backup files:"
	for file in `ls -1 $directory`; do
		if [[ $file = *.htm.* || $file = *.html.* ]]
		then
			echo "Delete " $file
			`rm -f ${directory}$file`
			echo "...done"
		fi
	done
	exit 0
}


#newMenu=$(<$1)


createBackup(){
	for file in $files; do
		if [[ $file = *.htm || $file = *.html ]]
		then
			`cp ${directory}$file ${directory}${file}".$date"`
		fi
	done
}


replaceHead (){
vEcho "" 1
vEcho "----------changing <head> sectionw----------" 1
vEcho "" 1
#files1=`ls -1 $directory`
for file in $files; do
	#Just handle *.htm? files
	if [[ $file = *.htm || $file = *.html ]]
	then
		vEcho "Working on file:  $directory$file:" 1
		startLine=0
		endLine=0
		maxLine=$(wc -l < "${directory}${file}")
		((maxLine++))

		n=1
		OIFS=$IFS; IFS=
		while read line
		do
			if [[ $line = *\<head\>* ]]
			then
				let startLine=$n+2
				((n++))
			elif [[ $line = *\<\/head\>* ]]
			then
				let endLine=$n-1
				break
			else
			((n++))
			fi

		done < ${directory}${file}
		IFS=$OIFS

		vEcho "Startline: $startLine" 2
		vEcho "Endline: $endLine" 2
		vEcho "MaxLine: $maxLine" 2

		part1=`sed -e "${startLine},${maxLine}d" ${directory}$file`
		part2=`sed -e "1,${endLine}d" ${directory}$file`


		echo "${part1}" > ${directory}$file
		echo "${newHead}" >> ${directory}$file
		echo "${part2}" >> ${directory}$file
		vEcho "...done" 1
	fi
done
}


replaceMenu (){
vEcho "" 1
vEcho "----------changing <div id=menu> section----------" 1
vEcho "" 1
#echo $files
for file in $files; do

	#Just handle *.htm? files
	if [[ $file = *.htm || $file = *.html ]]
	then
		vEcho "Working on file:  ${directory}${file}:" 1


		startLine=0
		endLine=0
		maxLine=$(wc -l < "${directory}${file}")
		((maxLine++))

		n=1
		divCounter=0
		OIFS=$IFS; IFS=
		while read line
		do
			if [[ $line = *\<div\ id\=* ]]
			then
				if [[ $line = *\<div\ id\=\"menu\"\>* ]]
				then
					((divCounter++))
					startLine=$n
				else
					if [[ $line != *\<\/div\>* ]]
					then
						((divCounter++))
					fi
				fi
				((n++))
			elif [[ $line = *\<\/div\>* ]]
			then
				((divCounter--))
				if [[ $divCounter = 0 ]]
				then
					endLine=$n
					break
				#else
					#((n++))
				fi
				((n++))
			else
			((n++))
			fi

		done < ${directory}${file}
		IFS=$OIFS

		vEcho "Startline: $startLine" 2
		vEcho "Endline: $endLine" 2
		vEcho "maxLine: $maxLine" 2

		part1=`sed -e "${startLine},${maxLine}d" ${directory}$file`
		part2=`sed -e "1,${endLine}d" ${directory}$file`

		echo "${part1}" > ${directory}$file
		echo "${newMenu}" >> ${directory}$file
		echo "${part2}" >> ${directory}$file
		vEcho "...done" 1
	fi
done

}


while [ $# -gt 0 ]; do
        case "$1" in
		"-h"|"--help")
			showHelp;;

		"-mf"|"--menufile")
			newMenu=$(<$2)
			newMenuFile=$2;;

		"-b"|"--backup")
			backup=1;;

		"-r"|"--remove")
			if [[ $# -gt 2 ]]
			then
				showHelp
			else
		        	removeBackupFiles
			fi;;

		"-d"|"--directory")
			sep=""
			if [[ $2 != /* ]]
			then
				directory=$globalDir
				sep="/"
			fi
			if [[ $2 = */ ]]
			then
				directory=${directory}${sep}$2
			else
				directory=${directory}${sep}$2"/"
			fi;;

		"-hf"|"--headfile")
			newHead=$(<$2)
			newHeadFile=$2;;

		"-v"|"--verbose")
			verbose=$2;;
	esac
	shift
done

if [[ $newHead = ""&& $newMenu = "" ]]
then
	showHelp
fi

files=`ls -1 $directory`

if [[ $verbose > 0 ]]
then
	init
fi



if [[ $backup = 1 ]]
then
	createBackup
fi

if [[ $newMenu != "" ]]
then
	replaceMenu
fi

if [[ $newHead != "" ]]
then
	replaceHead
fi





