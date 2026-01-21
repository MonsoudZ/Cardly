require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @collection = collections(:pokemon_collection)
  end

  test "should redirect index when not logged in" do
    get collections_url
    assert_redirected_to new_user_session_path
  end

  test "should get index when logged in" do
    sign_in @user
    get collections_url
    assert_response :success
  end

  test "should get new when logged in" do
    sign_in @user
    get new_collection_url
    assert_response :success
  end

  test "should create collection" do
    sign_in @user
    assert_difference("Collection.count") do
      post collections_url, params: { collection: { name: "New Collection", description: "Test", public: false } }
    end
    assert_redirected_to collection_url(Collection.last)
  end

  test "should not create collection with invalid data" do
    sign_in @user
    assert_no_difference("Collection.count") do
      post collections_url, params: { collection: { name: "", description: "Test" } }
    end
    assert_response :unprocessable_entity
  end

  test "should show collection" do
    sign_in @user
    get collection_url(@collection)
    assert_response :success
  end

  test "should get edit" do
    sign_in @user
    get edit_collection_url(@collection)
    assert_response :success
  end

  test "should update collection" do
    sign_in @user
    patch collection_url(@collection), params: { collection: { name: "Updated Name" } }
    assert_redirected_to collection_url(@collection)
    @collection.reload
    assert_equal "Updated Name", @collection.name
  end

  test "should not update collection with invalid data" do
    sign_in @user
    patch collection_url(@collection), params: { collection: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy collection" do
    sign_in @user
    assert_difference("Collection.count", -1) do
      delete collection_url(@collection)
    end
    assert_redirected_to collections_url
  end

  test "should not allow editing other user's collection" do
    sign_in users(:two)
    get edit_collection_url(@collection)
    assert_redirected_to collections_path
  end

  test "should not allow updating other user's collection" do
    sign_in users(:two)
    patch collection_url(@collection), params: { collection: { name: "Hacked" } }
    assert_redirected_to collections_path
    @collection.reload
    assert_not_equal "Hacked", @collection.name
  end

  test "should not allow destroying other user's collection" do
    sign_in users(:two)
    assert_no_difference("Collection.count") do
      delete collection_url(@collection)
    end
    assert_redirected_to collections_path
  end
end
