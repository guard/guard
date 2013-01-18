# encoding: utf-8

require 'spec_helper'

describe Guard::DslDescriber do

  let(:guardfile) do
    <<-GUARDFILE
      guard :test, :a => :b, :c => :d do
        watch('c')
      end

      group :a do
        guard 'test', :x => 1, :y => 2 do
          watch('c')
        end
      end

      group "b" do
        guard :another do
          watch('c')
        end
      end
    GUARDFILE
  end

  before do
    stub_const 'Guard::Test', Class.new(Guard::Guard)
    stub_const 'Guard::Another', Class.new(Guard::Guard)
  end

  describe '.list' do
    let(:output) do
      <<-OUTPUT.gsub(/^\s+|\n$/, '')
        +------------+--------------+
        |  Available Guard plugins  |
        +------------+--------------+
        | Plugin     | In Guardfile |
        +------------+--------------+
        | Another    | ✔            |
        | Even       | ✘            |
        | More       | ✘            |
        | Test       | ✔            |
        +------------+--------------+
      OUTPUT
    end

    before do
      ::Guard.stub(:guard_gem_names).and_return %w(test another even more)
    end

    it 'lists the available Guards when they\'re declared as strings or symbols' do
      # Delete is needed for 1.8.7 compatibility only
      ::Guard::DslDescriber.list(:guardfile_contents => guardfile).to_s.delete(' ').should eq(output.delete(' '))
    end
  end

  describe '.show' do
    let(:output) do
      <<-OUTPUT.gsub(/^\s+|\n$/, '')
       +---------+---------+--------+-------+
       |        Guardfile structure         |
       +---------+---------+--------+-------+
       | Group   | Plugin  | Option | Value |
       +---------+---------+--------+-------+
       | Default | Test    | a      | :b    |
       |         |         | c      | :d    |
       | A       | Test    | x      | 1     |
       |         |         | y      | 2     |
       | B       | Another |        |       |
       +---------+---------+--------+-------+
      OUTPUT
    end

    it 'shows the Guards and their options' do
      ::Guard::DslDescriber.show(:guardfile_contents => guardfile).to_s.should eq(output)
    end
  end

end
