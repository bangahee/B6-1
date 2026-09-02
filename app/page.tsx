const services = [
  { label: 'Region', value: 'Seoul', detail: 'ap-northeast-2' },
  { label: 'Network', value: 'Public', detail: '10.0.1.0/24' },
  { label: 'Web server', value: 'Nginx', detail: 'HTTP :80' },
];

export default function Home() {
  return (
    <main>
      <header className="site-header">
        <a className="brand" href="#top" aria-label="B6-1 Cloud 홈">
          <span className="brand-mark">B6</span>
          <span>Cloud Lab</span>
        </a>
        <nav aria-label="주요 메뉴">
          <a href="#architecture">Architecture</a>
          <a href="#status">Status</a>
        </nav>
      </header>

      <section className="hero" id="top">
        <div className="eyebrow"><span /> Built in Seoul · B6-1</div>
        <h1>
          Hello Cloud.<br />
          <em>인터넷에 연결되었습니다.</em>
        </h1>
        <p className="hero-copy">
          격리된 VPC에서 시작해 퍼블릭 서브넷, 보안 그룹, EC2까지.
          직접 설계하고 배포한 첫 번째 클라우드 웹 서비스입니다.
        </p>
        <div className="hero-actions">
          <a className="primary-action" href="/health">Health check <span>↗</span></a>
          <a className="text-action" href="#architecture">구성 살펴보기 <span>↓</span></a>
        </div>
      </section>

      <section className="service-grid" id="status" aria-label="서비스 정보">
        {services.map((service) => (
          <article className="service-card" key={service.label}>
            <p>{service.label}</p>
            <strong>{service.value}</strong>
            <span>{service.detail}</span>
          </article>
        ))}
        <article className="service-card status-card">
          <p>Service status</p>
          <strong><i /> Online</strong>
          <span>GET /health → 200 OK</span>
        </article>
      </section>

      <section className="architecture" id="architecture">
        <div className="section-heading">
          <p>01 / Infrastructure</p>
          <h2>요청이 서버에 도착하기까지</h2>
          <span>최소한의 구성으로 명확한 트래픽 경로를 만들었습니다.</span>
        </div>

        <div className="network-panel">
          <div className="network-label">HTTP request · TCP/80</div>
          <div className="network-flow" aria-label="Internet에서 EC2까지의 네트워크 흐름">
            <div className="flow-node external">
              <small>01</small>
              <b>Internet</b>
              <span>External user</span>
            </div>
            <div className="flow-line"><span>→</span></div>
            <div className="flow-node gateway">
              <small>02</small>
              <b>Gateway</b>
              <span>cloud-lab-igw</span>
            </div>
            <div className="flow-line"><span>→</span></div>
            <div className="flow-node server">
              <small>03</small>
              <b>EC2 + Nginx</b>
              <span>Security Group · :80</span>
            </div>
          </div>
          <div className="vpc-caption">
            <span>VPC 10.0.0.0/16</span>
            <span>Route 0.0.0.0/0 → IGW</span>
          </div>
        </div>
      </section>

      <footer>
        <span>B6-1 · AWS Cloud Fundamentals</span>
        <span>Seoul, KR · 2026</span>
      </footer>
    </main>
  );
}
