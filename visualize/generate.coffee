{spawn} = require 'child_process'
fs = require 'fs'

{tests, applyOps} = require '../test/types/tree'


writeState = (state, stream) ->
  stream.write 'digraph img {'
  stream.write 'graph [fontsize=10 fontname="Verdana"];'
  stream.write 'rankdir=TB;'
  stream.write 'size="4,4";'
  stream.write 'node [style=filled color="#ccff33"];'
  for node in state
    if -1 == node.parent
      stream.write "\"#{node.value}\";"
    else
      stream.write "\"#{state[node.parent].value}\" -> \"#{node.value}\";"
  stream.write '}'
  do stream.end

createImage = (name, state) ->
  dot = spawn('dot', ['-Tpng'])
  fstream = fs.createWriteStream(name)
  dot.stdout.pipe fstream
  writeState state, dot.stdin

createDiagramSet = (name, info, i) -> 
  {init, client1, server1, client2} = applyOps info[1], info[2], info[3]
  createImage 'images/' + name + '-A.png', init
  createImage 'images/' + name + '-B.png', client1
  createImage 'images/' + name + '-C.png', server1
  createImage 'images/' + name + '-D.png', client2
  "images/#{name}-#{letter}.png" for letter in ['A', 'B', 'C', 'D']

createHTML = (name, info, i) ->
  imgNames = createDiagramSet name, info, i
  html = fs.createWriteStream(name + '.html')
  html.end """
            <!DOCTYPE html>
            <html>
              <head>
                <title>#{name}</title>
              </head>
              <body>
                <table>
                  <tr><th colspan="3"></th></tr>
                  <tr><td><img src="#{imgNames[0]}" /></td>
                      <td><img src="images/right-arrow.png" /></td>
                      <td><img src="#{imgNames[1]}" /></td>
                  </tr>
                  <tr><td align="center" ><img src="images/down-arrow.png" /></td>
                      <td></td>
                      <td align="center" ><img src="images/down-arrow.png" /></td>
                  </tr>
                  <tr><td><img src="#{imgNames[2]}" /></td>
                      <td><img src="images/right-arrow.png" /></td>
                      <td><img src="#{imgNames[3]}" /></td>
                  </tr>
                </table>
              </body>
            </html>
            """
  

createTOC = (docs) ->
  html = fs.createWriteStream('index.html')
  html.write """
             <!DOCTYPE html>
             <html>
               <head>
                 <title>Diagram Table of Contents</title>
               </head>
               <body>
                 <table>
             """
  for _, group of docs
    for args, num in group
      name = (((args[0].substr 0, (args[0].indexOf ')'))
        .replace '(', '-')
        .replace ', ', '-') + '-' + num
      html.write "<tr><td><a href=\"#{name}.html\">#{name}</a></td><td>#{args[0]}</td></tr>"
      createHTML name, args, num
  html.end   """
                 </table>
               </body>
             </html>
             """
createTOC tests
