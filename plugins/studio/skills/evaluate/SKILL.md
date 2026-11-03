---
name: evaluate
description: Evaluate an app idea, feature idea, or business opportunity before building it. Sends the researcher to find competitors, pricing, and complaints in competitor reviews, then the skeptic to red-team the idea, and saves a scorecard with a verdict (pursue, reshape, or drop) and the cheapest real-world test to docs/research/. Use whenever the user wants to know whether an idea is worth building, asks about competitors or demand, or has just finished /studio:new-project.
argument-hint: "[the idea to evaluate]"
---

# Evaluate an idea

The idea to evaluate: $ARGUMENTS

You coordinate. The researcher gathers facts, the skeptic attacks the idea, and you combine both into a scorecard. Don't do the research or the critique yourself.

## 1. Pin down the idea

- Read `docs/product/vision.md` and `docs/product/mvp.md` if they exist.
- Look in `docs/research/` for an earlier evaluation of the same idea. If there is one, ask whether to update it or start fresh.
- If the idea is missing or vague, ask **one** question to learn what it is, who it's for, and the problem it solves.
- Choose a short kebab-case slug for the file name, such as `split-bill`.

## 2. Research: delegate to `studio:researcher`

Give the researcher the idea in 2–3 sentences, who it's for, and these questions:
1. Who already solves this problem? Include direct competitors and substitutes, such as spreadsheets, a group chat, or doing nothing.
2. What do they charge? Plans and prices, with the date checked.
3. What do their users complain about in reviews? Look for complaints that repeat.
4. Any signals about demand or market size that can be sourced.

## 3. Red-team: delegate to `studio:skeptic`

Run this after the research finishes, because the skeptic builds on it. Give the skeptic the idea and paste the researcher's **full report** into the prompt, since it can't see the report otherwise. Ask for its usual output: ranked risks, and the cheapest real-world test.

## 4. Write the scorecard

Save it to `docs/research/<slug>-evaluation.md` in this format:

```markdown
# Evaluation: <idea>

_<YYYY-MM-DD>. Research by studio:researcher, critique by studio:skeptic._

## The idea
<2–3 sentences: what it is, who it's for, the problem it solves.>

## Scorecard
Scores run from 1 (bad for us) to 5 (good for us).

| Area | Score | Evidence |
|---|---|---|
| Problem severity | <1–5> | <one line, with a source> |
| Who pays, and how much | <1–5> | <who, how much, and whether anyone already pays for this> |
| Competition | <1–5> | <5 means an open field, 1 means crowded with strong incumbents> |
| Our unfair advantage | <1–5> | <what we have that a competitor can't copy in a month, or "none yet"> |

## Biggest risks
1. **<risk>.** <why>. Would change our mind: <evidence>.

## Verdict: <Pursue | Reshape | Drop>
<2–3 sentences. For Reshape, say exactly what to change.>

## Cheapest real-world test
- **What:** <the test>
- **Who:** <who to test with, and where to find them>
- **Pass if:** <a number decided in advance>
- **Cost:** <money and time>

## Sources
- <title>: <URL> (checked <date>)

## What we couldn't confirm
- <claim>: <what would settle it>
```

Rules:
- Every score needs evidence from the research or the critique. Write "unknown" rather than guess, and score unknowns low.
- Don't average the scores into one number. The verdict is a judgement, explained in words.
- Take the risks and the test from the skeptic. Keep its severity order and don't soften them.
- **Always end with the cheapest real-world test.** Agents can't validate demand; only real people can.

## 5. Report back

In chat, give the verdict, the top risk, and the test in a few lines, plus the file path. Then offer the next step:
- **Pursue:** spec the first feature with `/studio:spec`.
- **Reshape:** update `docs/product/mvp.md` to match, then spec.
- **Drop:** say what evidence would bring the idea back.
