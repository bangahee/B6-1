# AWS 배포 실행서

> 현재 상태: 준비 완료 / 실행 보류  
> 실행 조건: Billing → Credits에서 사용 가능한 크레딧을 확인한 뒤 진행한다.

이 문서는 AWS를 처음 사용하는 사람도 서울 리전에서 과제 요구사항에 맞는 최소 구성을 만들고, 웹사이트를 배포하고, 증빙을 저장한 뒤, 과금이 남지 않도록 리소스를 삭제할 수 있게 안내한다. 생성하는 모든 리소스에는 `Project=B6-1` 태그를 사용한다.

AWS 콘솔의 메뉴 이름은 계정 언어 또는 UI 업데이트에 따라 조금 달라질 수 있다. 이 문서에서는 찾기 쉽도록 주요 메뉴의 영문 이름을 함께 적는다.

## 먼저 이해할 구성 요소

| 구성 요소 | 이 프로젝트에서 하는 일 | 쉬운 비유 |
|---|---|---|
| VPC | 프로젝트 전용 네트워크 범위를 만든다. | 건물이 들어갈 부지 |
| Public Subnet | 인터넷에 연결될 EC2가 위치하는 구역이다. | 건물 안의 공개 구역 |
| Internet Gateway | VPC와 인터넷 사이의 출입구다. | 건물의 정문 |
| Route Table | 트래픽을 어느 방향으로 보낼지 결정한다. | 도로 표지판 |
| Security Group | EC2에 들어올 수 있는 포트와 출발지를 제한한다. | 서버 앞의 방화벽 |
| EC2 | Nginx와 웹사이트가 실행되는 가상 컴퓨터다. | 웹 서버 컴퓨터 |
| EBS | EC2의 운영체제와 파일을 저장하는 디스크다. | 컴퓨터의 SSD |
| IAM 사용자 | 허용된 AWS 작업만 수행하는 로그인 사용자다. | 제한된 직원 출입증 |

외부 사용자의 요청은 다음 순서로 이동한다.

```text
Internet
  → Internet Gateway
  → Route Table의 0.0.0.0/0 경로
  → Public Subnet
  → Security Group의 HTTP 80 허용 규칙
  → EC2의 Nginx
```

Internet Gateway만 연결했다고 웹사이트가 공개되는 것은 아니다. Route Table, Public IPv4, Security Group, Nginx가 모두 올바르게 설정되어야 한다.

## 콘솔 화면을 따라 하는 상세 절차

### A. 시작 전 확인

1. AWS 콘솔 오른쪽 위에서 로그인 사용자가 `<IAM_USER_NAME>`인지 확인한다.
2. `root`로 로그인되어 있으면 로그아웃하고 IAM 사용자로 다시 로그인한다.
3. 오른쪽 위 Region 메뉴에서 **Asia Pacific (Seoul) / `ap-northeast-2`**를 선택한다.
4. Billing에서 크레딧, Zero spend budget, Free Tier usage alerts, 현재 청구액을 확인한다.
5. Mac의 Terminal에서 로컬 빌드를 확인한다.

```bash
cd <PROJECT_DIRECTORY>
npm run verify:ec2
```

마지막에 다음 결과가 나오면 로컬 배포 파일이 준비된 것이다.

```text
Home page: OK
Health endpoint: 200 OK (OK)
EC2 static package: READY (out/)
```

IAM과 Billing은 전역 서비스이므로 URL에 `us-east-1`이 보일 수 있다. VPC와 EC2 화면에서 Seoul이 선택되어 있는지가 중요하다. 최소 권한 정책 때문에 EC2 Dashboard 일부 위젯에 `Access denied`가 보일 수 있지만 `Instances`와 `Key Pairs` 작업 화면이 열리면 이 과제에는 문제가 없다.

현재 공인 IP도 준비한다.

```bash
curl https://checkip.amazonaws.com
```

