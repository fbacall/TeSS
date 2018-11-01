require 'test_helper'

class CurationTaskTest < ActiveSupport::TestCase
  test 'validates task key/status' do
    event = events(:portal_event)
    invalid_task = event.curation_tasks.build(status: 'banana', key: 'hotornot')

    refute invalid_task.save
    refute_empty invalid_task.errors[:status]
    refute_empty invalid_task.errors[:key]
  end

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

  test 'scopes' do
    event = events(:portal_event)
    curator = users(:curator)
    open = event.curation_tasks.create(status: 'open')
    resolved = event.curation_tasks.create(status: 'resolved')
    assigned = event.curation_tasks.create(status: 'open', assignee: curator)
    assigned_resolved = event.curation_tasks.create(status: 'resolved', assignee: curator)

    curators_tasks = curator.curation_tasks.to_a
    assert_includes curators_tasks, assigned
    assert_includes curators_tasks, assigned_resolved
    assert_not_includes curators_tasks, resolved
    assert_not_includes curators_tasks, open

    curators_open_tasks = curator.curation_tasks.open.to_a
    assert_includes curators_open_tasks, assigned
    assert_not_includes curators_open_tasks, assigned_resolved
    assert_not_includes curators_open_tasks, resolved
    assert_not_includes curators_open_tasks, open

    unassigned_tasks = CurationTask.unassigned.to_a
    assert_not_includes unassigned_tasks, assigned
    assert_not_includes unassigned_tasks, assigned_resolved
    assert_includes unassigned_tasks, resolved
    assert_includes unassigned_tasks, open

    unassigned_open_tasks = CurationTask.unassigned.open.to_a
    assert_not_includes unassigned_open_tasks, assigned
    assert_not_includes unassigned_open_tasks, assigned_resolved
    assert_not_includes unassigned_open_tasks, resolved
    assert_includes unassigned_open_tasks, open
  end

  test 'curation queue for user' do
    CurationTask.destroy_all
    event = events(:iann_event)
    curator = users(:curator)
    unassigned = event.curation_tasks.create(status: 'open', priority: 10)
    unassigned_high_prio = event.curation_tasks.create(status: 'open', priority: 100)
    resolved = event.curation_tasks.create(status: 'resolved')
    assigned = event.curation_tasks.create(status: 'open', assignee: curator, priority: 10)
    assigned_high_prio = event.curation_tasks.create(status: 'open', assignee: curator, priority: 100)

    queue = curator.curation_task_queue.to_a
    assert_not_includes queue, resolved
    assert_equal [assigned_high_prio, assigned, unassigned_high_prio, unassigned], queue
  end

  test 'auto-resolves review suggestion tasks when edit suggestion is destroyed' do
    event = events(:iann_event)
    topic = EDAM::Ontology.instance.lookup_by_name('Proteins')
    curator = users(:curator)
    User.current_user = curator
    suggestion = event.create_edit_suggestion(scientific_topic_uris: [topic.uri])
    review_task = event.curation_tasks.create(key: 'review_suggestions')

    assert_difference('event.curation_tasks.open.count', -1) do
      assert_difference('EditSuggestion.count', -1) do
        suggestion.accept_suggestion(:scientific_topics, topic)
      end
    end

    refute review_task.reload.open?
    assert_equal curator, review_task.completed_by
  end
end
