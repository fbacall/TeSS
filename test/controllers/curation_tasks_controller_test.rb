require 'test_helper'

class CurationTasksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index if curator' do
    sign_in users(:curator)

    get :index

    assert_response :success
  end

  test 'should get topic suggestions if admin' do
    sign_in users(:curator)

    get :index

    assert_response :success
  end

  test 'should not get index if regular user' do
    sign_in users(:regular_user)

    get :index

    assert_response :forbidden
    assert flash[:alert].include?('curator')
    assert_nil assigns(:curation_tasks)
  end
end
