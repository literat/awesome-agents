# Awesome Agents

## Workflows

### Define - Clarify what you build

* [grill-me][skill-grill-me]

### Review - Quality gates before merge

* [create-pr][skill-create-pr]
* [code-review][skill-code-review]
* [address-github-review][skill-address-github-review]

## Optimizations

* [Cavemen][skill-caveman] - Ultra-compressed communication mode. Spare tokens by dropping filler, articles, and pleasantries while keeping full technical accuracy.

## Key Concepts

### Agents (Personas)

> Pre-configured specialist personas for targeted tasks

[Claude Sub-agents Documentation][claude-subagents]

Commands are skills executed via slash commands. They overlap but are stored differently.

### Commands

> Quick executable prompts

### Skills

> Broader workflow definitions

### Hooks

> Hooks fire on tool events

[Claude Hooks Documentation][claude-hooks]

## References

* [Matt Pocock - Agent Skills][skills-matt-pocock]
* [AI Hero - 5 Agent Skills I Use Every Day][skills-aihero-everyday]
* [Claude Settings Documentation][claude-settings]
* [Claude GitHub Actions Documentation][claude-github-actions]

[claude-settings]: https://code.claude.com/docs/en/settings
[claude-subagents]: https://code.claude.com/docs/en/sub-agents
[claude-hooks]: https://code.claude.com/docs/en/hooks
[claude-github-actions]: https://code.claude.com/docs/en/github-actions
[skills-matt-pocock]: https://github.com/mattpocock/skills
[skills-aihero-everyday]: https://www.aihero.dev/5-agent-skills-i-use-every-day
[skill-grill-me]: commands/grill-me.md
[skill-create-pr]: commands/create-pr.md
[skill-code-review]: commands/code-review.md
[skill-address-github-review]: commands/address-github-review.md
[skill-caveman]: skills/caveman/SKILL.md