예를 들어 `203.0.113.10`이 출력되면 SSH Source에는 `203.0.113.10/32`를 입력한다. `/32`는 그 IP 하나만 허용한다는 뜻이다. 네트워크나 VPN을 바꾸면 IP도 바뀔 수 있다.

### B. VPC 만들기

1. AWS 상단 검색창에서 **VPC** 서비스를 연다.
2. Region이 Seoul인지 다시 확인한다.
3. 왼쪽 메뉴에서 **Your VPCs**를 선택한다.
4. **Create VPC**를 누른다.
5. Resources to create에서 반드시 **VPC only**를 선택한다.
   - `VPC and more`는 선택하지 않는다. NAT Gateway 같은 불필요한 유료 리소스가 만들어질 수 있다.
6. 다음 값을 입력한다.

| 화면 항목 | 값 |
|---|---|
| Name tag | `cloud-lab-vpc` |
| IPv4 CIDR manual input | `10.0.0.0/16` |
| IPv6 CIDR block | No IPv6 CIDR block |
| Tenancy | Default |

7. Tags에 `Project = B6-1`을 추가한다.
8. **Create VPC**를 누른다.
9. 생성한 VPC를 선택하고 **Actions → Edit VPC settings**를 연다.
10. **Enable DNS resolution**과 **Enable DNS hostnames**를 활성화하고 저장한다.

성공 기준:

- State가 `Available`이다.
- IPv4 CIDR이 `10.0.0.0/16`이다.
- default VPC가 아니라 `cloud-lab-vpc`를 보고 있다.

### C. Public Subnet 만들기

1. VPC 왼쪽 메뉴에서 **Subnets**를 선택한다.
2. **Create subnet**을 누른다.
3. VPC ID에서 `cloud-lab-vpc`를 선택한다.
4. 다음 값을 입력한다.

| 화면 항목 | 값 |
|---|---|
| Subnet name | `cloud-lab-public-subnet` |
| Availability Zone | No preference 또는 서울 AZ 하나 |
| IPv4 subnet CIDR block | `10.0.1.0/24` |

5. `Project = B6-1` 태그를 추가하고 생성한다.
6. 생성한 Subnet을 선택한다.
7. **Actions → Edit subnet settings**를 연다.
8. **Enable auto-assign public IPv4 address**를 체크하고 저장한다.

성공 기준:

- VPC가 `cloud-lab-vpc`다.
- IPv4 CIDR이 `10.0.1.0/24`다.
- Auto-assign public IPv4가 `Yes`다.

### D. Internet Gateway 만들기

1. VPC 왼쪽 메뉴에서 **Internet gateways**를 선택한다.
2. **Create internet gateway**를 누른다.
3. Name tag에 `cloud-lab-igw`를 입력한다.
4. `Project = B6-1` 태그를 추가하고 생성한다.
5. 생성 완료 화면에서 **Attach to a VPC**를 누른다.
   - 버튼이 없으면 Gateway를 선택한 뒤 **Actions → Attach to VPC**를 누른다.
6. `cloud-lab-vpc`를 선택하고 연결한다.

성공 기준은 State가 `Attached`이고 연결된 VPC가 `cloud-lab-vpc`인 것이다.

### E. Public Route Table 만들기

1. VPC 왼쪽 메뉴에서 **Route tables**를 선택한다.
2. **Create route table**을 누른다.
3. Name에 `cloud-lab-public-rt`를 입력한다.
4. VPC에서 `cloud-lab-vpc`를 선택한다.
5. `Project = B6-1` 태그를 추가하고 생성한다.
6. 생성한 Route Table의 **Routes** 탭을 연다.
7. **Edit routes → Add route**를 누른다.
8. Destination에 `0.0.0.0/0`을 입력한다.
9. Target에서 **Internet Gateway → `cloud-lab-igw`**를 선택하고 저장한다.
10. **Subnet associations** 탭을 연다.
11. **Edit subnet associations**를 누른다.
12. `cloud-lab-public-subnet`을 체크하고 저장한다.

