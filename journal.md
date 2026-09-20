<!-- AI_INSTRUCTIONS
This is a public journal for the AI Lab project. It documents progress, lessons,
and decisions across all subprojects (AI Lab, CorsixTH, OpenSearch, sepia-be-gone).

VOICE: First person, casual, honest. Write like talking to a friend, not a report.
No corporate language, no filler.

PRIVACY: Never include keys, tokens, passwords, logins, usernames, IPs, or
emails. Services can be named (e.g., Infisical, Backblaze B2, OVHcloud).
Use generic descriptions for credentials (the backup token, the storage key).

TIME TRACKER: The summary table stays at the top, below the description. Update
session count and total time after each session. If a new project is added,
create a new row for it. Format: [Project Name] date: topic.

STRUCTURE: Newest entry first. Each entry has: Mood, Story (what happened),
What I learned (key takeaways), Next time (what's next). Use the tag [project name] for the journal entries.

NO_SENSE: Remove any sensitive info if found. This file is public on GitHub.
-->

# Journal

## Time Tracker Summary

| Project | Sessions | Total Time |
|---------|----------|------------|
| AI Lab | 19 | 22:56 |
| CorsixTH | 10 | 13:21 |
| OpenSearch | 7 | 10:39 |
| sepia-be-gone | 1 | 2:30 |
| Testcontainers | 1 | 0:40 |
| **Total** | **38** | **50:06** |

### [AI Lab] 2026-09-20: JEV System One evaluation on Month 2 dataset

**Mood:** curious, then impressed, then satisfied

**Story:** We had five dollars in free TypeSafe credits expiring October twenty, so I finally tried JEV -- their System One model that does structured decisions instead of text generation. You send state plus typed questions (Choice, Score, Noul) and get back structured answers with probabilities and confidence. No parsing needed.

I ran three tests on our Month 2 dataset (20 runs from BSLBSL/month2-agent-runs):

Test 1 -- Dataset labeling: three questions per run (correctness Score, failure_mode Choice, security Noul). JEV caught four bugs our heuristic missed -- a SyntaxError marked as success, two hardcoded answers that weren't real queries, and a wrong sin(pi) calculation. Heuristic claimed 95% but JEV showed ~70% true correctness with 40% needing review.

Test 2 -- Derived labels: PASS/FAIL/REVIEW based on score + confidence thresholds. Result: 11 PASS, 1 FAIL, 8 REVIEW. The review queue matched the heuristic blind spots exactly.

Test 3 -- Code quality gate simulation: five snippets (good code, off-by-one bug, eval injection, shell injection, hardcoded secret). JEV caught all three security issues with 100% confidence and routed to reject. Clean code auto-accepted. Off-by-one went to human review (low confidence).

Total cost: 0.0013 of 5 credit. Remaining: 4.9987.

**What I learned:** JEV replaces fragile prompt engineering with typed decisions you branch on in code. Confidence thresholds enable deterministic auto-accept/review/reject. Cost is negligible -- 5 covers ~100k evals. Main limits: English-centric, dynamic rate limits.

**Feelings / notes:** Felt like upgrading from regex to a type system. Security detection especially -- eval, shell injection, hardcoded secrets all caught with perfect confidence -- that's the gate you want in CI. Credits expire in a month so we should use them for Month 3 integration.

**Did:** installed typesafe-sdk on VPS, fetched API key from Infisical, ran Test 1 (20 runs x 3 questions), ran Test 2 (PASS/FAIL/REVIEW labels), ran Test 3 (5 snippet quality gate), created typesafe-jev opencode skill, added JEV use cases to backburn, wrote jev-evaluation.md in vault, updated learning roadmap skeleton

### [Testcontainers] 2026-09-18: Proving both Python fixes on live containers

**Mood:** confident going in, relieved when the Trino URL actually connected

**Story:** Tonight I stopped trusting mocks and proved both Python fixes against real containers. First I woke docker back up after the bare OS sweep, then ran the wait strategy integration suite on the file descriptor leak branch. Four tests passed on real hello world and alpine containers plus compose waits, so the close fix holds outside unit land.

Then the Trino one. I pulled the Trino 451 image, which cost about two and a half gigs of disk, and ran the existing community test. It passed in twenty two seconds. But that test sidesteps the buggy method, so I wrote a small script that connects through get_connection_url itself, the exact repro from the issue. The URL came back with a mapped port in the thirty two thousand range instead of eighty eighty, and select one returned one row. That felt like the real proof.

I also lost some time fighting the shell on quoting. The transport kept eating my double quotes, so I rebuilt the script with printf and verified it byte by byte before running it. Annoying detour, useful trick to remember.

I recorded both results in the vault and pushed. Four pull requests are now open across Java, Rust, and Python, all waiting on reviewers or CI. The box sits at seventy eight percent disk with docker running again.

**What I learned:** A mock test proves the contract and a live container proves the point, you want both before calling a fix done. And when the shell eats your quotes, check the bytes instead of guessing.

**Feelings / notes:** Relieved the Trino URL connected on the first try. A little uneasy about disk at seventy eight percent with that big image sitting there, might drop it once reviewers are happy.

**Did:** restarted docker and confirmed the daemon healthy, ran four integration tests green, pulled the Trino image and ran the community test green, proved the fixed URL end to end with a live query, updated both test result notes and pushed the vault
