#!/bin/zsh

# PART 1 - FUNCTIONS #######################################################

export DATE_PATH=/usr/bin/date
print_msg(){
    echo -e "[$( ${DATE_PATH} +'%y/%m/%d %H:%M:%S.%3N' )] $*"
}

yes_or_no(){
	while true; 
	do
		printf "Y/N? "
		read yn
		case $yn in
            [Yy]* )   return 0;;
			[Nn]* )   return 1;;
        	esac
    	done
}

# PART 2 - TEXT EFFECTS #####################################################
export BOLD="\033[1m"
export FAINT="\033[2m"
export ITALIC="\033[3m"
export UNDERLINED="\033[4m"
export BLACK="\033[30m"
export RED="\033[31m"
export GREEN="\033[32m"
export YELLOW="\033[33m"
export BLUE="\033[34m"
export MAGENTA="\033[35m"
export CYAN="\033[36m"
export LGRAY="\033[37m"
export GRAY="\033[90m"
export LRED="\033[91m"
export LGREEN="\033[92m"
export LYELLOW="\033[93m"
export LBLUE="\033[94m"
export LMAGENTA="\033[95m"
export LCYAN="\033[96m"
export WHITE="\033[97m"
export BG_BLACK="\033[40m"
export BG_RED="\033[41m"
export BG_GREEN="\033[42m"
export BG_YELLOW="\033[43m"
export BG_BLUE="\033[44m"
export BG_MAGENTA="\033[45m"
export BG_CYAN="\033[46m"
export BG_LGRAY="\033[47m"
export BG_GRAY="\033[100m"
export BG_LRED="\033[101m"
export BG_LGREEN="\033[102m"
export BG_LYELLOW="\033[103m"
export BG_LBLUE="\033[104m"
export BG_LMAGENTA="\033[105m"
export BG_LCYAN="\033[106m"
export BG_WHITE="\033[107m"
export NORM="\033[0m"