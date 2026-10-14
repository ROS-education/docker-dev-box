# Blueprint: Containerized Development Box (dev-box)

พิมพ์เขียว (Blueprint) ฉบับสมบูรณ์สำหรับสถาปัตยกรรมและการทำงานของ **Containerized Ubuntu Development Box (`dev-box`)** ที่สร้างขึ้นในโปรเจกต์นี้ โดยผสานรวม **Antigravity CLI (`agy`)**, สภาพแวดล้อม **Miniconda**, การเข้าถึงฮาร์ดแวร์โฮสต์แบบเต็มรูปแบบ (**Full Host Hardware & Network Passthrough**), การจัดการโปรเซสผ่าน **Supervisor**, และการเชื่อมต่อผ่าน **SSH / VS Code Remote-SSH / DevContainer** ภายใต้ผู้ใช้ **`ubuntu` (Non-Root with Sudo)**

---

## 1. ภาพรวมสถาปัตยกรรม (System Architecture)

```
┌────────────────────────────────────────────────────────────────────────┐
│                              HOST MACHINE                              │
│  - Linux Kernel / Hardware (/dev, USB, Serial, Storage, Network)       │
│  - Docker Engine (/var/run/docker.sock, GID: 988)                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Host Passthrough (privileged, host net/pid/ipc)
┌───────────────────────────────────▼────────────────────────────────────┐
│                  CONTAINER: dev_box (Ubuntu Resolute)                  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ User: ubuntu (UID/GID 1000, sudo NOPASSWD, groups: docker,dialout)│  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ Process Manager: supervisord (managed as root)                   │  │
│  │   └── sshd (OpenSSH server on Port 2222)                         │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ Locale: en_US.UTF-8 (locales package + locale-gen)               │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ AI Automation: Antigravity CLI (agy)                             │  │
│  │   └── Config: ~/.gemini/antigravity-cli/settings.json            │  │
│  │   └── Auth: Google Account / OAuth (Stored in ~/.gemini volume)  │  │
│  │   └── Note: ไม่จำเป็นต้องใช้ GEMINI_API_KEY                     │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ Development Toolchain:                                           │  │
│  │   ├── Miniconda dev_env (Python 3.12, Node.js 22, CMake, C++)    │  │
│  │   ├── CLIs: gh (GitHub), gcloud (Google Cloud), ngrok, firebase  │  │
│  │   └── Diagnostic & Network: netcat, iproute2, tcpdump, nmap      │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  Volumes:                                                              │
│    - gemini: /home/ubuntu/.gemini (Session & Auth tokens)              │
│    - config: /home/ubuntu/.config (User configs)                       │
│    - conda:  /home/ubuntu/.conda  (Conda environments & packages)     │
│    - Codespaces: /workspace       (Workspace code)                     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. องค์ประกอบหลักของระบบ (Core Components)

### 2.1 สิทธิ์ผู้ใช้และความปลอดภัย (User & Permissions Model)
* **ผู้ใช้หลัก:** `ubuntu` (UID 1000 / GID 1000) พร้อมสิทธิ์ `sudo` แบบไม่ต้องใส่รหัสผ่าน (`/etc/sudoers.d/ubuntu-nopasswd`)
* **Group Access:** สมาชิกกลุ่ม `docker` (แมป GID ให้ตรงกับโฮสต์), `dialout`, `plugdev`, และ `tty` เพื่อให้เข้าถึงพอร์ตสื่อสารและอุปกรณ์ USB ได้ทันที
* **Supervisor:** รันเป็น `root` เพื่อคอยจัดการ lifecycle ของบริการพื้นหลัง (เช่น `sshd`)

### 2.2 การจัดการ Locale และ Encoding
* ติดตั้งแพ็กเกจ `locales` และสร้าง Locale `en_US.UTF-8` ด้วยคำสั่ง:
  ```bash
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  ```
* กำหนด Environment Variables:
  ```dockerfile
  ENV LANG=en_US.UTF-8 \
      LANGUAGE=en_US:en \
      LC_ALL=en_US.UTF-8
  ```
* ส่งผ่านค่าไปยัง SSH Session ผ่าน `/home/ubuntu/.ssh/environment` เพื่อป้องกันข้อผิดพลาด:
  `bash: warning: setlocale: LC_CTYPE: cannot change locale (en_US.UTF-8)` เมื่อรีโมตจากโฮสต์

### 2.3 Antigravity CLI (`agy`) & การยืนยันตัวตน
* ติดตั้งสำหรับผู้ใช้ `ubuntu` ที่พาธ `/home/ubuntu/.local/bin/agy`
* **การยืนยันตัวตน (Authentication):** ใช้การเข้าสู่ระบบผ่าน Google Account (`agy login`) หรือแชร์โทเคนผ่าน Named Volume `gemini:/home/ubuntu/.gemini` **โดยไม่ต้องพึ่งพา `GEMINI_API_KEY` ใน Environment**
* **การตั้งค่า Auto-Approve:** ปรับแต่งไฟล์ `~/.gemini/antigravity-cli/settings.json`:
  ```json
  {
    "toolPermission": "always-proceed",
    "artifactReviewPolicy": "always-proceed",
    "enableTerminalSandbox": false,
    "allowNonWorkspaceAccess": true,
    "permissions": {
      "allow": [
        "command(*)",
        "read_file(*)",
        "write_file(*)",
        "read_url(*)",
        "execute_url(*)",
        "mcp(*)",
        "shell(*)",
        "run_command(*)",
        "replace_file_content(*)",
        "create_file(*)"
      ]
    }
  }
  ```

### 2.4 Full Host Hardware & Network Passthrough
การคอนฟิกใน `docker-compose.yaml` ให้คอนเทนเนอร์มีสิทธิ์เข้าถึงฮาร์ดแวร์ของโฮสต์โดยตรง:

| พารามิเตอร์ | การทำงาน | ประโยชน์ที่ได้รับ |
| :--- | :--- | :--- |
| **`privileged: true`** | ปลดล็อกข้อจำกัดเคอร์เนลทั้งหมด | ควบคุมฮาร์ดแวร์และรันคำสั่งระบบระดับล่างได้ |
| **`network_mode: host`** | แชร์ Network Namespace กับโฮสต์โดยตรง | เข้าถึงพอร์ตและอุปกรณ์เน็ตเวิร์กของโฮสต์ ไม่ต้องผ่าน bridge NAT |
| **`pid: host` & `ipc: host`** | แชร์ PID และ IPC กับเครื่องโฮสต์ | ตรวจสอบโปรเซสบนโฮสต์ และรองรับ CUDA Shared Memory |
| **Mount `/dev:/dev`** | เมานต์โหนดอุปกรณ์ทั้งหมด | มองเห็น Serial (`/dev/ttyUSB*`), USB, และ Storage disks |
| **Mount Host Subsystems** | `/run/udev`, `/lib/modules`, `/sys`, `/proc` | ตรวจจับการเสียบอุปกรณ์ใหม่ โหลดโมดูลไดรเวอร์ และอ่านสถานะเคอร์เนล |
| **Docker Socket Passthrough** | `/var/run/docker.sock` | ให้ Agent หรือผู้ใช้สั่งรัน Docker containers ซ้อนได้ (Docker-outside-of-Docker) |

---

## 3. ผังโครงสร้างโปรเจกต์ (Project Structure)

```text
docker-dev-box/
├── Dockerfile                  # นิยาม Image หลัก (Ubuntu Resolute + Tools + agy)
├── docker-compose.yaml         # Compose file กำหนด Volumes, Privileged, Host Network
├── .env                        # ค่าคอนฟิกสภาพแวดล้อม (ARCH=amd64, HOST_DOCKER_GID=988)
├── .env.example                # ตัวอย่างไฟล์ .env
├── .devcontainer/
│   └── devcontainer.json       # คอนฟิกสำหรับเปิดด้วย VS Code Dev Containers
├── app/
│   ├── supervisord.conf        # ไฟล์คอนฟิกหลักของ Supervisor
│   └── conf.d/
│       └── sshd.conf           # ควบคุมการทำงานของ OpenSSH Daemon (Port 2222)
├── scripts/
│   ├── build-multiarch.sh      # สคริปต์สร้าง Image แบบ Multi-Arch (amd64, arm64)
│   └── transfer-to-remote.sh   # สคริปต์ส่งไฟล์ไปยังโฮสต์ปลายทาง
└── tests/                      # ชุดทดสอบ capabilities, network, conda, usb
```

---

## 4. ไฟล์คอนฟิกหลักตาม Implementation จริง

### 4.1 `docker-compose.yaml`
```yaml
version: '3.8'

