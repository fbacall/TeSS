require 'ontologies/edam/ontology'

OBO = RDF::Vocabulary.new('http://www.geneontology.org/formats/oboInOwl#')
OBO_EDAM = RDF::Vocabulary.new('http://purl.obolibrary.org/obo/edam#')

# EDAM::Ontology.instance.load