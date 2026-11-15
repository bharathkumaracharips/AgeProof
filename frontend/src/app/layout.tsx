import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ZK-Age | Privacy-Preserving Zero-Knowledge Age Verification",
  description: "Prove eligibility for age-restricted services without revealing an exact birth date using Groth16 and Poseidon Nullifiers on EVM",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="bg-slate-950 text-slate-100 antialiased selection:bg-purple-600 selection:text-white">
        <header className="border-b border-slate-800 bg-slate-900/60 backdrop-blur sticky top-0 z-50">
          <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-purple-600 to-indigo-500 flex items-center justify-center text-white font-black text-lg shadow-lg shadow-purple-500/20">
                ZK
              </div>
              <div>
                <span className="font-bold text-lg text-white tracking-tight">ZK-Age Protocol</span>
                <span className="ml-2 text-xs px-2 py-0.5 rounded-full bg-purple-500/10 text-purple-400 border border-purple-500/20 font-mono">
                  Groth16 • BN254
                </span>
              </div>
            </div>
            <div className="flex items-center space-x-6 text-sm font-medium text-slate-300">
              <a href="#prover" className="hover:text-purple-400 transition-colors">Holder Prover</a>
              <a href="#verifier" className="hover:text-purple-400 transition-colors">Verifier Portal</a>
              <a href="#issuer" className="hover:text-purple-400 transition-colors">Issuer Registry</a>
              <a href="#commitments" className="hover:text-purple-400 transition-colors">Merkle Tree</a>
            </div>
          </div>
        </header>
        <main>{children}</main>
        <footer className="border-t border-slate-800/80 py-8 text-center text-xs text-slate-500">
          ZK-Age Verification Protocol • Groth16 BN254 SNARKs • Scoped Poseidon Nullifiers • EVM Testnet
        </footer>
      </body>
    </html>
  );
}
