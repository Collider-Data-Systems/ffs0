export function MetricPanel() {
  const types = [
    { type: 'user', value: 85, color: '#4299e1' },
    { type: 'kernel', value: 72, color: '#48bb78' },
    { type: 'scheme', value: 45, color: '#9f7aea' },
    { type: 'tag', value: 30, color: '#f6ad55' },
    { type: 'operad', value: 15, color: '#f56565' },
  ]

  return (
    <div style={{ width: '100%', height: '100%', padding: '20px', boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
        {types.map((t, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: '5px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: '#a0aec0' }}>
              <span>{t.type}</span>
              <span>{t.value}%</span>
            </div>
            <div style={{ width: '100%', height: '8px', background: '#1a202c', borderRadius: '4px', overflow: 'hidden' }}>
              <div style={{ width: `${t.value}%`, height: '100%', background: t.color, borderRadius: '4px' }} />
            </div>
          </div>
        ))}
      </div>
      
      <div style={{ marginTop: '20px', padding: '10px', background: '#1a202c', borderRadius: '4px', fontSize: '11px', color: '#718096', border: '1px solid #2d3748' }}>
        <strong>Shapley Proxy:</strong> Contribution defined by type-graph spectral density.
      </div>
    </div>
  )
}
