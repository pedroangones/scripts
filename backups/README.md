# Backups Locais - Gitea e Portainer

## O que e backup neste contexto

Backup e a captura consistente dos dados persistentes dos servicos criticos locais para permitir recuperacao operacional em caso de erro, corrupcao ou perda de dados.

Servicos cobertos:

- Gitea (`/Users/pedroangones/srv/docker/volumes/gitea`)
- Portainer (`/Users/pedroangones/srv/docker/volumes/portainer`)

## Como executar (manual run)

```bash
cd /Users/pedroangones/srv/projects/scripts/backups
bash backup_now.sh
```

O script:

- para temporariamente os servicos por stack via `docker compose stop` em:
  - `/Users/pedroangones/srv/docker/stacks/gitea`
  - `/Users/pedroangones/srv/docker/stacks/portainer`
- gera arquivos `tar.gz` datados por dia;
- sobe novamente os servicos por stack via `docker compose up -d`;
- se um `compose stop/up` falhar, registra `WARN` e continua o processo;
- grava log em `/Users/pedroangones/srv/backups/backup.log`;
- registra snapshot de `docker ps --format "table {{.Names}}\t{{.Status}}"` (linhas de `gitea` e `portainer`) antes de parar e depois de subir.

## Onde ficam os arquivos

Estrutura de saida:

- `/Users/pedroangones/srv/backups/gitea/<YYYY-MM-DD>/gitea-volume-<YYYY-MM-DD>.tar.gz`
- `/Users/pedroangones/srv/backups/portainer/<YYYY-MM-DD>/portainer-volume-<YYYY-MM-DD>.tar.gz`
- `/Users/pedroangones/srv/backups/backup.log`

## Agendamento futuro (documentado, nao configurado)

Opcao recomendada para fase futura:

- executar `backup_now.sh` 1x ao dia (ex.: madrugada), via `cron` ou `launchd`.
- manter mesmo fluxo do script manual, sem alterar formato de saida.

## Retencao sugerida (nao implementada ainda)

- manter backups diarios por 14 dias.
- evoluir para politica por classe de dado apos validacao de restore recorrente.

## Pendencias

- copiar backups para midia externa.
- definir estrategia de sincronizacao/mirror no GitHub para artefatos de documentacao e scripts (nao para dados sensiveis).
- validar restore periodico com checklist operacional.
