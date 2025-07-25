# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=random

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
ZSH_THEME_RANDOM_CANDIDATES=(
    # "3den"
    # "adben"
    # "af-magic"
    # "afowler"
    # "agnoster"# "alanpeabody"
    # "amuse"
    # "apple"
    # "arrow"
    "aussiegeek"
    # "avit"
    # "awesomepanda"
    "bira"
    # "blinks"
    # "bureau"
    # "candy-kingdom"
    "candy"
    # "clean"
    # "cloud"
    "crcandy"
    # "crunch"
    "cypher"
    # "dallas"
    # "darkblood"
    # "daveverwer"
    # "dieter"
    # "dogenpunk"
    # "dpoggi"
    "dstufft"
    "dst"
    # "duellj"
    # "eastwood"
    # "edvardm"
    # "emotty"
    # "essembeh"
    # "evan"
    # "fino-time"
    # "fino"
    # "fishy"
    # "flazz"
    # "fletcherm"
    # "fox"
    # "frisk"
    # "frontcube"
    # "funky"
    # "fwalch"
    # "gallifrey"
    # "gallois"
    # "garyblessington"
    "gentoo"
    # "geoffgarside"
    "gianu"
    # "gnzh"
    # "gozilla"
    # "half-life"
    # "humza"
    # "imajes"
    # "intheloop"
    # "itchy"
    # "jaischeema"
    # "jbergantine"
    # "jispwoso"
    # "jnrowe"
    # "jonathan"
    # "josh"
    # "jreese"
    # "jtriley"
    "juanghurtado"
    "junkfood"
    # "kafeitu"
    # "kardan"
    # "kennethreitz"
    # "kiwi"
    # "kolo"
    # "kphoen"
    # "lambda"
    "linuxonly"
    # "lukerandall"
    # "macovsky-ruby"
    # "macovsky"
    # "maran"
    # "mgutz"
    # "mh"
    # "michelebologna"
    "mikeh"
    # "miloshadzic"
    # "minimal"
    # "mira"
    # "mlh"
    "mortalscumbag"
    # "mrtazz"
    # "murilasso"
    # "muse"
    # "nanotech"
    # "nebirhos"
    # "nicoulaj"
    # "norm"
    # "obraun"
    # "oldgallois"
    # "peepcode"
    # "philips"
    # "pmcgee"
    # "pygmalion-virtualenv"
    # "pygmalion"
    "random"
    # "re5et"
    # "refined"
    "rgm"
    # "risto"
    # "rixius"
    # "rkj-repos"
    # "rkj"
    # "robbyrussell"
    # "sammy"
    "simonoff"
    # "simple"
    # "skaro"
    # "smt"
    # "Soliah"
    # "sonicradish"
    # "sorin"
    # "sporty_256"
    # "steeef"
    # "strug"
    # "sunaku"
    # "sunrise"
    # "superjarin"
    # "suvash"
    # "takashiyoshida"
    # "terminalparty"
    # "theunraveler"
    # "tjkirch_mod"
    "tjkirch"
    # "tonotdo"
    # "trapd00r"``
    # "wedisagree"
    # "wezm+"
    # "wezm"
    # "wuffers"
    # "xiong-chiamiov-plus"
    # "xiong-chiamiov"
    "ys"
    # "zhann"
)

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(archlinux git vscode python tmux zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR='nano'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias now="date +%Y%m%d_%H%M%S"
alias lfs="cd ~/LFS"
alias aptupdate="sudo apt update && sudo apt upgrade --no-install-recommends"
alias aptinstall="sudo apt install --no-install-recommends"
alias aptremove="sudo apt remove --purge --auto-remove"
if [[ -f "/opt/bin/python3" ]]; then
    alias pipwheel="/opt/bin/python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all:"
    alias pipinstall="/opt/bin/python3 -m pip install --user -U --no-index --find-links ~/wheels"
    alias pipuninstall="/opt/bin/python3 -m pip uninstall -y"
else
    alias pipwheel="python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all:"
    alias pipinstall="python3 -m pip install --user -U --no-index --find-links ~/wheels"
    alias pipuninstall="python3 -m pip uninstall -y"
fi
alias tlmgrinstall="tlmgr --usermode install"

# Functions
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
