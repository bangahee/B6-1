import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'B6 Cloud Lab — Hello Cloud',
  description: 'AWS 서울 리전에 구축한 B6-1 클라우드 웹 서비스',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
