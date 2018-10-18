function init(){
  var $ = go.GraphObject.make;

  var myDiagram =
    $(go.Diagram, "fullDiagram",
      {
        initialContentAlignment: go.Spot.Top, // center Diagram contents
        "undoManager.isEnabled": true, // enable Ctrl-Z to undo and Ctrl-Y to redo
        isReadOnly: true,
        layout: $(go.TreeLayout, // specify a Diagram.layout that arranges trees
                  { angle: 90, layerSpacing: 35 })
      });

  // the template we defined earlier
  myDiagram.nodeTemplate =
    $(go.Node, "Horizontal",
      { background: "#44CCFF" },
      $(go.TextBlock, "Default Text",
        { margin: 12, stroke: "white", font: "bold 16px sans-serif" },
        new go.Binding("text", "email"))
    );

  // define a Link template that routes orthogonally, with no arrowhead
  myDiagram.linkTemplate =
    $(go.Link,
      { routing: go.Link.Orthogonal, corner: 5 },
      $(go.Shape, { strokeWidth: 3, stroke: "#555" })); // the link shape

  var model = $(go.TreeModel);
  model.nodeDataArray = gon.source
  myDiagram.model = model;
}