# Aka Multi Terminal Egg

Aka Multi Terminal adalah Docker image + egg Pterodactyl universal untuk menjalankan bot, website, API, scraper, compiler, terminal interaktif, dan Cloudflare Tunnel dalam satu container.

## Image

```txt
ghcr.io/akaanakbaik/egg-multi-terminal:nightly
```

Tag stabil terbaru:

```txt
ghcr.io/akaanakbaik/egg-multi-terminal:latest
```

## Runtime bawaan

- Ubuntu 24.04
- Node.js via NVM: 18, 20, 22, dan latest saat image dibuild
- NPM terbaru
- PM2 terbaru
- pnpm, yarn, nodemon, ts-node, TypeScript, Vite, serve, http-server
- Python 3 + pip + venv + uv + pipenv + poetry
- PHP CLI + Composer + ekstensi umum
- C/C++: GCC/G++ + Clang + CMake + Make
- Cloudflare Tunnel: cloudflared
- Java 21
- Go
- Bun
- Deno
- FFmpeg
- ImageMagick
- Git, curl, wget, jq, yq, tmux, screen, nano, vim, htop
- SQLite, Redis CLI, PostgreSQL client, MariaDB/MySQL client

## Build otomatis GHCR

Repo ini memakai GitHub Actions untuk build dan push image ke GHCR.

Jalankan manual dari:

```txt
Actions -> Build and publish Docker image -> Run workflow
```

Test pull:

```bash
docker pull ghcr.io/akaanakbaik/egg-multi-terminal:nightly
```

Test run lokal:

```bash
docker run -it --rm -p 3000:3000 -p 8000:8000 ghcr.io/akaanakbaik/egg-multi-terminal:nightly
```

## Import egg ke Pterodactyl

Import file:

```txt
egg-aka-multi-terminal.json
```

Default image:

```txt
ghcr.io/akaanakbaik/egg-multi-terminal:nightly
```

Default startup:

```bash
bash
```

Saat server start, terminal akan menampilkan banner berwarna dan versi runtime yang terpasang.

## Variabel egg utama

### STARTUP_CMD

Command utama yang dijalankan saat server start.

Nilai umum:

```bash
bash
```

Terminal interaktif. Cocok untuk server terminal-only.

```bash
auto
```

Deteksi otomatis. Entry point akan mencari file umum seperti `package.json`, `index.js`, `main.py`, `artisan`, atau `index.php`.

```bash
node index.js
```

Untuk bot Node.js.

```bash
npm start
```

Untuk project Node.js yang punya script `start` di `package.json`.

```bash
pm2-runtime start ecosystem.config.js
```

Untuk menjalankan banyak proses Node.js dengan PM2.

```bash
python3 main.py
```

Untuk bot atau script Python.

```bash
uvicorn main:app --host 0.0.0.0 --port ${SERVER_PORT}
```

Untuk FastAPI.

```bash
php -S 0.0.0.0:${SERVER_PORT}
```

Untuk PHP built-in server.

```bash
php artisan serve --host=0.0.0.0 --port=${SERVER_PORT}
```

Untuk Laravel.

### NODE_VERSION

Mengatur versi Node.js saat startup.

Contoh:

```txt
18
20
22
node
latest
```

Jika versi belum ada di image, entrypoint akan mencoba install lewat NVM. Jika gagal, otomatis fallback ke versi default.

### AKA_SHOW_INFO

Tampilkan banner dan daftar versi runtime.

```txt
1
```

Tampil.

```txt
0
```

Sembunyi.

### AUTO_INSTALL_ON_START

Install dependency otomatis saat server start.

```txt
true
```

Aktif.

```txt
false
```

Nonaktif.

File yang dideteksi:

- `package.json`
- `pnpm-lock.yaml`
- `yarn.lock`
- `bun.lockb` / `bun.lock`
- `requirements.txt`
- `composer.json`
- `go.mod`
- `Gemfile`

### APP_PORT

Port aplikasi di dalam container. Biasanya isi sama dengan allocation port Pterodactyl.

```txt
{{SERVER_PORT}}
```

Contoh manual:

```txt
3000
8000
```

## Git auto deploy saat install

Egg mendukung clone repo otomatis dari variabel install.

### GIT_ADDRESS

URL repo yang akan di-clone.

Contoh:

```txt
https://github.com/username/project
```

atau:

```txt
https://github.com/username/project.git
```

Kosongkan jika ingin terminal-only atau upload manual.

### BRANCH

Branch yang akan dipakai.

Contoh:

```txt
main
master
production
```

Kosongkan untuk default branch repo.

### USER_UPLOAD

Lewati git clone dan pakai upload manual via File Manager/SFTP.

```txt
true
```

Mode upload manual.

```txt
false
```

Mode git clone normal.

### Private repository

Di egg JSON publik, variabel rahasia tidak disertakan secara eksplisit supaya lebih aman. Kalau mau clone private repo, tambahkan sendiri variable di panel Pterodactyl:

```txt
ACCESS_TOKEN
```

Lalu isi token di server variables, bukan di file repo public.

## Cloudflare Tunnel

Image sudah membawa `cloudflared`, dan entrypoint sudah mendukung auto-start tunnel.

Karena token tunnel adalah data sensitif, variabel token tidak dipaksa masuk di JSON publik. Tambahkan manual di Pterodactyl jika perlu.

### Mode 1: Named Tunnel dengan token

Tambahkan variable di egg/panel:

