import { useCallback, useEffect } from 'react'
import {
  ReactFlow,
  useNodesState,
  useEdgesState,
  addEdge,
  Background,
  Controls,
} from '@xyflow/react'

import type { Connection } from '@xyflow/react'

const initialNodes: any[] = []
const initialEdges: any[] = []

export function TopologyPanel() {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges)

  const onConnect = useCallback(
    (params: Connection) => setEdges((eds) => addEdge(params, eds)),
    [setEdges],
  )

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [nodesRes, relsRes] = await Promise.all([
          fetch('http://localhost:8000/state/nodes'),
          fetch('http://localhost:8000/state/relations')
        ])

        const nodesData = await nodesRes.json()
        const relsData = await relsRes.json()

        const flowNodes = Object.entries(nodesData || {}).map(([urn, node]: [string, any], index) => ({
          id: urn,
          data: { label: node.type_id + '\n' + urn.split(':').pop() },
          position: { x: (index % 5) * 200, y: Math.floor(index / 5) * 100 },
          style: { 
            background: node.type_id === 'kernel' ? '#2f855a' : '#2d3748',
            color: 'white',
            borderRadius: '8px',
            fontSize: '10px',
            width: 150,
          }
        }))

        const flowEdges = (relsData || []).map((rel: any) => ({
          id: rel.rel_urn,
          source: rel.src_urn,
          target: rel.tgt_urn,
          label: rel.rewrite_category,
          animated: true,
          style: { stroke: '#4a5568' }
        }))

        setNodes(flowNodes)
        setEdges(flowEdges)
      } catch (err) {
        console.error('Failed to fetch topology:', err)
      }
    }

    fetchData()
    const interval = setInterval(fetchData, 5000)
    return () => clearInterval(interval)
  }, [setNodes, setEdges])

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        fitView
      >
        <Background color="#2d3440" gap={16} />
        <Controls />
      </ReactFlow>
    </div>
  )
}
