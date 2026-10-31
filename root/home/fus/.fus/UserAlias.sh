alias ll="ls -lath"
alias la="ls -at"

alias s="sudo xbps-install -S"
alias i="sudo xbps-install -Sy"
alias u="sudo xbps-install -Suy"
alias r="sudo xbps-remove -y"
alias q="sudo xbps-query -Rs"

alias l='ls -CF'

alias downloads='cd ~/Downloads'
alias desktop='cd ~/Desktop'
alias tmp='cd /tmp'

alias gclone='git clone'
alias gpush='git push'
alias gpull='git pull'
alias gaddall='git add -Av'
alias gcommit='git commit'
alias gcommitmsg='git commit -m '
alias gcheckout='git checkout'
alias gpushu='git push -u'
alias gresethard='git reset --hard'
alias gresetsoft='git reset --soft'
alias greset='git reset'

alias desktop="cd ~/Desktop"

alias zshrc="nvim ~/.zshrc"

alias tmuxNew="tmux new -S"
alias tmuxList="tmux ls"
alias tmuxAttachLast="tmux a"
alias tmuxAttach="tmux a -t"
alias tmuxKill="tmux kill-session -t"


# default editor ###############################################
if command -v nvim >/dev/null 2>&1; then
    alias nano="nvim"
    alias vim="nvim"
elif command -v vim >/dev/null 2>&1; then
    alias nano="vim"
fi


# esp-idf ######################################################
if [ -e /home/fus/.fus/esp/export.sh ]; then 
    alias esp-idf='. /home/fus/.fus/esp/export.sh'
    alias esp-idf-build='idf.py build'
fi
