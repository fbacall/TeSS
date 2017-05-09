# A policy specific to things that have been scraped. Events and Materials

class ScrapedResourcePolicy < ResourcePolicy
  def manage?
    super || (@user && @user.is_curator?) ||
      (@record.respond_to?(:content_provider) && @record.content_provider && @record.content_provider.user == @user)
  end
end
