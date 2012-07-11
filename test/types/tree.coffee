tree = require '../../src/types/tree'

state = [ { parent: -1, value: 'root', chi: [1,2,3] },
          { parent: 0, value: 'a', chi: [] },
          { parent: 0, value: 'b', chi: [] },
          { parent: 0, value: 'c', chi: [] },
          { parent: -1, value: 'x', chi: [] },
          { parent: -1, value: 'y', chi: [] } ]

unwrapState = [ { parent: -1, value: 'root', chi: [3,4] },
                { parent: 4, value: 'a', chi: [] },
                { parent: 5, value: 'b', chi: [] },
                { parent: 0, value: 'c', chi: [] },
                { parent: 0, value: 'x', chi: [1,5] },
                { parent: 4, value: 'y', chi: [2] } ]

triang = [ { parent: 2, value: 'A', chi: [1] }
         { parent: 0, value: 'B', chi: [2] }
         { parent: 1, value: 'C', chi: [0] } ]

circ = [ { parent: 1, value: 'A', chi: [1,2] }
         { parent: 0, value: 'B', chi: [0,3] }
         { parent: 0, value: 'C', chi: [] }
         { parent: 1, value: 'D', chi: [] } ]

twistedPair = [ { parent: 1, value: 'A', chi: [1] }
                { parent: 0, value: 'B', chi: [0, 2] }
                { parent: 1, value: 'c', chi: [] } ]

wrapUnwrapState = [ { parent: -1, value: 'root', chi: [3,4] },
                    { parent: 4, value: 'a', chi: [] },
                    { parent: 4, value: 'b', chi: [] },
                    { parent: 0, value: 'c', chi: [] },
                    { parent: 0, value: 'x', chi: [1,2] },
                    { parent: -1, value: 'y', chi: [] } ]

## Wrap

