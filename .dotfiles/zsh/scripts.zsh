#!/usr/bin/env zsh

# Test
matrix () {
    local lines=$(tput lines)
    cols=$(tput cols)

    awkscript='
    {
        letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"
        lines=$1
        random_col=$3
        c=$4
        letter=substr(letters,c,1)
        cols[random_col]=0;
        for (col in cols) {
            line=cols[col];
            cols[col]=cols[col]+1;
            printf "\033[%s;%sH\033[2;32m%s", line, col, letter;
            printf "\033[%s;%sH\033[1;37m%s\033[0;0H", cols[col], col, letter;
            if (cols[col] >= lines) {
                cols[col]=0;
            }
    }
}
'

echo -e "\e[1;40m"
clear

while :; do
    echo $lines $cols $(( $RANDOM % $cols)) $(( $RANDOM % 72 ))
    sleep 0.05
done | awk "$awkscript"
}

smartcp (){
  if [ $# -eq 0 ]
    then
      echo "No arguments supplied"
      exit 1
  fi

  local file_type="$1"
  local source_pattern target_pattern target_prompt target_type target_path

  case $file_type in
    s)
      source_pattern="Swagger.json"
      target_pattern="Swagger.json"
      target_prompt="Select the target Swagger file: "
      ;;
    a)
      source_pattern="appsettings*.json"
      target_prompt="Select the target appsettings file: "
      ;;
    d)
      source_pattern="deployment*.y*ml"
      target_prompt="Select the target deployment file: "
      ;;
    *)
      echo "Invalid parameter. Use 's' for Swagger or 'a' for appsettings."
      exit 1
      ;;
  esac

  if [[ -z $(rg --files --glob '*/bin/*FilesTest*' -g "$source_pattern") ]]; then
    echo "Running FilesTests"
    dotnet test --filter FullyQualifiedName~ThenEqualToCommittedContent -v q > /dev/null 2>&1
  fi

  source_file=$(rg --files --glob '*/bin/*FilesTest*' -g "$source_pattern" | fzf --prompt="Select the source file: ")

  if [[ -z $source_file ]]; then
      echo "No source file selected."
      exit 1
  fi

  if [[ $file_type == "a" || $file_type == "d" ]]; then
    case $source_file in
      *syst*) target_type="syst" ;;
      *prod*) target_type="prod" ;;
      *) echo "Selected file does not match expected naming conventions ('syst' or 'prod')."; exit 1 ;;
    esac
    target_pattern="${source_pattern/\*/.$target_type}"

    case $source_file in
      *RestApi*) target_path="RestApi" ;;
      *DbUp*) target_path="DbUp" ;;
      *ZCli*) target_path="ZCli" ;;
      *) echo "Selected file does not match expected file path ('RestApi' or 'DbUp')."; exit 1 ;;
    esac
  fi

  target_file=$(rg --files --glob "*$target_path*" -g "$target_pattern" --ignore-file <(echo "bin") | fzf --prompt="$target_prompt")

  if [[ -z $target_file ]]; then
      echo "No target file selected."
      exit 1
  fi

  cp "$source_file" "$target_file"
  echo "Copied $source_file to $target_file"
}

gbrowse (){
    gbrowsevar=$(git config --get remote.origin.url)
    start chrome $gbrowsevar
}
pr() {
  repo_url=$(git config --get remote.origin.url)

  project_name=$(echo $repo_url | sed -n 's#.*/Main/\([^/]*\)/_git/.*#\1#p')
  repo_name=$(echo $repo_url | sed -n 's#.*/_git/\([^/]*\)$#\1#p')

  source_ref=$(git rev-parse --abbrev-ref HEAD)
  target_ref="master" # You can change this to any default target branch

  pull_request_url="https://azuredevops.danskenet.net/Main/$project_name/_git/$repo_name/pullrequestcreate?sourceRef=$source_ref&targetRef=$target_ref"
  echo $pull_request_url

  start chrome $pull_request_url
}

base64ToUnicode() {
  local encoded_string="$1"

  local decoded_string=$(echo "$encoded_string" | base64 --decode)

  for (( i=0; i<${#decoded_string}; i++ )); do
    # Get the ASCII value of the character
    char="${decoded_string:$i:1}"
    printf  "$char: "
    printf '%04X ' "'$char"
  done
}

mkcd() {
    local dir="$*";
    local mkdir -p "$dir" && cd "$dir";
}

mkcp() {
    local dir="$2"
    local tmp="$2"; tmp="${tmp: -1}"
    [ "$tmp" != "/" ] && dir="$(dirname "$2")"
    [ -d "$dir" ] ||
        mkdir -p "$dir" &&
        cp -r "$@"
}

mkmv() {
    local dir="$2"
    local tmp="$2"; tmp="${tmp: -1}"
    [ "$tmp" != "/" ] && dir="$(dirname "$2")"
    [ -d "$dir" ] ||
        mkdir -p "$dir" &&
        mv "$@"
}

cleanNugetPackages(){
  set -e
  VERSION="5.0.0"

  setopt nullglob

  for dir in "$HOME/.nuget/packages"/dbcorp*(/); do
    target="$dir/$VERSION"
    if [[ -d "$target" ]]; then
      echo "Removing: $target"
      rm -rf -- "$target"
    fi
  done

  read -r -s -k1 "?Press any key to continue . . . "
}

dnupall(){
  run_dnup() {
    local folder=$1
    echo "Running dnup.cmd in $folder"
    (
      cd "$folder" || exit
      if [[ `git status --porcelain` ]]; then
        git stash -m "Stashed for package updates"
      fi
      git fetch origin
      if git rev-parse --verify besd/update_packages >/dev/null 2>&1; then
        echo "Branch 'besd/update_packages' exists. Resetting to origin/master."
        git switch besd/update_packages &&
        git reset --hard origin/master
      else
        echo "Branch 'besd/update_packages' does not exist. Creating it from origin/master."
        git switch -c besd/update_packages origin/master
      fi
      dnup.cmd
    )
  }

  create_pullrequest() {
    local folder=$1
    echo "Pushing project in $folder"
    (cd "$folder" || exit
      gc -a -m "Update packages" &&
      gp -u origin besd/update_packages &&
      pr)
  }

  folders=$(rg -g "*.sln" -g "*.slnx" --files --no-ignore-vcs $SOURCE | sed 's|\\|/|g' | xargs -I {} dirname {} | sort -u)

  if [[ -z "$folders" ]]; then
    echo "No folders with .sln or .slnx files found."
    exit 1
  fi

  selected_folders=$(echo "$folders" | fzf --multi --prompt="Select folders to run dnup.cmd: ")

  if [[ -z "$selected_folders" ]]; then
    echo "No folders selected."
    exit 1
  fi

  echo "$selected_folders" | while read -r folder; do
    run_dnup "$folder" &
  done

  wait

  echo "$selected_folders" | while read -r folder; do
    create_pullrequest "$folder" &
  done

  wait

  echo "Done!"
}

