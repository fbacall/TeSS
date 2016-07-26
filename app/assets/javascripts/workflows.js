$(document).ready(function () {
    var wfJsonElement = $('#workflow-content-json');
    var cytoscapeElement = $('#cy');
    var editable = cytoscapeElement.data('editable');

    if (wfJsonElement.length && cytoscapeElement.length) {
        var cy = window.cy = cytoscape({
            container: cytoscapeElement[0],
            elements: JSON.parse(wfJsonElement.html()),
            layout: {
                name: 'preset',
                padding: 20
            },
            style: [
                {
                    selector: 'node',
                    css: {
                        'shape': 'roundrectangle',
                        'content': 'data(name)',
                        'background-color': function (ele) {
                            return (typeof ele.data('color') === 'undefined') ? "#F0721E" : ele.data('color')
                        },
                        'color': function (ele) {
                            return (typeof ele.data('font_color') === 'undefined') ? "#000000" : ele.data('font_color')
                        },
                        'background-opacity': 0.8,
                        'text-valign': 'center',
                        'text-halign': 'center',
                        'width': '150px',
                        'height': '30px',
                        'font-size': '9px',
                        'border-width': '1px',
                        'border-color': '#000',
                        'border-opacity': 0.5,
                        'text-wrap': 'wrap',
                        'text-max-width': '130px'
                    }
                },
                {
                    selector: '$node > node',
                    css: {
                        'shape': 'roundrectangle',
                        'padding-top': '10px',
                        'font-weight': 'bold',
                        'padding-left': '10px',
                        'padding-bottom': '10px',
                        'padding-right': '10px',
                        'text-valign': 'top',
                        'text-halign': 'center',
                        'width': 'auto',
                        'height': 'auto',
                        'font-size': '9px'
                    }
                },
                {
                    selector: 'edge',
                    css: {
                        'target-arrow-shape': 'triangle',
                        'content': 'data(name)',
                        'line-color': '#ccc',
                        'source-arrow-color': '#ccc',
                        'target-arrow-color': '#ccc',
                        'font-size': '9px',
                        'curve-style': 'bezier'
                    }
                },
                {
                    selector: ':selected',
                    css: {
                        'line-color': '#2A62E4',
                        'target-arrow-color': '#2A62E4',
                        'source-arrow-color': '#2A62E4',
                        'border-width': '2px',
                        'border-color': '#2A62E4',
                        'border-opacity': 1,
                        'background-blacken': '-0.1'
                    }
                }
            ],
            userZoomingEnabled: false,
            autolock: !editable
        });

        if (editable) {
            $('#workflow-toolbar-add').click(function () {
                $('#node-modal-form-type').val('standard');
                Workflows.setAddNodeState();
                return false;
            });
            $('#workflow-toolbar-link-workflow').click(function () {
                $('#node-modal-form-type').val('workflow-link');
                Workflows.setAddNodeState();
                return false;
            });
            $('#workflow-toolbar-cancel').click(Workflows.cancelState);
            $('#workflow-toolbar-edit').click(Workflows.edit);
            $('#workflow-toolbar-link').click(Workflows.setLinkNodeState);
            $('#workflow-toolbar-undo').click(Workflows.history.undo);
            $('#workflow-toolbar-redo').click(Workflows.history.redo);
            $('#workflow-toolbar-add-child').click(Workflows.addChild);
            $('#workflow-toolbar-delete').click(Workflows.delete);
            $('#node-modal-form-confirm').click(Workflows.nodeModalConfirm);
            $('#edge-modal-form-confirm').click(Workflows.edgeModalConfirm);
            $('.node-modal-add-resource-btn').click(Workflows.associatedResources.add);
            $('#node-modal').on('click', '.delete-associated-resource', Workflows.associatedResources.delete);
            cy.on('tap', Workflows.handleClick);
            cy.on('select', function (e) {
                if (Workflows.state !== 'adding node') {
                    Workflows.select(e.cyTarget);
                }
            });
            cy.on('unselect', Workflows.cancelState);
            cy.on('drag', function () {
                Workflows._dragged = true;
            });
            cy.on('free', function () {
                if (Workflows._dragged) {
                    Workflows.history.modify('move node');
                    Workflows._dragged = false;
                }
            });

            $('#node-modal').on('hide.bs.modal', Workflows.cancelState);
            $('#edge-modal').on('hide.bs.modal', Workflows.cancelState);

            // Update JSON in form
            $('#workflow-form-submit').click(function () {
                $('#workflow_workflow_content').val(JSON.stringify(cy.json()['elements']));

                return true;
            });

            cy.$(':selected').unselect();
            Workflows.cancelState();
            Workflows.history.initialize();
            jscolor.installByClassName('jscolor');
        } else {
            Workflows.sidebar.init();
            cy.on('select', Workflows.sidebar.populate);
            cy.on('unselect', Workflows.sidebar.clear);
            cy.$(':selected').unselect();
        }

        cy.panzoom();
        var defaultZoom = cy.maxZoom();
        cy.maxZoom(2); // Temporary limit the zoom level, to restrict how zoomed-in the diagram appears by default
        cy.fit(50); // Fit diagram to screen with some padding around the edges
        cy.maxZoom(defaultZoom); // Reset the zoom limit to allow user to further zoom if they wish
    }
});