`10.0.0.0/16 → local`은 AWS가 만든 내부 통신 경로이므로 삭제하지 않는다.

성공 기준:

- `10.0.0.0/16 → local`이 있다.
- `0.0.0.0/0 → cloud-lab-igw`가 있다.
- Explicit subnet associations에 `cloud-lab-public-subnet`이 있다.

이 화면은 `docs/screenshots/02-route-table.png`로 저장할 증빙 후보이다.

### F. Security Group 만들기

1. AWS 검색창에서 **EC2** 서비스를 연다.
2. Region이 Seoul인지 확인한다.
3. 왼쪽 메뉴에서 **Network & Security → Security Groups**를 연다.
4. **Create security group**을 누른다.
5. 다음 값을 입력한다.

| 화면 항목 | 값 |
|---|---|
| Security group name | `cloud-lab-web-sg` |
| Description | `HTTP and restricted SSH for B6-1` |
| VPC | `cloud-lab-vpc` |

6. Inbound rules에 다음 두 규칙만 만든다.

| Type | Port | Source |
|---|---:|---|
| HTTP | 80 | Anywhere-IPv4 `0.0.0.0/0` |
| SSH | 22 | My IP 또는 현재 IP `/32` |

7. Outbound rules는 기본값인 **All traffic → `0.0.0.0/0`**을 유지한다. EC2가 Nginx를 다운로드하려면 아웃바운드 통신이 필요하다.
8. `Project = B6-1` 태그를 추가하고 생성한다.

다음 규칙은 만들지 않는다.

- SSH 22 → `0.0.0.0/0`
- All traffic 또는 All TCP → `0.0.0.0/0`
- IPv6를 사용하지 않는데 추가하는 `::/0`

Inbound rules 화면은 `docs/screenshots/03-security-group.png`로 저장한다.

### G. Key Pair 만들기

1. EC2 왼쪽 메뉴에서 **Network & Security → Key Pairs**를 연다.
2. **Create key pair**를 누른다.
3. 다음 값을 선택한다.

| 화면 항목 | 값 |
|---|---|
| Name | `cloud-lab-key` |
| Key pair type | RSA |
| Private key file format | `.pem` |

4. 생성하면 `cloud-lab-key.pem`이 한 번만 다운로드된다.
5. Mac Terminal에서 키 권한을 제한한다.

```bash
chmod 400 ~/Downloads/cloud-lab-key.pem
```

실제 저장 위치가 다르면 경로를 바꾼다. `.pem`을 GitHub, 프로젝트 폴더, 메시지 또는 스크린샷에 노출하지 않는다.

### H. EC2 인스턴스 만들기

이 단계부터 EC2, EBS, Public IPv4 비용이 발생할 수 있다. 배포와 증빙을 끝낼 시간이 충분할 때 시작한다.

1. EC2 왼쪽 메뉴에서 **Instances**를 연다.
2. **Launch instances**를 누른다.
3. Name에 `cloud-lab-web`을 입력하고 `Project = B6-1` 태그를 추가한다.
4. Application and OS Images에서 **Ubuntu Server 24.04 LTS**를 선택한다.
   - 가능하면 Canonical 공식 AMI인지 확인한다.
   - 별도 요금이 표시되는 Marketplace AMI는 선택하지 않는다.
5. Instance type에서 micro 유형을 선택한다. 과제 권장값은 `t3.micro`다.
6. Key pair에서 `cloud-lab-key`를 선택한다.
7. Network settings에서 **Edit**를 누르고 다음을 선택한다.

| 화면 항목 | 값 |
|---|---|
| VPC | `cloud-lab-vpc` |
| Subnet | `cloud-lab-public-subnet` |
| Auto-assign public IP | Enable |
| Firewall | Select existing security group |
| Common security groups | `cloud-lab-web-sg` |

