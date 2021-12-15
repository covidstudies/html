
$.ajax({
  url: "../json/visjs-studies_de.json",
  success: function (items) {
    // hide the "loading..." message
    document.getElementById("loading").style.display = "none";

    // DOM element where the Timeline will be attached
    var container = document.getElementById("visualization");

    var groups = new vis.DataSet([
      { id: 0, content: "Virus", value: 1 },
      { id: 1, content: "Vaccines", value: 2 },
      { id: 2, content: "Therapeutics", value: 3 },
      { id: 3, content: "Immunity", value: 4 },
    ]);

    var options = {
      // option groupOrder can be a property name or a sort function
      // the sort function must compare two groups and return a value
      //     > 0 when a > b
      //     < 0 when a < b
      //       0 when a == b
      groupOrder: function (a, b) {
        return a.value - b.value;
      },
      start: "2020-01-01",
      end: "2022-01-01",
      stack: false,
      cluster: true,
      editable: false,
    };

    var timeline = new vis.Timeline(container);
    timeline.setOptions(options);
    timeline.setGroups(groups);
    timeline.setItems(items);
  },
  error: function (err) {
    console.log("Error", err);
    if (err.status === 0) {
      alert(
        "Failed to load ../json/visjs-studies_de.json."
      );
    } else {
      alert("Failed to load ../json/visjs-studies_de.json.");
    }
  },
});

