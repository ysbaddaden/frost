require "../record_test_helper"

module Trail
  class Record
    class Associations::HasOneTest < Minitest::Test
      def setup
        Profile.callbacks.clear
      end

      def test_association
        assert_equal profiles(:julien), users(:julien).profile
        assert_equal profiles(:ary), users(:ary).profile
      end

      def test_association_memoization
        user = users(:julien)
        assert_same user.profile, user.profile

        user.profile.nickname = "blank"
        refute_same user.profile, user.profile(true)
        refute_equal "blank", user.profile.nickname
      end

      def test_association_setter
        user, profile = users(:julien), profiles(:ary)
        assert_same profile, user.profile = profile
        assert_equal users(:julien).id, profile.user_id
        assert_equal users(:julien).id, Profile.find(profile.id).user_id
      end

      def test_autosave
        user = User.new(email: "walt@example.com")
        profile = Profile.new(nickname: "Walter")

        assert_same profile, user.profile = profile
        assert_nil profile.user_id
        assert_same user, profile.user

        assert user.save
        assert profile.persisted?
        assert_equal user.id, profile.user_id
      end

      def test_autosave_with_invalid_record
        user = User.new(email: "walt@example.com")
        user.profile = Profile.new(nickname: "")
        assert user.valid?
        refute user.profile.valid?

        refute user.save
        refute user.persisted?
        refute user.profile.persisted?
        assert user.errors[:base].any?
      end

      def test_build_association
        profile = users(:nobody).build_profile({ "nickname" => "test" })
        assert profile.is_a?(Profile)
        refute profile.persisted?

        assert_nil profile.id
        assert_equal users(:nobody).id, profile.user_id
        assert_equal users(:nobody), profile.user
      end

      def test_create_association
        profile = users(:nobody).create_profile({ "nickname" => "test" })
        assert profile.is_a?(Profile)
        assert profile.persisted?

        assert_equal users(:nobody).id, profile.user_id
        assert_same profile, users(:nobody).profile
      end

      def test_create_association_with_invalid_record
        profile = users(:nobody).create_profile({ "nickname" => "" })
        assert profile.is_a?(Profile)
        refute profile.persisted?

        assert_equal users(:nobody).id, profile.user_id
        assert_same profile, users(:nobody).profile
      end

      def test_bang_create_association
        profile = users(:nobody).create_profile({ "nickname" => "test" })
        assert profile.is_a?(Profile)
        assert profile.persisted?

        assert_equal users(:nobody).id, profile.user_id
        assert_same profile, users(:nobody).profile
      end

      def test_bang_create_association_with_invalid_record
        exception = assert_raises(RecordInvalid) do
          users(:nobody).create_profile!({ "nickname" => "" })
        end
        assert exception.record.is_a?(Profile)
        refute exception.record.persisted?
      end

      ifdef test_dependent_destroy
        def test_dependent_destroy_option
          assert users(:julien).destroy
          refute Profile.exists?(users(:julien).id)
          refute_empty Profile.callbacks
        end

      elsif test_dependent_delete
        def test_dependent_delete_option
          assert users(:julien).destroy
          refute Profile.exists?(users(:julien).id)
          assert_empty Profile.callbacks
        end

      elsif test_dependent_nullify
        def test_dependent_nullify_option
          assert users(:julien).destroy
          assert_nil profiles(:julien).user_id
        end

      elsif test_dependent_exception
        def test_dependent_exception_option
          assert_raises(DeleteRestrictionError) { users(:julien).destroy }
          refute users(:julien).deleted?
          assert User.exists?(users(:julien).id)
          assert_equal users(:julien).id, profiles(:julien).user_id
        end

      else
        def test_no_dependent_option
          assert users(:julien).destroy
          assert_equal users(:julien).id, profiles(:julien).user_id
          assert_empty Profile.callbacks
        end
      end
    end
  end
end
