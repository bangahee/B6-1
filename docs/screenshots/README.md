# 증빙 스크린샷

AWS 실습 중 다음 스크린샷을 이 폴더에 저장한다. 비밀번호, MFA 코드, 키 파일, 전체 계정 ID 같은 민감 정보는 캡처하지 않는다.

- `01-ec2-running.png`: 서울 리전, EC2 Running, Public IPv4
- `02-route-table.png`: `0.0.0.0/0 → Internet Gateway`
- `03-security-group.png`: HTTP 80 공개, SSH 22 개인 IP `/32`
- `04-local-health.png`: EC2 내부 `GET /health → 200 OK`
- `05-external-health.png`: 외부 컴퓨터 `GET /health → 200 OK`
- `06-cleanup.png`: 실습 종료 후 리소스 정리 확인
- `07-billing.png`: 정리 후 Billing 확인(선택)

제출 전 README와 `docs/troubleshooting.md`, `docs/cleanup-checklist.md`의 해당 파일명을 실제 저장한 이름과 일치시킨다.
