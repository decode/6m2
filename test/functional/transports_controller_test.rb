require 'test_helper'

class TransportsControllerTest < ActionController::TestCase
  setup do
    @transport = transports(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:transports)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create transport" do
    assert_difference('Transport.count') do
      post :create, :transport => @transport.attributes
    end

    assert_redirected_to transport_path(assigns(:transport))
  end

  test "should show transport" do
    get :show, :id => @transport.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @transport.to_param
    assert_response :success
  end

  test "should update transport" do
    put :update, :id => @transport.to_param, :transport => @transport.attributes
    assert_redirected_to transport_path(assigns(:transport))
  end

  test "should destroy transport" do
    assert_difference('Transport.count', -1) do
      delete :destroy, :id => @transport.to_param
    end

    assert_redirected_to transports_path
  end
end
