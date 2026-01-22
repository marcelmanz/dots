---
description: "Generate an implementation design document"
agent: plan
---

Create a concise implementation design document for the following feature.

The document is intended to guide a single developer through implementation.

Focus on how to implement, not high-level product goals.
Structure the implementation in an organic, incremental order: introduce components, routes, logic, types, and UI only when they become necessary. Avoid
upfront “define everything first” sections.
Prefer concrete steps over abstract descriptions.

Include:
- A short overview of the feature and its purpose.
- A step-by-step implementation plan, ordered as it would realistically be built.
- For each step: what is implemented and why, plus dependencies/assumptions.
- UI sections: screens & flows, form inputs + validation, error handling and edge cases.
- Handling of completion states (success screens, redirects, warnings).
- Notes on UX decisions with brief rationale.

Tone: clear, practical, implementation-oriented and concise enough to code from.
Audience: a developer who will implement the feature.

