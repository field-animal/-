# BizCheck 배포 가이드

이 문서는 **BizCheck** 애플리케이션을 일반 웹 서버(Node.js 환경) 또는 Docker를 사용하여 배포하는 방법을 설명합니다.

이 프로젝트는 **React + TypeScript + Vite** 기반으로 구성되어 있습니다.

---

## 1. 사전 준비 사항

*   **Node.js**: v18.0.0 이상 (npm 포함)
*   **Docker** (Docker 배포 시 필요)

---

## 2. 일반 웹 서버(Node.js) 배포 절차

이 방법은 서버에 Node.js가 설치되어 있을 때 사용합니다.

### 2.1 의존성 설치
터미널에서 프로젝트 루트 경로로 이동하여 패키지를 설치합니다.

```bash
npm install
```

### 2.2 개발 모드 실행 (테스트용)
로컬에서 바로 실행하여 테스트할 때 사용합니다.

```bash
npm run dev
```

### 2.3 프로덕션 빌드
웹 서버에 배포할 정적 파일(HTML, CSS, JS)을 생성합니다.

```bash
npm run build
```
빌드가 완료되면 프로젝트 루트에 `dist` 폴더가 생성됩니다.

### 2.4 웹 서버 실행
생성된 `dist` 폴더의 내용을 Nginx, Apache 등의 웹 서버 루트에 업로드하거나, 간단하게 Node.js 기반의 정적 서버를 띄울 수 있습니다.

**`serve` 패키지 이용 예시:**
```bash
npx serve -s dist -l 3000
```
이제 브라우저에서 `http://localhost:3000`으로 접속할 수 있습니다.

---

## 3. Docker 배포 절차

Docker를 이용하면 환경 설정 없이 컨테이너 기반으로 쉽게 배포할 수 있습니다. Nginx를 포함한 경량 이미지를 생성합니다.

### 3.1 Dockerfile 작성
프로젝트 루트에 `Dockerfile`이 없다면 아래 내용으로 생성합니다. (이미 포함되어 있다면 건너뜁니다.)

```dockerfile
# 1. Build Stage
FROM node:18-alpine as builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# 2. Production Stage (Nginx)
FROM nginx:alpine
# 빌드된 결과물을 Nginx html 경로로 복사
COPY --from=builder /app/dist /usr/share/nginx/html
# 기본 Nginx 설정 사용 (SPA 라우팅 필요 시 설정 커스텀 필요)
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 3.2 Docker 이미지 빌드
아래 명령어로 도커 이미지를 생성합니다. (`bizcheck-app`은 이미지 이름입니다.)

```bash
docker build -t bizcheck-app .
```

### 3.3 Docker 컨테이너 실행
빌드된 이미지를 기반으로 컨테이너를 실행합니다. 호스트의 8080 포트를 컨테이너의 80 포트에 연결합니다.

```bash
docker run -d -p 8080:80 --name bizcheck-container bizcheck-app
```

### 3.4 접속 확인
브라우저를 열고 다음 주소로 접속합니다.
*   `http://localhost:8080` (로컬 실행 시)
*   `http://<서버_IP>:8080` (서버 실행 시)

---

## 4. 문제 해결

### API 400 Bad Request 에러
*   **원인:** 서비스 키 인코딩 문제
*   **해결:** 입력 폼에 제공된 **Decoding Key**(일반적으로 `/`, `+` 등이 포함됨) 혹은 **Encoding Key**(%가 포함됨)를 그대로 입력하세요. 애플리케이션이 자동으로 감지하여 처리합니다.

### CORS 에러
*   이 앱은 클라이언트(브라우저)에서 국세청 API(`api.odcloud.kr`)를 직접 호출합니다.
*   로컬 개발 환경(`localhost`)에서는 API 서버의 CORS 정책에 따라 호출이 허용되지만, **특정 도메인이나 IP로 배포된 서버**에서는 CORS 에러가 발생할 수 있습니다.
*   **해결 방법:** Nginx 등의 웹 서버에서 Proxy 설정을 하거나, 별도의 백엔드 중계 서버를 구축해야 할 수 있습니다. (공공데이터포털 API는 일반적으로 `localhost` 외의 호출에 대해 관대하지만, 정책 확인이 필요합니다.)
