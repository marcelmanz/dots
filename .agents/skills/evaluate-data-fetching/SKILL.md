---
name: evaluate-data-fetching
description: |-
  Evaluates frontend data fetching patterns to ensure sub-second page loads for LAN-only edge devices.
  Use proactively when a user asks to review an API file, a React component using React Query, or optimize page load speed.
  Examples:
  - user: "Review the data fetching in ModemConfigPage.tsx" -> apply waterfall and React Query checks.
  - user: "Why is the setup wizard step taking 2 seconds?" -> analyze network requests and caching.
---

# Skill: Evaluate Data Fetching for Edge Performance

This skill analyzes React components and API utilities to ensure data fetching meets the strict `< 1 second` rendering requirement for LAN-only edge devices.

## 1. Eliminate Network Waterfalls

A waterfall occurs when requests are made sequentially instead of in parallel. On low-power edge web servers, this drastically increases Time To Interactive (TTI).

**Checklist:**

- [ ] **API Layer:** Are there sequential `await` calls that don't depend on each other? Use `Promise.all()`.
- [ ] **Component Layer:** Are there stacked components where a child fetches data only _after_ the parent finishes fetching?
- [ ] **Hooks Layer:** Use `@tanstack/react-query`'s `useQueries` for parallel independent queries instead of multiple `useQuery` calls.

| Anti-Pattern (Sequential)                              | Optimized (Parallel)                                  |
| :----------------------------------------------------- | :---------------------------------------------------- |
| `const a = await getA();`<br>`const b = await getB();` | `const [a, b] = await Promise.all([getA(), getB()]);` |
| Multiple `useQuery` hooks                              | `useQueries({ queries: [...] })`                      |

## 2. React Query Cache & StaleTime Optimization

By default, React Query has a `staleTime` of `0`. This means it will instantly refetch data when a component mounts or the window regains focus, which can overload a small edge device.

**Checklist:**

- [ ] **Static Configuration Data:** (e.g., supported Wi-Fi bands, language packs). Set a high `staleTime` (e.g., `Infinity` or `5 * 60 * 1000`).
- [ ] **Dynamic Status Data:** (e.g., current signal strength). Keep `staleTime` low, but consider using a WebSocket or polling interval instead of relying purely on mount/focus refetches.
- [ ] Ensure `queryKey` arrays are structured consistently to avoid duplicate cache entries.

## 3. Proactive Prefetching (Setup Wizard Strategy)

In a linear setup wizard, we know exactly what page the user will visit next.

**Checklist:**

- [ ] Are we prefetching the _next_ step's data while the user is filling out the _current_ step?
- [ ] Implement `queryClient.prefetchQuery` inside event handlers (e.g., `onMouseEnter` of the "Next" button) or immediately after the current step's critical data loads.

```typescript
// Example: Prefetching the next step's data
const queryClient = useQueryClient();

const prefetchNextStep = () => {
  queryClient.prefetchQuery({
    queryKey: ["wifi-networks"],
    queryFn: fetchWifiNetworks,
  });
};
```
