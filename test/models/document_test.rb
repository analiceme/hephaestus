# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

class TestDocument < Test::Unit::TestCase
  context "Export to CSV" do
    setup do
      @document    = create :document
      @person1      = create :person
      @person2      = create :person
      @person3      = create :person
      @person1.documents << @document
      @person2.documents << @document
      @person3.documents << @document

      name_entity  = create :name_entity, document: @document
      date_entity  = create :date_entity, document: @document
      @register    = create :register, document: @document, who: [name_entity.id], what: "nacio", when: [date_entity.id]
    end

    should "generate CSV with all the people" do
      assert_respond_to @document, :to_csv
      assert_instance_of String, @document.to_csv
    end

    should "Export registers as CSV"
  end
end

