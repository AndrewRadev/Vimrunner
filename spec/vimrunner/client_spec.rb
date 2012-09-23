require "spec_helper"
require "vimrunner"

module Vimrunner
  describe Client do
    let!(:client) { Vimrunner.start }

    after :each do
      client.kill
    end

    it "is instantiated in the current directory" do
      cwd = FileUtils.getwd
      client.command(:pwd).should eq cwd
    end

    it "can write a file through Vim" do
      client.edit 'some_file'
      client.insert 'Contents of the file'
      client.write

      File.exists?('some_file').should be_true
      File.read('some_file').strip.should eq 'Contents of the file'
    end

    it "can execute commands with a bang" do
      client.edit 'some_file'
      client.insert 'Contents of the file'
      client.edit! 'some_other_file'
      client.insert 'Contents of the other file'
      client.command :write

      File.exists?('some_file').should be_false
      File.exists?('some_other_file').should be_true
      File.read('some_other_file').strip.should eq 'Contents of the other file'
    end

    it "can add a plugin for Vim to use" do
      FileUtils.mkdir_p 'example/plugin'
      File.open('example/plugin/test.vim', 'w') do |f|
        f.write 'command Okay echo "OK"'
      end

      client.add_plugin('example', 'plugin/test.vim')

      client.command('Okay').should eq 'OK'
    end

    it "can chain several operations" do
      client.edit('some_file').insert('Contents').write
      File.exists?('some_file').should be_true
      File.read('some_file').strip.should eq 'Contents'
    end

    describe "#set" do
      it "activates a boolean setting" do
        client.set 'expandtab'
        client.command('echo &expandtab').should eq '1'

        client.set 'noexpandtab'
        client.command('echo &expandtab').should eq '0'
      end

      it "sets a setting to a given value" do
        client.set 'tabstop', 3
        client.command('echo &tabstop').should eq '3'
      end

      it "can be chained" do
        client.set('expandtab').set('tabstop', 3)
        client.command('echo &expandtab').should eq '1'
        client.command('echo &tabstop').should eq '3'
      end
    end

    describe "#search" do
      before :each do
        client.edit 'some_file'
        client.insert 'one two'
      end

      it "positions the cursor on the search term" do
        client.search 'two'
        client.normal 'dw'

        client.write

        File.read('some_file').strip.should eq 'one'
      end

      it "can be chained" do
        client.search('two').search('one')
        client.normal 'dw'

        client.write

        File.read('some_file').strip.should eq 'two'
      end
    end

    describe "#echo" do
      it "returns the result of a given expression" do
        client.echo('"foo"').should eq 'foo'
      end

      it "returns the result of multiple expressions" do
        client.command('let b:foo = "bar"')
        client.echo('"foo"', 'b:foo').should eq 'foo bar'
      end
    end

    describe "#command" do
      it "returns the output of a Vim command" do
        client.command(:version).should include '+clientserver'
        client.command('echo "foo"').should eq 'foo'
      end

      it "allows single quotes in the command" do
        client.command("echo 'foo'").should eq 'foo'
      end

      it "raises an error for a non-existent Vim command" do
        expect {
          client.command(:nonexistent)
        }.to raise_error(InvalidCommandError)
      end
    end
  end
end
