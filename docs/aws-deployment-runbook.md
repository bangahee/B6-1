# AWS 배포 실행서

> 현재 상태: 준비 완료 / 실행 보류  
> 실행 조건: Billing → Credits에서 사용 가능한 크레딧을 확인한 뒤 진행한다.

이 문서는 서울 리전에서 과제 요구사항에 맞는 최소 구성을 만드는 순서와 각 단계의 증빙 항목을 정리한다. 생성하는 모든 리소스에는 `Project=B6-1` 태그를 사용한다.

## 0. 배포 전 확인

- [ ] 루트 계정이 아닌 실습용 IAM 사용자로 로그인했다.
- [ ] 리전이 `Asia Pacific (Seoul) / ap-northeast-2`다.
- [ ] Billing → Credits에 사용 가능한 크레딧이 표시된다.
- [ ] Zero spend budget과 Free Tier usage alerts가 활성화되어 있다.
- [ ] 로컬에서 `npm run verify:ec2`가 성공한다.
- [ ] 현재 공인 IPv4를 확인해 SSH 규칙에 사용할 `/32` 값을 준비했다.

## 1. IAM 최소 권한

1. IAM에서 `<IAM_USER_NAME>` 사용자를 만든다.
2. 콘솔 접근을 활성화하고 MFA를 등록한다.
3. `AdministratorAccess`를 연결하지 않는다.
4. [`../infra/iam-policy.json`](../infra/iam-policy.json)의 사용자 정의 정책만 연결한다.
5. 이후 인프라 생성과 삭제는 이 사용자로 수행한다.

증빙 권장: 사용자 이름, MFA 상태, 연결된 사용자 정의 정책이 보이는 화면. 비밀번호, 키, 계정 식별자는 캡처에서 제외한다.

## 2. VPC와 Public Subnet

### VPC

| 항목 | 값 |
|---|---|
| Name | `cloud-lab-vpc` |
| IPv4 CIDR | `10.0.0.0/16` |
| DNS resolution | Enabled |
| DNS hostnames | Enabled |

### Public Subnet

| 항목 | 값 |
|---|---|
| Name | `cloud-lab-public-subnet` |
| VPC | `cloud-lab-vpc` |
| IPv4 CIDR | `10.0.1.0/24` |
| Auto-assign public IPv4 | Enabled |

## 3. Internet Gateway와 Route Table

1. `cloud-lab-igw`를 만들고 `cloud-lab-vpc`에 연결한다.
2. `cloud-lab-public-rt`를 `cloud-lab-vpc`에 만든다.
3. Route에 `0.0.0.0/0 → cloud-lab-igw`를 추가한다.
4. `cloud-lab-public-subnet`을 이 Route Table에 명시적으로 연결한다.

확인할 트래픽 경로:

```text
Internet → Internet Gateway → 0.0.0.0/0 Route → Public Subnet → Security Group → EC2/Nginx
```

## 4. Security Group

`cloud-lab-web-sg`를 `cloud-lab-vpc`에 만든다.

| Type | Protocol | Port | Source |
|---|---|---:|---|
| HTTP | TCP | 80 | `0.0.0.0/0` |
| SSH | TCP | 22 | 현재 학습자 공인 IP `/32` |

- 전체 포트 허용 규칙을 만들지 않는다.
- SSH Source에 `0.0.0.0/0`을 사용하지 않는다.
- IPv6를 사용하지 않는다면 `::/0` HTTP 규칙도 만들 필요가 없다.

## 5. EC2

| 항목 | 값 |
|---|---|
| Name | `cloud-lab-web` |
| AMI | Ubuntu Server 24.04 LTS |
| Instance type | 콘솔에서 Free Tier 대상으로 표시되는 micro 유형 |
| Key pair | `cloud-lab-key` / `.pem` |
| VPC | `cloud-lab-vpc` |
| Subnet | `cloud-lab-public-subnet` |
| Auto-assign public IP | Enabled |
| Security Group | `cloud-lab-web-sg` |
| EBS | General Purpose SSD, 8 GiB, Delete on termination |

Elastic IP, NAT Gateway, Load Balancer, RDS는 이 과제에 필요하지 않으므로 만들지 않는다.

키 파일을 다운로드한 직후 권한을 제한한다.

```bash
chmod 400 /path/to/cloud-lab-key.pem
```

## 6. 배포

인스턴스가 Running이고 Status checks가 통과한 뒤 실행한다.

```bash
./scripts/deploy-ec2.sh /path/to/cloud-lab-key.pem PUBLIC_IP
```

이 스크립트는 정적 사이트를 빌드하고, EC2에 Nginx를 설치하고, `/var/www/b6-cloud`에 사이트를 배포한 뒤 인스턴스 내부의 `/health`를 검사한다.

## 7. 필수 검증과 증빙

### 인스턴스 내부

```bash
curl -i http://localhost/health
curl -I https://example.com
systemctl is-active nginx
```

기대 결과:

- `/health`: `HTTP 200`, 본문 `OK`
- 외부 통신: 응답 헤더 수신
- Nginx: `active`

### 외부 컴퓨터

```bash
curl -i --connect-timeout 10 http://PUBLIC_IP/health
```

기대 결과는 `HTTP 200`과 본문 `OK`다. 다음 화면을 `docs/screenshots/`에 저장한다.

- [ ] EC2 Running, Public IPv4, 서울 리전
- [ ] Route Table의 `0.0.0.0/0 → IGW`
- [ ] Security Group의 HTTP와 제한된 SSH 규칙
- [ ] 인스턴스 내부 `curl http://localhost/health`
- [ ] 외부 `curl http://PUBLIC_IP/health`

그 후 README의 Public IP, 검증 일시, 결과를 실제 값으로 교체하고 [`troubleshooting.md`](troubleshooting.md)를 실제 발생 내용으로 완성한다.

## 8. 정리

제출 증빙을 모두 저장한 뒤 [`cleanup-checklist.md`](cleanup-checklist.md)의 순서로 리소스를 삭제한다. EC2를 단순히 Stop하는 것으로 끝내지 않고 Terminate와 EBS 삭제 여부를 확인한다.
