#!/usr/bin/env zsh

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

  if [[ -z $(find . -type f -path "*/bin/*FilesTest*" -name "$source_pattern") ]]; then
    echo "Running FilesTests"
    dotnet test --filter FullyQualifiedName~ThenEqualToCommittedContent -v q > /dev/null 2>&1
  fi

  source_file=$(find . -type f -path "*/bin/*FilesTest*" -name "$source_pattern" | fzf --prompt="Select the source file: ")

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

  target_file=$(find . -type d -name "bin" -prune -o -type f -path "*$target_path*" -name "$target_pattern" -print | fzf --prompt="$target_prompt")

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

publishZcli (){
SEARCH_DIR="."

CSPROJ_FILE=$(find $SOURCE -name "*Zcli.csproj" | head -n 1)

if [ -z "$CSPROJ_FILE" ]; then
  echo "No .csproj file found."
  exit 1
fi

if ! rg -q "<IsPublishable>true</IsPublishable>" "$CSPROJ_FILE"; then
  sed -i '/<PropertyGroup>/a\
  <IsPublishable>true</IsPublishable>' "$CSPROJ_FILE"
fi

if ! rg -q "<AssemblyName>zcli</AssemblyName>" "$CSPROJ_FILE"; then
  sed -i '/<PropertyGroup>/a\
  <AssemblyName>zcli</AssemblyName>' "$CSPROJ_FILE"
fi

dotnet publish $CSPROJ_FILE -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o ~/.config/zcli

sed -i '/<IsPublishable>true<\/IsPublishable>/d' "$CSPROJ_FILE"
sed -i '/<AssemblyName>zcli<\/AssemblyName>/d' "$CSPROJ_FILE"

echo "Project published successfully to $(which zcli)"
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

# Function to generate SQL queries
cdiSqlQueries() {
  local userid="$1"

  # Ensure userid is exactly 6 characters long
  if [[ ${#userid} -ne 6 ]]; then
    echo "Error: userid must be exactly 6 characters long."
    return 1
  fi

  echo "### Accounts"
  echo "
SELECT [Iban], [Bban], Account.[Name], Account.[CustomName], [BalanceValue], [BalanceCurrency], [AvailableBalanceValue], [AvailableBalanceCurrency]
FROM [QJ.Server.Backend].[dbo].[Account]
INNER JOIN BankConnection ON Account.BankConnectionId = BankConnection.Id
INNER JOIN [User] ON BankConnection.UserId = [User].Id
WHERE [User].UserBoId = '${userid}' AND BankConnection.Deleted = 0 AND Account.Gone = 0
"

  echo "### Account Groups"
  echo "
SELECT [Name]
FROM [QJ.Server.Backend].[dbo].[AccountGroup]
INNER JOIN [User] ON AccountGroup.UserBoId = [User].UserBoId
WHERE [User].UserBoId = '${userid}'
"

  echo "### Bank Connections"
  echo "
SELECT [BankConnection], [Name], [CustomName]
FROM [QJ.Server.Backend].[dbo].[BankConnection]
INNER JOIN [User] ON BankConnection.UserId = [User].Id
WHERE [User].UserBoId = '${userid}' AND BankConnection.Deleted = 0
"

  echo "### Transactions"
  echo "
SELECT [Date], [Text], [OriginalText], [Amount_Value], [Amount_Currency], [Balance_Value], [Balance_Currency]
FROM [QJ.Server.Backend].[dbo].[Transaction]
INNER JOIN Account ON [Transaction].AccountId = Account.Id
INNER JOIN BankConnection ON Account.BankConnectionId = BankConnection.Id
INNER JOIN [User] ON BankConnection.UserId = [User].Id
WHERE [User].UserBoId = '${userid}' AND BankConnection.Deleted = 0 AND Account.Gone = 0 AND [Transaction].Deleted = 0
"

  echo "### Users"
  echo "
SELECT [UserBoId], [AgreementId], [Email]
FROM [QJ.Server.Backend].[dbo].[User]
WHERE [User].UserBoId = '${userid}'
"
}

accountGetMany(){
  if [ -z "$1" ]; then
    echo "Usage: $0 <token>"
    exit 1
  fi

  token="$1"

  response=$(curl --location --request GET 'https://syst-userapi4.danskebank.com/syst/syst-external-unauthenticated/x5p0.restapi/v1/accounts?name=true' \
  --header 'Accept-Language: da' \
  --header 'X-IBM-Client-Id: f4f53e87c0c23c2b8f5ad1493dd9b59c' \
  --header "X-System-Auth: $token" \
  --header 'Accept: application/json' \
  --header 'X-DB-Correlation-Id: E2FB678F-A3B9-4342-A7FB-3FAF0ECC47F4' \
  --header 'Cookie: NSC_JO5wjeo5ezuajf3didtnpidyi1sutbQ=7ce2a3d9ac461c5f6850bd7b16606b1c98d3eb4d2516160a7312840b92a58a20a17b90f8; NSC_JOhh3xdxcfns1g1dbfvu01ckepgwzd0=7ce2a3d9c1d4de09fe1ba6e62397fa10b441b0a7ce6af8364b95f403582e13bebf255a83; NSC_JOumuvprcioysshdslca35d5q02mze0=7ce2a3d986e41ed0ce99350cbf806b8c56463f65e16f7a57be22c2358ce73352a3a8f865; a30618e0b560962902e2293718178277=c66ddd548231af986d73935f38b23546')  

  echo $response | python -m json.tool
}

accountGetManyLocal(){
  if [ -z "$1" ]; then
    echo "Usage: $0 <token>"
    exit 1
  fi

  token="$1"

  response=$(./curl.exe -I --insecure --location --request GET 'https://127.0.0.1:5043/v1/accounts' \
  --header 'Accept-Language: da' \
  --header 'X-IBM-Client-Id: f4f53e87c0c23c2b8f5ad1493dd9b59c' \
  --header "X-System-Auth: $token" \
  --header 'Accept: application/json' \
  --header 'X-DB-Correlation-Id: E2FB678F-A3B9-4342-A7FB-3FAF0ECC47F4' \
  --header 'Cookie: NSC_JO5wjeo5ezuajf3didtnpidyi1sutbQ=7ce2a3d9ac461c5f6850bd7b16606b1c98d3eb4d2516160a7312840b92a58a20a17b90f8; NSC_JOhh3xdxcfns1g1dbfvu01ckepgwzd0=7ce2a3d9c1d4de09fe1ba6e62397fa10b441b0a7ce6af8364b95f403582e13bebf255a83; NSC_JOumuvprcioysshdslca35d5q02mze0=7ce2a3d986e41ed0ce99350cbf806b8c56463f65e16f7a57be22c2358ce73352a3a8f865; a30618e0b560962902e2293718178277=c66ddd548231af986d73935f38b23546')  

  echo $response | python -m json.tool
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
