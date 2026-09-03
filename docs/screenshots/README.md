# 증빙 스크린샷

AWS 실습 중 다음 스크린샷을 이 폴더에 저장한다.

## 공개 저장소 업로드 전 개인정보 확인

다음 정보는 캡처에서 자르거나 가린다.

- AWS 12자리 Account ID와 Account alias
- Root 이메일, 개인 이메일, 전화번호와 결제 정보
- 비밀번호, MFA 코드, Access key와 Secret key
- `.pem` 파일의 내용과 로컬 파일 경로
- Terminal prompt에 표시되는 Mac 사용자 이름과 `<LOCAL_HOME>/...` 경로
- 과제 증빙에 필요하지 않은 IAM 사용자 이름 또는 개인 식별 정보

Public IPv4는 외부 접속 증빙에 필요하므로 해당 증빙에서는 표시할 수 있다. 가능하면 EC2와 관련 리소스를 삭제한 뒤, 더 이상 작동하지 않는 것을 확인하고 스크린샷을 GitHub에 업로드한다.

- `01-ec2-running.png`: 서울 리전, EC2 Running, Public IPv4
- `02-route-table.png`: `0.0.0.0/0 → Internet Gateway`
- `03-security-group.png`: HTTP 80 공개, SSH 22 개인 IP `/32`
- `04-local-health.png`: EC2 내부 `GET /health → 200 OK`
- `05-external-health.png`: 외부 컴퓨터 `GET /health → 200 OK`
- `06-cleanup.png`: 실습 종료 후 리소스 정리 확인
- `07-billing.png`: 정리 후 Billing 확인(선택)

제출 전 README와 `docs/troubleshooting.md`, `docs/cleanup-checklist.md`의 해당 파일명을 실제 저장한 이름과 일치시킨다.