8. Configure storage에서 Root volume을 `8 GiB`, `gp3`로 설정한다.
9. Advanced를 펼칠 수 있으면 **Delete on termination = Yes**인지 확인한다.
10. 추가 EBS 볼륨은 만들지 않는다.
11. Summary에서 인스턴스 수가 1인지 확인한다.
12. **Launch instance**를 한 번만 누른다.

Default VPC 또는 default security group을 실수로 선택하지 않았는지 Launch 전에 다시 확인한다.

생성 후:

1. **View all instances**를 누른다.
2. `cloud-lab-web`을 선택한다.
3. Instance state가 `Running`이고 Status check가 `2/2 checks passed`가 될 때까지 기다린다.
4. Details의 Public IPv4 address를 복사한다.
5. Storage 탭에서 Root volume의 **Delete on termination = Yes**를 다시 확인한다.

### I. 웹사이트 자동 배포

EC2가 준비된 뒤 Mac Terminal에서 실행한다.

```bash
cd <PROJECT_DIRECTORY>
./scripts/deploy-ec2.sh ~/Downloads/cloud-lab-key.pem 실제_PUBLIC_IP
```

예를 들어 AWS가 `203.0.113.25`를 표시했다면 다음과 같이 실행한다.

```bash
./scripts/deploy-ec2.sh ~/Downloads/cloud-lab-key.pem 203.0.113.25
```

예시 IP를 그대로 사용하지 않는다. 처음 연결할 때 SSH가 서버 fingerprint 확인을 요청하면 IP가 본인의 EC2인지 확인한 뒤 `yes`를 입력한다.

스크립트는 다음 작업을 자동으로 수행한다.

1. Next.js 정적 사이트를 `out/`에 빌드한다.
2. 사이트와 Nginx 설정을 EC2에 업로드한다.
3. Ubuntu 패키지를 업데이트하고 Nginx를 설치한다.
4. 사이트를 `/var/www/b6-cloud/`에 배치한다.
5. Nginx 설정을 검사하고 실행한다.
6. EC2 내부 `/health`를 검사한다.

### J. 외부와 내부에서 검증

Mac에서 외부 접속을 확인한다.

```bash
curl -i --connect-timeout 10 http://실제_PUBLIC_IP/health
```

`HTTP/1.1 200 OK`와 본문 `OK`가 보여야 한다. 브라우저에서도 `http://실제_PUBLIC_IP`를 연다. 기본 과제는 HTTPS를 설정하지 않으므로 `https://`가 아니다.

EC2 내부 검증은 다음과 같이 한다.

```bash
ssh -i ~/Downloads/cloud-lab-key.pem ubuntu@실제_PUBLIC_IP
curl -i http://localhost/health
curl -I https://example.com
systemctl is-active nginx
exit
```

기대 결과:

- `/health`: HTTP 200과 `OK`
- `example.com`: 응답 헤더 표시
- Nginx: `active`

### K. 증빙을 먼저 저장하기

EC2를 삭제하기 전에 다음 화면을 저장한다.

| 파일명 | 반드시 보여야 하는 내용 |
|---|---|
| `01-ec2-running.png` | Seoul, EC2 이름, Running, Public IPv4 |
| `02-route-table.png` | `0.0.0.0/0 → Internet Gateway`와 Subnet 연결 |
| `03-security-group.png` | HTTP 80 공개, SSH 22 내 IP `/32` |
| `04-local-health.png` | EC2 내부 `/health`의 200/OK |
| `05-external-health.png` | 외부 브라우저 또는 Mac의 200/OK |

스크린샷은 `docs/screenshots/`에 저장한다. 계정 ID, 이메일, 전화번호, 비밀번호와 `.pem` 키 내용은 캡처하지 않는다.

README에 검증 방식, 당시 URL/IP, 검증 일시(KST), 응답 결과를 기록한다. 실제로 발생한 오류 한 건은 `docs/troubleshooting.md`에 기록한다. 오류를 제출용으로 일부러 만들거나 없는 일을 꾸미지 않는다.

