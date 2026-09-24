# Disko

A small black notch on the right edge of your Mac that shows how much disk
Claude, Cursor, Codex and Grok are using. Same look as
[Codenotch](https://github.com/vinzdg/codenotch).

- **Hover the pill** to open the notch. You get one ring per tool. The arc is that tool's share of the combined total, and the colour shows its size: green under 5 GB, yellow under 15 GB, orange above that.
- **Hover a ring** to see the card, which splits that tool's footprint by kind (worktrees, sessions, VM images, Docker, caches, temp files and so on). Each row names the biggest folder.
- **Click a row** to open those folders in Finder.
- **Click a ring** to rescan. It also rescans every 30 minutes.
- **Hover the curved corner** at the end of the notch. The thin arc there swells into a gear, and clicking it opens Settings. From there you pick the screen edge (left, right, top or bottom), turn Open at Login on or off, or rescan.
- **Right-click** for Rescan, Settings or Quit. Installing to `/Applications` turns Open at Login on the first time the app runs.

```bash
make run        # build build/Disko.app and launch it
make install    # copy it to /Applications
make print      # the same scan, printed as text in the terminal
```

The app has no dependencies and no Xcode project. It is about 600 KB, uses about 50 MB of memory, and sits at 0% CPU between scans.

## Where it looks

| | |
|---|---|
| Hidden home folders | `~/.claude`, `~/.claude.json`, `~/.codex`, `~/.cursor`, `~/.grok`, `~/.local/share/{claude,cursor-agent,grok}`, `~/.local/state/claude`, `~/.cache/{claude,grok}`. Each child folder is sorted into a kind, so new subfolders are picked up automatically. |
| App data | `~/Library/Application Support/{Claude,Cursor,Codex,Grok…}`, including Claude's `vm_bundles` VM images |
| Swept by name | `~/Library/{Caches,Logs,HTTPStorages,WebKit,Application Support}`, `/Applications`, `/private/tmp`, `$TMPDIR` |
| Worktrees | Found through each repo's `.git/worktrees`. Repos come from `~/.claude.json`, `~/.codex/config.toml` and Cursor's workspace storage. A worktree is credited to a tool if it sits under that tool's folder, or if the tool has a session recorded for that path. Failing that, it goes to whichever tool co-authored the most commits unique to its branch (commits not on the default branch). If no tool did, it is left out. |
| Docker | `docker system df -v`, when a daemon is running (Docker Desktop, OrbStack, Colima). Images, containers and volumes whose names mention a tool are credited to it. |
| Global CLIs | `node_modules/@anthropic-ai`, `@openai/codex` |
| Bundled | The Codex parts inside `ChatGPT.app` (its `codex` binary, `Codex Framework`, and dock plugin) |

When one path sits inside another, it is counted once. Sizes come from `du`, so they are the space actually allocated on disk.

## Credits

The provider glyph outlines and the notch geometry come from
[Codenotch](https://github.com/vinzdg/codenotch) by Vinz, MIT licensed.
