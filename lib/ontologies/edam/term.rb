module EDAM
  class Term < ::OntologyTerm
    def preferred_label
      data[RDF::RDFS.label].first.value
    end

    def has_exact_synonym
      data[OBO.hasExactSynonym] ? data[OBO.hasExactSynonym].map(&:value) : []
    end
    alias synonyms has_exact_synonym

    def has_narrow_synonym
      data[OBO.hasNarrowSynonym] ? data[OBO.hasNarrowSynonym].map(&:value) : []
    end

    def has_broad_synonym
      data[OBO.hasBroadSynonym] ? data[OBO.hasBroadSynonym].map(&:value) : []
    end

    def inspect
      "<#{self.class} @ontology=#{ontology.class.name}, @uri=#{uri}, preferred_label: #{preferred_label}>"
    end
  end
end
