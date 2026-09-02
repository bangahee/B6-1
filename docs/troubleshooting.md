# 트러블슈팅 보고서

> AWS 실습 중 실제 발생한 내용으로 대괄호 부분을 교체한다.

## 사례 1: 외부 `/health` 요청 타임아웃

### 증상

- 발생 시각: `[YYYY-MM-DD HH:MM KST]`
- 외부 컴퓨터에서 `http://[PUBLIC_IP]/health` 호출 시 타임아웃이 발생했다.

### 원인 가설

1. Nginx가 실행되지 않았을 수 있다.
2. Security Group에서 TCP/80이 허용되지 않았을 수 있다.
3. Public Route Table에 Internet Gateway 경로가 없을 수 있다.
4. EC2 인스턴스에 Public IPv4가 없을 수 있다.

### 검증

EC2 내부에서 다음 명령을 실행했다.

```bash
systemctl is-active nginx
curl -i http://localhost/health
```

- Nginx 상태: `[active/inactive]`
- localhost 응답: `[결과]`
- Public IPv4: `[있음/없음]`
- Route Table `0.0.0.0/0 → IGW`: `[있음/없음]`
- Security Group TCP/80 규칙: `[있음/없음]`

### 확인된 원인

`[검증으로 확인한 실제 원인]`

### 조치

`[실제로 변경한 설정 또는 실행한 명령]`

### 결과

외부에서 다시 호출한 결과 `[HTTP 상태와 응답 내용]`을 확인했다.

### 재발 방지

- 배포 전에 Public IPv4, Route Table, Security Group을 체크리스트로 확인한다.
- `localhost` 검증 후 외부 네트워크에서 `/health`를 검증한다.

### 증빙

- 장애 화면: `docs/screenshots/[파일명]`
- 해결 화면: `docs/screenshots/[파일명]`
