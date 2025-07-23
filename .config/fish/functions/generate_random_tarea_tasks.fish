function generate_random_tarea_tasks
    for i in (seq 1 10)
        set task (lipsum-cli -w 6)
        set desc (lipsum-cli -w 12)

        # random hour offset: 1‑72 h
        set hrs (random 1 72)

        set due (date -d "+$hrs hours" "+%Y-%m-%d %H:%M")
        tarea $task -d $desc --due "$due"
    end
end
