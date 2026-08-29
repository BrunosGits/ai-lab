---
date: 2026-08-27
tags: [study-log]
areas: [06-PR-TRACKING]
---

# GitHub Contribution Quality Improvement Study

## Introduction

This study examines external GitHub contribution guidelines to identify best practices for improving the quality and effectiveness of contributions to open source projects. The analysis focuses on two key resources:
1. Atlassian's GitFlow workflow tutorial
2. OpenRCT2's "How to Contribute" guide

By understanding and applying these principles, contributors can enhance their GitHub workflow, reduce friction in the contribution process, and increase the likelihood of their contributions being accepted.

## Key Insights from Atlassian GitFlow Tutorial

### GitFlow Branching Model
The GitFlow workflow defines a strict branching model designed around project releases:
- main branch: Contains production-ready code
- develop branch: Integration branch for features
- feature branches: Branch off develop for new features, merge back to develop
- release branches: Branch off develop for release prep, merge to main and develop
- hotfix branches: Branch off main for urgent fixes, merge to main and develop

### Workflow Principles
- Feature development occurs in isolated branches
- Develop branch always contains integrated features
- Main branch only contains production releases
- Release branches enable preparation while feature development continues
- Hotfix branches allow quick responses to production issues

## Key Insights from OpenRCT2 Contribution Guide

### Contributor Onboarding
- Requires original game assets (legal consideration)
- Mandatory GitHub account
- Fork & clone workflow for external contributors

### Development Process
1. Issue-driven workflow: Comment on issue before starting work to claim it
2. Branch creation: git checkout -b name_of_your_branch which will create and go to the branch.
3. Coding guidelines: When changing the code, make sure you follow our coding style and guidelines. If you follow the chances of your code being reviewed and merged by us faster increases considerably, as we won't have to spend time pointing out improvements.
4. Commit message conventions: When you're ready to commit your first changes, make sure you follow our commit messages guideline. Note that using the keywords Fix, Close, Part of followed by the issue number #XXXXX are specially important to link back to the task you picked up and make sure others see that there's work ongoing there, along with helping us maintain the project :)
5. Testing requirements: There are plenty of ways to test your changes, the most common one is actually running the game and seeing that nothing broke. Please make sure to test things before submitting it for review, so you can catch silly errors. Running the game is covered on the Building/Installing section above.

### PR Submission Process
- So it works, yay! Now you have to create a Pull Request (also known as PR) to let us review and at some point incorporate our changes to the code base. You can create it as a pull request if you don't feel like it is ready yet, but you want some input from the team members.
- There are some things that you need to understand when making a PR:
  - What is CI and what does it do?
  - Sync and rebase branch
  - Contributors file

- What is CI and what does it do?
  - CI stands for continuous integration and basically is a bunch of scripts and jobs that we run to make sure that the new changes being introduced are not breaking the game in anyway. If any of these checks fail, you know there is potentially something wrong with your changes, so do click on details for that check and investigate. Some of the jobs we run are:
    - Linter for the commit messages: Makes sure they follow our guidelines.
    - Clang Format: A tool that ensures that we have a consistent formatting on our code base.
    - Builds on multiple operational systems: To ensure it continues to work on all of our supported platforms.
  
- Sync and rebase branch
  - When you forked the repository, you created a copy of your own and it is now a snapshot of the past. There will be times you want to make sure it is up-to-date with the original one, be it:
    - To have the latest changes.
    - Because your PR now has "merge conflicts". This means that git doesn't know how to integrate your changes and someone else's and you have to solve it yourself. OpenRCT2 will kindly ask you to "please rebase" your PR.
  
- Contributors file
  - If it's the first time you're contributing with the project, make sure to update the contributors.md file by appending your name at the end of the respective list.

## Quality Improvement Takeaways

### Branch Discipline
- Always create feature branches from develop, never work directly on main branches
- Keep branches short-lived to reduce merge conflict risk
- Regularly sync feature branches with upstream develop

