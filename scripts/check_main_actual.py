#!/usr/bin/env python3
"""Проверяет, что текущая ветка содержит актуальный origin/main.

Плейбук запускают с рабочей ветки: её собственные коммиты на проверку не влияют.
Блокируется только случай, когда origin/main ушёл вперёд, а ветка его не
подтянула (иначе на сервер уедет устаревшая инфраструктура).
"""

import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REMOTE = "origin"
MAIN = "main"


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=REPO, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        fail(f"git {' '.join(args)} завершился с ошибкой:\n{result.stderr.strip()}")
    return result.stdout.strip()


def fail(message: str) -> None:
    print(f"ОШИБКА: {message}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    git("fetch", "--quiet", REMOTE, MAIN)

    remote_ref = f"{REMOTE}/{MAIN}"
    behind = int(git("rev-list", "--count", f"HEAD..{remote_ref}"))
    branch = git("rev-parse", "--abbrev-ref", "HEAD")

    if behind > 0:
        fail(
            f"в {remote_ref} есть {behind} коммит(ов), которых нет в ветке '{branch}'.\n"
            f"Подтяните их: git merge {remote_ref} (или git rebase {remote_ref})."
        )

    if git("status", "--porcelain"):
        print("ПРЕДУПРЕЖДЕНИЕ: есть незакоммиченные изменения, они попадут в запуск.")

    print(f"OK: ветка '{branch}' содержит актуальный {remote_ref}")


if __name__ == "__main__":
    main()
