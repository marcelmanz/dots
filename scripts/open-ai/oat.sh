#!/usr/bin/env bash

red_color='\033[0;31m'
yellow_color='\033[0;33m'
no_color='\033[0m'

if [[ -z $OPENAI_API_KEY ]]; then
	if command -v rbw &>/dev/null; then
		OPENAI_API_KEY=$(rbw get --folder openai api-key)
	fi
fi

usage() {
	echo -e "${yellow_color}Usage:${no_color} oat [-t text]"
	echo "Send text input to OpenAI's GPT-3 language model and display the model's response"
	echo ""
	printf "oat -t 'Write a hello world in Rust'\n"
	echo ""
	echo "Optional arguments:"
	echo "  -t   The text to send to OpenAI's GPT-3 model"
	echo "  -m   Select specific model (not working)"
	echo "  -h   Display this help menu"
}

while getopts t:m:h flag; do
	case "${flag}" in
	t) text=${OPTARG} ;;
	m) specific_model=${OPTARG} ;;
	h)
		usage
		exit 0
		;;
	*)
		usage
		exit 1
		;;
	esac
done

if [ -z "$text" ]; then
	echo -e "${red_color}!${no_color} Please provide the text that will be send to Open AI"
	echo
	usage
	exit 1
fi

clean_text=$(echo "$text" | tr '\n' ' ' | sed 's/"/\\"/g')

turbo_model="gpt-3.5-turbo"
# text_davinci_003="text-davinci-003"

model=$(if [[ -z "$specific_model" ]]; then echo "$turbo_model"; else echo "$specific_model"; fi)

base_url="https://api.openai.com/v1"
endpoint="chat/completions"

# this does not work yet
# endpoint=$(if [[ "$model" == "$text_davinci_003" ]]; then echo "completions"; else echo "chat/completions"; fi)

if [ "$model" != "$turbo_model" ]; then
	echo -e "${red_color}Error:${no_color} Right now only the turbo model is supported"
	exit 1
fi

response=$(curl -s "$base_url/$endpoint" \
	-H "Authorization: Bearer $OPENAI_API_KEY" \
	-H "Content-Type: application/json" \
	-d "{\"model\":\"${model}\",\"messages\":[{\"role\":\"user\",\"content\":\"$clean_text\"}]}")

ERROR=$(echo "$response" | jq -c .error)

if [ "$ERROR" != "null" ]; then
	error_message="$(echo "$response" | jq -rc .error.message)"
	echo -e "${red_color}Error:${no_color} $error_message"
	exit 1
fi

content=$(echo "$response" | jq -r '.choices[0].message.content')

echo -e "${red_color}Request:${no_color}"
printf '\n'
# shellcheck disable=2059
printf "$text"
printf '\n'
printf '\n'
echo -e "${yellow_color}Response:${no_color}"

if glow -v >/dev/null 2>&1; then
	# shellcheck disable=2059
	printf "$content" | glow
else
	# shellcheck disable=2059
	printf "$content"
fi

echo "Do you want to copy the response?"

should_copy_response=$(printf 'Yes\nNo' | fzy)

if [ "$should_copy_response" = "Yes" ]; then
	if [[ $OSTYPE == "darwin"* ]]; then
		echo "$content" | pbcopy
	else
		echo "$content" | xsel -ib
	fi
	echo "Copied to clipboard"
fi
