//= require jquery
//= require cytoscape
//= require cytoscape-panzoom
//= require jscolor
//= require jquery.simplecolorpicker.js
//= require split
//= require markdown-it
//= require handlebars.runtime
//= require ../handlebars_helpers.js
//= require ../workflows.js
//= require_tree ../templates
//= require_self

function loadWorkflow(url) {
    $.getJSON(url, function (data) {
        console.log(data);
        Workflows.load(data.workflow_content, $('#cy'));
    });
}
