require 'test/helper'

class AttachmentTest < Test::Unit::TestCase
  def setup
    @now = Time.now
    Time.stubs(:now).returns(@now)
  end

  context "With a standard model Dummy, attachment :avatar, and no options" do
    setup do
      define_attachment! "Dummy", :avatar
    end

    should "define #avatar on Dummy" do
      assert Dummy.instance_methods.include?('avatar')
    end

    should "define #avatar= on Dummy" do
      assert Dummy.instance_methods.include?('avatar')
    end
  end

  context "With a standard model Dummy, attachment :avatar, and no options, assigning a file" do
    setup do
      define_attachment! "Dummy", :avatar
      @dummy = Dummy.new
      @dummy.avatar = fixture_file("image.jpg")
    end

    should "assign the file's name to avatar_file_name" do
      assert_equal "image.jpg", @dummy.avatar_file_name
    end

    should "assign the file's content type to avatar_content_type" do
      assert_equal "image/jpeg", @dummy.avatar_content_type
    end

    should "assign the file's size to avatar_file_size" do
      assert_equal File.size(fixture_file("image.jpg").path), @dummy.avatar_file_size
    end

    should "not store the file on the filesystem yet" do
      assert ! File.exist?(@dummy.avatar.path)
    end

    should "store the file on the filesystem after the model has been saved" do
      @dummy.save
      assert File.exist?(@dummy.avatar.path), @dummy.avatar.path
    end
  end

  context "With a standard model Dummy, attachment :avatar, and no options, assigning a StringIO" do
    setup do
      define_attachment! "Dummy", :avatar
      @dummy = Dummy.new
      @stringio = StringIO.new("This is a file")
      @dummy.avatar = @stringio
    end

    should "assign the file's name to avatar_file_name" do
      assert_equal "default.txt", @dummy.avatar_file_name
    end

    should "assign the file's content type to avatar_content_type" do
      assert_equal "text/plain", @dummy.avatar_content_type
    end

    should "assign the file's size to avatar_file_size" do
      assert_equal @stringio.length, @dummy.avatar_file_size
    end

    should "not store the file on the filesystem yet" do
      assert ! File.exist?(@dummy.avatar.path)
    end

    should "store the file on the filesystem after the model has been saved" do
      @dummy.save
      assert File.exist?(@dummy.avatar.path), @dummy.avatar.path
    end
  end

  should "put the file in the right place when given a :path" do
    define_attachment! "Dummy", :avatar, :path => "tmp/:class/:attachment/:id_partition/:filename"
    @dummy = Dummy.new
    @dummy.avatar = fixture_file("image.jpg")
    @dummy.save
    assert_match %r{tmp/dummies/avatars/000/000/001/image.jpg}, @dummy.avatar.path
  end

  should "return a properly interpolated url from #url when given a :url option" do
    define_attachment! "Dummy", :avatar, :url => ":class/:attachment/:filename"
    @dummy = Dummy.new
    @dummy.avatar = fixture_file("image.jpg")
    assert_match %r{dummies/avatars/image.jpg}, @dummy.avatar.url
  end

  should "return a properly interpolated url from #url when there is no attachment" do
    define_attachment! "Dummy", :avatar, :default_url => ":class/:attachment/not_found"
    @dummy = Dummy.new
    assert_match %r{dummies/avatars/not_found}, @dummy.avatar.url
  end

  should "use the default url when there is no attachment and the real url when there is" do
    define_attachment! "Dummy", :avatar, :default_url => ":class/:attachment/not_found",
                                         :url         => ":class/:attachment/:filename"
    @dummy = Dummy.new
    assert_match %r{dummies/avatars/not_found}, @dummy.avatar.url
    @dummy.avatar = fixture_file("image.jpg")
    assert_match %r{dummies/avatars/image.jpg}, @dummy.avatar.url
  end

  context "with a saved attachment on a model" do
    setup do
      define_attachment! "Dummy", :avatar, :path => "tmp/:class/:attachment/:id_partition/:filename"
      @dummy = Dummy.new
      @dummy.avatar = fixture_file("image.jpg")
      @dummy.save
      @current_path = @dummy.avatar.path
    end

    should "not delete the attachment when assigned nil" do
      @dummy.avatar = nil
      assert File.exists?(@current_path)
    end

    should "delete the file attachment when assigned nil and saved" do
      @dummy.avatar = nil
      @dummy.save
      assert ! File.exists?(@current_path)
    end

    should "delete the file attachment when the model is destroyed" do
      @dummy.destroy
      assert ! File.exists?(@current_path)
    end

    should "move the file if the destination path changes" do
      @dummy.id = @dummy.id + 1000
      @expected_path = @dummy.avatar.path
      @dummy.save
      assert ! File.exists?(@current_path)
      assert   File.exists?(@expected_path)
    end
  end

    # should "retain all the right attributes after saving and reloading the model" do
    #   @dummy.save
    #   @dummy = Dummy.find(@dummy.id)

    #   assert_equal "image.jpg",  @dummy.avatar_file_name
    #   assert_equal "image/jpeg", @dummy.avatar_content_type
    #   assert_equal @now.to_i,    @dummy.avatar_updated_at.to_i
    #   assert_equal File.size(fixture_file_path("image.jpg")),
    #                              @dummy.avatar_file_size
    # end

    # should "save the attachment to a location on disk when saving the model" do
    #   @dummy.save
    #   assert File.exists?(@dummy.avatar.path)
    #   assert_equal IO.read(fixture_file_path("image.jpg")), IO.read(@dummy.avatar.path)
    # end
  # end

  # context "With a standard model, attachment, and a small thumbnail" do
  #   setup do
  #     define_attachment! "Dummy", :avatar, :styles => {:small => {:processors => [:null]}}
  #     @dummy = Dummy.new
  #     @dummy.avatar = fixture_file("image.jpg")
  #   end

  #   should "put a file in a location appropriate to the style after save" do
  #     @dummy.save
  #     assert File.exists?(@dummy.avatar.path(:small))
  #   end
  # end
end
