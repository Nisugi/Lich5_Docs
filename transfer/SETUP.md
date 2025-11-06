# Transfer Guide for Elanthia Online Organization

This guide explains how to transfer and set up this documentation automation in the Elanthia Online organization.

## Pre-Transfer Checklist

- [ ] Test the system locally with mock provider
- [ ] Test with Gemini API key to verify quality
- [ ] Review generated documentation samples
- [ ] Ensure all dependencies are documented
- [ ] Remove any personal/sensitive data

## Transfer Methods

### Option 1: Repository Transfer (Recommended)

1. **From current owner:**
   - Go to Settings → General
   - Scroll to "Danger Zone"
   - Click "Transfer ownership"
   - Enter `elanthia-online` as new owner
   - Confirm transfer

2. **Organization admin accepts transfer**

### Option 2: Fork and Archive

1. Fork to Elanthia Online org
2. Archive original repository
3. Update remote URLs

### Option 3: Fresh Setup

1. Create new repo in Elanthia Online
2. Push code to new repository:
   ```bash
   git remote add elanthia https://github.com/elanthia-online/lich5-docs.git
   git push elanthia main
   ```

## Post-Transfer Setup

### 1. Configure Repository Settings

**Settings → General:**
- [ ] Set repository description
- [ ] Add topics: `lich5`, `documentation`, `automation`
- [ ] Enable Issues
- [ ] Enable Projects (optional)

**Settings → Pages (if using GitHub Pages):**
- [ ] Source: Deploy from branch
- [ ] Branch: `gh-pages` or `main` → `/docs`

### 2. Add Secrets

**Settings → Secrets → Actions:**

Required:
```
GEMINI_API_KEY = [Google Gemini API key]
```

Optional:
```
OPENAI_API_KEY = [OpenAI key if using as backup]
```

### 3. Update Configuration

Edit `.github/workflows/check-updates.yml`:
```yaml
env:
  LICH_REPO: elanthia-online/lich-5  # Verify this is correct
```

### 4. Permissions

**Settings → Actions → General:**
- [ ] Allow all actions and workflows
- [ ] Read and write permissions
- [ ] Allow GitHub Actions to create pull requests

### 5. Test Workflows

1. **Test Manual Documentation:**
   ```
   Actions → Manual Documentation Generation → Run workflow
   - Provider: mock
   - Source: elanthia-online/lich-5
   - Branch: main
   ```

2. **Test Update Checker:**
   ```
   Actions → Check for Lich Updates → Run workflow
   ```

## Team Setup

### Recommended Team Permissions

- **Admins**: Full access to settings and secrets
- **Maintainers**: Write access, can run workflows
- **Contributors**: Read access, can submit PRs

### API Key Management

**Option 1: Organization-owned key**
1. Create Google account for organization
2. Generate Gemini API key
3. Store in organization password manager

**Option 2: Designated maintainer's key**
1. Trusted maintainer provides key
2. Add as repository secret
3. Document who owns the key

## Initial Documentation Run

After setup, generate initial documentation:

1. Go to Actions → Manual Documentation Generation
2. Run with these settings:
   - Provider: `gemini`
   - Source: `elanthia-online/lich-5`
   - Branch: `main`
   - Full rebuild: `true`

3. Review the generated PR
4. Merge if documentation looks good

## Maintenance

### Regular Tasks

**Weekly (Automated):**
- Check for new Lich releases
- Creates issue if update needed

**Per Release (Manual):**
- Review release notes
- Run documentation workflow
- Review and merge PR
- Update `.last_documented_version`

### Monitoring

Check these regularly:
- Actions tab for workflow runs
- Issues for update notifications
- API usage (if approaching limits)

## Troubleshooting

### Workflow Fails

1. Check Actions logs
2. Verify secrets are set correctly
3. Check API quotas
4. Try with mock provider

### API Quota Issues

- Gemini free tier: 1500 requests/day
- If exceeded, wait 24 hours
- Or switch to OpenAI temporarily

### Documentation Quality Issues

1. Test with different provider
2. Adjust prompts in `generate_docs.py`
3. Consider manual touch-ups for complex code

## Cost Management

**Current costs: $0/month** (using Gemini free tier)

To maintain free usage:
- Stay under 1500 requests/day
- Run full rebuilds sparingly
- Use incremental updates when possible

If costs become necessary:
- OpenAI: ~$0.50-2 per full run
- Consider organization funding
- Document expenses

## Support Contacts

**Documentation System:**
- Issues: Create issue in this repository
- Original author: [Your GitHub username]

**Lich5 Project:**
- Repository: https://github.com/elanthia-online/lich-5
- Maintainers: See Lich5 repository

## Appendix: Files to Review

Before going live, review these files:

1. `.env.example` - Ensure defaults are appropriate
2. `.github/workflows/*.yml` - Verify repository references
3. `requirements.txt` - Check dependencies
4. `README.md` - Update with organization details

---

## Quick Command Reference

```bash
# Test system
python test_provider.py --provider mock

# Generate docs locally
python generate_docs.py ../lich-5/src/lib --provider gemini

# Check provider configuration
python -c "from src.providers import ProviderFactory; print(ProviderFactory.get_provider_info())"
```

## Final Notes

- This system is designed to be low-maintenance
- No automatic documentation generation (requires manual trigger)
- All costs are optional (free tier is sufficient)
- System can run entirely on GitHub Actions

Good luck with the documentation automation!