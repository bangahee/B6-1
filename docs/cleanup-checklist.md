# 리소스 정리 체크리스트

- 정리 일시: `[YYYY-MM-DD HH:MM KST]`
- 리전: `ap-northeast-2`

- [ ] EC2 `cloud-lab-web`가 Terminated 상태다.
- [ ] 남아 있는 EBS Volume이 없다.
- [ ] Elastic IP를 만들지 않았거나 Release했다.
- [ ] NAT Gateway가 없다.
- [ ] ELB/ALB가 없다.
- [ ] RDS가 없다.
- [ ] 사용자 정의 Security Group을 삭제했다.
- [ ] 사용자 정의 Public Route Table을 삭제했다.
- [ ] Internet Gateway를 Detach하고 삭제했다.
- [ ] Public Subnet을 삭제했다.
- [ ] `cloud-lab-vpc`를 삭제했다.
- [ ] 불필요한 Key Pair를 삭제했다.
- [ ] Billing Dashboard를 확인했다.

## 정리 근거

- EC2/EBS 리소스 목록: `docs/screenshots/[파일명]`
- VPC 리소스 목록: `docs/screenshots/[파일명]`
- Billing 확인 화면: `docs/screenshots/[파일명]`
