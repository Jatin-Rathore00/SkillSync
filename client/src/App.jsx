import React, { useState, useEffect } from 'react';
import { Database, Server, Laptop, CheckCircle2, XCircle, RefreshCw, BookOpen, Layers, ShieldCheck, Zap } from 'lucide-react';
import api from './services/api';

export default function App() {
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchHealth = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get('/health');
      setHealth(res.data);
    } catch (err) {
      setError(err.message || 'Failed to reach Express backend');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealth();
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between selection:bg-indigo-500 selection:text-white">
      {/* Top Navigation Bar */}
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-violet-500 flex items-center justify-center shadow-lg shadow-indigo-500/20">
              <Zap className="w-5 h-5 text-white" />
            </div>
            <div>
              <span className="text-xl font-bold tracking-tight bg-gradient-to-r from-white via-slate-200 to-indigo-200 bg-clip-text text-transparent">
                SkillSync
              </span>
              <span className="hidden sm:inline-block ml-2 text-xs font-semibold px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                DBMS PBL Setup
              </span>
            </div>
          </div>
          <button 
            onClick={fetchHealth}
            disabled={loading}
            className="flex items-center space-x-2 text-xs font-medium px-3.5 py-2 rounded-lg bg-slate-800 hover:bg-slate-700/80 border border-slate-700 transition cursor-pointer disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
            <span>Probe Health</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-10 flex-1 w-full space-y-8">
        {/* Hero Section */}
        <div className="text-center max-w-3xl mx-auto space-y-3">
          <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/30 text-indigo-400 text-xs font-medium">
            <span>3rd Year DBMS Project-Based Learning</span>
            <span>•</span>
            <span>3-Person Team</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white">
            Campus Skill Exchange Platform
          </h1>
          <p className="text-slate-400 text-sm sm:text-base leading-relaxed">
            Initial full-stack setup initialized: React + Vite + Tailwind CSS frontend, Express.js REST API backend, and a 3NF normalized MySQL relational schema.
          </p>
        </div>

        {/* 3-Tier Architecture Health Check Status */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          {/* Frontend Card */}
          <div className="rounded-2xl bg-slate-900/50 border border-slate-800 p-6 space-y-4 hover:border-slate-700 transition">
            <div className="flex items-center justify-between">
              <div className="w-10 h-10 rounded-lg bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center">
                <Laptop className="w-5 h-5 text-cyan-400" />
              </div>
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                <CheckCircle2 className="w-3 h-3 mr-1" /> Ready
              </span>
            </div>
            <div>
              <h3 className="font-semibold text-white">Frontend Client</h3>
              <p className="text-xs text-slate-400 mt-1">React 19, Vite, Tailwind CSS</p>
            </div>
            <div className="pt-2 border-t border-slate-800 text-xs text-slate-400 space-y-1">
              <p>• Dev Port: <span className="text-slate-300 font-mono">5173</span></p>
              <p>• Axios Proxy: <span className="text-slate-300 font-mono">/api → :5000</span></p>
            </div>
          </div>

          {/* Backend Card */}
          <div className="rounded-2xl bg-slate-900/50 border border-slate-800 p-6 space-y-4 hover:border-slate-700 transition">
            <div className="flex items-center justify-between">
              <div className="w-10 h-10 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center">
                <Server className="w-5 h-5 text-indigo-400" />
              </div>
              {health ? (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  <CheckCircle2 className="w-3 h-3 mr-1" /> {health.status}
                </span>
              ) : (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
                  Checking...
                </span>
              )}
            </div>
            <div>
              <h3 className="font-semibold text-white">Express Backend</h3>
              <p className="text-xs text-slate-400 mt-1">Node.js, Express 4, REST API</p>
            </div>
            <div className="pt-2 border-t border-slate-800 text-xs text-slate-400 space-y-1">
              <p>• Port: <span className="text-slate-300 font-mono">5000</span></p>
              <p>• Endpoint: <span className="text-slate-300 font-mono">/api/health</span></p>
            </div>
          </div>

          {/* Database Card */}
          <div className="rounded-2xl bg-slate-900/50 border border-slate-800 p-6 space-y-4 hover:border-slate-700 transition">
            <div className="flex items-center justify-between">
              <div className="w-10 h-10 rounded-lg bg-violet-500/10 border border-violet-500/20 flex items-center justify-center">
                <Database className="w-5 h-5 text-violet-400" />
              </div>
              {health?.database?.status === 'CONNECTED' ? (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  <CheckCircle2 className="w-3 h-3 mr-1" /> Connected
                </span>
              ) : (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
                  Configuring...
                </span>
              )}
            </div>
            <div>
              <h3 className="font-semibold text-white">MySQL Database</h3>
              <p className="text-xs text-slate-400 mt-1">MySQL 8.0, 3NF Schema</p>
            </div>
            <div className="pt-2 border-t border-slate-800 text-xs text-slate-400 space-y-1">
              <p>• Schema: <span className="text-slate-300 font-mono">skillsync_db</span></p>
              <p>• Pool Driver: <span className="text-slate-300 font-mono">mysql2/promise</span></p>
            </div>
          </div>
        </div>

        {/* DBMS PBL Architectural Highlights */}
        <div className="rounded-2xl bg-slate-900/40 border border-slate-800/80 p-6 space-y-4">
          <div className="flex items-center space-x-2 text-white font-semibold">
            <Layers className="w-5 h-5 text-indigo-400" />
            <span>DBMS PBL Academic Implementations Ready in Database</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-xs">
            <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 space-y-2">
              <span className="font-semibold text-indigo-300 flex items-center space-x-1.5">
                <ShieldCheck className="w-4 h-4 text-indigo-400" />
                <span>3NF Relational Tables</span>
              </span>
              <p className="text-slate-400">
                8 distinct tables with primary/foreign keys, ON DELETE CASCADE/RESTRICT, and unique constraints.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 space-y-2">
              <span className="font-semibold text-emerald-300 flex items-center space-x-1.5">
                <Database className="w-4 h-4 text-emerald-400" />
                <span>Dynamic Aggregation</span>
              </span>
              <p className="text-slate-400">
                No redundant <code className="text-emerald-400">avg_rating</code> column in users table; dynamically computed from reviews via SQL view.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 space-y-2">
              <span className="font-semibold text-cyan-300 flex items-center space-x-1.5">
                <Zap className="w-4 h-4 text-cyan-400" />
                <span>Mutual 2-Way Match View</span>
              </span>
              <p className="text-slate-400">
                Self-relational multi-join view matching Student A & B where offered and wanted skills intersect bidirectionally.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 space-y-2">
              <span className="font-semibold text-amber-300 flex items-center space-x-1.5">
                <BookOpen className="w-4 h-4 text-amber-400" />
                <span>Triggers & Transactions</span>
              </span>
              <p className="text-slate-400">
                Integrity validation triggers and ACID session scheduling stored procedure with <code className="text-amber-400">FOR UPDATE</code>.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800/80 py-4 bg-slate-900/30 text-center text-xs text-slate-500">
        SkillSync • DBMS Course Project-Based Learning • Initial Setup Complete
      </footer>
    </div>
  );
}
