---
name: diagram
description: Draw a Mermaid diagram with merman-cli that explains a change, bug, flow or decision, and render it to an SVG that shows text in any viewer. Use when the user types /diagram, or asks for a diagram or picture of how something works or why a change is needed.
---

# Diagram

Explain one thing with one diagram, rendered with `merman-cli`. The input is
whatever follows `/diagram`: a topic, a bug, a change, a file or a question. If
there is no input, diagram the most recent thing being discussed.

## Steps

1. Read the real code or change first. Do not draw from memory or guess the flow.
2. Pick the one idea the reader must leave with, such as why a change is
   needed, what breaks, or how a request flows. One idea per diagram.
3. Write the source to a `.mmd` file in the scratchpad directory, not the repo.
4. Render it with the skill script, which follows the system light/dark
   preference and bakes in a background rect:

   ```
   ~/.agents/skills/diagram/render.sh diagram.mmd diagram.svg
   ```

5. Check the text survived:

   ```
   grep -o "<text" diagram.svg | wc -l
   grep -c foreignObject diagram.svg
   ```

   The first must be above zero and the second must be 0.

6. Open it with `xdg-open` and give the full absolute path of the SVG and of the
   `.mmd` source.

## Rules

- Always render through `render.sh`. The SVG is transparent by default, and
  the CSS background that `-b` writes is ignored by some viewers (imv), so the
  script adds a real background rect and picks the dark or light theme from
  the system setting.
- The script always passes `--svg-pipeline resvg-safe`. The default pipeline puts labels in
  `foreignObject` HTML, which many viewers draw as empty boxes.
- Do not render to PNG: it fails on a font size limit in this install. SVG only.
- Use `flowchart` for flows and decisions, `sequenceDiagram` for who calls whom
  over time, `stateDiagram-v2` for states.
- For a bug or change, use a BEFORE and an AFTER subgraph with the same input,
  so the difference is the only thing that moves.
- Use real names from the code for nodes. Keep labels short and break lines
  with `<br/>`.
- Color only the outcome, and set `color:#000` in the style so the text stays
  readable on the dark theme: red fill `#f8d7da` with stroke `#c0392b` for the bad
  result, green fill `#d4edda` with stroke `#27ae60` for the good one.
- Use a realistic example. Do not use a state the system cannot reach, and say
  so when the case is an edge case.
- Do not put diagram files in the repo unless asked.

## Reply

Say in two or three short sentences what the diagram shows, then the paths. Do
not retell the whole diagram in prose.