### PR Hygiene
- Descriptive commits: Clear messages with issue references (Fix/Close/#xxxx)
- Pre-PR testing: Verify changes work locally before opening PR
- Upstream sync: Rebase on latest develop to minimize conflicts
- CI compliance: Address all check failures before requesting review
- Draft PRs: Use for early feedback on work-in-progress contributions

### Process Adherence
- Issue engagement: Comment on issues before starting work
- Guideline following: Adhere to project-specific contribution documentation
- Communication: Respond promptly to review feedback
- Documentation: Update relevant docs when making changes

### Release Preparedness
- Understand how features flow from develop → release → main
- Consider release timing when submitting features
- Maintain develop branch stability for release branching

## Application to CorsixTH Context

### Current Alignment
- CorsixTH already uses issue tracking and PR system
- Deferred destruction fix (PR #3504) demonstrated good testing practices
- Study logs and architecture docs show commitment to documentation

### Potential Enhancements
1. Branching Strategy: 
   - Consider adopting explicit develop/main branch separation
   - Use feature branches for all work, even small fixes
   - Release branches for major version preparations

2. Contribution Guidelines:
   - Create explicit CONTRIBUTING.md file in corsixth-devlog/
   - Include commit message conventions (Fix/Close/#issue)
   - Detail testing expectations (smoketest, valgrind, etc.)
   - Outline PR review process and expected response times

3. PR Template Improvement:
   - Enhance existing PR templates with checklist items:
     - [ ] Tested on demo and full game data
     - [ ] Verified in graphical and headless modes
     - [ ] Smoketest passes with SMOKE_HEARTBEAT=1
     - [ ] Commit messages follow Fix/Close/#xxxx format
     - [ ] Synced with upstream develop branch

4. Issue Workflow Formalization:
   - Encourage commenting on issues before work begins
   - Use labels to indicate readiness (good first issue, help wanted)
   - Maintain issue descriptions with clear acceptance criteria

## Actionable Checklist for High-Quality Contributions

### Before Starting Work
- Check if issue exists; if not, create one with clear description
- Comment on issue indicating intent to work on it
- Fork repository (if external contributor) or ensure clean local state
- Create feature branch from develop: git checkout -b feature/issue-number-description

### During Development
- Follow coding standards and guidelines
- Make small, focused commits with descriptive messages
- Reference issues in commit messages: Fix #123: descriptive message
- Test changes regularly on intended platforms
- Keep branch up-to-date with upstream develop: git pull --rebase origin develop

### Before PR Submission
- Ensure changes are fully tested:
  - Demo data: 3/3 offscreen, 3/3 graphical
  - Full game (legal): 3/3 offscreen, 3/3 graphical
  - Smoketest passes with SMOKE_HEARTBEAT=1 for telemetry
- Update documentation if applicable (architecture docs, area summaries)
- Squash or fixup commits if necessary for clean history
- Sync with upstream: git fetch origin && git rebase origin/develop
- Push branch to remote: git push origin feature/your-branch-name

### During PR Process
- Open Pull Request against develop branch
- Fill PR template completely with relevant details
- Address all CI check failures promptly
- Respond to review feedback in timely manner
- Make requested changes as additional commits or force-push after rebasing
- Keep PR focused: avoid scope creep during review

### After PR Merge
- Delete feature branch locally and remotely
- Update any relevant study logs or documentation
- Consider if contribution warrants a study log entry

## References

1. https://www.atlassian.com/git/tutorials/comparing-workflows#gitflow-workflow
2. https://github.com/OpenRCT2/OpenRCT2/wiki/How-To-Contribute
3. CorsixTH PR #3504: Fix #1467: Deferred entity destruction to prevent iteration skip
4. CorsixTH PR #3494: Fix broken Lua docs links

## Related Pages

- [[2026-08-11-first-pr]]
- [[2026-08-12-entity-loop]]
- [[2026-08-16-movie-blocker]]
- [[2026-08-20-cleaner-pattern]]
- [[PR-3504-entity-destruction]]
- [[PR-3494-docs-links]]
- [[world-entity-flow]]
- [[save-load-migrations]]

## Opencode Resources
- Opencode GitHub Skill: Authentication and access instructions for GitHub operations (.opencode/skill/github.md)
