#!/usr/bin/env zsh

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
SELECT [Name], [CustomName]
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

ftRequest(){
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <csv_file>"
    exit 1
  fi

  input_file="$1"

  if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found!"
    exit 1
  fi

  filtered_file="filtered_$(input_file)"
  awk -F';' 'NR==1 || ($4 == "Authorisation" && $12 !~ /(2099|9999/))' "$input_file" > "$filtered_file"

  awk -F';' 'NR > 1 {print $5, $16}' "$filtered_file" | while read -r access_id business_need; do
    if [[ -n "$access_id" && -n "$business_need" ]]; then
      dbcli ft request-authorisation --access-id "$access_id" --days 365 --create-or-update --business-need "$business_need"
    else
      echo "Skipping row with missing access-id or business-need"
    fi
  done
}
