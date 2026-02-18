# Restore Guide (Gitea e Portainer)

Este guia descreve restauracao local a partir dos arquivos gerados por `backup_now.sh`.

## 1) Identificar backup

Escolha o arquivo `tar.gz` desejado em:

- `/Users/pedroangones/srv/backups/gitea/<YYYY-MM-DD>/`
- `/Users/pedroangones/srv/backups/portainer/<YYYY-MM-DD>/`

## 2) Parar container do servico

Gitea:

```bash
docker stop gitea
```

Portainer:

```bash
docker stop portainer
```

## 3) Restaurar volume com cuidado

A restauracao sobrescreve o conteudo atual do volume. Valide antes de executar.

Gitea:

```bash
rm -rf /Users/pedroangones/srv/docker/volumes/gitea
tar -C /Users/pedroangones/srv/docker/volumes -xzf /Users/pedroangones/srv/backups/gitea/<YYYY-MM-DD>/gitea-volume-<YYYY-MM-DD>.tar.gz
```

Portainer:

```bash
rm -rf /Users/pedroangones/srv/docker/volumes/portainer
tar -C /Users/pedroangones/srv/docker/volumes -xzf /Users/pedroangones/srv/backups/portainer/<YYYY-MM-DD>/portainer-volume-<YYYY-MM-DD>.tar.gz
```

## 4) Subir container

```bash
docker start gitea
docker start portainer
```

## 5) Validar

- Gitea: `curl -I http://localhost:3000`
- Portainer: `curl -I http://localhost:9000`
- Verificar login e dados esperados nas interfaces web.

## Observacao

Em ambiente de producao local, recomendavel fazer snapshot/copia dos volumes atuais antes de uma restauracao destrutiva.
