function generate_random_tarea_tasks
    set -l max_tasks 10

    if count $argv > /dev/null
        set max_tasks $argv[1]
    end

    for i in (seq 1 $max_tasks)
        set task (lipsum-cli -w 6)
        set desc (lipsum-cli -w 12)
        set hrs (random 1 72)
        set due (date -d "+$hrs hours" "+%Y-%m-%d %H:%M")
        tarea $task -d $desc --due "$due"
    end
end