services:
  dev-box:
    image: wn1980/dev-box:${ARCH}
    container_name: dev_box
    privileged: true
    network_mode: host
    pid: host
    ipc: host
    dns:
      - 8.8.8.8
      - 8.8.4.4
      - 1.1.1.1
    environment:
      - TZ=Asia/Bangkok
      - COMPOSE_BAKE=true
      - AGY_CLI_DISABLE_AUTO_UPDATE=true
    volumes:
      - config:/home/ubuntu/.config
      - conda:/home/ubuntu/.conda
      - gemini:/home/ubuntu/.gemini
      - Codespaces:/workspace
      - /var/run/docker.sock:/var/run/docker.sock
      - /dev:/dev
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /run/systemd:/run/systemd:ro
      - /run/udev:/run/udev:ro
      - /lib/modules:/lib/modules:ro
    devices:
      - /dev:/dev
    cap_add:
      - ALL
    security_opt:
      - seccomp:unconfined
      - apparmor:unconfined
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "pgrep", "-f", "sshd"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  config:
  conda:
  gemini:
  Codespaces:
    external: true
```

### 4.2 การรัน Background Services ด้วย Supervisor (`app/conf.d/sshd.conf`)
```ini
[program:sshd]
command=/usr/sbin/sshd -D -p 2222
user=root
autostart=true
autorestart=true
startsecs=3
startretries=3
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
priority=10
killasgroup=true
stopasgroup=true
```

---

## 5. วิธีการสร้างและใช้งาน (Build & Deployment)

### ขั้นตอนที่ 1: เตรียมสภาพแวดล้อม
```bash
# ตรวจสอบ GID ของ docker group บนโฮสต์
getent group docker | cut -d: -f3

