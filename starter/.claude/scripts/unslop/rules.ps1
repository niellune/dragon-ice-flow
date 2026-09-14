# rules.ps1 - the rule data for the unslop scanner (playbook R8). ASCII only (powershell.exe reads
# BOM-less scripts as ANSI). This file is the ONE home of every pattern, threshold and allowlist;
# skills/unslop/SKILL.md points here and copies nothing. Each entry carries a one-line why.
# Ported from MP's scripts/unslop/lib/rules.mjs (2026-09-13 calibration there: two true hits on a
# whole corpus). Re-calibrated on this project's corpus 2026-09-14 (see wiki/log.md, ref-022).
#
# Deliberately NOT rules, because they are this template's house style: em dashes, bold-led bullets,
# dense sentences, "not just X", triplet lists, check marks in tables.

# ------------------------------------------------------------------ phrase family
# Whole-word, case-insensitive, matched on a line with its protected spans masked out (code, quotes,
# URLs, link targets, paths, ids, hashes). Filler and assistant register only: a word that also has an
# engineering meaning in this repo belongs in $DomainAllowlist instead.
$Phrases = @(
    # filler openers and closers
    @{ id = 'worth-noting';       re = "\bit(?:'s| is) worth noting\b";                                    why = 'announces content instead of giving it' }
    @{ id = 'important-to-note';  re = "\bit(?:'s| is) important to (?:note|remember|understand)\b";       why = 'announces content instead of giving it' }
    @{ id = 'needless-to-say';    re = '\bneedless to say\b';                                              why = 'then do not say it' }
    @{ id = 'in-todays';          re = "\bin today's (?:world|landscape|era|age|environment|market|climate)\b"; why = 'stock opener; a literal today is fine' }
    @{ id = 'end-of-the-day';     re = '\bat the end of the day\b';                                        why = 'stock closer' }
    @{ id = 'in-conclusion';      re = '\bin conclusion\b';                                                why = 'recap loop' }
    @{ id = 'to-summarize';       re = '\bto summari[sz]e\b';                                              why = 'recap loop' }
    @{ id = 'in-summary';         re = '\bin summary\b';                                                   why = 'recap loop' }
    @{ id = 'simply-put';         re = '\bsimply put\b';                                                   why = 'restatement marker; keep one version' }
    @{ id = 'in-other-words';     re = '\bin other words\b';                                               why = 'restatement marker; keep one version' }
    @{ id = 'heres-the-thing';    re = "\bhere(?:'s| is) the thing\b";                                     why = 'empty framing' }
    @{ id = 'bottom-line';        re = '\bthe bottom line\b';                                              why = 'empty framing' }
    @{ id = 'deep-dive';          re = "\b(?:deep dive|dive into|let's dive|diving into)\b";               why = 'empty framing' }
    # assistant register
    @{ id = 'hope-this-helps';    re = '\bhope this helps\b';                                              why = 'chat register in a record' }
    @{ id = 'great-question';     re = '\bgreat question\b';                                               why = 'chat register in a record' }
    @{ id = 'rest-assured';       re = '\brest assured\b';                                                 why = 'chat register in a record' }
    @{ id = 'feel-free';          re = '\bfeel free to\b';                                                 why = 'chat register in a record' }
    @{ id = 'as-an-ai';           re = '\bas an ai\b';                                                     why = 'chat register in a record' }
    # inflated diction
    @{ id = 'delve';              re = '\bdelv(?:e|es|ed|ing)\b';                                          why = 'inflated verb; use look at, read, check' }
    @{ id = 'leverage';           re = '\b(?:leverag(?:es|ed|ing)|leverage (?:the|our|its|this|these|existing|your))\b'; why = "inflated verb; use use. The noun ('the lever') is not flagged" }
    @{ id = 'utilize';            re = '\butili[sz](?:e|es|ed|ing)\b';                                     why = 'inflated verb; use use' }
    @{ id = 'tapestry';           re = '\btapestry\b';                                                     why = 'inflated noun' }
    @{ id = 'testament-to';       re = '\b(?:a )?testament to\b';                                          why = 'stock praise' }
    @{ id = 'game-changer';       re = '\bgame[- ]chang(?:er|ing)\b';                                      why = 'stock praise' }
    @{ id = 'paradigm-shift';     re = '\bparadigm shift\b';                                               why = 'stock praise' }
    @{ id = 'holistic';           re = '\bholistic(?:ally)?\b';                                            why = 'vague scope word' }
    @{ id = 'meticulous';         re = '\bmeticulous(?:ly)?\b';                                            why = 'stock praise' }
    @{ id = 'multifaceted';       re = '\bmultifaceted\b';                                                 why = 'vague scope word' }
    @{ id = 'cutting-edge';       re = '\bcutting[- ]edge\b';                                              why = 'marketing word' }
    @{ id = 'state-of-the-art';   re = '\bstate[- ]of[- ]the[- ]art\b';                                    why = 'marketing word' }
    @{ id = 'best-in-class';      re = '\bbest[- ]in[- ]class\b';                                          why = 'marketing word' }
    @{ id = 'ever-evolving';      re = '\bever[- ]evolving\b';                                             why = 'stock modifier' }
    @{ id = 'fast-paced';         re = '\bfast[- ]paced\b';                                                why = 'stock modifier' }
    @{ id = 'in-the-realm-of';    re = '\bin the realm of\b';                                              why = 'inflated preposition' }
)

