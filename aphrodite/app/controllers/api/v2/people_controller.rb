class Api::V2::PeopleController < Api::V2::BaseController
  def index
    document = current_user.documents.find(params[:document_id])
    @people = document.people
  end
end
