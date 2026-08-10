# English Word Count Contract

All prose length checks use the same tokenization rule:

```text
[A-Za-z0-9]+(?:['’][A-Za-z0-9]+|-[A-Za-z0-9]+)*
```

This counts contractions (`didn't`) and hyphenated compounds
(`state-of-the-art`) as one word. Punctuation, Markdown markers, whitespace,
em dashes, and quote marks do not count. It is a practical English prose
count, not a character count and not a byte count.

The JavaScript Hook and the Codex Python mirror are the executable authority.
Short-form checks must use the same regular expression rather than plain
`split()`. Re-count after every rewrite and report the machine result.
