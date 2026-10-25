# Autonomous AI Coding Agent + pstack Orchestrator (`auto_ai`)

ระบบเชื่อมต่อและสั่งการอัตโนมัติ (Auto-Orchestrator & Control Center) ที่เปลี่ยนให้ **Antigravity**, **Cursor**, **Claude Code**, **Codex**, และ **VS Code** ทำงานเป็น **Autonomous AI Coding Agent** โดยเรียกใช้เวิร์กโฟลว์วิศวกรรมของ **[pstack (`poteto-mode`)](https://github.com/backnotprop/pstack)** เองอัตโนมัติโดยไม่ต้องพิมพ์คำสั่ง `/poteto-mode` นำหน้าทุกครั้ง

---

## ✨ คุณสมบัติหลัก (Features)

- **Zero-Slash-Command Auto-Routing:** วิเคราะห์คำขอของผู้ใช้ทุกเทิร์น หากเป็นงานวิศวกรรม (Feature, Bug Fix, Refactoring, Architecture, Review) จะเปิดใช้งาน `poteto-mode` และเลือก Playbook ที่เหมาะสมให้อัตโนมัติ
- **Multi-IDE & Multi-Harness Support:** ซิงค์สกิลและกฎอัตโนมัติเข้าสู่ **Antigravity**, **Cursor**, **Claude Code**, **Codex**, และ **VS Code (GitHub Copilot)** ในคำสั่งเดียว
- **Auto-Install Upstream `pstack`:** หากเครื่องที่โคลนโปรเจกต์นี้ไปแล้วยังไม่มี `pstack` สคริปต์จะทำการ `git clone` ชุดสกิล `pstack` มาติดตั้งให้อัตโนมัติ
- **Dynamic Path Resolution:** ไม่มี Path ตายตัว (`Hardcoded Path`) ใช้งานได้กับทุกชื่อผู้ใช้และทุกระบบปฏิบัติการ (Windows PowerShell & macOS/Linux Bash)
- **Built-in `deslop` Custom Skill:** แถมสกิลทำความสะอาดโค้ดขยะ (`deslop`) ก่อนส่งมอบงานมาให้ในตัว

---

## 🚀 วิธีติดตั้งใช้งาน (Quick Start)

### 1. โคลนโปรเจกต์ลงเครื่อง
```bash
git clone https://github.com/<your-username>/auto_ai.git
cd auto_ai
```

### 2. รันคำสั่งติดตั้งและเปิดโหมดอัตโนมัติ (1 คำสั่งจบ)

**สำหรับ Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .\pstack-ctl.ps1 install
```

**สำหรับ macOS / Linux / Git Bash:**
```bash
chmod +x ./pstack-ctl.sh
./pstack-ctl.sh install
```

> **หมายเหตุ:** คำสั่ง `install` จะตรวจหา `pstack` ในเครื่อง (หากไม่มีจะดึงจาก GitHub มาไว้ที่ `./vendor/pstack` อัตโนมัติ), สร้างลิงก์สกิลทั้ง 52 ตัว, ปลดล็อกให้ AI เรียกสกิลเองได้, และติดตั้งกฎอัตโนมัติไปยังทุก IDE ของคุณทันที

---

## 🛠️ คำสั่งจัดการระบบ (`pstack-ctl`)

| คำสั่ง (Windows PowerShell) | คำสั่ง (macOS / Linux) | หน้าที่การทำงาน |
| :--- | :--- | :--- |
| `.\pstack-ctl.ps1 status` | `./pstack-ctl.sh status` | ตรวจสอบสถานะลิงก์สกิล กฎอัตโนมัติ และการตั้งค่าโมเดลในทุก IDE |
| `.\pstack-ctl.ps1 update` | `./pstack-ctl.sh update` | ดึงอัปเดตล่าสุดของ `pstack` จาก GitHub (ไม่ติด Git Conflict) พร้อมเชื่อมสกิลใหม่และปลดล็อกโหมดอัตโนมัติให้ทันที |
| `.\pstack-ctl.ps1 enable-autoupdate` | `./pstack-ctl.sh enable-autoupdate` | เปิดระบบตั้งเวลาอัปเดต `pstack` เบื้องหลังอัตโนมัติทุกวันและเมื่อเปิดเครื่อง (Windows Task Scheduler / Cron) |
| `.\pstack-ctl.ps1 disable-autoupdate` | `./pstack-ctl.sh disable-autoupdate` | ปิดระบบตั้งเวลาอัปเดตเบื้องหลังอัตโนมัติ |
| `.\pstack-ctl.ps1 enable-auto` | `./pstack-ctl.sh enable-auto` | เปิดให้ AI เรียกใช้ `pstack` เองอัตโนมัติทุกโปรเจกต์ (พร้อมเปิด Auto-Update) |
| `.\pstack-ctl.ps1 disable-auto` | `./pstack-ctl.sh disable-auto` | ปิดโหมดอัตโนมัติ (กลับไปพิมพ์ `/poteto-mode` ด้วยตัวเองแบบดั้งเดิม) |
| `.\pstack-ctl.ps1 sync` | `./pstack-ctl.sh sync` | ซิงค์กฎใหม่หลังจากที่คุณแก้ไขไฟล์ `rules/auto-orchestrator.md` หรือเพิ่มสกิลใน `custom-skills/` |
| `.\pstack-ctl.ps1 init-project <Path>` | `./pstack-ctl.sh init-project <Path>` | คัดลอกไฟล์ `AGENTS.md`, `CLAUDE.md`, และ `.github/copilot-instructions.md` ไปใส่ในโฟลเดอร์โปรเจกต์ที่ต้องการ |

---

## ⚙️ การปรับแต่งในอนาคต (Customization Guide)

1. **ปรับเปลี่ยนกติกาการเลือกสกิลอัตโนมัติ:**
   แก้ไขไฟล์แม่แบบที่ [`rules/auto-orchestrator.md`](./rules/auto-orchestrator.md) แล้วรัน `.\pstack-ctl.ps1 sync` เพื่ออัปเดตไปยังทุก IDE พร้อมกัน
2. **ปรับแต่งโมเดลของแต่ละบทบาท (Subagent Models):**
   แก้ไขไฟล์ `~/.agents/pstack-models.md` หรือพิมพ์ `/setup-pstack` ในแชทของ IDE
3. **เพิ่มสกิลส่วนตัว (Custom Skills):**
   สร้างโฟลเดอร์สกิลใหม่ใน [`custom-skills/<skill-name>/SKILL.md`](./custom-skills/README.md) แล้วรัน `.\pstack-ctl.ps1 sync`

---

## 📄 License
MIT
