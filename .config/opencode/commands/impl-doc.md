---
description: "Generate an implementation design document"
agent: plan
---

Create a concise implementation design document for the following feature.

The document is intended to guide a single developer through implementation.

Guidelines:

- Focus on how to implement, not high-level product goals.
- Structure the implementation in an organic, incremental order: introduce components, routes, logic, types, and UI only when they become necessary.
- Avoid upfront “define everything first” sections.
- Prefer concrete steps over abstract descriptions.
- **Do not include code examples.** Describe what needs to be implemented and why.

When discussing technical details:

- Explain required validations, constraints, and behaviors in plain language.
- Mention possible tools or approaches conceptually (e.g. schema validation, refinement rules, async validation), without showing code.
- For schemas or validation steps, describe _what should be validated_ and _what mechanisms could be used_ (e.g. refinement-style validation), not how to write it.

Include:

- A short overview of the feature and its purpose.
- A step-by-step implementation plan, ordered as it would realistically be built.
- For each step:
  - What is implemented
  - Why it is implemented at this stage
  - Dependencies or assumptions
- UI sections describing:
  - Screens and flows
  - Form inputs and their validation rules (conceptual, no code)
  - Error states and edge cases
- Handling of completion states (success screens, redirects, warnings).
- Notes on UX decisions where alternatives exist, including brief rationale.

Tone & style:

- Clear, practical, and implementation-oriented
- Concise but complete enough to code from
- No unnecessary theory or repetition

Audience: a developer who will implement the feature.

$ARGUMENTS