```txt
ENABLE_CF_TUNNEL=true
CF_TOKEN=<token tunnel dari Cloudflare>
```

Saat server start, entrypoint menjalankan:

```bash
cloudflared tunnel --no-autoupdate run --token <token>
```

Log tunnel tersimpan di:

```txt
/home/container/cloudflared.log
```

Cara ambil token Cloudflare:

1. Buka Cloudflare Zero Trust Dashboard
2. Masuk Networks -> Tunnels
3. Create Tunnel
4. Pilih Cloudflared
5. Copy token tunnel
6. Paste ke variable `CF_TOKEN` di Pterodactyl

### Mode 2: Quick Tunnel tanpa token

Tambahkan variable:

```txt
ENABLE_CF_TUNNEL=true
CF_URL=http://127.0.0.1:3000
```

Atau biarkan `CF_URL` kosong dan isi:

```txt
APP_PORT=3000
```

Entry point akan menjalankan quick tunnel ke port itu.

Contoh startup web Node.js:

```txt
STARTUP_CMD=npm start
APP_PORT=3000
ENABLE_CF_TUNNEL=true
CF_URL=http://127.0.0.1:3000
```

### Mode 3: Tunnel sebagai script perantara di Pterodactyl

Kalau kamu ingin startup tetap menjalankan app dan tunnel sekaligus tanpa mengubah kode app, pakai wrapper script.

Buat file `start.sh` di File Manager:

```bash
#!/usr/bin/env bash
set -e

npm start &
APP_PID=$!

cloudflared tunnel --no-autoupdate --url http://127.0.0.1:${APP_PORT:-3000} > cloudflared.log 2>&1 &
CF_PID=$!

wait $APP_PID
kill $CF_PID 2>/dev/null || true
```

Lalu set:

```txt
STARTUP_CMD=bash start.sh
APP_PORT=3000
```

Untuk token named tunnel:

```bash
#!/usr/bin/env bash
set -e

npm start &
APP_PID=$!

cloudflared tunnel --no-autoupdate run --token "$CF_TOKEN" > cloudflared.log 2>&1 &
CF_PID=$!

wait $APP_PID
kill $CF_PID 2>/dev/null || true
```

## Contoh konfigurasi startup

### Terminal bebas

```txt
STARTUP_CMD=bash
```

### Auto detect project

```txt
STARTUP_CMD=auto
AUTO_INSTALL_ON_START=true
```

### Bot WhatsApp/Telegram Node.js

```txt
STARTUP_CMD=node index.js
NODE_VERSION=22
AUTO_INSTALL_ON_START=true
```

### Node.js dengan PM2

```txt
STARTUP_CMD=pm2-runtime start ecosystem.config.js
NODE_VERSION=22
```

### Python bot

```txt
STARTUP_CMD=python3 main.py
AUTO_INSTALL_ON_START=true
```

### FastAPI

```txt
STARTUP_CMD=uvicorn main:app --host 0.0.0.0 --port ${SERVER_PORT}
AUTO_INSTALL_ON_START=true
APP_PORT={{SERVER_PORT}}
```

### PHP native

```txt
STARTUP_CMD=php -S 0.0.0.0:${SERVER_PORT}
APP_PORT={{SERVER_PORT}}
```

### Laravel

```txt
STARTUP_CMD=php artisan serve --host=0.0.0.0 --port=${SERVER_PORT}
AUTO_INSTALL_ON_START=true
APP_PORT={{SERVER_PORT}}
```

### Bun

```txt
STARTUP_CMD=bun run start
AUTO_INSTALL_ON_START=true
```

### Deno

```txt
STARTUP_CMD=deno run --allow-all main.ts
```

### Go

```txt
STARTUP_CMD=go run .
AUTO_INSTALL_ON_START=true
```

### C++

```txt
STARTUP_CMD=g++ main.cpp -O2 -std=c++20 -o app && ./app
```

## Command berguna di terminal

```bash
aka-info
```

Lihat versi runtime.

```bash
aka-help
```

Lihat bantuan singkat.

```bash
n18
n20
n22
nlatest
```

Ganti versi Node.js di shell aktif.

```bash
node18 index.js
node20 index.js
node22 index.js
```

Jalankan file dengan versi Node tertentu.

```bash
pm2 list
pm2 logs
```

Cek proses PM2.

```bash
tail -f cloudflared.log
```

Cek log Cloudflare Tunnel.

## Troubleshooting

### Image tidak bisa dipull

Kalau muncul unauthorized/denied, ubah visibility package GHCR menjadi public:

```txt
GitHub Profile -> Packages -> egg-multi-terminal -> Package settings -> Change visibility -> Public
```

### Node version tidak berubah

Cek:

```bash
aka-info
```

Pastikan `NODE_VERSION` diisi `18`, `20`, `22`, `node`, atau `latest`.

### Web tidak bisa diakses

Pastikan aplikasi listen ke `0.0.0.0`, bukan `localhost` saja.

Benar:

```bash
0.0.0.0:${SERVER_PORT}
```

Kurang cocok:

```bash
127.0.0.1:3000
```

Untuk Cloudflare quick tunnel, target lokal boleh `127.0.0.1`, tapi app tetap lebih aman listen di `0.0.0.0`.

### Tunnel tidak jalan

Cek log:

```bash
tail -f /home/container/cloudflared.log
```

Pastikan `ENABLE_CF_TUNNEL=true` dan `CF_TOKEN` atau `CF_URL` sudah benar.
