require 'test_helper'

class CurationTaskTest < ActiveSupport::TestCase
  test 'resolves curation task on save' do
    event = events(:portal_event)
    curator = users(:curator)
    task = event.curation_tasks.create
    User.current_user = curator

    assert_equal 1, event.reload.curation_tasks.count
    assert_equal 1, event.reload.curation_tasks.open.count

    assert_difference('event.curation_tasks.open.count', -1) do
      event.related_curation_task = task
      event.update_attributes(title: 'I have been updated')
    end

    task.reload
    assert_equal curator, task.completed_by
  end
end