var Workflows = {
    handleClick: function (e) {
        if (Workflows.state === 'adding node') {
            Workflows.placeNode(e.cyPosition);
        } else if (Workflows.state === 'linking node') {
            if (e.cyTarget !== cy && e.cyTarget.isNode()) {
                Workflows.createLink(e);
            }
        }
    },

    setState: function (state, message) {
        Workflows.state = state;
        $('#workflow-status-message').html(message);
        var button = $('#workflow-toolbar-cancel');
        button.find('span').html('Cancel ' + state);
        button.show();
    },

    cancelState: function () {
        Workflows.state = '';

        if (Workflows.selected) {
            Workflows.selected.unselect();
            Workflows.selected = null;
        }

        $('#workflow-status-message').html('');
        $('#workflow-status-selected-node').html('<span class="muted">nothing</span>');
        $('#workflow-status-bar').find('.node-context-button').hide();
        $('#workflow-toolbar-cancel').hide();
    },

    select: function (target) {
        if (target.isNode()) {
            Workflows.selected = target;
            Workflows.setState('node selection');
            $('#workflow-status-bar').find('.node-context-button').show();
            $('#workflow-status-selected-node').html(Workflows.selected.data('name'));
        } else if (target.isEdge()) {
            Workflows.selected = target;
            Workflows.setState('edge selection');
            $('#workflow-status-bar').find('.edge-context-button').show();
            $('#workflow-status-selected-node').html(Workflows.selected.data('name') + ' (edge)');
        }
    },

    setAddNodeState: function () {
        Workflows.cancelState();
        Workflows.setState('adding node', 'Click on the diagram to add a new node.');
    },

    placeNode: function (position, parentId) {
        $('#node-modal-title').html(parentId ? 'Add child node' : 'Add node');
        $('#node-modal').modal('show');
        var type = $('#node-modal-form-type').val();
        $('.node-modal-variable-fields').hide();
        $('#node-modal-' + type + '-fields').show();

        $('#node-modal-form-id').val('');
        $('#node-modal-form-title').val('');
        $('#node-modal-form-description').val('');
        $('#node-modal-form-workflow').val('');
        $('#node-modal-form-colour').val('#F0721E')[0].jscolor.fromString('#F0721E');
        $('#node-modal-form-parent-id').val(parentId);
        $('#node-modal-form-x').val(position.x);
        // Offset child nodes a bit so they don't stack on top of each other...
        var y = position.y;
        if (parentId && Workflows.selected.children().length > 0)
            y = Workflows.selected.children().last().position().y + 40;
        $('#node-modal-form-y').val(y);
    },

    addNode: function () {
        var object = {
            group: 'nodes',
            data: {
                type: $('#node-modal-form-type').val(),
                name: $('#node-modal-form-title').val(),
                description: $('#node-modal-form-description').val(),
                color: $('#node-modal-form-colour').val(),
                font_color: $('#node-modal-form-colour').css("color"),
                parent: $('#node-modal-form-parent-id').val(),
                associatedResources: Workflows.associatedResources.fetch(),
                workflowPath: $('#node-modal-form-workflow').val()
            },
            position: {
                x: parseInt($('#node-modal-form-x').val()),
                y: parseInt($('#node-modal-form-y').val())
            },
            css: {
                color: $('#node-modal-form-colour').css("color")
            }
        };

        $('#node-modal').modal('hide');

        Workflows.history.modify(object.data.parent ? 'add child node' : 'add node', function () {
            cy.add(object).select();
        });
    },

    addChild: function () {
        Workflows.placeNode(Workflows.selected.position(), Workflows.selected.id());
    },

    edit: function () {
        var data;
        if (Workflows.state === 'node selection') {
            data = Workflows.selected.data();
            var position = Workflows.selected.position();
            $('#node-modal-title').html('Edit node');
            $('#node-modal').modal('show');
            var type = data.type || 'standard';
            $('#node-modal-form-type').val(type);
            $('.node-modal-variable-fields').hide();
            $('#node-modal-' + type + '-fields').show();

            $('#node-modal-form-id').val(data.id);
            $('#node-modal-form-title').val(data.name);
            $('#node-modal-form-description').val(data.description);
            $('#node-modal-form-workflow').val(data.workflowPath);
            $('#node-modal-form-colour').val(data.color)[0].jscolor.fromString(data.color);
            $('#node-modal-form-parent-id').val(data.parent);
            $('#node-modal-form-x').val(position.x);
            $('#node-modal-form-y').val(position.y);
            if (data.associatedResources) {
                Workflows.associatedResources.populate(data.associatedResources);
            }
        } else if (Workflows.state === 'edge selection') {
            data = Workflows.selected.data();
            $('#edge-modal').modal('show');
            $('#edge-modal-form-label').val(data.name);
        }
    },

    updateNode: function () {
        var node = Workflows.selected;
        Workflows.history.modify('edit node', function () {
            node.data('name', $('#node-modal-form-title').val());
            node.data('description', $('#node-modal-form-description').val());
            node.data('color', $('#node-modal-form-colour').val());
            node.data('font_color', $('#node-modal-form-colour').css("color"));
            node.data('associatedResources', Workflows.associatedResources.fetch());
            node.data('workflowPath', $('#node-modal-form-workflow').val());
            node.css('color', node.data('font_color'));
        });

        $('#node-modal').modal('hide');
        node.select();
    },

    updateEdge: function () {
        var edge = Workflows.selected;
        Workflows.history.modify('edit edge', function () {
            edge.data('name', $('#edge-modal-form-label').val());
        });

        $('#edge-modal').modal('hide');
        edge.select();
    },

    nodeModalConfirm: function () {
        if ($('#node-modal-form-id').val()) {
            Workflows.updateNode();
        } else {
            Workflows.addNode();
        }
    },

    edgeModalConfirm: function () {
        Workflows.updateEdge();
    },

    setLinkNodeState: function () {
        Workflows.setState('linking node', 'Click on a node to create a link.');
    },

    createLink: function (e) {
        Workflows.history.modify('link', function () {
            e.cy.add({
                group: "edges",
                data: {
                    source: Workflows.selected.data('id'),
                    target: e.cyTarget.data('id')
                }
            });
        });

        Workflows.cancelState();
    },

    delete: function () {
        if (confirm('Are you sure you wish to delete this?')) {
            Workflows.history.modify('delete node', function () {
                Workflows.selected.remove();
            });
            Workflows.cancelState();
        }
    },

    sidebar: {
        init: function () {
            var sidebar = $('#workflow-diagram-sidebar');
            sidebar.data('initialState', sidebar.html());
            //sidebar.html('');
        },

        populate: function (e) {
            if (e.cyTarget.isNode()) {
                $('#workflow-diagram-sidebar-title').html(e.cyTarget.data('name') || '<span class="muted">Untitled</span>');
                $('#workflow-diagram-sidebar-desc').html(HandlebarsTemplates['workflows/sidebar_content'](e.cyTarget.data()))
            } else if (e.cyTarget.isEdge()) {
                e.cyTarget.unselect();
                return false;
            }
        },

        clear: function () {
            var sidebar = $('#workflow-diagram-sidebar');
            sidebar.html(sidebar.data('initialState'));
        }
    },

    history: {
        initialize: function () {
            Workflows.history.index = 0;
            Workflows.history.stack = [{ action: 'initial state', elements: cy.elements().clone() }];
        },

        modify: function (action, modification) {
            if (typeof modification != 'undefined')
                modification();
            Workflows.history.stack.length = Workflows.history.index + 1; // Removes all "future" history after the current point.
            Workflows.history.index++;
            Workflows.history.stack.push({ action: action, elements: cy.elements().clone() });
            Workflows.history.setButtonState();
        },

        undo: function () {
            if (Workflows.history.index > 0) {
                Workflows.history.index--;
                Workflows.history.restore();
            }
        },

        redo: function () {
            if (Workflows.history.index < (Workflows.history.stack.length - 1)) {
                Workflows.history.index++;
                Workflows.history.restore();
            }
        },

        restore: function () {
            cy.elements().remove();
            Workflows.history.stack[Workflows.history.index].elements.restore();
            Workflows.history.setButtonState();
            Workflows.cancelState();
        },

        setButtonState: function () {
            if (Workflows.history.index < (Workflows.history.stack.length - 1)) {
                $('#workflow-toolbar-redo')
                    .removeClass('disabled')
                    .find('span')
                    .attr('title', 'Redo ' + Workflows.history.stack[Workflows.history.index + 1].action);
            } else {
                $('#workflow-toolbar-redo')
                    .addClass('disabled')
                    .find('span')
                    .attr('title', 'Redo');
            }

            if (Workflows.history.index > 0) {
                $('#workflow-toolbar-undo')
                    .removeClass('disabled')
                    .find('span')
                    .attr('title', 'Undo ' + Workflows.history.stack[Workflows.history.index].action);
            } else {
                $('#workflow-toolbar-undo')
                    .addClass('disabled')
                    .find('span')
                    .attr('title', 'Undo');
            }
        }
    },

    associatedResources: {
        types: {
            materials: { icon: 'fa-book' },
            events: {icon: 'fa-calendar'},
            tools: { icon: 'fa-wrench' },
            policies: { icon: 'fa-file-text-o' }
        },

        // Add a new blank form for an associated resource
        add: function () {
            var type = $(this).data('resourceType');
            $('#node-modal-associated-resource-list').append(
                HandlebarsTemplates['workflows/associated_resource_form']({
                    type: type,
                    icon: Workflows.associatedResources.types[type].icon
                })
            );
            return false;
        },

        delete: function () {
            $(this).parents('.associated-resource').remove();
            return false;
        },
        
        // Fetch the associated resources from the modal. Returns an array of objects that can be added to a node's data
        fetch: function (node) {
            var resources = [];
            $('#node-modal-associated-resource-list .associated-resource').each(function () {
                // "data-attribute" is just something I made up so I could identify the two form fields.
                // If I used the standard "name", they would end up getting posted to the server when the main workflow form is submitted.
                var resource = {
                    title: $('[data-attribute=title]', $(this)).val(),
                    url: $('[data-attribute=url]', $(this)).val(),
                    type: $('[data-attribute=type]', $(this)).val()
                };

                if (resource.url && resource.title) {
                    resources.push(resource);
                }
            });

            return resources;
        },

        // Populate the modal with existing associated resource forms that can be edited by the user
        populate: function (resources) {
            var resourceList = $('#node-modal-associated-resource-list');
            resourceList.html('');

            for(var i = 0; i < resources.length; i++) {
                var resource = resources[i];
                resource.icon = Workflows.associatedResources.types[resource.type].icon;
                resourceList.append(
                    HandlebarsTemplates['workflows/associated_resource_form'](resource)
                );
            }
        }
    }
};
