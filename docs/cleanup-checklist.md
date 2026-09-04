# 리소스 정리 체크리스트

- 정리 일시: `2026-09-04 16:50 KST`
- 리전: `ap-northeast-2`

- [x] EC2 `cloud-lab-web`가 Terminated 상태다.
- [x] 남아 있는 EBS Volume과 직접 생성한 Snapshot이 없다.
- [x] Elastic IP를 생성하지 않았고, EC2의 자동 Public IPv4는 Terminate 후 반환됐다.
- [x] NAT Gateway를 생성하지 않았다.
- [x] ELB/ALB를 생성하지 않았다.
- [x] RDS를 생성하지 않았다.
- [x] 사용자 정의 Security Group `cloud-lab-web-sg`를 삭제했다.
- [x] 사용자 정의 Public Route Table `cloud-lab-public-rt`를 삭제했다.
- [x] Internet Gateway `cloud-lab-igw`를 Detach한 뒤 삭제했다.
- [x] Public Subnet `cloud-lab-public-subnet`을 삭제했다.
- [x] `cloud-lab-vpc`를 삭제했다.
- [x] Key Pair `cloud-lab-key`를 삭제했다.
- [x] Billing에서 현재 월 예상 청구액 `USD 0.00`을 확인했다.

정리 후 서울 리전에서 EBS Volume, Snapshot, Elastic IP, NAT Gateway, Network Interface와 Key Pair가 각각 0개임을 확인했다. 사용자 정의 VPC 관련 리소스는 모두 사라졌고 AWS 기본 VPC, 기본 Subnet, main Route Table, 기본 Security Group과 기본 Internet Gateway만 남아 있다. 기본 리소스는 삭제하지 않았다.

## 정리 근거

- 배포 당시 EC2 상태: [`screenshots/01-ec2-running.png`](screenshots/01-ec2-running.png)
- 사용자 정의 VPC 삭제 확인: [`screenshots/06-cleanup.png`](screenshots/06-cleanup.png)
- 정리 직후 Billing 확인: [`screenshots/07-billing.png`](screenshots/07-billing.png)

Billing 데이터는 지연 반영될 수 있으므로 다음 날 같은 Billing period를 다시 확인한다.
