# 1. Build Stage (빌드 단계)
FROM node:18-alpine AS builder

WORKDIR /app

# 패키지 파일 복사 (package-lock.json이 없어도 에러나지 않도록 와일드카드 사용)
COPY package*.json ./

# 의존성 설치
RUN npm install

# 소스 코드 복사
COPY . .

# 프로덕션 빌드 실행 (dist 폴더 생성)
RUN npm run build

# 2. Production Stage (실행 단계 - Nginx)
FROM nginx:alpine

# 빌드 단계에서 생성된 dist 폴더의 내용을 Nginx의 웹 루트로 복사
COPY --from=builder /app/dist /usr/share/nginx/html

# 80번 포트 노출
EXPOSE 80

# Nginx 실행
CMD ["nginx", "-g", "daemon off;"]
