require 'test_helper'

class OverviewControllerTest < ActionController::TestCase
  test "show overview" do
    get(:show, {'system' => 'ps', 'name' => 'something'})
    assert_response :success
  end
end
