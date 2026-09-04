# 트러블슈팅 보고서

## 사례 1: 외부 `/health` 요청이 404를 반환함

### 증상

- 발생 시각: `2026-09-04 16:06 KST`
- Mac에서 `http://13.209.99.107/health`를 호출했을 때 연결은 성공했지만 `HTTP/1.1 404 Not Found`가 반환됐다.
- 응답의 `Server` 헤더는 `nginx/1.24.0 (Ubuntu)`였다.

### 원인 가설

1. Nginx가 아직 기본 사이트 설정을 사용하고 있을 수 있다.
2. `/health` 파일이 배포 경로에 복사되지 않았을 수 있다.
3. 새 Nginx 설정 파일의 문법이 잘못됐을 수 있다.
4. Security Group 또는 Route Table 설정이 잘못됐을 수 있다.

### 검증

외부 요청에서 Nginx가 생성한 404 응답을 받았으므로 Public IPv4, Internet Gateway 경로와 Security Group의 TCP/80 통신은 정상이라고 판단했다. SSH로 EC2에 접속한 뒤 다음 명령을 실행했다.

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -i http://localhost/health
```

- `sudo nginx -t`: 설정 문법 정상
- 설정 reload 후 localhost 응답: `HTTP/1.1 200 OK`, 본문 `OK`
- Public Route Table: `0.0.0.0/0 → Internet Gateway`, `Active`
- Security Group: HTTP 80은 `0.0.0.0/0`, SSH 22는 개인 IP `/32`

### 확인된 원인

배포 스크립트가 사용자 정의 사이트 설정을 설치한 뒤 `systemctl enable --now nginx`만 실행했다. 패키지 설치 과정에서 Nginx가 이미 기본 설정으로 시작된 경우 `enable --now`는 실행 중인 프로세스에 새 설정을 다시 읽게 하지 않는다. 따라서 외부 요청이 이전 설정으로 처리되어 `/health`가 404를 반환했다.

### 조치

설정 문법을 검사한 뒤 Nginx를 reload했다.

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 결과

- EC2 내부 검증: `2026-09-04 16:07 KST`, `HTTP/1.1 200 OK`, 본문 `OK`
- 외부 Mac 검증: `2026-09-04 16:08 KST`, `HTTP/1.1 200 OK`, 본문 `OK`

### 재발 방지

- 배포 스크립트에서 설정 파일을 설치한 뒤 `sudo nginx -t`와 `sudo systemctl reload nginx`를 항상 실행한다.
- 배포 완료 조건에 localhost `/health`와 외부 `/health` 검증을 모두 포함한다.
- 404처럼 웹 서버가 직접 반환한 응답과 네트워크 타임아웃을 구분해 조사한다.

### 증빙

- 내부 해결 확인: [`screenshots/04-local-health.png`](screenshots/04-local-health.png)
- 외부 해결 확인: [`screenshots/05-external-health.png`](screenshots/05-external-health.png)
- Route Table 확인: [`screenshots/02-route-table.png`](screenshots/02-route-table.png)
- Security Group 확인: [`screenshots/03-security-group.png`](screenshots/03-security-group.png)