# สร้าง external volume สำหรับพื้นที่ทำงาน (หากยังไม่มี)
docker volume create Codespaces
```

### ขั้นตอนที่ 2: สร้าง Image (Local Build)
```bash
# บิลด์สำหรับสถาปัตยกรรมปัจจุบัน (เช่น amd64)
./scripts/build-multiarch.sh --platform amd64 --registry wn1980
```

### ขั้นตอนที่ 3: เริ่มต้นคอนเทนเนอร์
```bash
docker compose up -d
```

### ขั้นตอนที่ 4: การเชื่อมต่อเข้าสู่ DevBox
* **เชื่อมต่อผ่าน SSH:**
  ```bash
  ssh -p 2222 ubuntu@localhost
  # Password เริ่มต้น: ubuntu
  ```
* **เชื่อมต่อผ่าน VS Code:**
  * ใช้ส่วนขยาย **Remote - SSH**: เพิ่ม Host `ssh ubuntu@localhost -p 2222`
  * หรือใช้ **Dev Containers**: เปิดโปรเจกต์แล้วเลือก *Reopen in Container*

### ขั้นตอนที่ 5: ใช้งาน Antigravity CLI
```bash
# เข้าสู่คอนเทนเนอร์
docker exec -it dev_box su - ubuntu

# ตรวจสอบเวอร์ชัน
agy --version

# ยืนยันตัวตน (ทำครั้งเดียว ข้อมูลจะถูกบันทึกใน volume gemini)
agy login

# รันแบบ Unattended / Headless
agy --dangerously-skip-permissions -p "Check system hardware and disk info"
```

---

## 6. ข้อควรระวังด้านความปลอดภัย (Security Guidelines)

1. **โหมด Privileged & การเข้าถึง Host Storage:**
   คอนเทนเนอร์สามารถมองเห็นและแก้ไขดิสก์จริงของโฮสต์ (`/dev/sda`, `/dev/nvme*`) ได้ ควรระมัดระวังในการสั่งคำสั่งที่เกี่ยวกับดิสก์หรือพาร์ทิชัน
2. **รหัสผ่านผู้ใช้เริ่มต้น:**
   รหัสผ่านเริ่มต้นของ `ubuntu` คือ `ubuntu` หากเปิดให้เข้าถึงผ่านเครือข่ายภายนอก ควรเปลี่ยนรหัสผ่านทันที (`passwd`) หรือปิดการล็อกอินด้วยรหัสผ่านแล้วใช้ SSH Public Key Authentication แทน
3. **การเก็บรักษาเซสชันของ AI:**
   ข้อมูลรับรองสิทธิ์ (Auth Tokens) จะถูกจัดเก็บอย่างปลอดภัยใน Named Volume `gemini` บนเครื่องโฮสต์ ไม่มีการเปิดเผย API Key ใน Compose manifest หรือซอร์สโค้ด