# frozen_string_literal: true

RSpec.describe RuboCop::Cop::GraphQL::FieldMethod, :config do
  it "not registers an offense" do
    expect_no_offenses(<<~RUBY)
      class UserType < BaseType
        field :phone, String, null: true, method: :home_phone
      end
    RUBY
  end

  context "when class has two fields" do
    it "not registers an offense" do
      expect_no_offenses(<<~RUBY)
        class UserType < BaseType
          field :name, String, null: true
          field :phone, String, null: true, method: :home_phone
        end
      RUBY
    end
  end

  context "when resolver method only calls one method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class UserType < BaseType
          field :phone, String, null: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use method: :home_phone

          def phone
            object.home_phone
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class UserType < BaseType
          field :phone, String, null: true, method: :home_phone
        end
      RUBY
    end

    context "when there are valid fields around" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class UserType < BaseType
            field :name, String, null: false
            field :phone, String, null: true
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use method: :home_phone
            field :address, String, null: true

            def phone
              object.home_phone
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class UserType < BaseType
            field :name, String, null: false
            field :phone, String, null: true, method: :home_phone
            field :address, String, null: true
          end
        RUBY
      end
    end

    context "when suggested method name would conflict with Ruby or GraphQL-Ruby keywords" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class UserType < BaseType
            field :context, String, null: true, resolver_method: :user_context

            def user_context
              object.context
            end
          end
        RUBY
      end
    end
  end

  context "when resolver method is more complex" do
    it "not registers an offense" do
      expect_no_offenses(<<~RUBY)
        class UserType < BaseType
          field :phone, String, null: true

          def phone
            object.contact.home_phone
          end
        end
      RUBY
    end
  end
end
