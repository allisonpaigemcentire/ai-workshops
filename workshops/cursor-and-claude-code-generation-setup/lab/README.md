# Lab: personal agent kit v2

Participant download for *How to set up Cursor and Claude for better code
generation*.

- **Zip:** [personal-agent-kit-v2.zip](personal-agent-kit-v2.zip)
  ([direct download](https://github.com/allisonpaigemcentire/ai-workshops/raw/main/workshops/cursor-and-claude-code-generation-setup/lab/personal-agent-kit-v2.zip))
- **Same files, unzipped:** [personal-agent-kit/](personal-agent-kit/). Start
  with its [README](personal-agent-kit/README.md).

Unzip into `~/src`, then run one command:

```bash
mkdir -p ~/src && unzip ~/Downloads/personal-agent-kit-v2.zip -d ~/src
bash ~/src/personal-agent-kit/scripts/install.sh
```

It previews every change, asks once, and backs up each file it touches.
Undo with `bash ~/.agents/scripts/uninstall.sh`.

If you cloned this repo instead, run the installer from the clone:

```bash
bash workshops/cursor-and-claude-code-generation-setup/lab/personal-agent-kit/scripts/install.sh --dry-run
```
