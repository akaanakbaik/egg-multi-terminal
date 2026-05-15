# Aka Multi Terminal Egg

Docker image dan egg Pterodactyl untuk terminal serbaguna: bot, web, API, tunnel, compile C/C++, dan runtime multi bahasa.

## Image

```txt
ghcr.io/akaanakbaik/egg-multi-terminal:nightly
```

Tag lain:

```txt
ghcr.io/akaanakbaik/egg-multi-terminal:latest
```

## Runtime bawaan

- Ubuntu 24.04
- Node.js via NVM: 18, 20, 22, dan Node terbaru saat image dibuild
- NPM terbaru
- PM2 terbaru
- Python 3 + pip + venv + pipx
- PHP CLI + Composer
- C/C++: GCC/G++ + Clang + CMake + Make
- Cloudflare Tunnel: cloudflared
- Java 21
- Go
- Bun
- Deno
- FFmpeg
- Git, curl, wget, jq, yq, tmux, screen, nano, vim, htop
- SQLite, Redis CLI, PostgreSQL client, MariaDB/MySQL client
- Library umum untuk bot, scraper, API, dan web server

## Cara build otomatis

Repo ini memakai GitHub Actions untuk build dan push image ke GHCR.

Setelah file masuk ke branch main, buka:

```txt
Actions -> Build and publish Docker image -> Run workflow
```

Setelah sukses, image bisa dipull:

```bash
docker pull ghcr.io/akaanakbaik/egg-multi-terminal:nightly
```

## Import egg ke Pterodactyl

Import file:

```txt
egg-aka-multi-terminal.json
```

Image default:

```txt
ghcr.io/akaanakbaik/egg-multi-terminal:nightly
```

Startup default:

```bash
bash
```

Saat server start, console akan masuk terminal interaktif berwarna dan menampilkan versi runtime.

## Environment egg

STARTUP_CMD default:

```bash
bash
```

Contoh untuk langsung run bot:

```bash
node index.js
```

Contoh untuk PM2 runtime:

```bash
pm2-runtime start ecosystem.config.js
```

AKA_SHOW_INFO default:

```txt
1
```

Isi 0 kalau tidak mau banner versi saat start.

## Local test

```bash
docker build -t aka-multi-terminal .
docker run -it --rm -p 3000:3000 -p 8000:8000 aka-multi-terminal
```
