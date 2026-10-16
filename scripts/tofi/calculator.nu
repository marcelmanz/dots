# Define environment variables and temporary directories
let XDG_CACHE_HOME = ($env.XDG_CACHE_HOME | default ($env.HOME + "/.cache"))
let tmp_dir = "$XDG_CACHE_HOME/tofi-calc"
let tmp_path = "$tmp_dir/history"
let is_history_value = false
let max_age_days = 10

# Create directory if it doesn't exist
mkdir -v $tmp_dir

# Create history file if it doesn't exist
if not ($tmp_path | path exists) {
    touch $tmp_path
}

# Input operation
let operation = open $tmp_path | ~/scripts/themed-bemenu -p " "

# Exit if no operation provided
if ($operation == "") {
    do {
        notify-send "No operation provided." "Please provide a valid operation."
        exit
    }
}

# Remove operation when using history values
if $operation or $operation contains "=" {
    let operation = $operation | str split "=" | get 1 | str trim
    let is_history_value = true
}

# Calculate the result
let result = (echo $operation | math eval)

# Exit if invalid operation
if ($result == "") {
    do {
        notify-send "Invalid operation." "Please provide a valid operation."
        exit
    }
}

# Save the operation and result to history if it's not a history value
if ($is_history_value == false) {
    if not (open $tmp_path | str contains ("$operation = $result")) {
        let temp_file = mktemp
        echo "$operation = $result" | save $temp_file
        open $tmp_path | append $temp_file
        mv $temp_file $tmp_path
    }
}

# Copy the result to the clipboard
echo $result | clip --trim-newline

notify-send "Result: $result" "The result has been copied to the clipboard."

