## New Lich Release Detected

A new version of Lich has been released and documentation needs to be updated.

**Version:** ${{ steps.check-release.outputs.latest_version }}
**Previous:** ${{ steps.check-release.outputs.last_version }}

### Recent Changes

The following commits were made since the last documented version:

```
{{ commits.txt }}
```

### Action Required

Please run the [manual documentation workflow](../../actions/workflows/manual-docs.yml) to generate updated documentation.

**Recommended settings:**
- Provider: `gemini` (free tier)
- Source repo: `elanthia-online/lich-5`
- Source branch: `main`
- Full rebuild: `true` (for new releases)

### Checklist

- [ ] Review changes in the new release
- [ ] Run documentation generation workflow
- [ ] Review generated documentation PR
- [ ] Merge documentation PR
- [ ] Update `.last_documented_version` file
- [ ] Close this issue

---
*This issue was automatically created by the update checker workflow*