# Words generic slop lists flag that this template uses on purpose. Each has a silence test in
# tests/unslop.tests.ps1 so a future phrase cannot catch them by accident. Counted 2026-09-14 across
# .context/ planning/ reference/ wiki/.
$DomainAllowlist = @(
    @{ word = 'harness';   why = 'the Claude Code harness' }
    @{ word = 'ensure';    why = 'drift-guard tests ensure; a precise verb in rules text' }
    @{ word = 'robust';    why = 'an engineering claim when it names what it is robust to' }
    @{ word = 'seamless';  why = 'a property of a merge or a boundary' }
    @{ word = 'navigate';  why = 'moving through a codebase or a wiki' }
    @{ word = 'not just';  why = 'precision contrast, house style' }
    @{ word = 'crucially'; why = 'precise emphasis when every hit is checked' }
)

# ---------------------------------------------------------------- structure family
$Structure = @{
    # identity voice: no exclamation marks, counted outside code and quotes. A `!` followed by a word
    # char, bracket, `=` or `-` is negation or a macro, not an exclamation.
    exclamation = @{ why = 'no exclamation marks in records; quoted strings are protected' }
    # A fragment question answered by its own next sentence ("The result? A cleaner build.") is a setup.
    # Terse "Too thin? see 13.6" shorthand is not: the answer must be a capitalised sentence.
    rhetoricalQuestion = @{ maxQuestionWords = 4; minAnswerWords = 3; maxAnswerChars = 40; why = 'fragment-question-then-answer is a setup; state the answer' }
    # Eight or more real sentences of nearly the same length read as generated; lists of short labels
    # (mean under 8 words) are not sentences.
    uniformRhythm = @{ minSentences = 8; minMeanWords = 8; maxStdDevWords = 3; why = 'uniform sentence length reads as generated' }
}

# ------------------------------------------------------------------- record family
# Path-conditioned rules for records whose shape .context/task-workflow.md Closeout Rule and the dossier
# template fix. Board and STATE budgets stay with budget-check.ps1; they are not duplicated here.
$Record = @{
    donePlans = @{
        pathRe = '(?:^|/)planning/done-plans/[^/]+\.md$'
        summaryHeadingRe = '^#{2,4}\s+(?:Summary|What landed)'
        maxSummaryBullets = 5
        maxParagraphWords = 60
        why = 'dossier shape: Summary is at most five bullets; no narrative paragraphs'
    }
    log = @{
        pathRe = '(?:^|/)wiki/log\.md$'
        ops = @('ingest', 'query', 'lint', 'decision', 'feat', 'fix', 'refactor', 'docs', 'housekeep')
        marker = '<!-- new entries go below this line -->'
        why = 'wiki/log.md heads below the marker are `## [YYYY-MM-DD] <op> | <title>`'
    }
}

# Directories the recursive walk never enters: immutable sources, the verbatim log archive, the nested
# template repo (it has its own copy), and build or VCS trees.
$SkipDirectories = @('raw', 'wiki/log', 'template', '.git', 'node_modules', 'target')

# Record paths the hook scans (relative, forward slashes). The board, STATE and the backlog are not
# records here: the first two have their own hook, the backlog is a working list.
$RecordRe = '^(?:planning/done-plans/[^/]+|wiki/[^/]+|reference/.+|\.context/.+)\.md$'
$RecordRoots = @('planning/done-plans', 'wiki', 'reference', '.context')

function Get-AllRuleIds {
    $out = @()
    foreach ($p in $Phrases) { $out += [pscustomobject]@{ family = 'phrase'; id = $p.id; why = $p.why } }
    $out += [pscustomobject]@{ family = 'structure'; id = 'exclamation';         why = $Structure.exclamation.why }
    $out += [pscustomobject]@{ family = 'structure'; id = 'rhetorical-question'; why = $Structure.rhetoricalQuestion.why }
    $out += [pscustomobject]@{ family = 'structure'; id = 'uniform-rhythm';      why = $Structure.uniformRhythm.why }
    $out += [pscustomobject]@{ family = 'record';    id = 'summary-bullets';     why = $Record.donePlans.why }
    $out += [pscustomobject]@{ family = 'record';    id = 'narrative-paragraph'; why = $Record.donePlans.why }
    $out += [pscustomobject]@{ family = 'record';    id = 'log-entry-head';      why = $Record.log.why }
    return $out
}
