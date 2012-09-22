require File.dirname(__FILE__) + '/../test_helper'
require 'data_summary_controller'

# Re-raise errors caught by the controller.
class DataSummaryController; def rescue_action(e) raise e end; end

class DataSummaryControllerTest < Test::Unit::TestCase
  def setup
    @controller = DataSummaryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
