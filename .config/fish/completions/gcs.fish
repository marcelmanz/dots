# Completion for gcs

function __fish_gcs_complete_path
    # List directories and files in the current Git repository
    git ls-files 2>/dev/null | sort | uniq
end

function __fish_gcs_complete_regex
    # Provide useful regex patterns
    echo "TODO(\.*)"
    echo "(?i)(password|api_key)\\s*=\\s*['\"][^'\"]+['\"]"
    echo "fn \\w+\\("
    echo "\\bversion\\s*=\\s*\"\\d+\\.\\d+\\.\\d+\""
end

# Add options with descriptions
complete -c gcs -s p -l path -d "Path to the repository (optional, defaults to current directory)"
complete -c gcs -s l -l conlines -d "Number of context lines to display (default: 1)"
complete -c gcs -l no-gitignore -d "Ignore .gitignore rules"
complete -c gcs -s d -l diff-tool -d "External diff tool to use (e.g., delta, colordiff)"
complete -c gcs -s d -l diff-tool -xa "delta colordiff diff meld" -d "Typical diff tools"
complete -c gcs -s m -l show-metadata -d "Show commits metadata (e.g., author, email, message)"
complete -c gcs -s f -l file-pattern -d "Restrict search to specific file patterns (e.g., *.rs)"
complete -c gcs -s i -l interactive -d "Enable interactive mode for reviewing matches"
complete -c gcs -s h -l help -d "Print help"
complete -c gcs -s V -l version -d "Print version"
complete -c gcs -a "(__fish_gcs_complete_regex)" -d "Regex pattern examples"
