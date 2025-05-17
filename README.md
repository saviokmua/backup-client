# 🔄 Backup Client

A Ruby script to copy files and directories to multiple destinations:
- FTP servers
- SCP servers (optional)
- Local folders

Supports Windows.

---

## 📁 Purpose

- Copy individual files or full directories
- Upload to multiple destinations simultaneously
- Optional subfolder creation with timestamp (`yyyy.mm.dd HH:mm:ss`)

---

## ⚙️ Configuration: `config.yml`

```
destinations:
- name: "main_server"
  type: "ftp"
  host: "ftp.example.com"
  user: "ftp_user"
  password: "ftp_password"

- name: "local_backup"
  type: "local"
  path: "D:/backups"

- name: "scp_server"
  type: "scp"
  host: "scp.example.com"
  user: "scp_user"
  password: "scp_password"
  path: "/home/scp_user/backups"

tasks:
- name: "Daily Project A Backup"
  source_folders:
    - "C:/projects/a"
    - "C:/projects/shared/readme.txt"
      destination_names:
    - "main_server"
    - "local_backup"
      timestamped_subfolder: true

- name: "Quick Local Copy"
  source_folders:
    - "C:/notes"
      destination_names:
    - "local_backup"
      timestamped_subfolder: false

```

---

## 🔑 Configuration Options

### 🔹 `destinations`
A list of all available upload targets.

| Field      | Type    | Required | Description                                      |
|------------|---------|----------|--------------------------------------------------|
| `name`     | string  | ✅       | Unique name used to reference the destination    |
| `type`     | string  | ✅       | Either `ftp`, `local`, or `scp`                  |
| `host`     | string  | only for FTP/SCP | Host address                             |
| `user`     | string  | only for FTP/SCP | Username                                 |
| `password` | string  | only for FTP/SCP | Password                                 |
| `path`     | string  | for `local` or `scp` | Destination path                    |

---

### 🔹 `tasks`
Describes which files/folders to upload, and to which destinations.

| Field                   | Type     | Required | Description                                                  |
|------------------------|----------|----------|--------------------------------------------------------------|
| `name`                 | string   | ✅       | Name of the task                                             |
| `source_folders`       | array    | ✅       | List of source file/folder paths                             |
| `destination_names`    | array    | ✅       | References destination `name`s from the list above           |
| `timestamped_subfolder`| boolean  | ❌ (default: `true`) | Whether to create a subfolder with current timestamp |

---

## 🚀 Running the script

```
ruby copy_script.rb
```

> Requires Ruby installed and all dependencies resolved (e.g. `net-ftp`).

---

## 📦 TODO / Optional Features

- [ ] SCP support via `net-scp` or `pscp.exe`
- [ ] Dry-run mode
- [ ] Logging to file

---

## 🪪 License

MIT License – use freely in commercial and personal projects.

---
