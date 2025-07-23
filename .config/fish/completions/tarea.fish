complete -c tarea -l completions -d 'Print completion script for <SHELL> to stdout' -r -f -a "bash\t''
zsh\t''
fish\t''
powershell\t''
elvish\t''"
complete -c tarea -s d -l desc -d 'Show task descriptions in list, or add description if text provided' -r
complete -c tarea -l due -d 'Set due date (today, tomorrow, 2h, 60m or YYYY-MM-DD [HH:MM[:SS]])' -r
complete -c tarea -s s -l status -d 'Filter tasks by status' -r -f -a "pending\t''
done\t''
standby\t''"
complete -c tarea -l show -d 'Show specific task by ID' -r
complete -c tarea -l done -d 'Mark task as done' -r
complete -c tarea -l pending -d 'Mark task as pending' -r
complete -c tarea -l standby -d 'Mark task as standby' -r
complete -c tarea -s a -l all -d 'Show all tasks regardless of status'
complete -c tarea -l delete-database -d 'Delete the task database'
complete -c tarea -s h -l help -d 'Print help'
