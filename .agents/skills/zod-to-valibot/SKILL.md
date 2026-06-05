---
name: zod-to-valibot
description: |-
  Automates and guides the migration of frontend validation schemas from Zod to Valibot. 
  Use proactively when a user mentions bundle size optimization, tree-shaking, or migrating from Zod.
  Examples:
  - user: "How do I migrate this Zod schema to Valibot?" -> provide conversion steps
  - user: "Reduce bundle size by replacing Zod" -> suggest Valibot migration
---

# Skill: Migrate Frontend App from Zod to Valibot

This skill provides a structured approach to migrating schemas, validation logic, and form resolvers from Zod to Valibot.

## Phase 1: Preparation

- **Install:** `npm install valibot`
- **RHF Users:** `npm install @hookform/resolvers`

## Phase 2: Automated Migration

Run the official codemod to handle 80% of the renaming:
`npx @valibot/zod-to-valibot ./src`

## Phase 3: Manual Logic Refactor

Valibot uses a modular `pipe` instead of Zod's chained methods.

| Feature          | Zod (Chained)        | Valibot (Functional)            |
| :--------------- | :------------------- | :------------------------------ |
| **Basic Schema** | `z.string().email()` | `v.pipe(v.string(), v.email())` |
| **Parsing**      | `schema.parse(data)` | `v.parse(schema, data)`         |
| **Inference**    | `z.infer<T>`         | `v.InferOutput<T>`              |

### Common Pattern Changes

- **Object Strictness:** Use `v.strictObject()` instead of `z.object().strict()`.
- **Coercion:** Replace `z.coerce.number()` with `v.pipe(v.unknown(), v.transform(Number), v.number())`.
- **Defaults:** Replace `.default('x')` with `v.optional(v.string(), 'x')`.

## Phase 4: Integration

Update `react-hook-form` resolvers:

```typescript
import { valibotResolver } from "@hookform/resolvers/valibot";
const { register } = useForm({ resolver: valibotResolver(MySchema) });
```
