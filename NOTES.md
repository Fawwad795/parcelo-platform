# NOTES

Your working log for the Parcelo assignment. Nobody grades this file, and it is still the most useful thing you will produce: it holds your evidence, your cost log, your review history and the record of what actually confused you.

Write in it every session. Short and honest beats long and tidy.

## 1. Baseline (fill in on Day 1 and in task 1.2)

**Repository ids** (from `gh api 'repos/{owner}/{repo}' ...`, Day 1 step 7):

```text
owner:
owner_id:
repo:
repo_id:
```

**Day 1 checkpoint** (`make test` summary line and `curl -s localhost:8000/version`):

```text

```

**AWS preflight** (output of `scripts/aws-preflight.sh`, task 1.2):

```text

```

| Item | Value |
| --- | --- |
| Account plan (FREE or PAID) | |
| Credits at the start | |
| Free plan expiry date | |
| vCPU quota (L-1216C47A) | |
| Quota increase requested on / granted on | |
| Region for the whole project | |
| Budget emails confirmed | |

## 2. Progress

### Part A (Weeks 1 and 2)

| Week | Focus | Must be true by the end of the week | Status |
| --- | --- | --- | --- |
| 1 | CI and containers | Gates block bad changes; hardened image published by SHA and public; secrets and vulnerabilities scanned; actions pinned; AWS quota checked | [ ] |
| 2 | Kubernetes on the laptop | One-command install on kind; probes, limits, security context; bad release gets no traffic and rolls back; chart tested in CI | [ ] |

### Part B (Weeks 3 to 5)

| Week | Focus | Must be true by the end of the week | Status |
| --- | --- | --- | --- |
| 3 | Terraform on AWS | Server from code; no keys, no SSH; plan on pull request, approved apply; dead-man switch seen firing; destroy and rebuild works | [ ] |
| 4 | Deploy and observe | Approved deploy by SHA; bad deploy rolls back; dashboard as code; alert derived from an objective, seen firing | [ ] |
| 5 | Prove it | Timed rebuild with no manual step; all drills re-run; runbook, cost report, security review, demo; everything torn down | [ ] |

### Hours

| Week | Planned | Actual | SHOULD items dropped, and why |
| --- | --- | --- | --- |
| 1 | 22 | | |
| 2 | 22 | | |
| 3 | 22 | | |
| 4 | 22 | | |
| 5 | 22 | | |

Per task, write the real hours next to the estimate. Estimates that were badly wrong are worth a sentence each.

| Task | Estimate | Actual | Note |
| --- | --- | --- | --- |
| 1.1 | 2h | | |

## 3. Drill log

Full write-ups go in `docs/drills.md`. This table is the index.

| # | Drill | First passed (date) | Game day (date) | Evidence |
| --- | --- | --- | --- | --- |
| D1 | Red build blocks merge | | | |
| D2 | Leaked secret caught | | | |
| D3 | Vulnerable dependency stops publish | | | |
| D4 | Failed health check, no traffic, rollback | | | |
| D5 | Pod loss | | | |
| D6 | Unapproved change does nothing | | | |
| D7 | Dead-man switch fires | | | |
| D8 | Bad deploy rolls back | | | |
| D9 | Alert fires and resolves | | | |
| D10 | Rebuild from code, timed | | | |

## 4. Cost log (from Week 3)

End-of-session checklist. Copy the block and tick it **every** session that touched AWS.

```text
Date:
[ ] 1. Destroy the infra stack (terraform workflow > destroy > approve)
[ ] 2. The run finished GREEN
[ ] 3. scripts/end-of-session.sh reports nothing left
[ ] 4. Remaining credits written in the table below
[ ] 5. aws logout
[ ] 6. Laptop: kind delete cluster --name parcelo ; docker compose down
```

| Date | Hours instance was up | Credits before | Credits after | Anything left running? | Notes |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

## 5. Review log

One row per week. The process is in `assignment/self-review.md`.

| Week | Date | MUST items failing at first check | Findings from AI review (fixed / deferred / disagreed) | Weakest oral-exam topic | Hours: planned / actual |
| --- | --- | --- | --- | --- | --- |
| 1 | | | | | 22 / |
| 2 | | | | | 22 / |
| 3 | | | | | 22 / |
| 4 | | | | | 22 / |
| 5 | | | | | 22 / |

### Weekly self-check

Answer these five at the end of every week.

1. What did I finish, and what is still broken?
2. Which part of this week do I not fully understand yet?
3. What took the most time, and was that time well spent?
4. What did an AI get wrong this week, and how did I catch it?
5. What am I carrying into next week?

## 6. Stuck log

Use this when the 45-minute rule triggers. Fill in all four lines before you search or ask anything.

```text
Date / task:
Trying to do:
Expected:
Got (exact error text):
Already tried:
Resolved by:
```

## 7. Decisions

One line each, as you make them: "Chose X over Y because Z. Cost: W." These become the decisions section of your README in Week 5.

-

## 8. Session log

Newest first. Three lines per session is enough.

### YYYY-MM-DD

- Did:
- Learned or got confused by:
- Next:
