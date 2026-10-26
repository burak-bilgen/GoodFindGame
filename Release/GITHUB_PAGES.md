# GitHub Pages publication

Owner decision, 24 October 2026: use GitHub Pages; publish later. Contact: bilgenburak@outlook.com. No custom domain or paid hosting is required for a public documentation repository.

## Prepared package

The release artifact `Pazlume-GitHub-Pages.zip` contains only the six-language static support/privacy website, its icon and `.nojekyll`. It does not contain game source, saves, signing material or test logs. Regenerate it with:

```sh
python3 Scripts/build_support_pages.py
python3 Scripts/package_github_pages.py
```

## Publish when ready

1. In the owner’s GitHub account, create a **new public repository** for these public pages, for example `pazlume-support`. Leave the game repository’s visibility unchanged.
2. Extract the ZIP and upload its contents to the new repository’s root on its default branch. `index.html` must be at the root, not inside another folder.
3. Open Settings → Pages → Deploy from a branch; select that default branch and `/ (root)`, then save.
4. Wait for the Pages deployment to succeed. Copy the **actual Visit site URL shown by GitHub**, then verify `support-en.html`, `privacy-en.html` and each language link on that published site. No unverified address is entered into the app.
5. Put the actual HTTPS privacy/support addresses in `Release/Publisher.json`, preserving the confirmed email. Run `python3 Scripts/configure_publisher.py` and rebuild the app/archive so the in-app links match the published site.
6. Run `python3 Scripts/check_release.py --app <archive>/Products/Applications/ProjectFlip.app --check-urls` before submission. Sign the archive with the owner’s Apple Developer account; passing website checks alone is insufficient.

Use the privacy/support links in App Store Connect. Update and republish these pages whenever the game’s data practices or contact details change.

[GitHub’s official Pages setup](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site) describes branch publishing and the public-repository requirement for GitHub Free. This session has not published the site or changed any repository visibility.