module.exports = {
  applyOps: (state, cop, sop) ->
    server = JSON.parse JSON.stringify state
    client = JSON.parse JSON.stringify state
    cop1 = []
    tree.append cop1, c for c in cop
    sop1 = []
    tree.append sop1, c for c in sop
    server1 = tree.apply server, sop1
    client1 = tree.apply client, cop1
    cop2 = tree.transform sop1, cop1, 'right'
    sop2 = tree.transform cop1, sop1, 'left'
    try
      server2 = tree.apply server1, sop2
    catch e
      console.log server1
      console.log sop1
      console.log sop2
      se = e
      server2 = []
    try
      client2 = tree.apply client1, cop2
    catch e
      console.log client1
      console.log cop1
      console.log cop2
      ce = e
      client2 = []

    { init: state
    client1: client1, client2: client2
    server1: server1, server2: server2, ce: ce, se: se }
  tests:
    "T(Wrap, Wrap)": [
      [ "T(Wrap, Wrap) same op.", state
        [ { wrap: 4, par: 0, chi: [1], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [1], seq: 6 } ]
        [-1, 4, 0, 0, 0, -1] ]

      [ "T(Wrap, Wrap) same target, same parent, diff children.", state
        [ { wrap: 4, par: 0, chi: [1], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [2], seq: 6 } ]
        [-1, 4, 4, 0, 0, -1] ]

      [ "T(Wrap, Wrap) same target, diff parent.", state
        [ { wrap: 4, par: 1, chi: [], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [2], seq: 6 } ]
        [-1, 0, 0, 0, 1, -1] ]

      [ "T(Wrap, Wrap) same target, diff parent.", state
        [ { wrap: 4, par: 0, chi: [2], seq: 6 } ]
        [ { wrap: 4, par: 1, chi: [], seq: 6 } ]
        [-1, 0, 4, 0, 0, -1] ]

      [ "T(Wrap, Wrap) diff target, diff parent.", state
        [ { wrap: 5, par: 1, chi: [], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [2], seq: 6 } ]
        [-1, 0, 4, 0, 0, 1] ]

      [ "T(Wrap, Wrap) diff target, same parent children subset.", state
        [ { wrap: 5, par: 0, chi: [1,2], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [2], seq: 6 } ]
        [-1, 5, 4, 0, 5, 0] ]

      [ "T(Wrap, Wrap) diff target, same parent children subset.", state
        [ { wrap: 5, par: 0, chi: [1], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [1,2], seq: 6 } ]
        [-1, 5, 4, 0, 0, 4] ]

      [ "T(Wrap, Wrap) diff target, same parent children disjoint.", state
        [ { wrap: 5, par: 0, chi: [1], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [2], seq: 6 } ]
        [-1, 5, 4, 0, 0, 0] ]

      [ "T(Wrap, Wrap) diff target, same parent children intersect.", state
        [ { wrap: 5, par: 0, chi: [1,2], seq: 6 } ]
        [ { wrap: 4, par: 0, chi: [2,3], seq: 6 } ]
        [-1, 5, 6, 4, 0, 0, 5] ]

      [ "T(Wrap, Wrap) circular ref.", state
        [ { wrap: 5, par: 4, chi: [], seq: 6 } ]
        [ { wrap: 4, par: 5, chi: [], seq: 6 } ]
        [-1, 0, 0, 0, 5, 4] ]

    ]
    "T(Unwrap, Unwrap)": [

      [ "T(Unwrap, Unwrap) same target, same children.", unwrapState,
        [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
        [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
        [-1, 0, 5, 0, -1, 4] ]

      [ "T(Unwrap, Unwrap) same target, diff children.", unwrapState,
        [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
        [ { unwrap: 4, par: 0, chi: [5], seq: 6 } ],
        [-1, 0, 5, 0, -1, 0] ]

      [ "T(Unwrap, Unwrap) disjoint ops.", unwrapState,
        [ { unwrap: 3, par: 0, chi: [], seq: 6 } ],
        [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
        [-1, 4, 4, -1, 0, -1] ]

      [ "T(Unwrap, Unwrap) nested targets.", unwrapState,
        [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
        [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
        [-1, 0, 4, 0, -1, -1] ]

      [ "T(Unwrap, Unwrap) nested targets.", unwrapState,
        [ { unwrap: 4, par: 0, chi: [1,5], seq: 6 } ],
        [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
        [-1, 0, 0, 0, -1, -1] ]

      [ "T(Unwrap, Unwrap) nested targets.", unwrapState,
        [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
        [ { unwrap: 4, par: 0, chi: [1,5], seq: 6 } ],
        [-1, 0, 0, 0, -1, -1] ]

      [ "T(Unwrap, Unwrap) circular target.", triang,
        [ { unwrap: 0, par: 2, chi: [1], seq: 4 } ],
        [ { unwrap: 1, par: 0, chi: [2], seq: 4 } ],
        [-1, -1, 2 ] ]

      [ "T(Unwrap, Unwrap) circular target.", triang,
        [ { unwrap: 0, par: 2, chi: [], seq: 4 } ],
        [ { unwrap: 1, par: 0, chi: [], seq: 4 } ],
        [-1, -1, 1 ] ]

      [ "T(Unwrap, Unwrap) circular target.", circ,
        [ { unwrap: 0, par: 1, chi: [], seq: 4 } ],
        [ { unwrap: 1, par: 0, chi: [], seq: 4 } ],
        [-1, -1, 0, 1] ]

      [ "T(Unwrap, Unwrap) circular target.", circ,
        [ { unwrap: 0, par: 1, chi: [2], seq: 4 } ],
        [ { unwrap: 1, par: 0, chi: [3], seq: 4 } ],
        [-1, -1, 1, 0] ]

      [ "T(Unwrap, Unwrap) twisted pair.", twistedPair
        [ { unwrap: 0, par: 1, chi: [1], seq: 3 } ]
        [ { unwrap: 1, par: 0, chi: [0, 2], seq: 3 } ]
        [-1, -1, 0] ]
    ]
    "T(Create, Create)": [

      [ "T(Create, Create) nested targets.", state,
        [ { cn: 6, value: 'hello' },
          { cn: 7, value: 'bye bye' }
        ],
        [ { cn: 6, value: 'Help!' },
          { cn: 7, value: 'I am stuck in a testing factory.' }
        ],
        [-1, 0, 0, 0, -1, -1, -1, -1, -1, -1] ]

      [ "T(Create, Create) nested targets.", state,
        [ { cn: 6, value: 'hello' },
          { cn: 7, value: 'bye bye' },
          { wrap: 7, par: 6, chi: [], seq: 8 }
        ],
        [ { cn: 6, value: 'Help!' },
          { wrap: 6, par: 0, chi: [1,2], seq: 7 }
          { cn: 7, value: 'I am stuck in a testing factory.' },
          { wrap: 7, par: 6, chi: [2], seq: 8 }
        ],
        [-1, 6, 7, 0, -1, -1, 0, 6, -1, 8] ]
    ]

    "T(Wrap, Unwrap)": [
      [ "T(Unwrap, Wrap) Chained. Wrap below.", wrapUnwrapState,
        [ { wrap: 5, par: 4, chi: [1], seq: 6 } ]
        [ { unwrap: 4, par: 0, chi: [], seq: 6 } ]
        [-1, 5, 4, 0, -1, 0] ]

      [ "T(Unwrap, Wrap) Chained. Wrap above.", wrapUnwrapState,
        [ { wrap: 5, par: 0, chi: [4,3], seq: 6 } ]
        [ { unwrap: 4, par: 0, chi: [1,2], seq: 6 } ]
        [-1, 5, 5, 5, -1, 0] ]
      [ "T(Unwrap, Wrap) Self-Help Loop?.", [ { parent: 0, value: 'A', chi: [0] }, { parent: -1, value: 'B', chi: [] } ]
        [ { unwrap: 0, par: 0, chi: [0], seq: 6 } ]
        [ { wrap: 1, par: 0, chi: [0], seq: 6 } ]
        [1, 0] ]
      [ "T(Unwrap, Wrap) Self-Help Loop?.", [ { parent: 1, value: 'A', chi: [1] }, { parent: 0, value: 'B', chi: [0] }, { parent: -1, value: 'C', chi: [] } ]
        [ { unwrap: 0, par: 1, chi: [1], seq: 6 } ]
        [ { wrap: 2, par: 1, chi: [0], seq: 6 } ]
        [-1, 2, 1] ]

      [ "T(Unwrap, Wrap) Self-Help Loop?.", [ { parent: 1, value: 'A', chi: [1] }, { parent: 0, value: 'B', chi: [0] } ]
        [ { unwrap: 1, par: 0, chi: [ 0 ], seq: 6 } ]
        [ { unwrap: 0, par: 1, chi: [  ], seq: 7 } ]
        [-1, -1] ]
    ]
}

