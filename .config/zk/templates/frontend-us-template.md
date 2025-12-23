## {{title}}

<sub>{{format-date now "medium"}}</sub>
#thread #us

**User Story:**
As a [User Role], I want to [Action] so that [Benefit/Goal].

### Implementation Details

[Brief description of the UI/UX work required. Mention specific screens or flows.]

[Feature paths (happy/unhappy)]

- ...

### Backend Contract (API)

Define the interface between Frontend and Backend.

- Endpoint: `[METHOD] /url/path`
- Payload (Request):
  ```json
  {
    "field": "type",
    "example": "value"
  }
  ```
- Response (Success):
  ```json
  {
    "data": "..."
  }
  ```
- Real time update requirement: [Yes/No]

#### Error Scenarios

| HTTP Code | Error Code (Internal) | Description | UI Behavior |
| --------- | --------------------- | ----------- | ----------- |
| **000**   | `ERROR_CODE`          | Error desc  | Show error  |

### Acceptance Criteria

- [ ] UI matches the provided design.
- [ ] Success flow works as expected.
- [ ] All Error messages are displayed to the user.
- [ ] Network timeout/offline states are handled gracefully.

### Minumum tests

[Following the ACs and the feature paths, specify what needs to be tested so the US is valid for the merge]

### Technical Notes

- Validation: Frontend validation should match backend constraints.
