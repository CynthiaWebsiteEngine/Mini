# TODO

This TODO was created for branch `issue-fixer-1`. These are the issues and tasks I'll work on in this PR.

---

## Issues and Tasks

### ~~1. Comment Out Birdie-Dependent Tests~~ ✅

~~**Related GitHub issue:**~~

~~- [#44](https://github.com/CynthiaWebsiteEngine/Mini/issues/44): Tests all fail~~

~~**Description:**~~

~~- Almost all tests are failing due to issues with Birdie, which is temporarily broken on both ends.~~

~~**Task:**~~

~~- Identify and comment out all tests that rely on Birdie.~~

~~**Priority:** Very High~~

---

### 2. Fix Latency When Switching Pages with Comments

**Related GitHub issue:**
To be created

**Description:**

- There is significant latency when switching from a post page with comments to another page. This issue likely stems from the timing of the removal of the comment box.

**Task:**

- Investigate the client-side code responsible for comment box removal.
- Optimize the timing to reduce latency.

**Priority:** High

---

### 3. Resolve Navigational Mishap with Active CynthiaSession

**Related GitHub issue:**
To be created

**Description:**

- When a link is opened while the CynthiaSession is still active, a navigational mishap occurs. This is likely due to an overly long session lease.

**Task:**

- Investigate the session lease duration in the client.
- Adjust the lease duration to prevent mishaps.

**Priority:** Medium

---

### 4. Centralize Common Functions

**Related GitHub issue:**

- [#30](https://github.com/CynthiaWebsiteEngine/Mini/issues/30): Lessen the amount of FFI

**Description:**

- Some common functions used by both the client and server reside on both sides. These should be centralized in the shared module within the client or at least on the client side.

**Task:**

- Create a list of common functions currently duplicated across the client and server.
- Plan the migration of these functions to the shared module.

**Priority:** Low
