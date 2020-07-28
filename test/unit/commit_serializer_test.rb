# frozen_string_literal: true
require 'test_helper'

module Shipit
  class DeploySerializerTest < ActiveSupport::TestCase
    test 'commit includes author object' do
      commit = shipit_commits(:first)

      serializer = ActiveModel::Serializer.serializer_for(commit)
      assert_equal CommitSerializer, serializer
      serialized = serializer.new(commit).to_json

      assert_json("author.name", commit.author.name, document: serialized)
    end
  end
end
