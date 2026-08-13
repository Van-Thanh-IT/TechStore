```markdown
# 🚀 PRODUCTION DEPLOYMENT GUIDE & TOPOLOGY

Tài liệu này chi tiết hóa kiến trúc triển khai (Deployment Architecture), quy trình đóng gói container, cấu hình Nginx Reverse Proxy, cấp phát chứng chỉ SSL/TLS Let's Encrypt và Tự động hóa triển khai (CI/CD) cho hệ thống **TechStore**.

---

## 1. SƠ ĐỒ KIẾN TRÚC TRIỂN KHAI (DEPLOYMENT TOPOLOGY)

Hệ thống được triển khai theo mô hình Containerized đằng sau Nginx Reverse Proxy trên máy chủ ảo VPS (Ubuntu Server 22.04 LTS):

```text
                                [ Internet Users ]
                                        │
                                        ▼ (HTTPS / Port 443)
                         ┌─────────────────────────────┐
                         │   Nginx Reverse Proxy       │
                         │   (SSL Let's Encrypt)       │
                         └──────────────┬──────────────┘
                                        │
             ┌──────────────────────────┴──────────────────────────┐
             ▼ (Port 3000)                                         ▼ (Port 8080)
┌─────────────────────────────┐                       ┌─────────────────────────────┐
│  Frontend Service Container │                       │  Backend Service Container  │
│           (React)           │                       │     (Spring Boot App)       │
└─────────────────────────────┘                       └──────────────┬──────────────┘
                                                                     │
                                       ┌─────────────────────────────┴─────────────────────────────┐
                                       ▼                                                           ▼
                        ┌─────────────────────────────┐                             ┌─────────────────────────────┐
                        │           MySQL             │                             │   Redis Cache Container     │
                        │     (Port 3306/5432)        │                             │        (Port 6379)          │
                        └─────────────────────────────┘                             └─────────────────────────────┘

```

---

## 2. QUY TRÌNH CHUẨN BỊ MÁY CHỦ VPS (SERVER SETUP)

### 2.1. Cài đặt Docker & Docker Compose

Thực thi lệnh trên máy chủ VPS Ubuntu:

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker
curl -fsSL [https://get.docker.com](https://get.docker.com) -o get-docker.sh
sudo sh get-docker.sh

# Cài đặt Docker Compose Plugin
sudo apt install docker-compose-plugin -y

# Thêm User hiện tại vào group Docker
sudo usermod -aG docker $USER

```

### 2.2. Cấu hình Firewall (UFW)

Chỉ mở các Cổng cần thiết ra ngoài Internet:

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Let's Encrypt Challenge)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

```

---

## 3. CẤU HÌNH NGINX REVERSE PROXY & SSL

### 3.1. File Cấu hình Nginx (`/etc/nginx/sites-available/techstore.conf`)

```nginx
server {
    listen 80;
    server_name techstore.vn www.techstore.vn api.techstore.vn;

    # Tự động chuyển hướng HTTP sang HTTPS
    return 301 https://$host$request_uri;
}

# 1. Frontend Domain Configuration
server {
    listen 443 ssl http2;
    server_name techstore.vn www.techstore.vn;

    ssl_certificate /etc/letsencrypt/live/techstore.vn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/techstore.vn/privkey.pem;

    location / {
        proxy_pass [http://127.0.0.1:3000](http://127.0.0.1:3000);
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# 2. Backend API & WebSocket Domain Configuration
server {
    listen 443 ssl http2;
    server_name api.techstore.vn;

    ssl_certificate /etc/letsencrypt/live/techstore.vn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/techstore.vn/privkey.pem;

    # REST API Routing
    location / {
        proxy_pass [http://127.0.0.1:8080](http://127.0.0.1:8080);
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Spring WebSocket (STOMP) Support
    location /ws {
        proxy_pass [http://127.0.0.1:8080](http://127.0.0.1:8080);
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}

```

### 3.2. Cấp phát Chứng chỉ SSL Miễn phí bằng Certbot

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d techstore.vn -d www.techstore.vn -d api.techstore.vn

```

---

## 4. QUY TRÌNH CI/CD TỰ ĐỘNG (GITHUB ACTIONS)

Tự động hóa luồng **Build $\rightarrow$ Test $\rightarrow$ Push Docker Image $\rightarrow$ Deploy lên VPS** mỗi khi push code vào branch `main`.

### File Cấu hình Workflow (`.github/workflows/deploy.yml`)

```yaml
name: Production CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      # 1. Run Backend Unit Tests
      - name: Build & Test Backend with Maven
        run: |
          ./mvnw clean package -DskipTests=false

      # 2. Login to Docker Hub
      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # 3. Build & Push Docker Image
      - name: Build and Push Backend Image
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/techstore-backend:latest

      # 4. SSH into VPS & Trigger Deployment
      - name: Deploy to VPS via SSH
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USERNAME }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /var/www/techstore
            docker compose pull
            docker compose up -d --remove-orphans
            docker image prune -f

```

---

## 5. BẢO TRÌ & GIÁM SÁT (MONITORING & LOGS)

* **Xem Log Backend Real-time trên Server:**
```bash
docker compose logs -f backend --tail=100

```


* **Kịch bản Backup Database tự động hàng ngày (Crontab):**
```bash
# Tạo file script backup database
0 2 * * * docker exec techstore-db mysqldump -u root -p'YOUR_PASSWORD' TechStore | gzip > /backups/techstore_$(date +\%Y\%m\%d).sql.gz

```



```

```