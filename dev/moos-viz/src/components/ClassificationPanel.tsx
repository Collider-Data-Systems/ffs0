import { Zap } from 'lucide-react'

export function ClassificationPanel() {
  // Mock data for PCA投影 (HDC vectors)
  const schemes = [
    { name: 'arXiv', x: 200, y: 150, color: '#9f7aea' },
    { name: 'IFRS', x: 450, y: 300, color: '#9f7aea' },
    { name: 'LCC', x: 150, y: 350, color: '#f6ad55' },
    { name: 'ISO', x: 500, y: 100, color: '#48bb78' },
  ]

  return (
    <div style={{ width: '100%', height: '100%', padding: '20px', boxSizing: 'border-box' }}>
      <svg width="100%" height="100%" viewBox="0 0 600 500">
        {/* Axes */}
        <line x1="50" y1="450" x2="550" y2="450" stroke="#2d3440" />
        <line x1="50" y1="50" x2="50" y2="450" stroke="#2d3440" />
        
        {/* Scheme Nodes */}
        {schemes.map((s, i) => (
          <g key={i}>
            <circle cx={s.x} cy={s.y} r="12" fill={s.color} opacity="0.6" />
            <circle cx={s.x} cy={s.y} r="4" fill={s.color} />
            <text x={s.x + 15} y={s.y + 5} fill="#a0aec0" fontSize="12" fontWeight="500">{s.name}</text>
          </g>
        ))}

        {/* Crosswalk Arrows (Residuals) */}
        <path d="M 212 150 L 438 300" stroke="#4a5568" strokeDasharray="4 4" fill="none" />
        <text x="325" y="210" fill="#718096" fontSize="10" transform="rotate(33 325, 210)">ι₄₃: 0.12</text>
      </svg>

      <div style={{ position: 'absolute', bottom: '15px', right: '15px', color: '#4a5568', fontSize: '10px' }}>
        PCA projection (Dim: 256 → 2)
      </div>
    </div>
  )
}
