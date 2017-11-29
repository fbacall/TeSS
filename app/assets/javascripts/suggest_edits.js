/**
 * Created by milo on 29/11/2017.
 */
function showSEarea() {
    $('#suggest_edits_form_area').show('slow');
    $('#open_suggest_edits').hide('slow');
}

function hideSEarea() {
    $('#suggest_edits_form_area').hide('slow');
    $('#open_suggest_edits').show('slow');
}

function submitEditSuggestions() {
    alert("Form submitted!");
}