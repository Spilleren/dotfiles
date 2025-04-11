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
  # Determine the file type based on the parameter
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

  # Locate and select the source file
  source_file=$(find . -type f -path "*/bin/*FilesTest*" -name "$source_pattern" | fzf --prompt="Select the source file: ")

  # Check if a source file was selected
  if [[ -z $source_file ]]; then
      echo "No source file selected."
      exit 1
  fi

  # Additional logic for appsettings to determine 'syst' or 'prod'
  if [[ $file_type == "a" || $file_type == "d" ]]; then
    case $source_file in
      *syst*) target_type="syst" ;;
      *prod*) target_type="prod" ;;
      *) echo "Selected file does not match expected naming conventions ('syst' or 'prod')."; exit 1 ;;
    esac
    target_pattern = "${source_pattern/\*/$taget_type}"

    case $source_file in
      *RestApi*) target_path="RestApi" ;;
      *DbUp*) target_path="DbUp" ;;
      *) echo "Selected file does not match expected file path ('RestApi' or 'DbUp')."; exit 1 ;;
    esac
 
  fi

  # Locate and select the target file
  target_file=$(find . -type d -name "bin" -prune -o -type f -path "*$target_path*" -name "$target_pattern" -print | fzf --prompt="$target_prompt")

  # Check if a target file was selected
  if [[ -z $target_file ]]; then
      echo "No target file selected."
      exit 1
  fi

  # Copy the source file to the target directory
  cp "$source_file" "$target_file"
  echo "Copied $source_file to $target_file"
}
