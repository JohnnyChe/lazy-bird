## Task Description

[Brief overview of what needs to be done]

## Detailed Steps

1. [Specific step with file names and code]
2. [Another step]
3. [Final step]

<!--
Example:
1. Create res://player/health.gd
2. Add Health class that extends Node
3. Add @export var max_health: int = 100
4. Add var current_health: int = max_health
5. Implement func take_damage(amount: int) -> void
6. Implement func heal(amount: int) -> void (max at max_health)
7. Add signal health_changed(old_value: int, new_value: int)
8. Emit health_changed in take_damage and heal methods
-->

## Acceptance Criteria

- [ ] [Criterion 1]
- [ ] Tests pass
- [ ] [Criterion 3]

<!--
Example:
- [ ] Health class exists with all required methods
- [ ] Tests pass (test_player_health.gd)
- [ ] Signal emits correctly with old and new values
- [ ] Health cannot go below 0 or above max_health
-->

## Complexity

<!-- Choose one: simple | medium | complex -->
**Complexity:** medium

<!--
- **simple**: UI changes, dialogue, config tweaks (2GB RAM, fast)
- **medium**: Gameplay features, AI, refactoring (3GB RAM, moderate)
- **complex**: Physics systems, rendering, optimization (5GB RAM, slow)
-->

## Estimated Time

<!-- Optional: How long do you expect this to take? -->
**Estimated:** 30-60 minutes

## Context / References

<!-- Links to docs, related issues, or additional context -->

- Related to issue #XX
- See: [Godot docs](https://docs.godotengine.org/)
- Reference implementation: `path/to/similar/code.gd`

## Additional Notes

<!-- Anything else Claude should know? -->

---

## ✅ Ready to Process?

**To trigger automation:**

1. Review the task description above - ensure steps are clear and specific
2. Add label: `ready`
3. Monitor progress with: `./wizard.sh --status`
4. Review PR when created (typically 1-2 hours)

**Tips for Better Results:**

✅ **Do:**
- Be specific (exact file names, function signatures)
- Provide examples of expected behavior
- Include test requirements in acceptance criteria
- Reference existing code patterns in your project

❌ **Don't:**
- Use vague instructions ("make it better", "optimize code")
- Assume Claude knows your project structure
- Skip important context or constraints
- Forget to specify testing requirements

---

**Labels to add:** `ready` (to start), then system adds `processing` → `automated` when done

/label ~ready
