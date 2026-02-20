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
2. Fetch von Upstream-Branch (`UPSTREAM_BRANCH`, Default: `master`)
3. Merge von Upstream in den Arbeitsstand
4. Selektives Checkout der T5UID1-Dateien aus `T5UID1_SOURCE_REMOTE/T5UID1_SOURCE_BRANCH`
   (Default: `t5uid1/master` → `https://github.com/gbkwiatt/klipper.git`)
5. PR-Erstellung nur wenn es echte Änderungen gegenüber `origin/TARGET_BRANCH` gibt
6. Öffnen/Aktualisieren eines PRs `bot/t5uid1-autosync`

## Wichtige Voraussetzung

Das T5UID1-Quell-Repo muss erreichbar sein und den angegebenen Branch enthalten
(Default: `https://github.com/gbkwiatt/klipper.git`, Branch `master`).

## Anpassung

Du kannst Branches direkt im Workflow über die `env`-Werte ändern:

- `TARGET_BRANCH`
- `UPSTREAM_BRANCH`
- `T5UID1_SOURCE_REMOTE`
- `T5UID1_SOURCE_REPO`
- `T5UID1_SOURCE_BRANCH`

Für manuelle Runs (`workflow_dispatch`) gibt es zusätzlich das optionale
Input-Feld `t5uid1_source_branch`, um den Reapply-Branch ad-hoc zu überschreiben.

Der Workflow nutzt außerdem `concurrency`, damit keine parallelen Sync-Läufe
gegeneinander arbeiten.
