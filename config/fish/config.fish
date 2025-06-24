function aptupdate --wraps='sudo apt update && sudo apt upgrade' --description 'alias aptupdate=sudo apt update && sudo apt upgrade'
  sudo apt update && sudo apt upgrade $argv
end

function aptinstall --wraps='sudo apt install --no-install-recommends' --description 'alias aptinstall=sudo apt install --no-install-recommends'
  sudo apt install --no-install-recommends $argv
end
