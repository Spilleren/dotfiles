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

pr2() {
local approve=false

  while getopts "ch" opt; do
    case $opt in
      a)
        approve=true
        ;;
      h)
        echo "Usage: pr2 [-c] [-h]"
        echo "  -c    Approve the PR automatically"
        echo "  -h    Show this help message"
        return 0
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        echo "Usage: pr2 [-c] [-h]"
        return 1
        ;;
    esac
  done

  if [[ -z "$AZURE_DEVOPS_PAT" ]]; then
    echo "Azure DevOps PAT not found. Set AZURE_DEVOPS_PAT environment variable."
    return 1
  fi

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi

  local repo_url=$(git config --get remote.origin.url)

  local project_name=$(echo $repo_url | sed -n 's#.*/Main/\([^/]*\)/_git/.*#\1#p')
  local repo_name=$(echo $repo_url | sed -n 's#.*/_git/\([^/]*\)$#\1#p')
  local source_branch=$(git rev-parse --abbrev-ref HEAD)

  if [[ -z "$project_name" || -z "$repo_name" ]]; then
    echo "Could not extract project or repository name from: $repo_url"
    return 1
  fi

  if [[ "$source_branch" == "master" ]]; then
    echo "Cannot create PR from master to master"
    return 1
  fi

  local commit_message=$(git log -1 --pretty=format:"%s")
  local pr_data=$(cat <<EOF
{
  "sourceRefName": "refs/heads/$source_branch",
  "targetRefName": "refs/heads/master",
  "title": "$commit_message",
  "description": "$commit_message\n\n---\n*Created via command line*"
}
EOF
)

  echo "Creating pull request: $source_branch → master"

  local api_url="https://azuredevops.danskenet.net/Main/$project_name/_apis/git/repositories/$repo_name/pullrequests?api-version=7.0"
  local auth_header="Authorization: Basic $(echo -n ":$AZURE_DEVOPS_PAT" | base64)"

  local response=$(curl -s -w "\n%{http_code}" -X POST "$api_url" \
    -H "Content-Type: application/json" \
    -H "$auth_header" \
    -d "$pr_data")

  local http_code=$(echo "$response" | tail -n1)
  local json_response=$(echo "$response" | sed '$d')

  if [[ "$http_code" != "201" ]]; then
    echo "Failed to create pull request (HTTP $http_code)"
    echo "$json_response"
    return 1
  fi

  local pr_id=$(echo "$json_response" | grep -o '"pullRequestId":[0-9]*' | cut -d':' -f2)
  local web_url="https://azuredevops.danskenet.net/Main/$project_name/_git/$repo_name/pullrequest/$pr_id"


  local user_response=$(curl -s \
    -H "$auth_header" \
    "https://azuredevops.danskenet.net/Main/_apis/connectionData?api-version=7.0-preview")

  local current_user_id=$(echo "$user_response" | grep -o '"authenticatedUser":{"id":"[^"]*"' | cut -d'"' -f6)

  if [[ -z "$current_user_id" ]]; then
    echo "Could not get user ID, skipping auto complete"
  else

  local commit_count=$(git rev-list --count origin/master..$source_branch --not master)
  local merge_strategy
  if [[ commit_count -gt 1 ]]; then
    merge_strategy="squash"
  else
    merge_strategy="noFastForward"
  fi

  local update_pr_data=$(cat <<EOF
{
  "autoCompleteSetBy": {
    "id": "$current_user_id"
  },
  "completionOptions": {
    "mergeStrategy": "$merge_strategy",
    "deleteSourceBranch": true,
    "bypassPolicy": false,
    "mergeCommitMessage": "Merged PR $pr_id: $commit_message"
  }
}
EOF
)
    local update_api_url="https://azuredevops.danskenet.net/Main/$project_name/_apis/git/repositories/$repo_name/pullrequests/$pr_id?api-version=7.0"

    local update_response=$(curl -s -w "\n%{http_code}" -X PATCH "$update_api_url" \
      -H "Content-Type: application/json" \
      -H "$auth_header" \
      -d "$update_pr_data")

    local update_http_code=$(echo "$update_response" | tail -n1)

    if [[ "$update_http_code" == "200" ]]; then
      echo "Auto-complete enabled with $merge_strategy strategy"
    else
      echo " Failed to enable auto-complete (HTTP $update_http_code)"
      echo "$(echo "$update_response" | sed '$d')"
    fi
  fi

  echo "Pull request #$pr_id created successfully!"

  echo "$web_url" | clip.exe
  echo "Link copied to clipboard"

  start chrome "$web_url"
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

htmlEncode(){
  python -c "import sys; print(''.join(f'&#{ord(c)};' for c in sys.argv[1]))" "$1"
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

backwards(){
  git checkout .
  git clean -fd
  git checkout $(git log --pretty=%H --parents -n 2 | tail -n 1)
}

forwards(){
  git checkout .
  git clean -fd
  git checkout $(git log --reverse --pretty=%H --ancestry-path HEAD..copilot-demo | head -n 1)
}
