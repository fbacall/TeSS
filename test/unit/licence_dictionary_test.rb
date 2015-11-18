require 'test_helper'
# require File.expand_path('lib/licence_dictionary.rb')
require File.expand_path(Rails.root.join('lib', 'tess', 'licence_dictionary.rb'))

class LicenceDictionaryTest < ActiveSupport::TestCase

  test "singleton" do
    dic = TeSS::LicenceDictionary.instance
    assert dic.is_a?(TeSS::LicenceDictionary)

    dic2 = TeSS::LicenceDictionary.instance
    assert_same dic,dic2

    assert_raise NoMethodError do
      TeSS::LicenceDictionary.new
    end
  end

  test "licences dictionary exists" do
    dic = TeSS::LicenceDictionary.instance
    assert_not_nil dic, "licence dictionary should exist"
    assert_not dic.licence_names.blank?, "licence dictionary should not be empty"
  end

  test "licence values exist" do
    dic = TeSS::LicenceDictionary.instance
    assert (dic.licence_abbreviations.include? "Apache-2.0"), "'Apache-2.0' should be among the licence abbreviations"
    assert_not (dic.licence_abbreviations.include? "licence_that_will_never_exist"), "'licence_that_will_never_exist' should not be among licences"
    assert (dic.licence_names.include? "Apache Software License 2.0"), "'Apache Software License 2.0' should be among the licence names"
    assert_equal "http://www.opensource.org/licenses/Apache-2.0", dic.licence_url_for_abbreviation("Apache-2.0"), "'http://www.opensource.org/licenses/Apache-2.0' should be among the licence names"

  end

end