리소스를 삭제하면 Public IP는 더 이상 작동하지 않는다. 다음처럼 삭제 사실도 함께 기록한다.

```text
2026-09-04 15:30 KST에 http://203.0.113.25/health로 외부 접속을 검증했고
HTTP 200 및 OK 응답을 확인했다. 증빙 저장 후 과금 방지를 위해 AWS 리소스를 삭제했다.
```

### L. 자주 발생하는 문제

#### SSH 연결 시간이 초과됨

다음을 순서대로 확인한다.

1. Security Group에 SSH 22 규칙이 있는가?
2. SSH Source의 `/32`가 현재 공인 IP와 같은가?
3. EC2에 Public IPv4가 있는가?
4. Subnet이 `cloud-lab-public-rt`와 연결되어 있는가?
5. Route Table에 `0.0.0.0/0 → cloud-lab-igw`가 있는가?

#### `Permission denied (publickey)`

- `-i` 뒤의 `.pem` 경로가 정확한지 확인한다.
- Ubuntu 로그인 사용자는 `ubuntu`다.
- `chmod 400`을 실행했는지 확인한다.
- 인스턴스에서 선택한 Key Pair와 다운로드한 키가 같은지 확인한다.

#### EC2 내부는 성공하지만 외부 접속은 실패함

Nginx보다 Security Group, Public IP, Route Table 또는 Internet Gateway 문제일 가능성이 크다. HTTP 80 규칙부터 트래픽 경로의 역순으로 확인한다.

#### `Host key verification failed`

문제의 IP가 새로 만든 본인의 EC2인지 먼저 확인한 후 다음을 실행한다.

```bash
ssh-keygen -R 실제_PUBLIC_IP
```

### M. 증빙 후 즉시 삭제하기

1. EC2 → Instances에서 `cloud-lab-web`을 선택한다.
2. **Instance state → Terminate (delete) instance**를 선택한다.
3. `Terminated`가 될 때까지 확인한다. Stop으로 끝내지 않는다.
4. EC2 → **Elastic Block Store → Volumes**에서 8 GiB 볼륨이 사라졌는지 확인한다.
5. Snapshots에 직접 만든 프로젝트 스냅샷이 없는지 확인한다.
6. Elastic IP addresses, NAT gateways, Load Balancers, RDS Databases가 없는지 확인한다.
7. EC2 네트워크 인터페이스가 정리될 때까지 몇 분 기다린다.
8. `cloud-lab-web-sg`를 삭제한다.
9. `cloud-lab-public-rt`의 Subnet association을 해제하고 Route Table을 삭제한다.
10. `cloud-lab-igw`를 VPC에서 Detach한 후 삭제한다.
11. `cloud-lab-public-subnet`을 삭제한다.
12. `cloud-lab-vpc`를 삭제한다.
13. EC2 Key Pairs에서 `cloud-lab-key`를 삭제한다.
14. Billing Dashboard를 확인하고 다음 날 다시 확인한다.

AWS가 VPC와 함께 자동 생성한 main route table, default network ACL, default security group은 VPC를 삭제하면 함께 정리된다. 별도로 지우려고 할 필요가 없다.

---

# 빠른 실행 체크리스트

위 상세 절차를 한 번 이해한 뒤에는 아래 요약 목록을 보면서 빠르게 진행한다.

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

## 공식 AWS 참고 문서

- [VPC 만들기](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html)
- [Subnet 만들기](https://docs.aws.amazon.com/vpc/latest/userguide/create-subnets.html)
- [Internet Gateway로 인터넷 연결](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html)
- [Route Table 구성](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html)
- [EC2 Security Group 규칙](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/changing-security-group.html)
- [EC2 시작 설정 항목](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-launch-parameters.html)
- [EC2 종료와 EBS 삭제 동작](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/how-instance-termination-works.html)
