export function TimelinePanel() {
  const steps = [
    { t: '159', label: 'Foundation', status: 'completed' },
    { t: '160', label: 'HDC Gate', status: 'completed' },
    { t: '162', label: 'Federation Seed', status: 'completed' },
    { t: '169', label: 'Menno Demo', status: 'in_progress' },
    { t: '180', label: 'Operad Final', status: 'planned' },
  ]

  return (
    <div style={{ width: '100%', height: '100%', padding: '40px 20px', boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative' }}>
        {/* Connector Line */}
        <div style={{ position: 'absolute', top: '15px', left: '20px', right: '20px', height: '2px', background: '#2d3440', zIndex: 0 }} />
        
        {steps.map((s, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', zIndex: 1, flex: 1 }}>
            <div style={{ 
              width: '32px', 
              height: '32px', 
              borderRadius: '50%', 
              background: s.status === 'completed' ? '#38a169' : s.status === 'in_progress' ? '#d69e2e' : '#2d3440',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '10px',
              border: '4px solid #0d0f14',
              color: 'white',
              fontSize: '10px',
              fontWeight: 'bold'
            }}>
              T{s.t}
            </div>
            <div style={{ color: s.status === 'planned' ? '#4a5568' : '#e2e8f0', fontSize: '11px', fontWeight: '500' }}>
              {s.label}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
