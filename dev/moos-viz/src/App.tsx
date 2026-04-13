import { Share2, Layers, Activity, Zap } from 'lucide-react'
import { TopologyPanel } from './components/TopologyPanel'
import { ClassificationPanel } from './components/ClassificationPanel'
import { TimelinePanel } from './components/TimelinePanel'
import { MetricPanel } from './components/MetricPanel'
import '@xyflow/react/dist/style.css'
import './index.css'

function App() {
  return (
    <div className="dashboard-container">
      <div className="panel">
        <div className="panel-header">
          <Share2 size={16} style={{ marginRight: '8px' }} />
          Federation Topology
        </div>
        <div className="panel-content">
          <TopologyPanel />
        </div>
      </div>

      <div className="panel">
        <div className="panel-header">
          <Layers size={16} style={{ marginRight: '8px' }} />
          Classification Space
        </div>
        <div className="panel-content">
           <ClassificationPanel />
        </div>
      </div>

      <div className="panel">
        <div className="panel-header">
          <Activity size={16} style={{ marginRight: '8px' }} />
          Temporal DAG
        </div>
        <div className="panel-content">
           <TimelinePanel />
        </div>
      </div>

      <div className="panel">
        <div className="panel-header">
          <Zap size={16} style={{ marginRight: '8px' }} />
          Value Attribution
        </div>
        <div className="panel-content">
           <MetricPanel />
        </div>
      </div>
    </div>
  )
}

export default App
