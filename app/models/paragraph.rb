class Paragraph
  include Mongoid::Document

  field :content,          :type => String
  field :information,      :type => Hash

  embedded_in :document

  def info
    output= ""
    # self.information.each do |k, v|
    #   output << "#{k}: #{v}\n"
    # end
    output
  end

  def first_words
    self.content[0..40]
  end
end
