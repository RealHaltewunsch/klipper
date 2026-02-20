# T5UID1 Auto-Sync Workflow

Diese Repo enthält jetzt einen Workflow, der Upstream-Updates aus
`Klipper3d/klipper` automatisch übernimmt und danach den T5UID1-Patchsatz
wieder einspielt.

## Dateien

- Workflow: `.github/workflows/t5uid1-autosync.yml`
- Sync-Skript: `scripts/t5uid1_sync.sh`
- Selektive Dateiliste: `.github/t5uid1-sync-files.txt`

## Standard-Verhalten

Der Workflow läuft:

- manuell über `workflow_dispatch`
- täglich per Cron

Ablauf:

1. Checkout von `TARGET_BRANCH` (Default: Repo-Default-Branch, z.B. `master`)
2. Fetch von Upstream-Branch (`UPSTREAM_BRANCH`, Default: `main`)
3. Merge von Upstream in den Arbeitsstand
4. Selektives Checkout der T5UID1-Dateien aus `T5UID1_SOURCE_BRANCH`
   (Fallback auf `TARGET_BRANCH`, falls der Source-Branch im Fork fehlt)
5. PR-Erstellung nur wenn es echte Änderungen gegenüber `origin/TARGET_BRANCH` gibt
6. Öffnen/Aktualisieren eines PRs `bot/t5uid1-autosync`

## Wichtige Voraussetzung

`T5UID1_SOURCE_BRANCH` muss in deinem Fork existieren und die gewünschte
T5UID1-Implementierung enthalten (z.B. ein stabiler Branch wie `t5uid1-port`).

## Anpassung

Du kannst Branches direkt im Workflow über die `env`-Werte ändern:

- `TARGET_BRANCH`
- `UPSTREAM_BRANCH`
- `T5UID1_SOURCE_BRANCH`

Für manuelle Runs (`workflow_dispatch`) gibt es zusätzlich das optionale
Input-Feld `t5uid1_source_branch`, um den Reapply-Branch ad-hoc zu überschreiben.

Der Workflow nutzt außerdem `concurrency`, damit keine parallelen Sync-Läufe
gegeneinander arbeiten.
