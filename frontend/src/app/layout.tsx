import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "LocalLens - Intelligent Local Discovery",
  description: "Intelligent Local Discovery & Experience Platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
