# Safeguarding Knowledge Updates

When updating `qdoora-references/agent/rules/*.md` files, the primary goal is **NO DATA LOSS**. 

## Steps for Safe Modification
1. **Always read first**: Use `view_file` on the target file (e.g., `qdoora-references/agent/rules/Backend.md`) to read its content. Never assume you know what's in there.
2. **Locate the exact section**: Find the precise line numbers where the new rule should be added (e.g., under `## Security`).
3. **Use targeted replace**: Use `replace_file_content` or `multi_replace_file_content` providing the `StartLine` and `EndLine` to insert the new rule exactly where it belongs without altering the rest of the document.
4. **NEVER overwrite entire files**: Truncation happens when trying to rewrite the entire markdown file from memory. Always do partial replacements.
5. **Format**: Rules should be appended at the end of the matching section, formatted consistently with the surrounding text.
