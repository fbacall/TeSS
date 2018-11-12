require 'test_helper'

class CurationTasksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index if curator' do
    sign_in users(:curator)

    get :index

    assert_redirected_to next_curation_tasks_path
  end

  test 'should get topic suggestions if admin' do
    sign_in users(:curator)

    get :index

    assert_redirected_to next_curation_tasks_path
  end

  test 'should not get index if regular user' do
    sign_in users(:regular_user)

    get :index

    assert_response :forbidden
    assert flash[:alert].include?('curator')
    assert_nil assigns(:curation_tasks)
  end

  test 'should get curation task' do
    sign_in users(:curator)
    task = curation_tasks(:assigned)

    get :show, params: { id: task }

    assert_response :success
    assert_select '#related_curation_task_id[value=?]', task.id.to_s
    assert_select '#event_form', count: 1
  end

  test 'should get next curation task from queue' do
    CurationTask.destroy_all
    event = events(:iann_event)
    curator = users(:curator)
    unassigned = event.curation_tasks.create(status: 'open', priority: 10)
    unassigned_high_prio = event.curation_tasks.create(status: 'open', priority: 100)
    assigned = event.curation_tasks.create(status: 'open', assignee: curator, priority: 10)
    assigned_high_prio = event.curation_tasks.create(status: 'open', assignee: curator, priority: 100)

    sign_in curator

    get :next
    assert_redirected_to assigned_high_prio
    assigned_high_prio.resolve

    get :next
    assert_redirected_to assigned
    assigned.resolve

    get :next
    assert_redirected_to unassigned_high_prio
    unassigned_high_prio.resolve

    get :next
    assert_redirected_to unassigned
    unassigned.resolve

    get :next
    assert_redirected_to curation_tasks_path
    assert_includes flash[:notice], 'tasks'
  end
end
